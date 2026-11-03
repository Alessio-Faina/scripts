#!/bin/bash
# Save a set of messages piped from mutt (pipe_split=no) as a git-am-ready mbox.
#
# Mutt does not emit mbox "From " separator lines when piping messages that
# live in Maildir/IMAP, so the muttrc macro sets $pipe_sep to a marker line
# which we replace with a real "From " line here. Cover letters ([PATCH 0/N])
# and empty messages are dropped so that git am does not stop on them.

DEST_DIR="$HOME/kernel-patches"
SEP_MARKER="__MUTT_PIPE_SEP__"
FROM_LINE="From mutt@localhost Thu Jan  1 00:00:00 1970"

mkdir -p "$DEST_DIR"
RAW_FILE=$(mktemp)
TMP_FILE=$(mktemp "$DEST_DIR/.save-mbox.XXXXXX")
trap 'rm -f "$RAW_FILE" "$TMP_FILE"' EXIT

cat > "$RAW_FILE"

# Name the file after the first Subject (the cover letter if present),
# unfolding continuation lines.
RAW_SUBJECT=$(awk '
    insubj && /^[ \t]/ { sub(/^[ \t]+/, " "); s = s $0; next }
    insubj             { exit }
    tolower($0) ~ /^subject:/ { sub(/^[^:]*:[ \t]*/, ""); s = $0; insubj = 1 }
    END { print s }
' "$RAW_FILE")

CLEAN_SUBJECT=$(printf '%s' "$RAW_SUBJECT" | sed -E 's/[^a-zA-Z0-9]+/_/g; s/^_+|_+$//g' | cut -c1-150)
[ -z "$CLEAN_SUBJECT" ] && CLEAN_SUBJECT="patch_series_$(date +%s)"

# Split on markers, drop cover letters and empty messages, emit mbox.
awk -v marker="$SEP_MARKER" -v from="$FROM_LINE" '
    function flush(   i) {
        if (n && nonblank && !cover) {
            print from
            for (i = 1; i <= n; i++) print buf[i]
        }
        n = 0; nonblank = 0; cover = 0; inhdr = 1
    }
    BEGIN { inhdr = 1 }
    $0 == marker { flush(); next }
    n == 0 && /^From / { next }          # drop any existing From_ line
    {
        buf[++n] = $0
        if ($0 != "") nonblank = 1
        if (inhdr && $0 == "") inhdr = 0
        if (inhdr && tolower($0) ~ /^subject:.*\[[^]]*patch[^]]* 0+\/[0-9]+\]/) cover = 1
    }
    END { flush() }
' "$RAW_FILE" > "$TMP_FILE"

if [ ! -s "$TMP_FILE" ]; then
    echo "save-mbox: no patches found in input" >&2
    exit 1
fi

mv "$TMP_FILE" "$DEST_DIR/${CLEAN_SUBJECT}.mbox"

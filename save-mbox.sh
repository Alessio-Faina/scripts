#!/usr/bin/env python3
"""Save a patch thread piped from mutt (pipe_split=no) as a git-am-ready mbox.

Mutt does not emit mbox "From " separator lines when piping messages that live
in Maildir/IMAP, so the muttrc macro sets $pipe_sep to a marker line which is
used here to split the stream into individual messages.

- Only real patches (non-reply messages containing a diff) are written, so
  cover letters, ACK/NACK/APPLIED and other replies don't stop git am.
- Replies whose subject starts with "ACK" add "Acked-by: Name <email>" and
  replies starting with "APPLIED" add "Signed-off-by: Name <email>" to the
  commit message of the patch they reply to (or to every patch if they reply
  to the cover letter). Acks come first, ordered by date, then sign-offs.
- Mailing-list munged senders ("Name via kernel-team <list@...>") are
  resolved through the Reply-To header, both for trailers and for the patch
  From: header (which git am uses as the commit author).
"""

import base64
import os
import quopri
import re
import sys
import tempfile
from email import message_from_bytes
from email.header import decode_header, make_header
from email.policy import compat32
from email.utils import formataddr, getaddresses, parseaddr, parsedate_to_datetime

DEST_DIR = os.path.expanduser("~/kernel-patches")
SEP_MARKER = b"__MUTT_PIPE_SEP__"
FROM_LINE = b"From mutt@localhost Thu Jan  1 00:00:00 1970\n"

REPLY_RE = re.compile(r"^\s*(re|aw|fwd?|ack|nack|nak|applied)\b", re.I)
ACK_RE = re.compile(r"^\s*ack\b", re.I)            # ACK:, ACK/Cmnt:
NACK_RE = re.compile(r"^\s*(nack|nak)\b", re.I)
APPLIED_RE = re.compile(r"^\s*applied\b", re.I)
PATCHNUM_RE = re.compile(r"\[[^\]]*patch[^\]]*?\s(\d+)/(\d+)\]", re.I)
VIA_RE = re.compile(r"\s+via\s+\S+$")


def warn(msg):
    print(f"save-mbox: {msg}", file=sys.stderr)


def hdr(msg, name):
    """Decoded, unfolded header value."""
    value = msg.get(name)
    if value is None:
        return ""
    try:
        value = str(make_header(decode_header(value)))
    except Exception:
        value = str(value)
    return re.sub(r"\s*\n\s*", " ", value).strip()


def msgids(value):
    return re.findall(r"<[^>]+>", value or "")


class Mail:
    def __init__(self, raw, index):
        self.raw = raw
        self.index = index
        self.msg = message_from_bytes(raw, policy=compat32)
        self.subject = hdr(self.msg, "Subject")
        self.msgid = (msgids(hdr(self.msg, "Message-ID")) or [None])[0]
        parents = msgids(hdr(self.msg, "In-Reply-To")) or msgids(hdr(self.msg, "References"))[-1:]
        self.parent = parents[0] if parents else None
        try:
            self.date = parsedate_to_datetime(hdr(self.msg, "Date")).timestamp()
        except Exception:
            self.date = float(index)
        m = PATCHNUM_RE.search(self.subject)
        self.num = int(m.group(1)) if m else None
        self.trailers = []

    def text_part(self):
        for part in self.msg.walk():
            if part.get_content_type() == "text/plain" and not part.is_multipart():
                payload = part.get_payload(decode=True) or b""
                charset = part.get_content_charset() or "utf-8"
                try:
                    return payload.decode(charset, errors="surrogateescape")
                except LookupError:
                    return payload.decode("utf-8", errors="surrogateescape")
        return ""

    @property
    def is_reply(self):
        return bool(REPLY_RE.match(self.subject))

    @property
    def is_patch(self):
        return not self.is_reply and re.search(r"^diff --git ", self.text_part(), re.M) is not None

    @property
    def is_cover(self):
        return not self.is_reply and self.num == 0

    def sender(self):
        """Real (name, email) of the sender, undoing mailing-list munging."""
        name, addr = parseaddr(hdr(self.msg, "From"))
        list_addrs = {a.lower() for a in re.findall(r"mailto:([^>?\s]+)", hdr(self.msg, "List-Post"))}
        if VIA_RE.search(name) or addr.lower() in list_addrs:
            name = VIA_RE.sub("", name)
            for h in ("Reply-To", "X-Original-From"):
                for rname, raddr in getaddresses([hdr(self.msg, h)]):
                    if raddr and raddr.lower() not in list_addrs:
                        return (rname or name), raddr
            return name, None
        return name, addr

    def fix_author(self, raw):
        """Replace a list-munged From: header with the real sender.

        git am takes the commit author from From:, so without this commits end
        up authored by "Name via kernel-team <kernel-team@lists.ubuntu.com>".
        Returns (raw, new_author or None).
        """
        name, addr = parseaddr(hdr(self.msg, "From"))
        real_name, real_addr = self.sender()
        if not real_addr:
            if VIA_RE.search(name):
                warn(f"cannot determine real author e-mail, From: left as is: {self.subject}")
            return raw, None
        if (real_name, real_addr.lower()) == (name, addr.lower()):
            return raw, None
        split = raw.find(b"\n\n")
        header, rest = raw[: split + 1], raw[split + 1 :]
        new_from = formataddr((real_name, real_addr), charset="utf-8").encode("ascii")
        header, n = re.subn(rb"(?im)^from:.*\n(?:[ \t].*\n)*", lambda _: b"From: " + new_from + b"\n", header, count=1)
        if not n:
            return raw, None
        return header + rest, f"{real_name} <{real_addr}>" if real_name else real_addr

    def add_trailers(self):
        """Append trailers to the commit message; returns the new raw mail."""
        if self.msg.is_multipart():
            warn(f"multipart patch, trailers not added: {self.subject}")
            return self.raw
        cte = (self.msg.get("Content-Transfer-Encoding") or "7bit").strip().lower()
        charset = self.msg.get_content_charset() or "us-ascii"
        lines = self.text_part().split("\n")
        try:
            sep = lines.index("---")
        except ValueError:
            warn(f"no '---' separator, trailers not added: {self.subject}")
            return self.raw
        existing = {l.strip() for l in lines[:sep]}
        new = []
        for t in self.trailers:
            if t not in existing and t not in new:
                new.append(t)
        if not new:
            return self.raw
        pos = sep
        while pos > 0 and lines[pos - 1].strip() == "":
            pos -= 1
        lines[pos:pos] = new
        text = "\n".join(lines)

        split = self.raw.find(b"\n\n")
        header, _ = self.raw[: split + 1], self.raw[split + 2 :]
        try:
            body = text.encode(charset, errors="surrogateescape")
        except (UnicodeEncodeError, LookupError):
            # e.g. us-ascii mail but a reviewer's name needs UTF-8
            body = text.encode("utf-8", errors="surrogateescape")
            if re.search(rb"(?im)^content-type:", header):
                header = re.sub(rb'(?i)charset="?[^";\s]+"?', b'charset="utf-8"', header, count=1)
            else:
                header += b'Content-Type: text/plain; charset="utf-8"\n'
            if cte in ("7bit", ""):
                cte = "8bit"
                header = re.sub(rb"(?im)^(content-transfer-encoding:).*$", rb"\1 8bit", header)
        if cte == "base64":
            body = base64.encodebytes(body)
        elif cte == "quoted-printable":
            body = quopri.encodestring(body)
        return header + b"\n" + body

    def summary(self):
        return f"[{self.num}] " if self.num is not None else ""


def split_stream(data):
    chunks, cur = [], []
    for line in data.splitlines(keepends=True):
        if line.rstrip(b"\r\n") == SEP_MARKER:
            chunks.append(b"".join(cur))
            cur = []
        else:
            cur.append(line)
    chunks.append(b"".join(cur))
    mails = []
    for chunk in chunks:
        if chunk.startswith(b"From "):  # pre-existing From_ line
            chunk = chunk.split(b"\n", 1)[1] if b"\n" in chunk else b""
        if chunk.strip():
            if not chunk.endswith(b"\n"):
                chunk += b"\n"
            mails.append(Mail(chunk, len(mails)))
    return mails


def resolve_targets(reply, by_id, patches):
    """Patches a reply refers to: walk up the thread to a patch or cover letter."""
    seen = set()
    parent = reply.parent
    while parent and parent in by_id and parent not in seen:
        seen.add(parent)
        p = by_id[parent]
        if p in patches:
            return [p]
        if p.is_cover:
            return patches
        parent = p.parent
    # Fall back to the [PATCH n/N] number in the reply subject.
    if reply.num:
        match = [p for p in patches if p.num == reply.num]
        if match:
            return match
    return patches


def main():
    mails = split_stream(sys.stdin.buffer.read())
    if not mails:
        warn("empty input")
        return 1

    patches = [m for m in mails if m.is_patch]
    if not patches:
        warn("no patches found in input")
        return 1
    by_id = {m.msgid: m for m in mails if m.msgid}

    replies = sorted((m for m in mails if m.is_reply), key=lambda m: (m.date, m.index))
    acks, signoffs = [], []
    for r in replies:
        if NACK_RE.match(r.subject):
            name, addr = r.sender()
            warn(f"NACK from {name} <{addr}>: {r.subject}")
            continue
        if ACK_RE.match(r.subject):
            kind, bucket = "Acked-by", acks
        elif APPLIED_RE.match(r.subject):
            kind, bucket = "Signed-off-by", signoffs
        else:
            continue
        name, addr = r.sender()
        if not addr:
            warn(f"cannot determine e-mail of {name!r}, skipping: {r.subject}")
            continue
        trailer = f"{kind}: {name} <{addr}>" if name else f"{kind}: {addr}"
        bucket.append((trailer, resolve_targets(r, by_id, patches)))

    for trailer, targets in acks + signoffs:
        for p in targets:
            p.trailers.append(trailer)

    # File name from the first message (normally the cover letter).
    clean = re.sub(r"[^a-zA-Z0-9]+", "_", mails[0].subject).strip("_")[:150]
    if not clean:
        import time
        clean = f"patch_series_{int(time.time())}"

    os.makedirs(DEST_DIR, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=".save-mbox.", dir=DEST_DIR)
    try:
        with os.fdopen(fd, "wb") as out:
            for i, p in enumerate(patches):
                if i:
                    out.write(b"\n")
                out.write(FROM_LINE)
                raw, p.author = p.fix_author(p.add_trailers())
                out.write(raw)
        final = os.path.join(DEST_DIR, clean + ".mbox")
        os.replace(tmp, final)
    except BaseException:
        os.unlink(tmp)
        raise

    print(f"save-mbox: {final}: {len(patches)} patch(es)", file=sys.stderr)
    for p in patches:
        extra = ", ".join(t for t in dict.fromkeys(p.trailers)) or "no trailers added"
        print(f"  {p.summary()}{extra}", file=sys.stderr)
        if p.author:
            print(f"  {p.summary()}Author: {p.author}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())

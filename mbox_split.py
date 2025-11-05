#! /usr/bin/env python3

# mbox_split.py
#
# Split a mailbox into separate patch files, stripping the transfer encoding
# and minimizing the headers along the way.
#
# Written by Paolo Bonzini <pbonzini@redhat.com>
#
# Added a download utility from url to grab an mbox.gz from a mailing list
# and automatically uncompress it and split it in patches
# 
# Written by Alessio Faina <alessio.faina@canonical.com>

import argparse
import email.parser, email.header
import gzip
import os
import re
import requests
import shutil
import sys

def download_patch(addr:str):
    """ Downloads a patchset from a mailing list http URL """

    url = addr + "/t.mbox.gz"
    r = requests.get(url, allow_redirects=True)
    filename=r.headers['content-disposition'].split("filename=",1)[1]
    if filename.strip() == "":
        filename="tmp.mbox"
    print("Downloading " + url + " into " + filename)
    with open(filename, 'wb') as f:
        f.write(r.content)
    return filename

def subj_to_name(subj):
    """Convert a subject to a filename."""

    # You can write Perl in any language.  - Edgar Dijkstra, probably.
    def dashify(text):
        text = re.sub("[^a-zA-Z0-9_-]", "-", text)
        text = re.sub("--+", "-", text)
        text = re.sub("^[.-]*", "", text)
        return re.sub("[.-]*$", "", text)

    subj = re.sub("\n\s+", " ", subj, re.S)
    m = re.match(r"""\s* (\[ [^]]* \] )""", subj, re.X)
    num = 1
    if m:
        m2 = re.search(r"(\[SRU\])(\[.*\])(\[PATCH\b.*\b)([0-9]+)\/([0-9]+)].*", subj, re.X)
        if m2:
            num = int(m2.group(4))
        subj = subj[m.end() :]

    m = re.match(r"""\s* ( \[ [^]]* \] | \S+: )?""", subj, re.X)
    area = "misc"
    if m and m.group(1):
        area = dashify(m.group(1))
        subj = subj[m.end() :]

    text = dashify(subj.strip())
    return "%04d-%s-%s.patch" % (num, area, text)


def has_patch(body):
    """Return whether the body includes a patch."""
    return re.search(
        b"""^---.*     ^\\+\\+\\+.*   ^@@
            |^diff.*   ^index.*       ^GIT binary patch
            |^diff.*   ^old mode .*   ^new mode""",
        body,
        re.M | re.S | re.X,
    )


def header_to_string(v):
    """Convert a MIME encoded header to Unicode."""
    return email.header.make_header(email.header.decode_header(v))


def do_single(msg, outfile=None):
    """Remove unnecessary headers from the message as well as
       content-transfer-encoding, and print it to outfile or to
       a file whose name is derived from the subject.  If the
       latter, the name of the file is printed to stdout."""

    def open_output_file(msg):
        name = subj_to_name(msg["Subject"])
        print(name)
        return open(name, "wb")

    container = msg.get_payload(0) if msg.is_multipart() else msg
    body = container.get_payload(decode=True)
    if not body is None:
        if not args.keep_cr:
                body = body.replace(b"\r\n", b"\n")
        if not args.nopatch and not has_patch(body):
            return
        with outfile or open_output_file(msg) as f:
            for k in ("From", "Subject", "Date", "Content-Type"):
                if k in msg:
                    f.write(("%s: %s\n" % (k, header_to_string(msg[k]))).encode())
            f.write(b"\n")
            f.write(body)


def split_mbox(stream, func):
    """Split an mbox file and pass each part to a function func."""
    parser = None
    for line in stream:
        if line.startswith(b"From "):
            # finish the previous message
            if parser:
                func(parser.close())
                parser = None
        else:
            if not parser and line.strip() == b"":
                continue
            if line.startswith(b">From"):
                line = line[1:]
            if not parser:
                parser = email.parser.BytesFeedParser()
            parser.feed(line)

    if parser:
        func(parser.close())


parser = argparse.ArgumentParser(
    description="Splits a given mailbox into separate patch files"
)
parser.add_argument(
    "--nopatch",
    action="store_true",
    default=False,
    help="exports even if it's not a patch",
)
parser.add_argument(
    "--single",
    action="store_true",
    default=False,
    help="do not split mbox file",
)
parser.add_argument(
    "--keep-cr",
    action="store_true",
    default=False,
    help=r"do not remove \r from lines ending with \r\n",
)
parser.add_argument(
    "--keep-mbox",
    action="store_true",
    default=False,
    help="do not delete the mbox file",
)

parser.add_argument(
    "--prefix",
    type=str,
    default="",
    nargs=1,
    help="add prefix in front of folder name",
)

parser.add_argument(
    "--url", "-u",
    type=str,
    default="",
    nargs=1,
    help="download the mbox from a mailing list URL",
)
parser.add_argument(
    "--file", "-f",
    type=str,
    default="",
    nargs=1,
    help="split a local mbox file",
)
args = parser.parse_args()
folder = ""

if args.url:
    filename_gzip = download_patch(args.url[0])
    filename = filename_gzip[:-3]
    folder = filename[:-5]
    if args.prefix:
        folder = args.prefix[0] + folder
    os.mkdir(folder)
    with gzip.open(filename_gzip, 'rb') as f_in:
        with open(folder + "/" + filename, 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)
    os.remove(filename_gzip)
    os.chdir(folder)
    infile = open(filename, "rb")
elif args.file:
    infile = open(args.file[0], "rb")
else:
    parser.print_help()
    sys.exit()

if args.single:
    msg = email.parser.BytesParser().parse(infile)
    do_single(msg, sys.stdout.buffer)
else:
    split_mbox(infile, do_single)

if not args.keep_mbox:
    os.remove(filename)

if args.url:
    print("")
    print("Patches ready in " + folder)

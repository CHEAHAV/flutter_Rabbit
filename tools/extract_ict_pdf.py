# -*- coding: utf-8 -*-
"""Rebuild assets/data/part_28.json from the ICT teacher-recruitment PDF.

`assets/pdf/វិញ្ញាសា QCM ព័ត៌មានវិទ្យា (ICT) ៣០០ សំណួរ សម្រាប់ការប្រឡងគ្រូ.pdf`
is a 44-page paper of 300 multiple-choice questions on information technology
for the teacher-recruitment exam: pages 1-39 hold the questions, and pages
40-44 an answer-key table of three (number, letter) column pairs covering
1-100, 101-200 and 201-300.

Unlike QCM.pdf and the ethics collection this one is set in Kantumruy Pro and
carries usable ToUnicode maps, so it does not need tools/khmer_pdf.py. It has
two defects of its own instead, both repaired here:

* Every orthographic cluster is split across PDF text objects wherever the
  writer repositioned the pen, so `page.get_text()` breaks words like
  សម្រាប់ in half ("សម្រ" / "ាប់"). The text is rebuilt per *baseline*
  instead - all runs sharing a y, in x order - which puts those halves back
  together; real spaces survive because they are written as space glyphs.
* The split vowels ៀ and ឿ are drawn as two glyphs, and the ToUnicode of the
  left half repeats the whole cluster. "រៀន" comes out as "រៀរៀន" and
  "ត្រៀម" as "ត្រៀៀម". [DEDUPE] undoes both shapes of that.

Run it with PyMuPDF installed:

    python tools/extract_ict_pdf.py
"""
import glob
import json
import os
import re
import sys

import pymupdf

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PDF = next(p for p in glob.glob(os.path.join(ROOT, 'assets', 'pdf', '*.pdf'))
           if 'ICT' in os.path.basename(p))
OUT = os.path.join(ROOT, 'assets', 'data', 'part_28.json')

LET = 'កខគឃ'
KD = '០១២៣៤៥៦៧៨៩'
EXPECTED = 300

QNUM = re.compile(r'^\s*([០-៩]{1,3})\.\s*')
OPTION = re.compile(r'\s*([កខគឃ])\.\s+')
KEYROW = re.compile(r'([០-៩]{1,3})\s+([កខគឃ])')

# The paper misprints one question number, so questions are numbered by the
# position they are printed in and every disagreement with the printed number
# has to be listed here, as {position: number printed}. Question 33 is printed
# as "៣." and repeats question 3 word for word - same options, and the answer
# key gives both of them ខ - so it is kept as the paper has it rather than
# dropped, and only its number is put right.
MISPRINTED = {33: 3}

# ([base] vowel) repeated, and the bare vowel repeated. The first has to run
# first: "ធៀធៀ" must collapse to "ធៀ" before "ៀៀ" is looked for.
DEDUPE = [
    (re.compile(r'([ក-អ])([ឿៀ])\1\2'), r'\1\2'),
    (re.compile(r'([ឿៀ])\1+'), r'\1'),
]


def fix(text):
    for pattern, repl in DEDUPE:
        text = pattern.sub(repl, text)
    return text


def clean(text):
    return re.sub(r'\s+', ' ', fix(text).replace('​', '')).strip()


def kint(digits):
    return int(''.join(str(KD.index(c)) for c in digits))


def pdf_lines(path):
    """The document as lines of text, one per printed baseline."""
    doc = pymupdf.open(path)
    out = []
    for page in doc:
        rows = {}
        for block in page.get_text('rawdict')['blocks']:
            if block['type'] != 0:
                continue
            for line in block['lines']:
                y = round(line['bbox'][3], 1)
                key = next((k for k in rows if abs(k - y) < 3.0), y)
                rows.setdefault(key, []).append(
                    (line['bbox'][0],
                     ''.join(c['c'] for s in line['spans'] for c in s['chars']))
                )
        for key in sorted(rows):
            out.append(''.join(t for _, t in sorted(rows[key])))
    return out


def split_options(line):
    """Split a line into its (letter, text) options.

    Most options are printed one per line, but short ones - "ក. GB ខ. GHz
    គ. MB ឃ. TB" - share a line, so a line can hold up to four of them.
    """
    hits = list(OPTION.finditer(line))
    found = []
    for i, hit in enumerate(hits):
        end = hits[i + 1].start() if i + 1 < len(hits) else len(line)
        found.append((hit.group(1), line[hit.end():end]))
    return found


def parse_questions(lines):
    rows, current = [], None
    for line in lines:
        hit = QNUM.match(line)
        if hit:
            current = {'n': kint(hit.group(1)), 'q': line[hit.end():], 'o': {}}
            rows.append(current)
            continue
        if current is None:
            continue                      # the cover page's instructions
        for letter, text in split_options(line):
            current['o'].setdefault(letter, text)
    return rows


def parse_key(lines):
    """The answer-key table at the back, as {question number: answer index}."""
    key = {}
    for line in lines:
        for number, letter in KEYROW.findall(line):
            key[kint(number)] = LET.index(letter)
    return key


def main():
    lines = pdf_lines(PDF)
    # The key table starts at its own heading; everything before it is the paper.
    cut = next(i for i, l in enumerate(lines) if 'Answer Key' in l)
    rows = parse_questions(lines[:cut])
    key = parse_key(lines[cut:])

    out, problems = [], []
    for slot, row in enumerate(rows, 1):
        where = 'question %d' % slot
        if row['n'] != slot and MISPRINTED.get(slot) != row['n']:
            problems.append('%s is printed as %d' % (where, row['n']))
            continue
        stem = clean(row['q'])
        if not stem:
            problems.append('%s has no text' % where)
            continue
        if sorted(row['o']) != sorted(LET):
            problems.append('%s has options %s' % (where, ''.join(sorted(row['o']))))
            continue
        opts = [clean(row['o'][letter]) for letter in LET]
        if not all(opts):
            problems.append('%s has an empty option' % where)
            continue
        if slot not in key:
            problems.append('%s is missing from the answer key' % where)
            continue
        out.append({'id': slot, 'q': stem, 'o': opts, 'a': key[slot]})

    if len(rows) != EXPECTED:
        problems.append('the paper prints %d question(s), %d expected'
                        % (len(rows), EXPECTED))
    if sorted(key) != list(range(1, EXPECTED + 1)):
        problems.append('the answer key covers %d question(s), 1-%d expected'
                        % (len(key), EXPECTED))

    for line in problems:
        print(line)
    print('%d question(s) read, %d written, %d problem(s).'
          % (len(rows), len(out), len(problems)))
    if problems:
        return 1
    with open(OUT, 'w', encoding='utf-8') as fh:
        json.dump(out, fh, ensure_ascii=False, indent=4)
        fh.write('\n')
    print('wrote %s' % OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())

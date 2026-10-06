# -*- coding: utf-8 -*-
"""Rebuild assets/data/part_29.json from the National Police QCM PDF.

`assets/pdf/នរគបាលជាតិ.pdf` (the file name misspells នគរបាលជាតិ) is a
136-page practice paper for the National Police and prison-officer exam. It
prints four options A-D under each question and the answer straight after
them ("ចម្លើយត្រឹមត្រូវ៖ C"). It was pasted together from several chatbot
replies, so it is not a clean paper:

* Questions run 1-300 and then 401-500: 302-330 and 332-400 were never
  pasted in. Questions keep the number the paper prints, so a uid always
  points back at the page it came from.
* The chat leftovers - "okay", "JPG", "[cite: 2, 3]", the "ask for the next
  set" prompts and an English chat turn - are dropped.
* Four stems end in a run of "គគគ…" where the pasted text was lost; [STEMS]
  gives them back an ending. Three questions are beyond repair and are left
  out ([BROKEN]).

The paper is set in Google's Battambang (embedded by Word as
"___WRD_EMBED_SUB_1235"), whose ToUnicode map is as wrong as the Khmer OS
ones, so the text is rebuilt from glyph ids with tools/khmer_pdf.py. Word
kept the font's glyph order, so the decoder only needs the published
Battambang-Regular.ttf (v8.002), from
https://github.com/google/fonts/tree/main/ofl/battambang - put it in
tools/fonts/, install it, or point BATTAMBANG_TTF at it. Three glyphs the
GSUB walk cannot name are given their characters in [HALVES].

Run it with PyMuPDF and fonttools installed:

    python tools/extract_police_pdf.py
"""
import glob
import json
import os
import re
import sys

import khmer_pdf
from khmer_pdf import DATA, PDFDIR

PDF = next(p for p in glob.glob(os.path.join(PDFDIR, '*.pdf'))
           if 'នរគបាល' in os.path.basename(p) or 'នគរបាល' in os.path.basename(p))
OUT = os.path.join(DATA, 'part_29.json')
FONT = '___WRD_EMBED_SUB_1235'

LETTERS = 'ABCD'
KD = '០១២៣៤៥៦៧៨៩'

QNUM = re.compile(r'^([០-៩]{1,3})\.\s*(.*)$')
OPTION = re.compile(r'^([ABCD])\.\s*(.*)$')
ANSWER = re.compile(r'^ចម្លើយត្រឹមត្រូវ\s*៖\s*([ABCD])')
CITE = re.compile(r'\s*\[cite:[^\]]*\]?')

# Lines that are never part of a question, wherever they turn up - page and
# section headings, and the chat leftovers. A continuation line between an
# answer and the next question is dropped anyway; these can also fall
# between two options.
JUNK = re.compile(
    r'^(?:JPG|okay|can I add'
    r'|កម្រងសំណួរ|ផ្នែកទី|វិញ្ញាសាត្រៀមប្រឡង|ប្រសិនបើចង់បាន)'
)

# Glyphs the GSUB walk leaves unnamed: the lower halves Battambang draws
# ញ្ញ, ណ្ដ and ណ្ឋ with.
HALVES = {
    'ta.half': '្ញ',     # ្ញ
    'ru.half': '្ដ',     # ្ដ
    'ruu.half': '្ឋ',    # ្ឋ
}

# Stems whose ending the paste replaced with "គគគ…".
STEMS = {
    35: 'តើការឃាត់ខ្លួនបណ្ដោះអាសន្នបឋម (Garde à vue) មានរយៈពេលប៉ុន្មាន?',
    38: 'បទល្មើសជាក់ស្តែង (Flagrant délit) មានន័យដូចម្តេច?',
    84: 'ដីកាបង្គាប់ឱ្យចាប់ខ្លួន (Mandat d\'arrêt) មានគោលបំណងអ្វី?',
    222: 'ការកត់ត្រាព័ត៌មានជនជាប់ឃុំក្នុងសៀវភៅបញ្ជីពន្ធនាគារ (Écrou) '
         'ត្រូវមានព័ត៌មានអ្វីខ្លះ?',
}

# 301 lost its option A and its answer, 331's options belong to another
# question, and 460 is a stem with nothing under it.
BROKEN = {301, 331, 460}

# An option that names other options by letter. The app shuffles options and
# shows no letters, but it spells out a Khmer "ចម្លើយ ក និង ខ" when the bank
# loads, so the Latin letters are put into that form.
LETTER_REFS = {'ទាំង A និង B': 'ចម្លើយ ក និង ខ'}

EXPECTED = 399


def font_path():
    here = os.path.dirname(os.path.abspath(__file__))
    for path in (
        os.environ.get('BATTAMBANG_TTF', ''),
        os.path.join(here, 'fonts', 'Battambang-Regular.ttf'),
        os.path.join(khmer_pdf.FONTS, 'Battambang-Regular.ttf'),
        os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Microsoft', 'Windows',
                     'Fonts', 'Battambang-Regular.ttf'),
    ):
        if path and os.path.exists(path):
            return path
    sys.exit('Battambang-Regular.ttf not found - see the docstring.')


def install_font():
    khmer_pdf.FONTFILES[FONT] = font_path()
    text, names, _ = khmer_pdf.maps()[FONT]
    for gid, name in enumerate(names):
        # A consonant fused with the left of ៅ. Without the vowel it reads as
        # ោ: the decoder joins the េ before it and the ា after it.
        if name.endswith('_17C5') and gid in text:
            text[gid] = text[gid] + 'ៅ'
    for name, chars in HALVES.items():
        text[names.index(name)] = chars


def fix(line):
    line = re.sub('ៅា', 'ៅ', line)   # ៅ + its own right stroke
    line = line.replace('ណ្ញ', 'ណ្ឌ')                 # ្ឌ and ្ញ share a glyph
    line = line.replace('េុើ', '៊ើ')                  # ស៊ើប, typed as សុើប
    return line.replace('េី', 'ើ')


def clean(text):
    return re.sub(r'\s+', ' ', CITE.sub('', text)).strip()


def kint(digits):
    return int(''.join(str(KD.index(c)) for c in digits))


def parse(lines):
    """Walk the document as a state machine over question / option / answer."""
    rows, cur, field = [], None, None
    for raw in lines:
        line = fix(raw).strip()
        if not line or JUNK.match(line):
            continue
        hit = QNUM.match(line)
        if hit:
            cur = {'n': kint(hit.group(1)), 'q': hit.group(2), 'o': {}, 'a': None}
            rows.append(cur)
            field = 'q'
            continue
        if cur is None:
            continue
        hit = ANSWER.match(line)
        if hit:
            cur['a'] = hit.group(1)
            field = None
            continue
        hit = OPTION.match(line)
        if hit and field is not None:
            field = hit.group(1)
            cur['o'].setdefault(field, hit.group(2))
            continue
        if field == 'q':
            cur['q'] += ' ' + line
        elif field is not None:
            cur['o'][field] += ' ' + line
        # A line after an answer and before the next question is chat text.
    return rows


def main():
    install_font()
    rows = parse(khmer_pdf.pdf_lines(PDF))

    out, problems, seen = [], [], set()
    for row in rows:
        n = row['n']
        where = 'question %d' % n
        if n in BROKEN:
            continue
        if n in seen:
            problems.append('%s is printed twice' % where)
            continue
        seen.add(n)
        stem = STEMS.get(n) or clean(row['q'])
        if 'គគគ' in stem or not stem:
            problems.append('%s has a damaged stem' % where)
            continue
        if sorted(row['o']) != list(LETTERS):
            problems.append('%s has options %s' % (where, ''.join(sorted(row['o']))))
            continue
        opts = [clean(row['o'][letter]) for letter in LETTERS]
        opts = [LETTER_REFS.get(o, o) for o in opts]
        if not all(opts):
            problems.append('%s has an empty option' % where)
            continue
        if row['a'] is None:
            problems.append('%s has no answer' % where)
            continue
        out.append({'id': n, 'q': stem, 'o': opts, 'a': LETTERS.index(row['a'])})

    missing = sorted(BROKEN - {r['n'] for r in rows})
    if missing:
        problems.append('expected broken question(s) %s are gone - '
                        'check the PDF changed' % missing)
    if len(out) != EXPECTED:
        problems.append('%d question(s) written, %d expected' % (len(out), EXPECTED))

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

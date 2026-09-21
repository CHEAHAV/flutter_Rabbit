# -*- coding: utf-8 -*-
"""Rebuild assets/data/part_27.json from the teacher-ethics PDF.

`assets/pdf/ក្រមសីលធម៌វិជ្ជាជីវៈគ្រូបង្រៀន.pdf` is a 62-page collection by
លោកគ្រូ ងួន ប៊ុនធិន: ten practice papers of twenty multiple-choice questions
each, for the teacher-recruitment exam's professional-ethics section. Unlike
QCM.pdf it prints the answer under each question rather than in a key at the
back, and it numbers each paper from one, so the papers are merged into a
single 200-question subject numbered 1-200.

The text is read with tools/khmer_pdf.py, which explains why the PDF cannot
simply be copied out. Run it with PyMuPDF and fonttools installed:

    python tools/extract_ethics_pdf.py
"""
import json
import os
import re
import sys
import unicodedata
from difflib import SequenceMatcher

from khmer_pdf import DATA, PDFDIR, pdf_lines

PDF = os.path.join(PDFDIR, 'ក្រមសីលធម៌វិជ្ជាជីវៈគ្រូបង្រៀន.pdf')
OUT = os.path.join(DATA, 'part_27.json')

# The author's credit line sits in a font variant whose glyph numbering we
# cannot resolve; it is printed below this y on every page.
FOOTER_Y = 780

KD = '០១២៣៤៥៦៧៨៩'
LET = 'កខគឃ'
RUNNING_HEAD = 'កម្រងវិញ្ញាសាពហុចម្លើយ'
PAPER = re.compile(r'^វិញ្ញាសា')
QNUM = re.compile(r'^\s*([០-៩]{1,3})\.\s*')
OPTION = re.compile(r'^\s*([កខគឃ])\.\s*')
ANSWER = re.compile(r'^\s*ចម្លើយត្រឹមត្រូវ\s*៖\s*([កខគឃ])\.\s*')


def norm(s):
    s = unicodedata.normalize('NFC', s or '')
    s = re.sub(r'[​ \s]+', '', s)
    return re.sub(r'[“”«»"\'()., ។៕?!:;-]', '', s)


def clean(s):
    return re.sub(r'\s+', ' ', s or '').strip()


def parse(lines):
    """Walk the document as a state machine over question / option / answer."""
    questions, current, field = [], None, None

    def finish(letter, text):
        if current is None:
            return
        current['a'] = LET.index(letter)
        current['answer_text'] = text
        questions.append(current)

    for line in lines:
        stripped = line.strip()
        if not stripped:
            # a blank line closes the block - without this the last answer in
            # the document runs on into the closing page
            if field and field[0] == 'answer':
                finish(field[1], field[2])
                current, field = None, None
            continue
        if stripped.startswith(RUNNING_HEAD) or PAPER.match(stripped):
            continue
        hit = ANSWER.match(line)
        if hit:
            field = ['answer', hit.group(1), line[hit.end():]]
            continue
        if field and field[0] == 'answer':
            # the answer repeats the option's text and may wrap
            if not (QNUM.match(line) or OPTION.match(line)):
                field[2] += ' ' + stripped
                continue
            finish(field[1], field[2])
            current, field = None, None
        hit = QNUM.match(line)
        if hit:
            current = {'n': hit.group(1), 'q': line[hit.end():], 'o': []}
            field = ['q']
            continue
        hit = OPTION.match(line)
        if hit and current is not None:
            current['o'].append(line[hit.end():])
            field = ['o']
            continue
        if current is None:
            continue                      # cover page and closing page
        if field and field[0] == 'q':
            current['q'] += ' ' + stripped
        elif field and field[0] == 'o' and current['o']:
            current['o'][-1] += ' ' + stripped
    if field and field[0] == 'answer':
        finish(field[1], field[2])
    return questions


def main():
    rows = parse(pdf_lines(PDF, skip_below=FOOTER_Y))
    out, problems = [], []
    for i, row in enumerate(rows, 1):
        stem = clean(row['q'])
        opts = [clean(o) for o in row['o']]
        where = 'question %d (printed as %s)' % (i, row['n'])
        if len(opts) != 4:
            problems.append('%s has %d options' % (where, len(opts)))
            continue
        if not stem:
            problems.append('%s has no text' % where)
            continue
        # the document repeats the chosen option's text beside the letter, so
        # the two must agree - that is the only check on the answer available
        picked = opts[row['a']]
        stated = clean(row['answer_text'])
        # the key sometimes shortens the option it repeats, so a prefix counts
        agrees = (not stated
                  or norm(picked).startswith(norm(stated))
                  or SequenceMatcher(None, norm(stated), norm(picked)).ratio() >= 0.8)
        if not agrees:
            best = max(range(4), key=lambda j: SequenceMatcher(
                None, norm(stated), norm(opts[j])).ratio())
            problems.append('%s: the key says %s. but its text matches %s.\n'
                            '    key:    %s\n    option: %s'
                            % (where, LET[row['a']], LET[best], stated[:70],
                               picked[:70]))
            continue
        out.append({'id': len(out) + 1, 'q': stem, 'o': opts, 'a': row['a']})

    for line in problems:
        print(line)
    print('%d question(s) read, %d written, %d problem(s).'
          % (len(rows), len(out), len(problems)))
    if problems:
        return 1
    with open(OUT, 'w', encoding='utf-8') as fh:
        json.dump(out, fh, ensure_ascii=False, indent=4)
    print('wrote %s' % OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())

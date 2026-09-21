# -*- coding: utf-8 -*-
"""Check assets/data/part_01..13.json against assets/pdf/QCM.pdf.

The Khmer civil-service bank (parts 1-13) is hand-maintained, not generated,
so this script does not rewrite it: it reads the source document and reports
every question the app is missing, every answer that disagrees with the
document's answer key, and every question the app repeats. Run it after
touching parts 1-13:

    python tools/check_qcm_pdf.py

Reading the PDF is the hard part; tools/khmer_pdf.py explains how and does it.
"""
import json
import os
import re
import sys
import unicodedata
from collections import Counter
from difflib import SequenceMatcher

from khmer_pdf import DATA, PDFDIR, pdf_lines

PDF = os.path.join(PDFDIR, 'QCM.pdf')

# ------------------------------------------------------------------ parsing

KD = '០១២៣៤៥៦៧៨៩'
LET = 'កខគឃងច'
# An option letter, allowing for the hyphens and missing spaces the source
# uses. "គ.ស" is the Christian era, not an option, so a letter glued straight
# onto ស is never a marker.
MARK = re.compile(r'(?:(?<=\s)|^)([កខគឃងចយ])[.\-](?!ស)\s*')
QNUM = re.compile(r'^\s*([០-៩]{1,3})[.\-]\s*(?=\S)')
SECTION = re.compile(r'^ផ្នែកទី([០-៩]+)')
ANSWER_SECTION = re.compile(r'^ចម្ល.{0,6}ផ្នែកទី([០-៩]+)')
ANSWER_ROW = re.compile(r'([០-៩]{1,3})\s*[,/]\s*([កខគឃងច០-៩])\s*[.\-]')


def k2i(s):
    return int(''.join(str(KD.index(c)) for c in s))


def norm(s):
    s = unicodedata.normalize('NFC', s or '')
    s = re.sub(r'[\u200b\u00a0\s]+', '', s)
    return re.sub(r'[\u201c\u201d\u00ab\u00bb"\'()., \u17d4\u17d5?!:;-]', '', s)


def sim(a, b):
    return SequenceMatcher(None, norm(a), norm(b)).ratio()


def split_options(text):
    """Split one question block into its stem and its lettered options.

    The source is not consistent: a letter may be followed by a hyphen instead
    of a dot, an option may lose its letter entirely, and one question prints
    "ឃ." where "គ." belongs. So the ordered reading is tried first and a purely
    positional one is the fallback.
    """
    text = re.sub(r'\s+', ' ', text).strip()
    marks = [(m.start(), m.end(), m.group(1)) for m in MARK.finditer(text)]
    if not marks:
        return text, []

    def cut(chosen):
        opts = []
        for i, (_, end, _) in enumerate(chosen):
            nxt = chosen[i + 1][0] if i + 1 < len(chosen) else len(text)
            opts.append(text[end:nxt].strip())
        return text[:chosen[0][0]].strip(), opts

    ordered, expect = [], 0
    for mark in marks:
        letter = mark[2]
        if expect < len(LET) and (letter == LET[expect]
                                  or (LET[expect] == 'ឃ' and letter == 'យ')):
            ordered.append(mark)
            expect += 1
    if len(ordered) >= 4 and len(ordered) == len(marks):
        return cut(ordered)
    if len(marks) >= 4:
        return cut(marks)
    stem, opts = cut(marks)
    if len(marks) == 3:
        tail = re.search(r'\s(ឃ|យ)\s+', opts[-1])
        if tail:
            rest = opts[-1][tail.end():].strip()
            opts[-1] = opts[-1][:tail.start()].strip()
            opts.append(rest)
    return stem, opts


def parse(lines):
    start = next(i for i, l in enumerate(lines) if l.startswith('ចម្ល'))
    sections, current = {}, None
    for line in lines[:start]:
        hit = SECTION.match(line.strip())
        if hit:
            current = k2i(hit.group(1))
            sections[current] = []
        elif current is not None:
            sections[current].append(line)

    questions = {}
    for sec, body in sections.items():
        rows, buf = [], None
        for line in body:
            if not line.strip() or re.fullmatch(r'\s*\d+\s*', line):
                continue
            if line.strip() == 'ចំណេះដឹងទូទៅ':
                continue
            hit = QNUM.match(line)
            if hit:
                if buf:
                    rows.append(buf)
                buf = [k2i(hit.group(1)), line[hit.end():]]
            elif buf:
                buf[1] += ' ' + line.strip()
        if buf:
            rows.append(buf)
        out, seen = [], set()
        for num, text in rows:
            stem, opts = split_options(text)
            out.append({'n': num, 'q': stem, 'o': opts})
        # section 6 prints "30." twice, the second where 128 belongs
        for i, row in enumerate(out):
            if row['n'] in seen and i > 0:
                row['n'] = out[i - 1]['n'] + 1
            seen.add(row['n'])
        questions[sec] = out

    keys, current = {}, None
    for line in lines[start:]:
        hit = ANSWER_SECTION.match(line.strip())
        if hit:
            current = k2i(hit.group(1))
            keys.setdefault(current, {})
            continue
        if current is None:
            continue
        hits = list(ANSWER_ROW.finditer(line))
        for i, hit in enumerate(hits):
            num = k2i(hit.group(1))
            letter = hit.group(2)
            end = hits[i + 1].start() if i + 1 < len(hits) else len(line)
            if num not in keys[current]:
                keys[current][num] = (
                    LET.index(letter) if letter in LET else None,
                    re.sub(r'\s+', ' ', line[hit.end():end]).strip(),
                )
    # where the source typed a digit instead of an option letter, the answer
    # text printed beside it says which option was meant
    for sec, rows in keys.items():
        byn = {q['n']: q for q in questions.get(sec, [])}
        for num, (letter, text) in list(rows.items()):
            opts = [o for o in (byn.get(num, {}).get('o') or []) if o]
            if letter is not None and letter < len(opts):
                rows[num] = letter
            elif opts and text:
                rows[num] = max(range(len(opts)), key=lambda i: sim(text, opts[i]))
            else:
                rows[num] = letter if letter is not None else 0
    return questions, keys


# ----------------------------------------------------------------- checking

def assign(app, pdf_questions):
    """One-to-one match between the app's questions and the document's."""
    scored = []
    for ai, q in enumerate(app):
        for pi, p in enumerate(pdf_questions):
            ratio = sim(q['q'], p['q'])
            if ratio >= 0.4:
                scored.append((ratio, ai, pi))
    scored.sort(reverse=True)
    out, taken = {}, set()
    for ratio, ai, pi in scored:
        if ai in out or pi in taken:
            continue
        out[ai] = (pdf_questions[pi], ratio)
        taken.add(pi)
    return out


def main():
    questions, keys = parse(pdf_lines(PDF))
    problems = 0
    for part in range(1, 14):
        app = json.load(open(os.path.join(DATA, 'part_%02d.json' % part),
                             encoding='utf-8'))
        pdfq = questions[part]
        pdfa = keys[part]
        matched = assign(app, pdfq)
        seen = set()
        for i, q in enumerate(app):
            src, ratio = matched.get(i, (None, 0.0))
            where = 'part_%02d id=%d' % (part, q['id'])
            if src is None or ratio < 0.55:
                print('%s: no question like this in the PDF\n    %s'
                      % (where, q['q'][:90]))
                problems += 1
                continue
            seen.add(src['n'])
            key = pdfa.get(src['n'])
            opts = [o for o in src['o'] if o]
            if key is None or key >= len(opts):
                continue
            # the app reorders and rewords options, so compare against the text
            # the key points at rather than trusting the index
            picked = q['o'][q['a']]
            best = max(range(len(q['o'])), key=lambda j: sim(q['o'][j], opts[key]))
            # where the source glues two options onto one line, the key's text
            # starts with the option the app kept
            glued = norm(opts[key]).startswith(norm(picked))
            if (best != q['a'] and not glued and sim(picked, opts[key]) < 0.6
                    and sim(q['o'][best], opts[key]) >= 0.75):
                print('%s: marks "%s" but the key (%s) says "%s"'
                      % (where, picked[:45], LET[key], opts[key][:45]))
                problems += 1
        for src in pdfq:
            if src['n'] in seen:
                continue
            opts = [o for o in src['o'] if o]
            note = ('' if len(opts) >= 4
                    else '  (the source prints only %d options)' % len(opts))
            print('part_%02d: PDF question %d is missing%s\n    %s'
                  % (part, src['n'], note, src['q'][:90]))
            problems += 1
        # Repeated stems are worth knowing about, but QCM.pdf repeats plenty of
        # them itself - each copy above matched a question of its own - so they
        # are a note, not a fault.
        for text, n in Counter(norm(q['q']) for q in app).items():
            if n > 1:
                ids = [q['id'] for q in app if norm(q['q']) == text]
                print('part_%02d: note - ids %s ask the same question, as the '
                      'PDF does' % (part, ids))
    print('\n%d problem(s).' % problems)
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())

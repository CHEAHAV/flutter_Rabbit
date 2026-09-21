# -*- coding: utf-8 -*-
"""Check assets/data/part_01..13.json against assets/pdf/QCM.pdf.

The Khmer civil-service bank (parts 1-13) is hand-maintained, not generated,
so this script does not rewrite it: it reads the source document and reports
every question the app is missing, every answer that disagrees with the
document's answer key, and every duplicate. Run it after touching parts 1-13:

    python tools/check_qcm_pdf.py

Reading the PDF is the hard part. QCM.pdf was written in Word with the Khmer
OS fonts, and the ToUnicode maps Word embedded are wrong - PyMuPDF's own text
extraction turns "ទោស" into "តោស" and so on, because several shaped glyphs are
mapped back to the same base letter. So the text here is rebuilt from the
*glyph ids* instead: each id is resolved to the characters it was made from by
walking the original font's GSUB table backwards, and the visual glyph order
is then put back into logical order (a pre-base vowel and a coeng-ro are drawn
before the consonant they belong to). That needs the fonts themselves, which
ship with Windows; on another machine point FONTFILES at a copy.

Requires PyMuPDF and fonttools.
"""
import io
import json
import os
import re
import sys
import unicodedata
from collections import Counter, defaultdict
from difflib import SequenceMatcher

import pymupdf
from fontTools.ttLib import TTFont

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PDF = os.path.join(ROOT, 'assets', 'pdf', 'QCM.pdf')
DATA = os.path.join(ROOT, 'assets', 'data')
FONTS = os.environ.get('WINDIR', r'C:\Windows') + r'\Fonts'
FONTFILES = {
    'KhmerOSBattambang': os.path.join(FONTS, 'KhmerOSBattambang-Regular.ttf'),
    'KhmerOSMuolLight': os.path.join(FONTS, 'KhmerOSmuollight.ttf'),
    'DaunPenh': os.path.join(FONTS, 'daunpenh.ttf'),
}

# ----------------------------------------------------------- glyph decoding

CONS = set(chr(c) for c in range(0x1780, 0x17A3))
INDEP = set(chr(c) for c in range(0x17A3, 0x17B4))
BASECH = CONS | INDEP
PREV = {'\u17C1', '\u17C2', '\u17C3'}          # drawn to the left of the base
FULLPRE = {'\u17BE', '\u17BF', '\u17C0', '\u17C4', '\u17C5'}
VOWELS = set(chr(c) for c in range(0x17B6, 0x17C6))
SHIFT = {'\u17C9', '\u17CA'}                   # register shifters, before the vowel
SIGNS = set(chr(c) for c in range(0x17C6, 0x17D2)) | {'\u17DD'}
COENG = '\u17D2'
RO = '\u17D2\u179A'


def _resolve_map(path):
    """glyph id -> the characters that glyph was substituted from."""
    font = TTFont(path)
    order = font.getGlyphOrder()
    base = {}
    for code, name in sorted(font.getBestCmap().items()):
        base.setdefault(name, chr(code))
    back = {}
    if 'GSUB' in font:
        for lookup in font['GSUB'].table.LookupList.Lookup:
            for sub in lookup.SubTable:
                kind = type(sub).__name__
                if kind == 'SingleSubst':
                    for src, dst in sub.mapping.items():
                        back.setdefault(dst, (src,))
                elif kind == 'MultipleSubst':
                    for src, seq in sub.mapping.items():
                        for dst in seq:
                            back.setdefault(dst, (src,))
                elif kind == 'LigatureSubst':
                    for first, ligs in sub.ligatures.items():
                        for lig in ligs:
                            back.setdefault(
                                lig.LigGlyph, tuple([first] + list(lig.Component))
                            )
                elif kind == 'AlternateSubst':
                    for src, alts in sub.alternates.items():
                        for dst in alts:
                            back.setdefault(dst, (src,))

    def resolve(name, depth=0):
        if name in base:
            return base[name]
        if depth > 15 or name not in back:
            return None
        out = ''
        for part in back[name]:
            got = resolve(part, depth + 1)
            if got is None:
                return None
            out += got
        return out

    text = {}
    for gid, name in enumerate(order):
        got = resolve(name)
        if got is not None:
            text[gid] = got
    cmapped = {order.index(n) for n in font.getBestCmap().values() if n in order}
    return text, order, cmapped


_MAPS = None


def maps():
    global _MAPS
    if _MAPS is None:
        _MAPS = {}
        for name, path in FONTFILES.items():
            if os.path.exists(path):
                _MAPS[name] = _resolve_map(path)
    return _MAPS


class _Cluster:
    """One orthographic syllable, collected in visual order."""

    def __init__(self, base='', pre='', ro=False):
        self.base = base
        self.coeng = []
        self.ro = ro
        self.pre = pre
        self.shift = ''
        self.vow = ''
        self.sign = ''

    def empty(self):
        return not (self.base or self.coeng or self.ro or self.pre
                    or self.shift or self.vow or self.sign)

    def text(self):
        vow, pre = self.vow, self.pre
        if pre:
            if vow == '':
                vow = pre
            elif vow[0] == '\u17B6' and pre == '\u17C1':
                vow = '\u17C4' + vow[1:]      # េ + ា = ោ
            elif vow[0] in FULLPRE:
                pass                          # the vowel already carries its left half
            else:
                vow = pre + vow
        return (self.base + ''.join(self.coeng) + (RO if self.ro else '')
                + self.shift + vow + self.sign)


def decode(font, gids, ucs):
    """Rebuild one run of text from its glyph ids."""
    entry = maps().get(font)
    if entry is None:                          # Latin fonts map back correctly
        return ''.join(chr(u) if u and u > 0 else '' for u in ucs)
    text, names, cmapped = entry
    chars = []
    for i, gid in enumerate(gids):
        got = text.get(gid)
        if got is None:
            chars.append('\ufffd')
            continue
        if got == COENG:
            # A bare coeng is either a real one in front of a subscript form,
            # or Word's zero-width placeholder for a character a ligature has
            # already swallowed. Only the first is worth keeping.
            nxt = gids[i + 1] if i + 1 < len(gids) else None
            nname = names[nxt] if nxt is not None and nxt < len(names) else ''
            ntext = text.get(nxt) if nxt is not None else None
            if ntext and nname.startswith('glyph') and ntext[0] in CONS:
                chars.append(COENG)
            continue
        chars.extend(got)

    out, cur, pend_pre, pend_ro = [], _Cluster(), '', False

    def flush():
        nonlocal cur
        if not cur.empty():
            out.append(cur.text())
        cur = _Cluster()

    i, n = 0, len(chars)
    while i < n:
        c = chars[i]
        if c == COENG and i + 1 < n and chars[i + 1] in CONS:
            sub = chars[i + 1]
            i += 2
            if sub == '\u179A':                # coeng ro is drawn before its base
                if pend_ro:
                    out.append(RO)
                flush()
                pend_ro = True
            else:
                if cur.base == '':
                    flush()
                cur.coeng.append(COENG + sub)
            continue
        if c in BASECH:
            flush()
            cur = _Cluster(c, pend_pre, pend_ro)
            pend_pre, pend_ro = '', False
            i += 1
            continue
        if c in PREV:
            if cur.base or cur.vow or cur.sign or cur.shift:
                flush()
            if pend_pre:
                out.append(pend_pre)
            pend_pre = c
            i += 1
            continue
        if c in SHIFT or c in VOWELS or c in SIGNS:
            if cur.base == '' or (c in VOWELS and cur.sign):
                flush()
                out.append(c)
            elif c in SHIFT:
                cur.shift += c
            elif c in VOWELS:
                cur.vow += c
            else:
                cur.sign += c
            i += 1
            continue
        flush()
        if pend_pre:
            out.append(pend_pre)
            pend_pre = ''
        if pend_ro:
            out.append(RO)
            pend_ro = False
        out.append(c)
        i += 1
    flush()
    if pend_pre:
        out.append(pend_pre)
    if pend_ro:
        out.append(RO)
    return ''.join(out)


def pdf_lines():
    """The whole document as lines of correctly ordered Khmer."""
    doc = pymupdf.open(PDF)
    lines = []
    for page in doc:
        runs = []
        for span in page.get_texttrace():
            if span['type'] != 0:
                continue
            chars = [c for c in span['chars'] if c[1] != -1]
            if not chars:
                continue
            runs.append((round(chars[0][2][1], 1), chars[0][2][0], span['font'],
                         [c[1] for c in chars], [c[0] for c in chars]))
        runs.sort(key=lambda r: (r[0], r[1]))
        rows = {}
        for y, x, font, gids, ucs in runs:
            key = next((k for k in rows if abs(k - y) < 3), y)
            rows.setdefault(key, []).append((x, font, gids, ucs))
        for key in sorted(rows):
            parts = sorted(rows[key], key=lambda p: p[0])
            lines.append(''.join(decode(f, g, u) for _, f, g, u in parts))
    return lines


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
    questions, keys = parse(pdf_lines())
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

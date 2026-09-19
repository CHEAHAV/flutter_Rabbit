# -*- coding: utf-8 -*-
"""Rebuild assets/data/part_14..24.json from assets/pdf/grammar.pdf.

The PDF is a 434-page English test bank of three books. Questions and the
answer key are printed in separate halves of the document, so this script
parses both, aligns each test's question run with its answer run, and writes
only the items it can vouch for. One output file is written per part of the
book - Book 1 Parts A-E, Book 2 Parts A-E and Book 3 - so no single part of
the app holds a whole book. Run it with PyMuPDF installed:

    python tools/extract_grammar_pdf.py
"""
import pymupdf, re, sys, os, json, io, unicodedata
from collections import Counter
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PDF  = os.path.join(ROOT, 'assets', 'pdf', 'grammar.pdf')
OUT  = os.path.join(ROOT, 'assets', 'data')
doc = pymupdf.open(PDF)

def printed(phys): return phys - 2

# ------------------------------------------------------------------ lexing
QNUM     = re.compile(r'^(\d{1,3})\.\s*(.*)$')
OPTSTART = re.compile(r'^([A-E])\)')
OPTSPLIT = re.compile(r'(?:(?<=\s)|(?<=[a-z\u2019.,;])|^)([A-E])\)\s*')
PAGENO   = re.compile(r'^\d{1,3}$')
# Running heads and test titles. PyMuPDF emits them in the middle of the text
# flow, where they would otherwise be glued onto the option above them.
NOISE = re.compile(
    r'^(TEST\b.{0,30}|ELEMENTARY|PRE-INTERMEDIATE|INTERMEDIATE|UPPER-INTERMEDIATE|'
    r'ADVANCED|BOOK\s*\d.*|PART\s*[A-E]\b.*)$'
    r'|^(Test\s*[-\u2013]?\s*\d+|Elementary|Pre-Intermediate|Intermediate|'
    r'Upper-Intermediate|Advanced|Book\s*\d.*|Part\s*[A-E]\b.*)$')
BULLET  = re.compile(r'^[-\u2022\u2013]\s')
# A section instruction is printed once, above the run of questions it governs
# ("Find the antonym of the following words written in capitals."). Without it a
# synonym item and an antonym item are indistinguishable, so it has to be
# carried down onto every question until the next instruction replaces it.
INSTR = re.compile(r'^(Find|Choose|Fill|Complete|Put|Match|Select|Write|Mark|Give|'
                   r'Replace|Circle|Which of the)\b.{0,140}$')
# decorative all-caps section banners, printed several times to fake a drop shadow
BANNER  = re.compile(r"^[A-Z][A-Z\s'\-&.,/()]{0,40}$")

def section_headings():
    """Short title lines that recur on three or more pages are running heads or
    section titles ("Dialogue Completion", "Everyday Vocabulary"). PyMuPDF drops
    them into the middle of the text flow, so they have to be recognised by
    repetition rather than by position."""
    pages = {}
    for phys in range(4, 405):
        for raw in doc[phys].get_text().split('\n'):
            line = raw.strip()
            if (3 < len(line) < 40 and line[0].isupper()
                    and line[-1] not in '.?!:;,' and len(line.split()) <= 4
                    and ')' not in line and '_' not in line
                    and not OPTSTART.match(line) and not QNUM.match(line)):
                pages.setdefault(line, set()).add(phys)
    # matched case-insensitively: the same heading is set in several styles
    # ("Dialogue Completion" in the running head, "Dialogue completion" inline)
    return {l.lower() for l, ps in pages.items() if len(ps) >= 3}

HEADINGS = section_headings()

def qstream():
    for phys in range(4, 405):
        for raw in doc[phys].get_text().split('\n'):
            line = raw.strip()
            if not line:
                continue
            if (PAGENO.match(line) or NOISE.match(line) or BULLET.match(line)
                    or BANNER.match(line) or line.lower() in HEADINGS):
                continue
            yield phys, line

def parse_questions():
    out, cur, curopt, instr, pending, tentative = [], None, None, '', '', ''
    for phys, line in qstream():
        m = QNUM.match(line)
        if m:
            if cur:
                out.append(cur)
            rest = m.group(2).strip()
            num = int(m.group(1))
            # An instruction seen while reading a stem turned out to be followed
            # by the next question, not by that stem's options - so it opened a
            # new section rather than belonging to the question above it.
            if tentative:
                pending, tentative = tentative, ''
            if num == 1:
                # Only an instruction printed directly above question 1 governs
                # a whole test. One that appears mid-test opens a sub-section
                # whose extent the layout does not record, so applying it to the
                # rest of the test would mislabel ordinary grammar items.
                instr = pending
            pending = ''
            cur = {'num': num, 'text': '', 'opts': [], 'phys': phys,
                   'instr': instr}
            curopt = None
            if OPTSTART.match(rest):
                line = rest
            else:
                cur['text'] = rest
                continue
        if cur is None:
            if INSTR.match(line):
                pending = line
            continue
        if OPTSTART.match(line):
            if tentative:
                # Options follow, so the instruction really was part of this
                # stem ("49. He likes mending old radios. / Choose the
                # synonym of the underlined word. / A) ...").
                cur['text'] = (cur['text'] + ' ' + tentative).strip()
                tentative = ''
            parts = OPTSPLIT.split(line)
            i = 1
            while i < len(parts):
                cur['opts'].append([parts[i], parts[i + 1].strip() if i + 1 < len(parts) else ''])
                curopt = cur['opts'][-1]
                i += 2
            continue
        if curopt is not None:
            # An instruction between two questions opens a new sub-section; it
            # is not a continuation of the option above it.
            if INSTR.match(line):
                pending = line
                continue
            curopt[1] = (curopt[1] + ' ' + line).strip()
        elif INSTR.match(line) and cur['text']:
            tentative = line
        else:
            cur['text'] = (cur['text'] + ' ' + line).strip()
    if cur:
        out.append(cur)
    return out

# -------------------------------------------------------------- answer key
PAGEHDR = re.compile(r'\(\s*Page\s*(\d+)\s*\)\s*$')
ANS  = re.compile(r'^(\d{1,3})\s*[-\u2013\u2014]\s*([A-E])\s*$')
ANS2 = re.compile(r'^(\d{1,3})\s*([A-E])\s*$')

def parse_key():
    tests, cur, buf = [], None, []
    for p in range(405, doc.page_count):
        for raw in doc[p].get_text().split('\n'):
            line = raw.strip()
            if not line:
                continue
            m = ANS.match(line) or ANS2.match(line)
            if m and cur is not None:
                cur['ans'].append((int(m.group(1)), m.group(2)))
                continue
            hm = PAGEHDR.search(line)
            if hm:
                cur = {'label': ' '.join(buf[-2:] + [line]), 'page': int(hm.group(1)), 'ans': []}
                tests.append(cur); buf = []
                continue
            if not m:
                buf.append(line)
    return tests

def blocks(items, numof):
    out, run, prev = [], [], 0
    for it in items:
        n = numof(it)
        if run and n <= prev:
            out.append(run); run = []
        run.append(it); prev = n
    if run:
        out.append(run)
    return out

# --------------------------------------------------------------- alignment
NEG = -1e9
def match_score(qbk, abk):
    pdiff = abs(printed(qbk[0]['phys']) - abk['page'])
    if pdiff != 0:
        return NEG
    qn = {q['num'] for q in qbk}; an = {n for n, _ in abk['ans']}
    if not an or not qn:
        return NEG
    jac = len(qn & an) / len(qn | an)
    if jac < 0.6:
        return NEG
    return 100 * jac + (20 if pdiff == 0 else 0) - 0.5 * abs(len(qbk) - len(abk['ans']))

def dp_align(qb, ab):
    n, m = len(qb), len(ab)
    F = [[0.0] * (m + 1) for _ in range(n + 1)]
    P = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            s = match_score(qb[i - 1], ab[j - 1])
            d = F[i - 1][j - 1] + s if s > NEG / 2 else NEG
            u, l = F[i - 1][j], F[i][j - 1]
            best = max(d, u, l)
            F[i][j] = best
            P[i][j] = 0 if best == d else (1 if best == u else 2)
    pairs, i, j = [], n, m
    while i > 0 and j > 0:
        if P[i][j] == 0:
            pairs.append((qb[i - 1], ab[j - 1])); i -= 1; j -= 1
        elif P[i][j] == 1:
            i -= 1
        else:
            j -= 1
    return list(reversed(pairs))

# ---------------------------------------------------------------- cleaning
TRANS = {0x2018: "'", 0x2019: "'", 0x201a: "'", 0x201b: "'", 0x201c: '"', 0x201d: '"',
         0x201e: '"', 0x2032: "'", 0x2033: '"', 0x2013: '-', 0x2014: '-', 0x2212: '-',
         0x2010: '-', 0x2011: '-', 0x00a0: ' ', 0x2026: '...', 0x2022: '-'}
def clean(s):
    s = s.translate(TRANS)
    s = ''.join(ch for ch in s if unicodedata.category(ch) not in ('Cc', 'Cf', 'Co', 'Cs', 'Cn'))
    s = re.sub(r'\s+', ' ', s).strip()
    # the book itself mistypes a few sentence-final "d." as "D)" etc.
    s = re.sub(r'(?<=[a-z])([A-E])\)$', lambda m: m.group(1).lower() + '.', s)
    return re.sub(r'_{2,}', '_____', s)

BAD_TEXT = re.compile(r'^(?:[A-E]\)|[IVX]+\.)', re.I)
CLOZE    = re.compile(r'__\(\d+\)__')
# stems that only make sense next to a reading passage printed above them
PASSAGE  = re.compile(r'\b(passage|the text|the author|the writer|according to the|'
                      r'the paragraph|the dialogue|following text)\b', re.I)
REPEAT   = re.compile(r'\b(\w{3,})\b(?:\s+\1\b){2,}', re.I)
# safety net: anything that still carries a running head is not trustworthy text
HEADJUNK = re.compile(r'\b(TEST\b|Test\s*\d|Elementary|Pre-Intermediate|'
                      r'Upper-Intermediate)', re.I)

# Instructions whose absence changes the right answer (synonym vs antonym).
AMBIGUOUS = re.compile(r'\b(synonym|antonym|opposite|meaning|logic list|definition)\b', re.I)

def usable(q, letter):
    letters = [o[0] for o in q['opts']]
    n = len(letters)
    if n not in (4, 5) or letters != list('ABCDE'[:n]):
        return None
    if letter not in 'ABCDE'[:n]:
        return None
    text = clean(q['text'])
    instr = clean(q.get('instr') or '')
    if instr and AMBIGUOUS.search(instr) and not AMBIGUOUS.search(text):
        text = instr.rstrip(':.') + '. ' + text
    opts = [clean(o[1]) for o in q['opts']]
    if not (8 <= len(text) <= 320) or BAD_TEXT.match(text) or CLOZE.search(text):
        return None
    if PASSAGE.search(text) or REPEAT.search(text):
        return None
    if any(not o for o in opts) or any(len(o) > 90 for o in opts):
        return None
    if any(REPEAT.search(o) for o in opts):
        return None
    if HEADJUNK.search(text) or any(HEADJUNK.search(o) for o in opts):
        return None
    if len(set(o.lower() for o in opts)) != n:
        return None
    return {'q': text, 'o': opts, 'a': 'ABCDE'.index(letter)}

# -------------------------------------------------------------------- main
# One app part per part of the book, with the printed page ranges the book's
# own index gives (physical pages 1-2 of the PDF). The ranges are kept
# contiguous from printed page 2 to 401 - Book 2 Part A is opened at 219
# rather than the index's 220 so the divider page cannot swallow a test - so
# every question the parser accepts lands in exactly one part.
PARTS = [
    (14, 2, 50, 'Book 1 Part A - Grammar'),
    (15, 51, 102, 'Book 1 Part B - Grammar'),
    (16, 103, 150, 'Book 1 Part C - Grammar'),
    (17, 151, 190, 'Book 1 Part D - Grammar'),
    (18, 191, 218, 'Book 1 Part E - Grammar'),
    (19, 219, 250, 'Book 2 Part A - Vocabulary'),
    (20, 251, 286, 'Book 2 Part B - Vocabulary'),
    (21, 287, 302, 'Book 2 Part C - Phrasal Verbs'),
    (22, 303, 327, 'Book 2 Part D - Vocabulary'),
    (23, 328, 341, 'Book 2 Part E - Synonyms'),
    (24, 342, 401, 'Book 3 - Miscellaneous'),
]

def part_of(printed_page):
    for pid, lo, hi, _ in PARTS:
        if lo <= printed_page <= hi:
            return pid
    return None

def build():
    qs = parse_questions()
    key = parse_key()
    qb = blocks(qs, lambda q: q['num'])
    ab, split_tests = [], 0
    for t in key:
        runs = blocks(t['ans'], lambda a: a[0])
        # A key test whose answers restart their numbering holds several tests
        # under one header, and the header only gives the page of the first.
        # Their order is not recoverable, so none of them can be trusted.
        if len(runs) != 1:
            split_tests += 1
            continue
        ab.append({'page': t['page'], 'label': t['label'], 'ans': runs[0]})
    pairs = dp_align(qb, ab)

    stats = Counter()
    stats['key_tests_with_split_numbering'] = split_tests
    accepted, dropped = 0, 0
    buckets = {p[0]: [] for p in PARTS}
    for qbk, abk in pairs:
        amap = {n: l for n, l in abk['ans']}
        qnums = [q['num'] for q in qbk]
        # STRICT GATE: the parsed question run and the answer run must describe
        # the same test - contiguous 1..N numbering, identical length, and an
        # answer letter present for every single question. Anything less and the
        # whole block is discarded rather than risk a shifted answer.
        ok = (len(set(qnums)) == len(qnums)
              and qnums == sorted(qnums)
              and qnums[0] == 1
              and len(qbk) == len(abk['ans'])
              and all(n in amap for n in qnums))
        if not ok:
            dropped += len(qbk); stats['block_rejected'] += 1
            continue
        accepted += 1
        # A test is filed whole, by the page it opens on. Bucketing question by
        # question would tear the last test of a part in two when it runs over
        # onto the first page of the next part.
        part = part_of(printed(qbk[0]['phys']))
        if part is None:
            stats['out_of_range'] += len(qbk); continue
        for q in qbk:
            stats['candidates'] += 1
            item = usable(q, amap[q['num']])
            if item is None:
                stats['filtered'] += 1; continue
            item['_key'] = (item['q'].lower(),
                            tuple(sorted(o.lower() for o in item['o'])))
            buckets[part].append(item)

    # Independent consistency check. Many stems are reused between tests, so a
    # repeat is a free second opinion on the answer: if two copies disagree, at
    # least one block is misaligned and neither copy can be trusted.
    by_key = {}
    for part, lst in buckets.items():
        for it in lst:
            by_key.setdefault(it['_key'], []).append(it)
    conflicted = set()
    for k, group in by_key.items():
        if len({g['o'][g['a']].lower() for g in group}) > 1:
            conflicted.add(k)
    stats['repeated_stems'] = sum(1 for g in by_key.values() if len(g) > 1)
    stats['conflicting_stems'] = len(conflicted)

    # Deduplication is global, not per part: the same stem is printed in several
    # parts, and a question the learner has already met in Part A should not
    # come round again in Part D.
    seen = set()
    for part in list(buckets):
        keep = []
        for it in buckets[part]:
            k = it.pop('_key')
            if k in conflicted:
                stats['dropped_conflict'] += 1; continue
            if k in seen:
                stats['duplicate'] += 1; continue
            seen.add(k)
            keep.append(it)
            stats['part_%d' % part] += 1
        buckets[part] = keep
    return buckets, stats, accepted, dropped

def write(buckets):
    """Write assets/data/part_14..24.json, and remove any part file this run no
    longer produces so a renumbering cannot leave a stale file behind for the
    app to load."""
    wanted = {p[0] for p in PARTS}
    for pid, lo, hi, title in PARTS:
        items = [{'id': i + 1, 'q': it['q'], 'o': it['o'], 'a': it['a']}
                 for i, it in enumerate(buckets[pid])]
        path = os.path.join(OUT, 'part_%02d.json' % pid)
        if not items:
            print('part_%02d: no usable questions, file not written' % pid)
            continue
        # Written in exactly the shape of the existing part_01..part_13 files:
        # a list of {id, q, o, a}, 4-space indent, CRLF, UTF-8, no trailing
        # newline.
        text = json.dumps(items, ensure_ascii=False, indent=4)
        with io.open(path, 'w', encoding='utf-8', newline='\r\n') as f:
            f.write(text)
        print('wrote %s  (%d questions, %.1f KB)'
              % (path, len(items), len(text.encode('utf-8')) / 1024))
    for name in sorted(os.listdir(OUT)):
        m = re.match(r'^part_(\d{2})\.json$', name)
        if m and 14 <= int(m.group(1)) and int(m.group(1)) not in wanted:
            os.remove(os.path.join(OUT, name))
            print('removed stale %s' % name)

if __name__ == '__main__':
    buckets, stats, accepted, dropped = build()
    print('blocks accepted: %d   rejected: %d (%d parsed questions dropped)'
          % (accepted, stats['block_rejected'], dropped))
    print(dict(stats))
    total = 0
    for pid, lo, hi, title in PARTS:
        lst = buckets[pid]
        total += len(lst)
        c = Counter(len(x['o']) for x in lst)
        print('part_%02d  %-30s pages %3d-%3d  %5d questions   4-opt=%d 5-opt=%d'
              % (pid, title, lo, hi, len(lst), c[4], c[5]))
    print('total: %d questions in %d parts' % (total, len(PARTS)))
    write(buckets)

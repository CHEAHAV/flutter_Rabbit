"""Checks build/web before it is deployed.

Run it right after `flutter build web --release`:

    python tool/check_web_build.py

It guards the two things that have silently shipped a wrong site before:

1. The compiled bundle is actually newer than the Dart sources. Vercel does not
   compile anything - `vercel.json` only uploads `build/web` - so deploying
   without rebuilding republishes the previous app.

2. `web/flutter_bootstrap.js` (this repo's custom template) came out intact:
   every {{token}} substituted, and the entrypoint URL still carries the
   per-build version that keeps browsers off a cached copy. If a future Flutter
   release changes those tokens, this fails loudly instead of shipping a
   bootstrap that cannot run.

Exits non-zero, with an explanation, when something is wrong.
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
WEB = ROOT / "build" / "web"

problems: list[str] = []
notes: list[str] = []


def fail(message: str) -> None:
    problems.append(message)


def newest(paths: list[pathlib.Path]) -> tuple[pathlib.Path | None, float]:
    newest_path, newest_mtime = None, 0.0
    for path in paths:
        mtime = path.stat().st_mtime
        if mtime > newest_mtime:
            newest_path, newest_mtime = path, mtime
    return newest_path, newest_mtime


# ---- 1. is the build newer than the code it is built from? ----------------

main_js = WEB / "main.dart.js"
if not main_js.exists():
    fail(f"{main_js} does not exist - run: flutter build web --release")
else:
    sources = sorted((ROOT / "lib").rglob("*.dart"))
    sources.append(ROOT / "pubspec.yaml")
    sources += sorted((ROOT / "web").rglob("*"))
    sources += sorted((ROOT / "assets").rglob("*"))
    sources = [p for p in sources if p.is_file()]
    newest_source, newest_source_mtime = newest(sources)
    # Compared against the newest file in build/web rather than against
    # main.dart.js alone: a change under web/ (index.html, this bootstrap
    # template) is copied straight through and does not recompile the Dart,
    # which leaves main.dart.js legitimately untouched.
    _, newest_built_mtime = newest([p for p in WEB.rglob("*") if p.is_file()])
    if newest_source is not None and newest_source_mtime > newest_built_mtime:
        rel = newest_source.relative_to(ROOT)
        fail(
            f"build/web is older than {rel} - the deploy would republish the "
            f"previous app. Run: flutter build web --release"
        )
    else:
        notes.append("build/web is newer than lib/, web/, assets/ and pubspec.yaml")


# ---- 2. did the custom bootstrap come out intact? -------------------------

bootstrap = WEB / "flutter_bootstrap.js"
if not bootstrap.exists():
    fail(f"{bootstrap} does not exist - run: flutter build web --release")
else:
    text = bootstrap.read_text(encoding="utf-8")
    leftovers = sorted(set(re.findall(r"\{\{[^}]*\}\}", text)))
    if leftovers:
        fail(
            "flutter_bootstrap.js still contains unsubstituted tokens "
            f"({', '.join(leftovers)}) - this Flutter version no longer "
            "provides them, and the built file is not valid JavaScript. Fix "
            "web/flutter_bootstrap.js against the current Flutter template."
        )
    match = re.search(r'mainJsPath"?\s*:\s*"([^"]+)"', text)
    if match is None:
        fail(
            "flutter_bootstrap.js has no mainJsPath - the Flutter build config "
            "changed shape, so web/flutter_bootstrap.js needs revisiting."
        )
    version_match = re.search(r'const version = "([^"]+)"', text)
    if version_match is None:
        fail(
            "flutter_bootstrap.js does not carry a build version - the "
            "entrypoint would be cached under the same URL forever. Check "
            "web/flutter_bootstrap.js."
        )
    else:
        notes.append(f"entrypoint cache-busted with v={version_match.group(1)}")


# ---- report ---------------------------------------------------------------

for note in notes:
    print(f"  ok  {note}")

if problems:
    print()
    for problem in problems:
        print(f"FAIL  {problem}")
    sys.exit(1)

print("\nbuild/web looks deployable.")

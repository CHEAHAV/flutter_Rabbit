// Custom bootstrap template. Flutter uses this instead of its built-in one
// and substitutes the double-brace tokens below at `flutter build web` time.
// Do not write a literal double brace anywhere else in this file: anything
// left unsubstituted in the built output is treated as a broken build.
//
// Why it exists: `main.dart.js` is written out under that exact name on every
// build - there is no content hash in the filename - so a browser that has
// cached one copy keeps serving it until its cache entry expires, whatever is
// on the server. That is how a deploy can go live without anybody seeing the
// new app. Correct cache headers (see vercel.json) fix this going forward, but
// they cannot reach a copy a browser has already promised itself it may reuse.
//
// Pointing the loader at a URL that carries this build's own version makes
// every build a separate cache entry, so a stale copy can never be reused, by
// anybody, ever - no hard refresh, no clearing site data.
//
// After `flutter build web`, run `python tool/check_web_build.py`: it fails if
// a future Flutter release stops substituting a token here (which would ship a
// broken bootstrap) or drops the version from the entrypoint URL.

{{flutter_js}}
{{flutter_build_config}}

(() => {
  // Substituted as a quoted string, e.g. "1052733068"; it changes on every
  // build, which is exactly the property needed here.
  const version = {{flutter_service_worker_version}};
  for (const build of _flutter.buildConfig.builds) {
    // The second entry is an empty placeholder for the wasm variant.
    if (!build.mainJsPath) continue;
    const separator = build.mainJsPath.includes("?") ? "&" : "?";
    build.mainJsPath += separator + "v=" + version;
  }
})();

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  }
});

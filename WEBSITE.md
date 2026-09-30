# Strut website maintenance contract

This Nift project is the public documentation surface for Strut.

## Rules

- Keep the site dark by default and avoid a blue-dominated palette.
- Keep documentation multi-page; do not collapse the project into a single landing page.
- Desktop docs navigation uses collapsible sections. Mobile uses a hamburger that opens a full-screen navigation/docs surface with the same collapsible groups.
- The 404 page is deliberately standalone and must not gain the normal site header/footer.
- Use `@path(...)` for internal tracked pages/assets and build with Nift after meaningful changes.
- Never claim planned language syntax is implemented. Update `docs/status` as compiler checkpoints land.
- When a language syntax or CLI decision changes, update the relevant docs in the same checkpoint or as part of the nearest website maintenance checkpoint.
- Preserve accessibility basics: semantic navigation, keyboard-operable native `<details>`, visible labels, Escape-to-close mobile navigation, and responsive layouts.
- Run both `nift build` and `nift status` before committing.
- Run `python3 check_site.py` after building. It validates generated pages, local links, sitemap coverage, and source/deployment parity for `llms.txt`, `robots.txt`, and `sitemap.xml`.
- Keep the current-main versus latest-release boundary visible. New major public runtime APIs require a page, navigation entry, status entry, and agent-facing `llms.txt` link in the same documentation checkpoint.

The source/stage repository intentionally ignores `public/`; `public/` is a nested deployment repository and receives the generated site in its own commits.

Publication is a two-commit process: commit source on `stage`, build with Nift, then commit the generated files in the nested `public/` repository on `main`. `public/SOURCE_DIGEST` records the tracked source/template digest and prevents the stage workflow from silently accepting output from unrelated sources. Push generated `main` before source `stage` so the stage certification workflow compares against the matching published output.

## September 2026 stdlib/docs refresh

The website documentation now reflects the explicit standard-library module work and the CP21-32 language/runtime additions:

- angle-bracket includes cover both Strut stdlib modules and package modules; quoted includes are local/native;
- vector/deque/list, hash and ordered maps/sets, queue/stack/priority_queue, and tuple are documented;
- `priority_queue<T,min>` is documented for min-first ordering;
- filesystem docs cover scalar/vector/wildcard copy/move/remove, `remove_all`, metadata, traversal, path helpers and cwd;
- whole-file text/binary read/write APIs and the optimized bulk-read path are documented;
- CLI syntax-highlighted diagnostics, migration notes, profiler/module-size coverage, and examples/status pages were refreshed.

The September 2026 backend parity pass added current-main crypto/encoding, HTTP client/server streaming, WebSocket, cancellation, process, PTY, architecture, and security documentation. Canonical snippets live in the compiler repository under `examples/docs`; `tools/certify_docs.py` compiles them, synchronizes marked website regions, verifies required API registry names, and rejects missing major website surfaces.

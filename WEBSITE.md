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

The source/stage repository intentionally ignores `public/`; `public/` is a nested deployment repository and receives the generated site in its own commits.

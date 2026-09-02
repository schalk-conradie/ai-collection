---
name: create-custom-ui-registry
description: Create and publish a static shadcn/ui registry that create-ec-app can consume. Use when the user wants a new shadcn registry from a name, wants every shadcn component copied into it (--all), needs a theme or global CSS registry item, wants the registry JSON published to GitHub Pages with gh, or wants to verify a registry from create-ec-app or the shadcn CLI.
---

# Create custom UI registry

Publish a static registry at `https://<owner>.github.io/<repo>/r/registry.json` with one item file per component at `https://<owner>.github.io/<repo>/r/<name>.json`. create-ec-app consumes the catalog URL. `shadcn registry add` consumes the `{name}` template URL. Both must live under the same `/r/` directory.

Check the current shadcn registry docs before relying on CLI flags or schema fields. The CLI changes often and the working EC registry is a better model than memory. `references/static-registry-workflow.md` has the manifest, theme, Pages workflow, and verification templates.

## Inputs

Before touching files or GitHub, know the registry name, GitHub owner and repo, the theme source (existing CSS, a copied registry theme, or new token values), and the component source (an existing registry, the official `shadcn-ui/registry-template`, or a fresh app). If only the name is known, derive the rest and confirm before publishing:

```bash
node ~/.agents/skills/personal/create-custom-ui-registry/scripts/derive-registry-config.mjs --name "Acme UI" --owner acme --repo acme-ui-registry
```

## Rules that are easy to get wrong

- A new registry starts with every shadcn component. Run `npx shadcn@latest add --all` in a temporary app and copy `components/ui`, `lib/utils.ts`, and generated hooks into the registry source. Do not hand-pick a subset, even if the user only named one component as an example.
- Keep `@ui`, `@lib`, and `@hooks` target placeholders in manifests so installs follow the consumer's `components.json`.
- Nested `registry.json` files sit beside the files they publish, because file paths are relative to the declaring manifest. The root manifest lists them under `include`.
- Same-registry dependencies use full item URLs, `https://<owner>.github.io/<repo>/r/<item>.json`. A bare name such as `"button"` resolves to the built-in shadcn registry.
- The theme is a `registry:theme` item named `<slug>-theme`. Its `css` imports `tw-animate-css` and `./<slug>-theme.css`; its `files` target `src/<slug>-theme.css`. The CSS file holds `@custom-variant`, `@theme inline`, `:root:root`, `.dark.dark`, and `@layer base`. It must never overwrite the consumer's existing global CSS.
- UI items depend on the theme item and `utils` whenever they use theme tokens or `cn`.
- `public/r` is build output from `shadcn build registry.json --output public/r`. Inspect it, do not hand-edit it.
- Keep component internals at shadcn defaults unless the user asked for branded behaviour.

## Publish and verify

Run the smallest local checks first (`npm run validate:registry`, `npm run build:registry`, then the repo's build). Create or connect the public repo with `gh repo create <owner>/<repo> --public --source . --remote origin --push` and serve `public/r` through GitHub Pages from Actions or another static host.

Then verify from outside the repo:

```bash
npx shadcn@latest list https://<owner>.github.io/<repo>/r/registry.json
npx shadcn@latest registry add @<namespace>=https://<owner>.github.io/<repo>/r/{name}.json
npx shadcn@latest add @<namespace>/button
npx create-ec-app@latest <slug>-consumer --shadcn-registry https://<owner>.github.io/<repo>/r/registry.json
```

Run the last command inside a fresh temporary folder outside the registry repo. The generated app must contain `src/<slug>-theme.css`, import it from its app CSS, install `tw-animate-css` and the component dependencies, and build with styled components. Report anything on that list you did not check.

# Nope — Example Vault

A complete, ready-to-open Obsidian vault with worked examples for every core
feature of the **Nope** plugin (Markdown → PDF via Pandoc + LaTeX).

## Opening

1. Open this folder (`example-vault/`) in Obsidian (*Open folder as vault*).
2. Make the **Nope** plugin available to the vault — pick one:
   - **From the Community Store** — install (or enable) Nope like any other
     community plugin.
   - **From a cloned repo** — create a symlink so the vault uses your local
     build (see [Creating a symlink](#creating-a-symlink)).
3. Enable Nope under *Settings → Community plugins*. For the base examples,
   also enable the core **Bases** plugin (Obsidian ≥ 1.10).
4. Open a document and export it, or use the live PDF preview.

## Creating a Linux/Mac

Use this if you cloned the repo and want the vault to load Nope straight from
your **local build** — every rebuild is picked up, with no copying.

Obsidian looks for plugins in `<vault>/.obsidian/plugins/<id>/`. We point a
`nope` link there at the repo root, which holds `manifest.json` and the
built `main.js`.

Build the plugin once in the repo root, then create the link from the
`example-vault/` root:

```bash
# first time
npm install

# in the repo root: produce main.js
npm run build

# in example-vault/: link the plugin folder to the repo root
mkdir -p .obsidian/plugins
ln -s ../../.. .obsidian/plugins/nope
```

- The link name **must** be `nope` — it has to match the plugin `id` in
  `manifest.json`.
- `../../..` is resolved from the link's location (`.obsidian/plugins/`) and
  points three levels up to the repo root.
- After each rebuild, reload the plugin in Obsidian (toggle it off/on, or run
  *Reload app without saving*) so the new `main.js` is loaded.

### Windows

Use a real **Junction**  (works on the same drive, no admin rights or
Developer Mode needed):

```powershell
# first time
npm install

# in the repo root: produce main.js
npm run build

# still in the repo root: link the plugin folder to the repo root
New-Item -ItemType Directory -Force -Path "example-vault\.obsidian\plugins" | Out-Null
New-Item -ItemType Junction -Path "example-vault\.obsidian\plugins\nope" -Target "$PWD"
```

- If a `nope.lnk` shortcut already exists there, delete it first
  (`Remove-Item .obsidian\plugins\nope.lnk`) - Obsidian won't pick up the
  plugin as long as it's present, even alongside a correct link.
- `Get-Item example-vault\.obsidian\plugins\nope | Select LinkType` should
  report `Junction` if it worked.
- Same reload rule as above: after each rebuild, toggle the plugin off/on (or
  *Reload app without saving*) to pick up the new `main.js`.



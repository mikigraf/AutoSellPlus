# Contributing to AutoSellPlus

Thanks for your interest in contributing. This document covers the workflow and conventions used in this project.

## Getting Started

1. Fork the repository and clone your fork
2. Run the install script to set up local testing:
   ```bash
   ./install.sh
   ```
3. Make sure [luacheck](https://github.com/mpeterv/luacheck) is installed:
   ```bash
   luarocks install luacheck
   ```

## Development Workflow

1. Create a branch from `main`:
   ```bash
   git checkout -b your-branch-name
   ```
2. Make your changes in the `AutoSellPlus/` source directory
3. Test in-game by running `./install.sh` and `/reload`
4. Run the linter before committing:
   ```bash
   luacheck AutoSellPlus/
   ```
5. Commit and push your branch
6. Open a pull request against `main`

## Code Style

- **Lua 5.1** — WoW uses Lua 5.1. Do not use features from later versions.
- **No external libraries** — the addon has zero dependencies and should stay that way.
- **Namespace** — all addon code lives under the `ns` namespace table passed by WoW. Do not create new globals.
- **Naming** — `PascalCase` for functions, `camelCase` for local variables, `UPPER_SNAKE` for constants.
- **Indentation** — 4 spaces, no tabs.
- **Line length** — no hard limit, but keep lines readable.

## File Overview

| File | Purpose |
| :--- | :--- |
| `Config.lua` | Default settings, saved variable initialization |
| `Helpers.lua` | Utility functions (item level, transmog checks, money formatting) |
| `UI.lua` | Settings panel registered under Options > AddOns |
| `Popup.lua` | The merchant popup frame, filters, item rows, sell action |
| `Core.lua` | Sell queue, slash commands, event handling |

Files are loaded in the order listed in `AutoSellPlus.toc`. If you add a new file, add it to the `.toc` in the correct load order.

## Luacheck

The project uses luacheck for static analysis. Configuration is in `.luacheckrc`.

- WoW API globals go in `read_globals`
- Globals the addon writes to go in `globals`
- The CI pipeline will fail on any warning or error

If you use a new WoW API function, add it to the appropriate list in `.luacheckrc`.

## Commit Messages

- Use the imperative mood: "Add feature" not "Added feature"
- Keep the first line under 72 characters
- Reference issue numbers where applicable: `Fix item scan crash (#12)`

## Pull Requests

- Keep PRs focused on a single change
- Describe what the change does and why
- Make sure luacheck passes with zero warnings
- Test in-game before submitting

## What Not to Do

- Do not bump the version in the `.toc` file. The packager handles this automatically using git tags.
- Do not add files to the `.toc` without testing load order.
- Do not add external library dependencies.
- Do not modify `.github/workflows/` without discussing it first.

## Releasing

Only maintainers can create releases. See the [Releasing](README.md#-releasing) section of the README for details.

## Questions

Open an issue if you have questions or want to discuss a change before starting work.

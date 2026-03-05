<a id="readme-top"></a>

<br>
<br>

<p align="center">
  <img src="assets/icon.png" alt="AutoSellPlus" width="128">
</p>

<h1 align="center">AutoSellPlus for World of Warcraft</h1>

<p align="center">
  <b>Mass-sell low item level greens and blues in one click.</b>
</p>

<p align="center">
  <a href="#features">Features</a> &middot;
  <a href="#getting-started">Getting Started</a> &middot;
  <a href="#commands">Commands</a> &middot;
  <a href="#configuration">Configuration</a>
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/CloudsailDev/AutoSellPlus?style=for-the-badge&color=0078D4" alt="Version">
  &nbsp;
  <img src="https://img.shields.io/badge/WoW-Midnight-148EFF?style=for-the-badge&logo=battle.net&logoColor=white" alt="WoW Midnight">
  &nbsp;
  <img src="https://img.shields.io/badge/license-Proprietary-DA3B3B?style=for-the-badge" alt="License">
</p>

<br>

<p align="center">
  <img src="assets/demo.gif" alt="AutoSellPlus in action" width="640" style="border-radius:8px;">
</p>

<br>

<p align="center">
  AutoSellPlus pops up the moment you open a merchant and lays out every green and blue<br>
  below your gear level, pre-checked and ready to vendor. It knows what you're wearing,<br>
  protects upgrades and uncollected transmog, and sets ilvl thresholds automatically.
</p>

<h3 align="center">No setup. No accidents. Just gold.</h3>

<br>

---

<br>

## Features

|                            |                                                                            |
| :------------------------- | :------------------------------------------------------------------------- |
| **Instant merchant popup** | Every vendorable item laid out the moment you talk to a vendor             |
| **Smart auto-select**      | Grays, greens, and blues below your equipped ilvl are pre-checked          |
| **Upgrade protection**     | Never sells upgrades, equipment sets, uncollected transmog, or refundables |
| **Auto ilvl thresholds**   | Adapts to your gear automatically, no manual config needed                 |
| **Full control**           | One click to sell, Escape to cancel, uncheck anything you want to keep     |

<p align="right"><a href="#readme-top">back to top</a></p>

## Getting Started

### Installation

Drop the `AutoSellPlus` folder into your addons directory:

```
World of Warcraft/_retail_/Interface/AddOns/AutoSellPlus/
```

Or run the install script on macOS:

```bash
./install.sh
```

### Usage

1. Visit any merchant
2. AutoSellPlus popup appears with your junk pre-selected
3. Review, uncheck anything you want to keep
4. Hit **Sell Selected**

<p align="right"><a href="#readme-top">back to top</a></p>

## Commands

| Command            | Description                           |
| :----------------- | :------------------------------------ |
| `/asp`             | Show help                             |
| `/asp toggle`      | Enable / disable                      |
| `/asp dryrun`      | Preview mode, nothing gets sold       |
| `/asp config`      | Open settings panel                   |
| `/asp add <id>`    | Never sell this item                  |
| `/asp remove <id>` | Remove from never-sell list           |
| `/asp list`        | Show never-sell and always-sell lists |

> [!TIP]
> `/autosell` works as an alias for `/asp`

<p align="right"><a href="#readme-top">back to top</a></p>

## Configuration

Open with `/asp config` or **Options > AddOns > AutoSellPlus**.

| Category   | Options                                                   |
| :--------- | :-------------------------------------------------------- |
| **Safety** | Protect equipment sets, protect uncollected transmog      |
| **Output** | Sale summary, itemized log, dry run mode, buyback warning |

Filter controls (sell grays / greens / blues, ilvl sliders, equippable-only toggle) live directly on the popup and persist between sessions.

<p align="right"><a href="#readme-top">back to top</a></p>

---

<br>

<p align="center">
  Made by <a href="https://cloudsail.com">Cloudsail Digital Solutions</a>
</p>

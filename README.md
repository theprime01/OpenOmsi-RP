# OpenOmsi-RP

Ready-to-play builds of [openOMSI](https://github.com/openOMSI-org/openOMSI) that work with **ReShade**, with the **Realistic Passengers** changes built in. One zip per release, nothing to compile.

What's different from the official openOMSI:

- **The ReShade fix.** The official `openomsi.exe` crashes inside `dxgi.dll` as soon as ReShade is installed. These builds don't.
- **Realistic Passengers.** neoOMSI's people and passenger work is ported in: natural animations, driver animations, contact and sun shadows, boarding by the least busy door, and seat fixes. Every release also includes the RealisticPax-v2 figure pack.
- **Its own updates.** The launcher tells you when a new OpenOmsi-RP release is out. *Update now* installs it with `Update OpenOmsi.ps1`, so the official updater never swaps the ReShade fix back out.

## Install

1. Download `openOMSI-<version>-windows-x64-RP-full.zip` from the newest release on the [Releases](../../releases) page. It has everything, including the Realistic Passengers figures.
2. Unzip it into your openOMSI folder, or into a new folder.
3. Install [ReShade](https://reshade.me) for `openomsi.exe` with DirectX 10/11/12. ReShade isn't included.
4. Start `openomsi.exe`.

## Update

- **From the launcher:** when it says a new OpenOmsi-RP release is available, choose **Update now**. The launcher closes, the updater downloads and installs the release, then starts openOMSI again.
- **By hand:** close openOMSI and double-click **`Update OpenOmsi.cmd`** in the game folder.

The updater checks the download against the SHA-256 GitHub lists for it. It sets every file it replaces aside in `.update-backup\<old version>`. Your ReShade files, presets, mods and settings aren't in the zip, so they stay as they are.

Option: `Update OpenOmsi.cmd -Force` reinstalls the current release.

## Source and licences

Every release includes `openOMSI-<version>-RP-source.zip`, the exact source its exes were built from.

- openOMSI: MIT
- Code ported from [neoOMSI](https://github.com/neoOMSI/neoOMSI): GPL-3.0
- RealisticPax-v2 figures: Microsoft Rocketbox (MIT) and MakeHuman (CC0). The licences are in `RealisticPax-licenses\`.

This is a community build. It isn't made or supported by the openOMSI team, so please report problems with it here, not to openOMSI.

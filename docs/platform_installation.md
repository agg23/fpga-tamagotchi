# Platform-Specific Installation

* [ROMs](#roms)
* [Analogue Pocket](#analogue-pocket-1)
* [MiSTer](#mister-1)

## ROMs

The Tamagotchi ROM can be commonly found in the MAME zip `tama.zip`, and will be named `tama.b` inside that zip. I will not tell you how to obtain this ROM

MD5: `3fce172403c27274e59723bbb9f6d8e9`

----
### Analogue Pocket

All files are in `/Assets/tamagotchi_p1/common/`

* `rom.bin` - The Tamagotchi ROM
* `background.bin` - The background rendered by the core (Included)
* `spritesheet.bin` - The spritesheet/status icons (Included)

The background and spritesheet can be replaced by the user. See the [image generation tools](tools.md#image-preparation-prepare_imagejs) for more information.

----
### MiSTer

All files are in `/games/Tamagotchi/`

* `rom.bin` - The Tamagotchi ROM
* `boot1.rom` - The rendered background (Included)
* `boot2.rom` - The spritesheet/status icons (Included)

The background and spritesheet can be replaced by the user. See the [image generation tools](tools.md#image-preparation-prepare_imagejs) for more information.

## Analogue Pocket

### Easy Mode

I highly recommend the updater tools by [@mattpannella](https://github.com/mattpannella), [@RetroDriven](https://github.com/RetroDriven), and [@](https://github.com/neil-morrison44). Choose one of the following updaters:
* [Pocket Updater](https://github.com/RetroDriven/Pocket_Updater) - Windows only
* [Pocket Sync](https://github.com/neil-morrison44/pocket-sync) - Cross platform
* [Pocket Updater Utility](https://github.com/mattpannella/pocket-updater-utility) - Cross platform, command line only

Any of these will allow you to automatically download and install openFPGA cores onto your Analogue Pocket. Go donate to the creators if you can

----
### Manual Mode
Visit [Releases](https://github.com/agg23/openfpga-wonderswan/releases) and download the latest version of the core by clicking on the file named `agg23...-Pocket.zip`.

To install the core, copy the `Assets`, `Cores`, and `Platform` folders over to the root of your SD card. Please note that Finder on macOS automatically _replaces_ folders, rather than merging them like Windows does, so you have to manually merge the folders.

See [ROMs](#roms) to install the correct ROMs and have a booting core.

## MiSTer

There is currently no integration with the MiSTer updater, and therefore the core must be installed manually.

### Manual Mode

Visit [Releases](https://github.com/agg23/openfpga-wonderswan/releases) and download the latest version of the core by clicking on the file named `agg23...-MiSTer.zip`.

To install the core, copy the `_Other` and `games` folders over to the root of your SD card. Please note that Finder on macOS automatically _replaces_ folders, rather than merging them like Windows does, so you have to manually merge the folders.

See [ROMs](#roms) to install the correct ROMs and have a booting core.
# Organize Astrophotography Data

This is a Ruby gem command line tool to help organize astrophotography data into folders using keywords to assist in grouping and matching subframes for preprocessing and calibration. Subframe organization is compatible with keyword grouping in PixInsight using `WeightedBatchPreProcessing`.

The tool can quickly rename raw (CR2) files based on EXIF metadata and manual user input, which can then be used to group for preprocessing and calibration.

AstroSubframeOrganizer has been adapted from a standalone [Ruby Script](https://gist.github.com/shekibobo/b8e853bf70d787b55a87f7a4cf7ed248) to a customizable gem, with more features, customizability, and improved usability and safeguards.

This version of the gem was written to organize or reorganize the data collected to match my current workflow.

## Installation

Install the gem:

```bash
gem install astro-subframe-organizer
```

Or clone the repository and run:

```bash
bundle install
bundle exec rake install
```

## Getting Started

### Initialize your equipment set

Create a default config file with sample equipment and settings (~/astro-subframe-organizer-config.yml) and edit it to include your equipment:

```bash
astro-subframe-organizer init
```

Or create it with your equipment list directly:

```bash
astro-subframe-organizer init --telescope CarbonStar200 --filter NBZ --camera 'ZWO ASI183MC Pro'
```

Run the organizer:

```bash
astro-subframe-organizer run
```

Follow the interactive prompts to organize your files.

### Configuration

The gem supports customizable lists of telescopes, filters, and cameras. By default, it uses built-in lists, but you can create a personal configuration file.

#### Creating a Config File

To create a default configuration file:

```bash
astro-subframe-organizer init
```

This creates `~/astro-subframe-organizer-config.yml` with default values. Edit this file to customize your equipment or change configurations:

```yaml
telescopes:
  - RedCat51
  - ZhumellZ130
  - YourTelescope
filters:
  - BaaderMoon
  - NBZ
  - YourFilter
cameras:
  - T7
  - 183MC
  - ZWO ASI183MC Pro
  - Canon EOS 1500D
  - YourCamera
temperature_tolerance: 5.0
```

If you only use one set of equipment, you can create and update the config file in one shot:

```bash
astro-subframe-organizer init --telescope CarbonStar200 --filter NBZ --camera 'ZWO ASI183MC Pro'
```

When you run the organizer with only one option in each equipment category, the interactive organizer will automatically select the equipment unless there's a mismatch in the available metadata (FITS headers or EXIF data), so it may be useful to create multiple config files that include your common equipment configurations:

```bash
astro-subframe-organizer init --config ~/galaxy-season.yml --telescope CarbonStar200 --filter BaaderMoon --camera 'ZWO ASI533MC Pro'
```

```bash
astro-subframe-organizer init --config ~/nightscape.yml --telescope Rokinon135 --filter BaaderMoon --camera 'Canon T7'
```

```bash
astro-subframe-organizer init --config ~/dual-narrowband.yml --telescope Redcat51 --filter NBZ --camera 'ZWO ASI183MC Pro'
```

If you shoot with multiple filters, you can add additional filters in the config file:

```yaml
telescopes:
  - Redcat71
filters:
  - L
  - R
  - G
  - B
cameras:
  - ZWO ASI2600MM Pro
temperature_tolerance: 5.0
```

Note: if you have an automatic filter wheel and your software records the filter name in FITS headers, ASO will automatically select the assigned filter for organization.

#### Using a Custom Config File

You can specify a custom config file in all subcommands, and that config will be used for the duration of that run session:

```bash
astro-subframe-organizer run --config ~/galaxy-season.yml # All interactive menus will use equipment from galaxy-season.yml until you quit
```

## Organization Tools

There are several ways to use `astro-subframe-organizer`.

- [Organize Astrophotography Data](#organize-astrophotography-data)
  - [Installation](#installation)
  - [Getting Started](#getting-started)
    - [Initialize your equipment set](#initialize-your-equipment-set)
    - [Configuration](#configuration)
      - [Creating a Config File](#creating-a-config-file)
      - [Using a Custom Config File](#using-a-custom-config-file)
  - [Organization Tools](#organization-tools)
    - [Interactive Menu](#interactive-menu)
    - [Global Options](#global-options)
    - [Equipment Options](#equipment-options)
    - [Command Mode](#command-mode)
      - [Darks](#darks)
        - [Flat Darks](#flat-darks)
      - [Flats](#flats)
        - [FlatSet](#flatset)
      - [Lights](#lights)
      - [Biases](#biases)
      - [Unorganize](#unorganize)
    - [Raw Tools](#raw-tools)
      - [Rename From EXIF](#rename-from-exif)
      - [Revert Rename](#revert-rename)
    - [Cleanup Tools](#cleanup-tools)
      - [Delete Thumbnails](#delete-thumbnails)
      - [Delete Empty Directories](#delete-empty-directories)
    - [Utils](#utils)
  - [Historical Notes / Workflow](#historical-notes--workflow)
    - [Camera](#camera)
    - [Pre-ASIAir Image Data](#pre-asiair-image-data)
      - [Exposure Time](#exposure-time)
      - [Renaming Previously Renamed Files](#renaming-previously-renamed-files)
    - [PixInsight - WBPP](#pixinsight---wbpp)
      - [WBPP\_Darks](#wbpp_darks)
      - [WBPP\_Flats](#wbpp_flats)
      - [WBPP\_Integration](#wbpp_integration)
  - [Contributing](#contributing)
    - [Get Started Coding](#get-started-coding)
  - [Disclaimer](#disclaimer)

### Interactive Menu

To run the interactive organizer:

```bash
astro-subframe-organizer run # aliases: -i, --interactive
```

This will present you with a series of interactive menus to walk you through organizating each subframe type. Each subframe type has its own set of required inputs, which it will try to gather from FITS headers or filename patterns. If the information can't be detected automatically, the you will be prompted to choose, typically from the equipment in your [configuration file](#configuration).

```stdout
$ astro-subframe-organizer run --dry-run
Using config file at /Users/joshkovach/.astro_subframe_organizer.yml
What are we organizing? (Dry Run)
  1) Darks
  2) Flats
  3) Lights
  4) Biases
  5) Remove empty directories
  6) Remove jpg thumbnails
  7) Rename files from EXIF data
  8) Quit
  Choose 1-8 [1]: 
```

Selecting a given tool will lead you through an interactive set of prompts and confirmation steps to help organize your data, for example:

```stdout
What are we organizing? (Dry Run) Lights
Using config file at ~/.astro_subframe_organizer.yml
Preparing to move 330 Light files from 14 groups...
Preparing to move 1 Light file(s) 
  FROM spec/fixtures/cr2 
  TO   spec/fixtures/cr2/Light_Aurora_FLATSET_20210418_ISO_6400_EXP_4.0s_Bin_1_CCD-TEMP_20._TELESCOPE_????_FILTER_????_CAMERA_????
Continue? (Y/n) 
```

Note the `????` in the target path name – these are the fields that were not able to be detected automatically, and you will be prompted to select from a series of options to pick the missing fields from your configured equipment:

```stdout
For Light set Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2..Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2:
⚠ Telescope auto-detect failed.
What telescope is this set for? 
  1) RedCat51
  2) ZhumellZ130
  3) AperturaAD8
  4) MeadeDS90
  5) CanonEFS1855
  Choose 1-5 [1]: 

Selected Telescope: RedCat51

⚠ Filter auto-detect failed.
What filter is used with this set? 
  1) BaaderMoon
  2) NBZ
  3) NoFilter
  Choose 1-3 [1]: 

Selected Filter: NBZ

⚠ Camera auto-detect failed.
What camera is used with this set? 
  1) T7
  2) 183MC
  Choose 1-2 [1]: 

Selected Camera: 183MC

mv /Users/joshkovach/astrophotography/ruby-scripts/astro-subframe-organizer/spec/fixtures/cr2/Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2 /Users/joshkovach/astrophotography/ruby-scripts/astro-subframe-organizer/spec/fixtures/cr2/Light_Aurora_FLATSET_20210418_ISO_6400_EXP_4.0s_Bin_1_CCD-TEMP_20._TELESCOPE_RedCat51_FILTER_NBZ_CAMERA_183MC/Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2
Done

Preparing to move 62 Light file(s) 
  FROM spec/fixtures/fits/light-blanks 
  TO   spec/fixtures/fits/light-blanks/Light_C 1_FLATSET_20260411_ROTATION_108deg_GAIN_111_EXP_300.0s_Bin_1_TELESCOPE_EQMod Mount_FILTER_????_CAMERA_ZWO ASI183MC Pro
Continue? (Y/n) 
```

For each new set of files (split by index number overflow or when detected equipment changes) within the target directory, you'll be guided through the same set of prompts until all files have been organized into descriptive, keyword-based directories.

### Global Options

**`--dry-run`**

Great way to start experimenting with the tool. It will display all the `mv` commands that would happen, but without actually moving anything. Experiment without any risk, and to get a feel for how it will work with your files.

**`--skip-confirm`**

After you've become comfortable with how the tools work, you can pass override options to any command to make your workflow quicker. Passing the `--skip-confirm` option to any command will skip the `Continue?` prompts, and just assume that you know what you're doing. Especially helpful when you're using [command mode](#command-mode), where you can skip all interactions completely.

```stdout
$ astro-subframe-organizer run --dry-run --skip-confirm
Using config file at /Users/joshkovach/.astro_subframe_organizer.yml
What are we organizing? (Dry Run) Lights
⚠ Unprocessed raw images detected, but will be ignored. Raw images must be renamed before organizing. Run `astro-subframe-organizer raw rename_from_exif`, then try again.
Using config file at ~/.astro_subframe_organizer.yml
Preparing to move 330 Light files from 14 groups...
For Light set Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2..Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2:
⚠ Telescope auto-detect failed.
What telescope is this set for? 
  1) RedCat51
  2) ZhumellZ130
  3) AperturaAD8
  4) MeadeDS90
  5) CanonEFS1855
  Choose 1-5 [1]: 
```

**`--verbose`**

Prints all logs, including debug messages. Every file moved will display its `mv` command.

**`--path`**

By default, ASO will operate on the working directory (where the command is called from), and works on all sub-directories. Alternatively, you can specify a `--path` to operate on. Again, this will run recursively by default.

```bash
astro-subframe-organizer light --path staged/Plan/Lights/NGC\ 2264/
```

The above command will organize only the light files in the `NGC 2264` directory.

### Equipment Options

> [!TIP]
>
> Use the [`unorganize`](#unorganize) command if you need to undo an organization that didn't work as you expected.

**`--telescope`**

Automatically sets the telescope field for any command that uses it. When using `--telescope`, it will override the `TELESCOP` FITS header, and does not need to be one of the telescopes in your config file. If the auto-detected telescope is different from the `--telescope` value, a warning will be logged (e.g., `Using telescope RedCat51, but detected EQMod Mount`), but the move will continue using your override.

> [!NOTE]
>
> ASIAir sets the `TELESCOP` header to your *mount*, not your telescope, so you will likely see the warning a lot if your capture software does the same.

**`--camera`**

Automatically sets the camera field for any command that uses it. When using `--camera`, it will override the `INSTRUME` FITS header. If the auto-detected camera differs from your override, a warning will be logged, but the move will continue.

**`--filter`**

Automatically sets the filter field for any command that uses it. When using `--filter`, it will override the `FILTER` FITS header. If the auto-detected filter differs from your override, a warning will be logged, but the move will continue.

### Command Mode

If you want to skip the interactive menu, or you know what you're doing without it, you can directly call each of the available commands (and a few more) using the commands directly.

> [!NOTE]
>
> By default, all image types that get grouped by `CCD-TEMP` will be grouped together with the temperature rounded to the nearest 5°C. See the following example table for rounding ranges:
>
> | Actual Temp | Rounded Temp | Notes |
> | --- | --- | --- |
> | -10.0C | -10. | exactly on boundary |
> | -9.5C | -10. | 0.5 below boundary, rounds to -10 |
> | -10.5C | -10. | 0.5 above boundary, rounds to -10 |
> | -7.5C | -10. | equidistant between -5 and -10, rounds toward -10 |
> | -12.5C | -15. | equidistant between -10 and -15, rounds toward -15 |
> | -13.0C | -15. | closer to -15 |
> | -8.0C | -10. | closer to -10 |
> | 0.0C | 0. | zero |
> | 36.0C | 35. | warm DSLR, rounds to 35 |
> | 37.0C | 35. | closer to 35 |
> | 38.0C | 40. | closer to 40 |
> | -20.0C | -20. | colder target, exactly on boundary |
> | -18.0C | -20. | closer to -20 |
>
> Override `temperature_tolerance` in your config files to change the rounding.

#### Darks

Darks will be grouped in a folder by `CCD-TEMP` (rounded to nearest 5°C), `ISO` or `GAIN`, `EXP`, `CAMERA` and `MONTH` (e.g. 2022-06).

```bash
# run without interactive steps
astro-subframe-organizer darks --camera 'ZWO ASI183MC Pro' --skip-confirm
```

> [!TIP]
> When shooting with an uncooled camera, you can get a good idea what temperatures you need, and allows me to create master darks with combined temperatures of +/- 5°C if I need more darks at a certain temperature.

##### Flat Darks

The `darks` command will also check for possible flat darks, and will ask for confirmation when the exposure time is 10.0s or less. In the case of a flat dark set, it will organize them into a folder with `ISO` or `GAIN`, `EXP`, and `FLATSET` (the date of the darks and flats). These don't take `CCD-TEMP` into account, assuming the flats and flat darks are taken at roughly the same time and under the same conditions. 1°C variation is not going to make enough of a difference for me to care, and I only want one master flat from this `FLATSET`.

These files will be grouped into a folder prefixed with `DarkFlat` instead of just `Dark`. When moving off the ASIAir, I put this folder inside a `FLATSET_<date>` folder with the accompanying flats folder so I can load all the necessary files by directory in one shot in WBPP.

> [!NOTE]
> I don't actually use the DarkFlat capability anymore. This is a relic of when I had less control over operating conditions, so I've left it for beginners who may find it useful. The keywords used make it easier to match flats to flat-darks when dumping raw subframes into WBPP instead of using masters from a calibration library.
>
> Instead, I always shoot my flats at a fixed exposure time (5.0s), adjusting my flat panel to give the desired brightness for the equipment and exposure time I'm using. Whenever I create my Dark library for the season, I capture a set matching the exposure time of my flats. I use that master dark to separately calibrate my flats for the season.

#### Flats

Flats need to be taken with the same image train conditions as your lights, which typically includes:

- `ROTATION`
- `ISO` or `GAIN`
- `EXP`
- `TELESCOPE`
- `FILTER`
- `CAMERA`

Ideally, they are taken during or right after your session, so that any variation in the image train (dust, focus, ice, etc.) don't have a chance to change before you capture the frames that are meant to remove those variations.

> [!TIP]
> For this reason, I always take my flats in the morning after my imaging session, and before shutting off the camera to prevent any moisture that might be present on the sensor from melting and freezing in a different position.

In order to match lights, flats will be grouped using the [`FLATSET`](#flatset) keyword along with the keywords listed above.

```bash
# run without interactive steps
astro-subframe-organizer flats --telescope Redcat51 --filter NBZ --camera 'ZWO ASI183MC Pro' --skip-confirm
```

All of the aforementioned keywords are used in WBPP when doing the lights calibration and integration.

> [!TIP]
> Calibrate your flats after each session with a matching master dark from your darks library, and use the master flat in WBPP instead of the raw subframes. If you calibrate your flats with darks, you don't need to take bias frames.

##### FlatSet

The `FLATSET` value is just the date in format `YYYYMMdd`. Because I always take my flats in the morning after my session, the `FLATSET` for lights is calculated as the *end date* of the session. Any subframe taken after noon will use the `FLATSET` of the following day, and anything before noon will use the same date.

In the rare event that I can't take flats for a session, as long as I didn't change the image train significantly, I can usually still calibrate with a `FLATSET` taken on another date close to the missed session.

#### Lights

Similar to flats, organizing lights will prompt to select the telescope and filter used for this data set, and will organize into a folder with most of the same keywords as the flats.

```bash
# run without interactive steps
astro-subframe-organizer lights --telescope Redcat51 --filter BaaderMoon --camera 'ZWO ASI183MC Pro' --skip-confirm
```

#### Biases

Biases are taken at the fastest shutter speed available to your camera to remove the latent electrical noise on the camera sensor. When using flats without flat-darks, the flats and lights both need to be calibrated with bias frames. These frames are grouped primarily by `EXP`, `CAMERA`, and `MONTH` (to help match appropriate darks).

```bash
# run without interactive steps
astro-subframe-organizer biases --camera 'ZWO ASI183MC Pro' --skip-confirm
```

> [!TIP]
> If you take darks to calibrate your flats (a.k.a. flat-darks, a.k.a. dark-flats) and use the master flat calibrated with those darks, you don't need to use bias frames at all.

#### Unorganize

If you find that the organization didn't go as you hoped, you can easily ungroup those subframes, which just takes them out of their grouped directory, and removes the empty directory after the move.

```bash
# run without interactive steps
astro-subframe-organizer unorganize --skip-confirm
```

### Raw Tools

If you're shooting RAW without any software to wrap them with FITS headers, you'll end up getting an image named something like `IMG_00001.CR2` (that's what my Canon T7 does, anyway). This doesn't really help you be an organized astrophotographer, so I built a tool to help!

To use this tool uses [`exiftool`](https://exiftool.org/) for working with RAW files. For Mac and Linux users, the tool is included with the gem, but Windows users will need to install it separately.

**Windows**

Follow instructions at <https://exiftool.org/>, or install using Chocolatey on Windows 10. I don't use Windows, so if anyone uses it and wants to update this to be more specific, please submit a pull request.

```bash
choco install exiftool
```

**OSX**

```bash
brew install exiftool
```

**Ubuntu Linux**

```bash
sudo apt install exiftool 
```


#### Rename From EXIF

I first wrote this tool after I had started using an ASIAir with my Canon T7, and my original organization script used a filename parser to capture metadata and group accordingly. So for historical reasons, this tool renames RAW files to match the naming scheme used by ASIAir, which allowed me to group data from before and after getting my ASIAir.

> [!TIP]
> If you are starting out in astrophotography, and are just using a DSLR, I recommend starting here. Rename your unhelpful raw files, then run them through the organizer tools.

Use `raw rename` to rename `IMG_****.CR2` files to something helpful based on the embedded EXIF data and your own knowledge about what's in those photos.

```bash
# run without interactive steps
astro-subframe-organizer raw rename --type light --target 'NGC 2264' --telescope Redcat51 --filter BaaderMoon --skip-confirm
astro-subframe-organizer raw rename --type flat  --target 'NGC 2264' --telescope Redcat51 --filter BaaderMoon --skip-confirm
astro-subframe-organizer raw rename --type dark --skip-confirm
astro-subframe-organizer raw rename --type bias --skip-confirm
```

You should do this on files that are already grouped in separate directories to help keep them separate. There's currently no auto-detection set up for the type of subframe you're organizing, so you have to specify it. If you leave off any of the options, you will be prompted to fill in or select the required values for the subframe type.

#### Revert Rename

The `raw rename` tool will only work on images that match the prefix `IMG_`, so if you messed up the rename on the first pass, you can revert them and have another go.

```bash
# run without interactive steps
astro-subframe-organizer raw revert --skip-confirm
```

This will rename each image back to `IMG_****.CR2` as Canon intended.

### Cleanup Tools

#### Delete Thumbnails

ASIAir, and maybe other capturing software, includes a thumbnail for each FITS files so that it can display preview images on your phone. Outside of that context, they are a nuisance and are completely unnecessary. This tool will delete all those annoying jpgs in a snap!

```bash
# run without interactive steps
astro-subframe-organizer cleanup thumbnails --skip-confirm
```

It can't be undone, but why would you want to?

#### Delete Empty Directories

After reorganizing my photos and moving them to a better place, I'm often left with a bunch of deeply nested empty directories, with some not-so-empty ones mixed in, and I'd rather not have to dig through each one to figure out what to delete. So I made a tool for that!

```bash
astro-subframe-organizer cleanup empty
```

This will remove any directory that completely empty, recursively. Mac users may be familiar with the infamous hidden `.DS_Store` file - I don't count that as content. If the directory contains *only* `.DS_Store`, it still counts as empty. You can run this at the top-level of wherever you're working to make it easier to find what matters.

### Utils

If you want to see FITS headers or EXIF data that's on your images, use `inspect`:

```bash
astro-subframe-organizer inspect dark/IMG_0001.CR2
```

This will print out all the metadata on your RAW images, or all the FITS headers on a `.fit` image.

## Historical Notes / Workflow

### Camera

I used to use a Canon EOS 1500 (T7) DSLR for astrophotography, and attach it to one of my telescopes. Data capture is performed using the ASIAir Plus. In the ASIAir app, my camera's settings are configured to include ISO, Date, and Temp in the customized file name.

> Note: If you are using a different camera, the parameters included in your file name will likely be different, and you will need to change the `FitsFile#initialize` method to correctly match your file's properties based on the order they appear. You may also want to update your target directories to include those parameters, in whatever order you feel is appropriate for your workflow.

With the above settings, the files I generally capture are formatted as follows:

- Lights: `Light_M51_300.0s_Bin1_ISO800_20220309-024714_6.0C_0040.fit`
  - Target: M51
  - Exposure: 300.0s
  - Binning: 1
  - ISO: 800
  - DateTime: 20220309-024714
  - CCD-TEMP: 6.0C
  - Image index: 0040
- Lights: `Light_10 Lacertae_1-1_150.0s_Bin1_ISO800_20220913-223831_22.0C_0006.fit`
  - Target: 10 Lacerta
  - Pane: 1-1
  - Exposure: 150.0s
  - Binning: 1
  - ISO: 800
  - DateTime: 20220913-223831
  - CCD-TEMP: 22.0C
  - Image index: 0006
- Darks: `Dark_300.0s_Bin1_ISO800_20220517-152626_51.0C_0070.fit`
  - Exposure: 300.0s
  - Binning: 1
  - ISO: 800
  - DateTime: 20220517-152626
  - CCD-TEMP: 51.0C
  - Image index: 0070
- Flats: `Flat_2.3s_Bin1_ISO800_20220603-052827_14.0C_0006.fit`
  - Exposure: 2.3s
  - Binning: 1
  - ISO: 800
  - DateTime: 20220603-052827
  - CCD-TEMP: 14.0C
  - Image index: 0006

The goal of this script is to group these files in a way that works well with WBPP in a multi-step process, and to facilitate this file organization rather than taking all the time to do it manually.

### Pre-ASIAir Image Data

With the Canon T7 data captured before I started using an ASIAir Plus, the images were captured in RAW format as `CR2` files, with the name `IMG_0001.CR2`, which is pretty useless for AP photo organization. However, I've found that these RAW files do include most of the necessary data in EXIF tags to allow renaming to match my newer data generated by the ASIAir Plus, including exposure time, camera temperature, iso, etc. Using [exiftool](https://exiftool.org), these files can be renamed (with some extra parsing work in Ruby and some user input) to match the same file name pattern with actual data from the original source files.

To rename your older `IMG_XXXX.CR2` files, you can use the `Rename files with EXIF data` option. You will then be prompted to choose which type of file you are organizing. If you are organizing a `Light` file, you'll also be prompted to enter the target name.

**IMPORTANT** you must have `exiftool` installed and in your system path in order to run this renaming process.

#### Exposure Time

When the EXIF data includes `ExposureTime` less than 1 second, the value is formatted as a fraction, e.g. `1/250`, which then gets interpreted by most file systems as a directory separator. In order to handle this appropriately to match the decimal exposure formatting that the ASIAir generates, we need to do a few workarounds. First, we need to replace the `/` character with `-` so that the files don't get misplaced in a new directory. Second, we need to take the file that `exiftool` generates and parse it to recalculate that fraction value as a decimal at an appropriate time scale. So we parse the `1-250`, convert that to a `Rational` in Ruby, `Rational(1, 250)`, and then change the scale from seconds to milliseconds to nanoseconds until we have the exposure time represented as a number equal to or greater than 1.0.

#### Renaming Previously Renamed Files

This operation also lets you rename files that you renamed with an older naming format and convert it automatically to use the consistent naming pattern. If the script finds files that are not named `IMG_XXXX.CR2`, it will prompt you to choose whether to skip or rename them. It will then rename them all to `IMG_XXXX.CR2`, where `XXXX` is the last 4 characters of the filename (usually the sequence number). It will then run the script as normal on the now normallized files.

Once all of the files are renamed, they can then be organized into folders just as we do with the FITS files that we get from the ASIAir.

### PixInsight - WBPP

All of this organization is to facilitate a standardized workflow in PixInsight using WBPP with predefined process icons for generating each of master darks, master flats, and the master lights.

#### WBPP_Darks

This process icon is preloaded with appropriate master biases, uses the following grouping keywords on the Calibration tab:

| Keyword  | Pre | Post |
| -------- | --- | ---- |
| CCD-TEMP | x   | x    |
| ISO      | x   | x    |
| EXP      | x   | x    |
| MONTH    | x   | x    |

The generated darks are then able to be used in the `WBPP_Integration` process icon.

#### WBPP_Flats

This process icon is also preloaded with appropriate master biases, and uses the following grouping keywords on the Calibration tab:

| Keyword  | Pre | Post |
| -------- | --- | ---- |
| FLATSET  | x   | x    |
| BIN      | x   | x    |
| EXP      | x   |      |
| CCD-TEMP |     |      |
| ISO      | x   | x    |

Since my flats and darkflats are together in the same directory, I can load them into WBPP using the `Directory` button in one step, and then click the run button. One important manual step after this is to remove the `EXP_*` segment from the new master flat's file name. If you don't do this, the next step, `WBPP_Integration` will not automatically match your flats to your lights, since `EXP` is a required grouping keyword in that step to automatically match darks to lights. If the property exists on the filename, they must match. If keywors on one file don't exist on another, they are ignored in keyword grouping in WBPP.

#### WBPP_Integration

This process icon is preloaded with appropriate biases, but shouldn't be necessary at this point if you followed the process described so far. This step uses the following grouping keywords on the Calibration tab:

| Keyword  | Pre | Post |
| -------- | --- | ---- |
| FLATSET  | x   |      |
| BIN      | x   | x    |
| EXP      | x   |      |
| CCD-TEMP | x   |      |
| ISO      | x   | x    |
| LIGHT    |     | x    |
| PANE     | x   | x    |

Note that the `LIGHT` and `PANE` keywords are optional, but are important if you are working with multiple targets at the same time, e.g. for a multi-panel mosaic with each target named differently, or if using the new ASIAir mosaic helper in your plans. If you are working on multiple targets, you'll want to make sure you choose the `Registration Reference Image -> Mode -> auto by LIGHT (or PANE)` setting under the Calibration tab.

This final step is relatively easy. Simply load your master darks (not darkflats), your master flats, and all your lights. The script should automatically detect and group all the files for calibration. You may have to manually select a few of the darks and flats for calibration if you don't have the right temperature of darks for some lights, or if you reuse the same FLATSET for multiple nights. Other than that, just check your other settings and output directory for this run and you should be good to go.

## Contributing

This is a tool I've been using for several years now, and I'm excited to get it into a place I feel comfortable sharing it with other people to use. That said, it's *alpha* and has only been used *by me*. If you use this and have any problems with it, or would like better support for your equipment or workflows, please drop a friendly issue, and we can discuss it. If you have ideas for improvement, I'm also happy to consider pull requests.

Contributions are welcome from astrophotographers and developers alike — you don't need to write code to help. You can test the organizer with your own equipment and report what works or doesn't, validate the organization structure for your stacking software workflow, improve documentation, or help other users.

See [CONTRIBUTING.md](CONTRIBUTING.md) for full details, including development setup, fixture file guidelines, and pull request expectations.

This project follows the [Contributor Covenant](https://www.contributor-covenant.org/) [Code of Conduct](CODE_OF_CONDUCT.MD).

### Get Started Coding

```bash
git clone https://github.com/your-username/astro-subframe-organizer
cd astro-subframe-organizer
bin/setup
bundle exec rake spec
```

The test suite uses real stripped FITS fixture files. If you're working on a bug that
requires a new fixture, strip it first to remove image data and location headers:

```bash
bundle exec bin/strip_fits -o spec/fixtures/fits/your-set/ your_file.fit
```

## Disclaimer

I make no claims about the reliability of this script under your circumstances. Please test and verify the code and the conditions you will run this script through before running it on your data. Dry runs are your friend. If you are modifying the script to work for your data, you can use `puts file.inspect` to get a good look at how the script parsed your file names. **I am not responsible for lost or corrupted data or damaged devices resulting from the use of this script**, although under my specific conditions it has been working very well. Just be careful, make backups, test things out before you rely on this fully.

Clear skies!

Organize Astrophotography Data
===============

This is a Ruby script to help organize astrophotography data into folders using keywords that can then be used to help process in PixInsight using `WeightedBatchPreProcessing`.

This version of the script was written to organize or reorganize the data collected to match my current workflow, which I will outline below.

## Camera

I currently use a Canon EOS 1500 (T7) DSLR for astrophotography, and attach it to one of my telescopes. Data capture is performed using the ASIAir Plus. In the ASIAir app, my camera's settings are configured to include ISO, Date, and Temp in the customized file name.

> Note: If you are using a different camera, the paarameters included in your file name will likely be different, and you will need to change the `FitsFile#initialize` method to correctly match your file's properties based on the order they appear. You may also want to update your target directories to include those parameters, in whatever order you feel is appropriate for your workflow.

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

## Pre-ASIAir Image Data

With the Canon T7 data captured before I started using an ASIAir Plus, the images were captured in RAW format as `CR2` files, with the name `IMG_0001.CR2`, which is pretty useless for AP photo organization. However, I've found that these RAW files do include most of the necessary data in EXIF tags to allow renaming to match my newer data generated by the ASIAir Plus, including exposure time, camera temperature, iso, etc. Using [exiftool](https://exiftool.org), these files can be renamed (with some extra parsing work in Ruby and some user input) to match the same file name pattern with actual data from the original source files.

To rename your older `IMG_XXXX.CR2` files, you can use the `Rename files with EXIF data` option. You will then be prompted to choose which type of file you are organizing. If you are organizing a `Light` file, you'll also be prompted to enter the target name.

**IMPORTANT** you must have `exiftool` installed and in your system path in order to run this renaming process.

**Exposure Time**

When the EXIF data includes `ExposureTime` less than 1 second, the value is formatted as a fraction, e.g. `1/250`, which then gets interpreted by most file systems as a directory separator. In order to handle this appropriately to match the decimal exposure formatting that the ASIAir generates, we need to do a few workarounds. First, we need to replace the `/` character with `-` so that the files don't get misplaced in a new directory. Second, we need to take the file that `exiftool` generates and parse it to recalculate that fraction value as a decimal at an appropriate time scale. So we parse the `1-250`, convert that to a `Rational` in Ruby, `Rational(1, 250)`, and then change the scale from seconds to milliseconds to nanoseconds until we have the exposure time represented as a number equal to or greater than 1.0.

**Renaming Previously Renamed Files**

This operation also lets you rename files that you renamed with an older naming format and convert it automatically to use the consistent naming pattern. If the script finds files that are not named `IMG_XXXX.CR2`, it will prompt you to choose whether to skip or rename them. It will then rename them all to `IMG_XXXX.CR2`, where `XXXX` is the last 4 characters of the filename (usually the sequence number). It will then run the script as normal on the now normallized files.

Once all of the files are renamed, they can then be organized into folders just as we do with the FITS files that we get from the ASIAir.


## Darks

Darks will be grouped in a folder by `CCD-TEMP`, `ISO`, `EXP` and `MONTH` (e.g. 2022-06). This lets me get a good idea what temperatures I might be missing while shooting with an uncooled camera, and allows me to create master darks with combined temperatures of +/- 1°C if I need more darks at a certain temperature. If I don't have enough for a temperature, I can just copy some from another nearby temperature into that directory for the purpose of generating the master.

## Flat Darks

This script will also check for possible flat darks, and will ask for confirmation when the exposure time is 10.0s or less. In the case of a flat dark set, it will organize them into a folder with `ISO`, `EXP`, and `FLATSET` (the date of the darks and flats). These don't take `CCD-TEMP` into account, assuming the flats and flat darks are taken at roughly the same time and under the same conditions. 1°C variation is not going to make enough of a difference for me to care, and I only want one master flat from this `FLATSET`.

These files will be grouped into a folder prefixed with `DarkFlat` instead of just `Dark`. When moving off the ASIAir, I put this folder inside a `FLATSET_<date>` folder with the accompanying flats folder so I can load all the necessary files by directory in one shot in WBPP.

## Flats

Similar to flat darks, flats will be grouped using the `FLATSET` keyword, as well as `ISO`, `EXP`, and also `TELESCOPE` and `FILTER`. Since the ASIAir doesn't keep track of those parameters in the file name, this script prompts you to select from a list of your telescopes and filters to fill in those names for the grouping directory.

All of the aforementioned keywords are used in WBPP when doing the lights calibration and integration.

## Lights

Similar to flats, organizing lights will prompt to select the telescope and filter used for this data set, and will organize into a folder with vary similar keywords as the flats set.

## PixInsight - WBPP

All of this organization is to facilitate a standardized workflow in PixInsight using WBPP with predefined process icons for generating each of master darks, master flats, and the master lights.

### WBPP_Darks

This process icon is preloaded with appropriate master biases, uses the following grouping keywords on the Calibration tab:

|  Keyword  |  Pre  |  Post  |
| --------- | ----- | ------ |
|  CCD-TEMP |   x   |    x   |
|  ISO      |   x   |    x   |
|  EXP      |   x   |    x   |
|  MONTH    |   x   |    x   |

The generated darks are then able to be used in the `WBPP_Integration` process icon.

### WBPP_Flats

This process icon is also preloaded with appropriate master biases, and uses the following grouping keywords on the Calibration tab:

|  Keyword  |  Pre  |  Post  |
| --------- | ----- | ------ |
|  FLATSET  |   x   |    x   |
|  BIN      |   x   |    x   |
|  EXP      |   x   |        |
|  CCD-TEMP |       |        |
|  ISO      |   x   |    x   |

Since my flats and darkflats are together in the same directory, I can load them into WBPP using the `Directory` button in one step, and then click the run button. One important manual step after this is to remove the `EXP_*` segment from the new master flat's file name. If you don't do this, the next step, `WBPP_Integration` will not automatically match your flats to your lights, since `EXP` is a required grouping keyword in that step to automatically match darks to lights. If the property exists on the filename, they must match. If keywors on one file don't exist on another, they are ignored in keyword grouping in WBPP.

### WBPP_Integration

This process icon is preloaded with appropriate biases, but shouldn't be necessary at this point if you followed the process described so far. This step uses the following grouping keywords on the Calibration tab:

|  Keyword  |  Pre  |  Post  |
| --------- | ----- | ------ |
|  FLATSET  |   x   |        |
|  BIN      |   x   |    x   |
|  EXP      |   x   |        |
|  CCD-TEMP |   x   |        |
|  ISO      |   x   |    x   |
|  LIGHT    |       |    x   |
|  PANE     |   x   |    x   |

Note that the `LIGHT` and `PANE` keywords are optional, but are important if you are working with multiple targets at the same time, e.g. for a multi-panel mosaic with each target named differently, or if using the new ASIAir mosaic helper in your plans. If you are working on multiple targets, you'll want to make sure you choose the `Registration Reference Image -> Mode -> auto by LIGHT (or PANE)` setting under the Calibration tab.

This final step is relatively easy. Simply load your master darks (not darkflats), your master flats, and all your lights. The script should automatically detect and group all the files for calibration. You may have to manually select a few of the darks and flats for calibration if you don't have the right temperature of darks for some lights, or if you reuse the same FLATSET for multiple nights. Other than that, just check your other settings and output directory for this run and you should be good to go.

## System Requirements

This script is written in Ruby, so you'll need to have a modern version of that language installed on your computer. If you're on a Mac like I am, you might already have that installed, but if not, you can use HomeBrew to install `ruby-installer`, and then use that to install an appropriately recent version of Ruby. I developed this script using `ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [x86_64-darwin21]`. You can install that with `ruby-install ruby 3.1.2` in your terminal.

You will also need to install the gem `highline` to run this script. This is as simple as running the command `gem install highline` from the terminal after you have Ruby installed. Aside from that library, everything else is part of the standard language library.

If you are using the script to rename old `IMG_XXXX.CR2` files, you must install [exiftool](https://exiftool.org), which can also be installed on a Mac with Homebrew using `brew install exiftool` from the command line.

## Running the Organizer

This script MUST be run from the directory containing the files you want to group. The script file itself can live anywhere, but I keep it in my home directory.

Here is an example script run:

```bash
$ cd /Volumes/TF Images/ASIAIR/Autorun/Dark
$ ruby ~/organize_astro_data.rb
```

You will then be led through a list of prompts depending on what data you are organizing. You also have the option of doing a dry-run for each organization task you can choose.

```
$ ruby ~/astrophotography/organize_astro_data.rb
1. Darks
2. Flats
3. Lights
4. Biases
5. Remove empty directories
6. Remove jpg thumbnails
7. Rename files from EXIF data
8. Quit
What are we organizing?
1
Preparing to move 1564 DARK files...
Is this a dry run? [y/n]: n
```

This menu will repeat after completing each task until you quit. If all the files are already in their target directories, there will be nothing to move, and the script will just complete and go back to the main menu.

If you choose a dry-run for a given task, it will not move anything, but will print out the source file and its destination path. If you don't choose a dry run, nothing will be printed, and things will actually be moved.

There are also options to remove empty directories, which is useful if you've reorganized your files from a previous organization structure, and an option to remove all the jpg thumbnails to reduce the data that you'll be migrating off the ASIAir.

## Disclaimer

I make no claims about the reliability of this script under your circumstances. Please test and verify the code and the conditions you will run this script through before running it on your data. Dry runs are your friend. If you are modifying the script to work for your data, you can use `puts file.inspect` to get a good look at how the script parsed your file names. **I am not responsible for lost or corrupted data or damaged devices resulting from the use of this script**, although under my specific conditions it has been working very well. Just be careful, make backups, test things out before you rely on this fully.

Clear skies!

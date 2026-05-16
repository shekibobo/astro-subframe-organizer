# AI Agent Instructions for astro-subframe-organizer

## Project Overview
This is a Ruby gem CLI tool that organizes astrophotography FITS and CR2 image files by metadata for use with PixInsight's WeightedBatchPreProcessing. It uses an interactive command-line interface powered by highline and extracts image metadata via mini_exiftool.

For project context, see [README.md](README.md).

## Essential Commands

### Testing
```bash
rake test          # Run Minitest suite (default task)
rake test VERBOSE=1  # Run with verbose output
```

### Code Quality
```bash
rake rubocop       # Run linting checks
rake               # Run both tests and RuboCop (default)
```

### Building & Installation
```bash
bundle exec rake build     # Build the gem
bundle exec rake install   # Install locally for testing
bundle exec rake release   # Release to rubygems.org
```

## Project Structure

- `bin/astro-subframe-organizer` - CLI entry point; calls `AstroSubframeOrganizer.run`
- `lib/astro_subframe_organizer.rb` - Main module; coordinates FitsOrganizer and user interaction
- `lib/astro_subframe_organizer/` - Domain models:
  - `fits_organizer.rb` - Orchestrates file organization using metadata extraction and organization logic
  - `astrophoto.rb` - Represents a single astronomical image file with metadata
  - `camera.rb`, `telescope.rb`, `filter.rb` - Metadata models for organizing images
  - `version.rb` - Version constant
- `test/` - Minitest test suite with fixtures for testing FITS file handling

## Development Conventions

### Testing Approach
- **Test-Driven**: Write tests first (Red), make minimal changes to pass (Green), then refactor
- **Atomic commits**: Each commit represents one logical unit (e.g., add class + tests, then integrate)
- **Frequent commits**: Don't wait until a feature is complete; commit passing states frequently

### Code Style
- Use RuboCop for style enforcement; all code must pass `rake rubocop`
- Frozen string literals required: `# frozen_string_literal: true` at the top of every file
- Ruby >= 3.2.0 required

### File Organization & Naming
- Classes organized by concern in separate files under `lib/astro_subframe_organizer/`
- Tests mirror source structure: `test/astro_subframe_organizer/<class>_test.rb`
- Fixtures stored in `test/fixtures/` for mock data and test files

## Common Development Patterns

### Adding a New Feature or Fix
1. Write a failing test in the appropriate test file
2. Implement minimal code to make the test pass
3. Run `rake` to ensure all tests pass and linting passes
4. Refactor for clarity
5. Commit with a clear, focused message

### Running Tests During Development
When making multiple changes, run tests frequently:
```bash
rake test
```

Use this approach to verify your changes don't break existing functionality.

## Key Dependencies
- `highline` (~2.0) - Interactive CLI prompts
- `mini_exiftool` (~2.10) - Extract metadata from image files
- `minitest` (~5.0) - Testing framework
- `rubocop` - Linting and style enforcement

## Metadata Extraction Logic

### Astrophoto Class
[Astrophoto](lib/astro_subframe_organizer/astrophoto.rb) is the core model for parsing image file metadata from two sources:

**1. Filename Parsing**
The FITS/CR2 filename (from ASIAir) is split by underscores and parsed sequentially:
```
Light_M51_300.0s_Bin1_ISO800_20220309-024714_6.0C_0040.fit
 ↓     ↓    ↓     ↓    ↓      ↓              ↓    ↓
type target exp  bin  iso    created_at    temp index
```

Files may include: `type`, `target` (LIGHT only), `mosaic_pane` (optional), `exposure`, `binning`, `camera`, `iso`, `gain`, `created_at`, `ccd_temp`, `image_index`.

**2. Path-Based Extraction**
Some metadata is extracted from the file's current directory path using regex patterns:
- `telescope` via `TELESCOPE_<name>` pattern
- `filter` via `FILTER_<name>` pattern
- `dark_flat` by checking for `DarkFlat` in path

**3. Customizing for Different Camera Systems**
To adapt for different cameras or ASIAir configurations:
- Modify the parsing order in `Astrophoto#initialize` to match your filename pattern
- Update the regex patterns for telescope/filter extraction as needed
- Add camera models to the `Camera` constant

### Key Methods
- `target_dir` - Generates the destination folder path based on metadata and file type
- `flatset_id` - Generates a date-based grouping ID for flats (accounts for 12-hour offset)
- `month` - Extracts year-month from timestamp for seasonal dark grouping
- `maybe_flat_dark?` - Identifies short-exposure darks that may be flat darks (< 10 seconds)
- `dark_flat?` - Returns true if file has already been marked as a dark flat

## File Organization Workflow

### FitsOrganizer Class
[FitsOrganizer](lib/astro_subframe_organizer/fits_organizer.rb) orchestrates the organization of all file types using an interactive CLI.

**File Type Organization Methods**
- `organize_biases` - Group by ISO, BIN, CCD-TEMP; prompt for camera
- `organize_darks` - Group by ISO, BIN, CCD-TEMP, EXPOSURE, MONTH; offer dark flat classification
- `organize_flats` - Group by FLATSET, ISO, BIN, EXPOSURE; prompt for telescope, filter, camera
- `organize_lights` - Group by FLATSET, ISO, BIN, EXP, CCD-TEMP; prompt for telescope, filter, camera, target

**Grouping Strategy**
Files are grouped by `image_index` (sequential numbering per capture session). Within each group:
1. User is asked for confirmation before moving
2. Missing metadata (camera, telescope, filter) is prompted via highline CLI
3. Flat darks are classified (exposure < 10s) with user confirmation
4. All files in the group are moved to their computed target directories

**Dry Run Mode**
The organizer offers a dry-run option to preview moves without modifying files.

### Metadata Model Constants
- [Camera](lib/astro_subframe_organizer/camera.rb) - List of supported cameras (add new models here)
- [Telescope](lib/astro_subframe_organizer/telescope.rb) - List of available telescopes/lenses
- [Filter](lib/astro_subframe_organizer/filter.rb) - List of available filters

To add new equipment, append to the `ALL` constant in the appropriate class.

## Important Notes
- The gem is sensitive to FITS file naming conventions; metadata parsing depends on file name format
- If adapting for different camera systems, update `Astrophoto#initialize` to match file naming patterns (see README for details)
- Interactive prompts use highline for user-friendly input handling
- Files are grouped by `image_index` for batch processing; renumbering filenames can break grouping
- Dark flat detection assumes short exposures (< 10 seconds) are intentional—verify during organization

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.2] - 2025-02-24

### Added

- Multi-manufacturer RAW support: Added default support for `.cr3`, `.nef`, `.arw`, `.orf`, `.raf`, and `.dng` files.
- Configurable file extensions: Added `fits_extensions` and `raw_extensions` to the configuration file, allowing users to define which file types the tool should process.

### Changed

- Generalized RAW renaming: Updated `ExifRenamer` to recognize common manufacturer filename prefixes beyond Canon (e.g., Sony's `DSC_`, Nikon's `_DSC` and `DSCN`).
- Robustified EXIF parsing: Improved timezone handling when extracting metadata from RAW files to handle cases where time offset data is missing.
- Refactored `FilenameParser` factory to dynamically use extensions defined in the configuration.

### Fixed

- Fixed an issue where non-Canon RAW files were ignored by the file discovery logic.
- Resolved a potential crash in `ExifRenamer` when encountering unexpected date formats in metadata.

## [0.0.1] - 2025-02-24

### Added

- Interactive subframe organizer for FITS and CR2 files.
- Command-line interface powered by `dry-cli` with multiple subcommands:
  - `init`: Bootstraps the default configuration file.
  - `run`: Interactive wizard for organizing files.
  - `inspect`: View FITS headers and EXIF metadata.
  - `lights`, `darks`, `flats`, `biases`: Direct organization by type.
  - `raw rename`: Renames CR2 files based on EXIF data.
  - `unorganize`: Reverts files from organized subdirectories to a root directory.
  - `cleanup`: Removes thumbnails and empty directories.
- Configuration support via `~/astro-subframe-organizer-config.yml` or custom environment variables.
- Support for user-defined equipment (telescopes, cameras, filters) in configuration.
- `strip_raw` utility to create MIE metadata-only files from RAW images for testing.
- `FitsStripper` utility to remove location-identifying headers from FITS files.
- Structured logging system using Ruby's `Logger` with support for verbose output.
- Progress bar integration for long-running file operations.
- Multi-platform support (Linux, macOS, Windows) for path handling and shell dependencies.

### Changed

- Refactored filename parsing to use a Strategy pattern (`FilenameParser` and specific format parsers).
- Switched to `YAML.safe_load_file` for improved security when loading configuration.
- Centralized path building logic into `PathBuilder` and specific type builders.
- Standardized metadata handling using a `FileMetadata` value object.
- Replaced standard `puts` debugging with a structured logger.

### Fixed

- Cross-platform path separator issues.
- Case-insensitivity issues for file extensions and paths on Windows.
- Standard stream buffering issues in CI environments.
- Security: Explicitly permitted `Symbol` and `DateTime` classes in YAML loading.

[0.0.1]: https://github.com/joshkovach/astro-subframe-organizer/releases/tag/v0.0.1

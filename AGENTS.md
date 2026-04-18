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

## Important Notes
- The gem is sensitive to FITS file naming conventions; metadata parsing depends on file name format
- If adapting for different camera systems, update `FitsFile#initialize` to match file naming patterns (see README for details)
- Interactive prompts use highline for user-friendly input handling

# Contributing to Astro Subframe Organizer

Thank you for your interest in contributing! This project exists to help astrophotographers
spend less time on file management and more time imaging. Contributions of all kinds are
welcome — you don't need to write code to make a meaningful difference.

## Code of Conduct

This project follows the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/)
[Code of Conduct](CODE_OF_CONDUCT.MD). By participating, you agree to uphold it. Please report unacceptable
behavior to the project maintainer.

---

## Ways to Contribute

### Test with Your Equipment and Software

One of the most valuable contributions is running the organizer against your own data and
reporting what works and what doesn't. Every camera, mount, and capture application writes
FITS headers differently, and real-world test data is irreplaceable.

- Test with cameras, mounts, and rotators not already covered
- Test with capture software other than ASIAIR (N.I.N.A., Sequence Generator Pro, KStars/INDI, AstroPhoton, etc.)
- Submit issues when files aren't parsed or organized correctly
- Share anonymized (location-stripped) sample `.fit` or `.CR2` files that expose parsing gaps

> **Note:** Before sharing FITS files, please run them through `bin/strip_fits` to remove
> image data and strip location headers (`SITELAT`, `SITELONG`, RA/Dec, and WCS data) to protect 
> your privacy.

---

### Validate Organization Structure for Stacking Software

The directory and filename naming conventions are designed to support automated
calibration frame matching in preprocessing workflows. If you use stacking software
and can validate or improve compatibility, that's a high-value contribution.

Software of particular interest:
- **PixInsight** (WBPP — WeightedBatchPreProcessing)
- **Astro Pixel Processor**
- **DeepSkyStacker**
- **Siril**

If the current naming scheme doesn't work with your preprocessor's batch matching, open an
issue describing what keywords or structure it expects.

---

### Report Issues and Request Features

- **Bug reports:** Include your capture software, camera model, a sample filename, and
  the actual vs expected behavior. If possible, include a stripped fixture file.
- **Feature requests:** Describe your workflow and what problem the feature would solve.
  Context about your imaging setup helps evaluate the request.
- **Usability improvements:** If something is confusing, hard to discover, or produces
  unclear output, that's worth reporting even if it isn't technically broken.

Open issues at: [GitHub Issues](../../issues)

---

### Improve Documentation

Documentation improvements are always welcome:

- Fix typos, unclear wording, or outdated instructions
- Add examples for equipment setups not currently covered
- Document FITS header variations for specific cameras or capture software
- Improve inline code comments or RDoc

---

### Resolve Open Issues

Browse [open issues](../../issues) and help by:

- Reproducing and confirming reported bugs
- Suggesting solutions or workarounds in the discussion
- Submitting a pull request with a fix
- Writing or improving tests that cover a reported edge case

---

### Help Other Users

If you see a question in the issues or discussions that you can answer from experience,
please do — especially questions from users new to astrophotography or Ruby. A welcoming
community is part of what makes open-source tools worth using.

---

### Port to Other Languages

If you'd like to port this tool to Python, Rust, Go, or another language, please open an
issue first to discuss. Coordination helps avoid duplicated effort and ensures the
organizational logic stays consistent across implementations.

---

### Translate to Other Languages

CLI output strings, error messages, and documentation are currently English-only.
Translations are welcome. Open an issue to coordinate before starting a translation
to ensure the approach (i18n library, file structure) is agreed on first.

---

## Development Setup

### Prerequisites

- Ruby 3.2+
- Bundler
- ExifTool (for CR2 processing): `brew install exiftool`

### Getting Started

```bash
git clone https://github.com/your-username/astro-subframe-organizer
cd astro-subframe-organizer
bin/setup
bundle exec rake spec
```

### Running Tests

```bash
# Full test suite
bundle exec rake spec

# Single spec file
bundle exec rspec spec/path/to/spec.rb

# With coverage
bundle exec rake spec
open coverage/index.html
```

### Adding Fixture Files

If you're contributing a bug fix that requires a new FITS fixture:

1. Strip the file: `bundle exec bin/strip_fits -o spec/fixtures/fits/your-set/ your_file.fit`
2. Verify it still parses: `bundle exec astro-subframe-organizer inspect spec/fixtures/fits/your-set/your_file.fit`
3. Commit the stripped file

Never commit raw unstripped FITS files — they contain location data and are too large
for a source repository.

---

## Pull Request Guidelines

- **One concern per PR.** Separate bug fixes from feature additions.
- **Tests required.** New behavior needs specs. Bug fixes should include a regression test.
- **Run the full suite** before submitting: `bundle exec rake spec`
- **Follow existing style.** The project uses `rubocop` — run `bundle exec rubocop` and
  address any offenses before submitting.
- **Describe your changes** in the PR description, including what problem it solves and
  how you tested it.

---

## Commit Message Style

Use the imperative mood in the subject line:

```
Add support for ZWO ASI2600MC headers
Fix temperature grouping for darks with -9.5C variation
Update CONTRIBUTING with N.I.N.A. header examples
```

---

## Questions?

Open a [GitHub Discussion](../../discussions) or file an issue tagged `question`.

# frozen_string_literal: true

# Usage in specs:
#
# require 'support/fits_factory'
#
# RSpec.describe AstroSubframeOrganizer::FilenameParsers::FitsHeaderParser do
#   let(:test_dir) { Dir.mktmpdir }
#   after          { FileUtils.rm_rf(test_dir) }
#
#   let(:light_file) { FitsFactory.light(File.join(test_dir, 'light.fit')) }
#   let(:dark_file)  { FitsFactory.dark(File.join(test_dir, 'dark.fit')) }
#   let(:flat_file)  { FitsFactory.flat(File.join(test_dir, 'flat.fit'), filter: 'Ha') }
#
#   it 'parses a light frame' do
#     parser = described_class.new(light_file)
#     expect(parser.parse.type).to eq('Light')
#     expect(parser.parse.target).to eq('68 Cygni')
#   end
# end
module FitsFactory
  BLOCK_SIZE = 2880
  CARD_SIZE  = 80

  # Default headers matching a ZWO ASI183MC Pro light frame from ASIAIR Plus.
  # Override any key by passing a headers: hash.
  DEFAULTS = {
    'SIMPLE' => true,
    'BITPIX' => 16,
    'NAXIS' => 0,
    'IMAGETYP' => 'Light',
    'EXPOSURE' => 300.0,
    'EXPTIME' => 300.0,
    'CCD-TEMP' => -10.0,
    'XBINNING' => 1,
    'YBINNING' => 1,
    'INSTRUME' => 'ZWO ASI183MC Pro',
    'TELESCOP' => 'EQMod Mount',
    'OBJECT' => '68 Cygni',
    'GAIN' => 111,
    'DATE-OBS' => '2025-09-08T02:46:15.614262',
    'FILTER' => nil,
    'ROTATANG' => nil,
  }.freeze

  # Creates a minimal valid FITS file at `path` with no image data (NAXIS=0).
  # Pass `headers:` to override or add specific header values.
  # Pass `type:` as a shortcut for common frame types.
  def self.create(path, headers: {}, type: nil)
    merged = DEFAULTS
             .merge(type_defaults(type))
             .merge(headers)
             .compact

    File.binwrite(path, build(merged))
    path
  end

  def self.light(path, target: '68 Cygni', **)
    create(path, headers: { 'IMAGETYP' => 'Light', 'OBJECT' => target }, **)
  end

  def self.dark(path, **)
    create(path, headers: { 'IMAGETYP' => 'Dark' }, **)
  end

  def self.flat(path, filter: nil, **)
    create(path, headers: { 'IMAGETYP' => 'Flat', 'FILTER' => filter }.compact, **)
  end

  def self.bias(path, **)
    create(path, headers: { 'IMAGETYP' => 'Bias', 'EXPOSURE' => 0.0 }, **)
  end

  private_class_method def self.type_defaults(type)
    case type
    when :dark  then { 'IMAGETYP' => 'Dark',  'OBJECT' => nil }
    when :flat  then { 'IMAGETYP' => 'Flat',  'OBJECT' => nil }
    when :bias  then { 'IMAGETYP' => 'Bias',  'OBJECT' => nil, 'EXPOSURE' => 0.0 }
    else {}
    end
  end

  private_class_method def self.build(headers)
    cards = headers.map { |key, value| format_card(key, value) }
    cards << 'END'.ljust(CARD_SIZE)

    # Pad to a multiple of 2880 bytes
    raw = cards.join
    raw.ljust((raw.size.to_f / BLOCK_SIZE).ceil * BLOCK_SIZE)
  end

  private_class_method def self.format_card(key, value)
    formatted_value = case value
                      when true    then 'T'
                      when false   then 'F'
                      when Integer then value.to_s.rjust(20)
                      when Float   then format('%20.10G', value)
                      when String  then "'#{value.ljust(8).slice(0, 68)}'"
                      end
    "#{key.ljust(8)}= #{formatted_value}".ljust(CARD_SIZE).slice(0, CARD_SIZE)
  end
end

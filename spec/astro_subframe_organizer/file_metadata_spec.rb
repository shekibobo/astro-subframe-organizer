# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  include FilenameParsers

  describe FileMetadata do
    def build_metadata(ccd_temp:, type: 'Dark')
      FileMetadata.new(
        type: type,
        path: 'dark.fit',
        filename: 'dark.fit',
        file_format: :fits,
        ccd_temp: ccd_temp,
        exposure: '300.0s',
        gain: 111,
        camera: '183MC',
        created_at: DateTime.new(2026, 4, 11, 13, 0, 0),
      )
    end

    it 'parses metadata from filename' do
      path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
      parser = FitsFilenameParser.new(path)
      parsed_data = parser.parse

      metadata = described_class.from_parsed_data(parsed_data)

      expect(metadata).to have_attributes(
        type: 'Light',
        target: 'M42',
        exposure: '1.0s',
        bin: '1',
        camera: 'T7',
        iso: '100',
        gain: nil,
      )
    end

    it 'correctly identifies file format' do
      path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2'
      parser = CR2FilenameParser.new(path)
      parsed_data = parser.parse
      metadata = described_class.from_parsed_data(parsed_data)

      expect(metadata.file_format).to equal(:cr2)
    end

    it 'includes path and filename' do
      path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
      parser = FitsFilenameParser.new(path)
      parsed_data = parser.parse
      metadata = described_class.from_parsed_data(parsed_data)

      expect(metadata).to have_attributes(
        path: path,
        filename: 'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
      )
    end

    it 'can parse camera and gain' do
      path = '/fake/path/Light_M42_1.0s_Bin1_183MC_gain100_20220508-120000_-10.0C_0001.fit'
      parser = FitsFilenameParser.new(path)
      parsed_data = parser.parse
      metadata = described_class.from_parsed_data(parsed_data)

      expect(metadata).to have_attributes(
        camera: '183MC',
        gain: '100',
        iso: nil,
      )
    end

    describe '#rounded_ccd_temp' do
      context 'when ccd_temp is nil' do
        subject(:metadata) { build_metadata(ccd_temp: nil) }

        it 'returns nil' do
          expect(metadata.rounded_ccd_temp).to be_nil
        end
      end

      context 'with default tolerance of 5.0 degrees' do
        {
          '-10.0C' => '-10.', # exactly on boundary
          '-9.5C' => '-10.', # 0.5 below boundary, rounds to -10
          '-10.5C' => '-10.', # 0.5 above boundary, rounds to -10
          '-7.5C' => '-10.', # equidistant between -5 and -10, rounds toward -10
          '-12.5C' => '-15.',  # equidistant between -10 and -15, rounds toward -15
          '-13.0C' => '-15.',  # closer to -15
          '-8.0C' => '-10.', # closer to -10
          '0.0C' => '0.', # zero
          '36.0C' => '35.',   # warm DSLR, rounds to 35
          '37.0C' => '35.',   # closer to 35
          '38.0C' => '40.',   # closer to 40
          '-20.0C' => '-20.',  # colder target, exactly on boundary
          '-18.0C' => '-20.',  # closer to -20
        }.each do |input, expected|
          it "rounds #{input} to #{expected}" do
            expect(build_metadata(ccd_temp: input).rounded_ccd_temp).to eq(expected)
          end
        end
      end

      context 'with tolerance of 1.0 degree (exact grouping)' do
        {
          '-10.0C' => '-10.',
          '-10.5C' => '-11.',
          '-9.5C' => '-10.',
          '-9.6C' => '-10.',
          '-9.4C' => '-9.',
        }.each do |input, expected|
          it "rounds #{input} to #{expected}" do
            expect(build_metadata(ccd_temp: input).rounded_ccd_temp(tolerance: 1.0)).to eq(expected)
          end
        end
      end

      context 'with tolerance of 10.0 degrees (broad grouping)' do
        {
          '-10.0C' => '-10.',
          '-9.5C' => '-10.',
          '-14.9C' => '-10.',
          '-15.0C' => '-20.',
          '36.0C' => '40.',
          '34.9C' => '30.',
        }.each do |input, expected|
          it "rounds #{input} to #{expected}" do
            expect(build_metadata(ccd_temp: input).rounded_ccd_temp(tolerance: 10.0)).to eq(expected)
          end
        end
      end

      context 'when config provides the tolerance' do
        before do
          allow(Config).to receive(:temperature_tolerance).and_return(2.0)
        end

        it 'uses the configured tolerance by default' do
          expect(build_metadata(ccd_temp: '-10.5C').rounded_ccd_temp).to eq('-10.')
        end

        it 'uses explicit tolerance over config when provided' do
          expect(build_metadata(ccd_temp: '-10.5C').rounded_ccd_temp(tolerance: 5.0)).to eq('-10.')
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module FilenameParsers
    describe 'factory .for_file()' do
      it 'with fits file, creates a FitsFilenameParser' do
        path = '/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
        parser = FilenameParser.for_file(path, use_headers: false)

        expect(parser).to be_instance_of(FitsFilenameParser)
      end

      it 'with raw file, creates CR2FilenameParser' do
        path = '/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2'
        parser = FilenameParser.for_file(path)

        expect(parser).to be_instance_of(CR2FilenameParser)
      end

      it 'handles uppercase extensions' do
        path = '/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.FIT'
        parser = FilenameParser.for_file(path, use_headers: false)

        expect(parser).to be_instance_of(FitsFilenameParser)
      end
    end
  end
end

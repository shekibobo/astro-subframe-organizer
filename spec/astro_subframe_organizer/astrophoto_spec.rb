# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  describe Astrophoto do
    describe 'initialization' do
      it 'initializes with already organized path (extracts telescope/filter)' do
        path = '/organized/Flat_FLATSET_20220508_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
        photo = Astrophoto.new(path)

        expect(photo).to have_attributes(
          telescope: 'RedCat51',
          filter: 'BaaderMoon',
        )
      end

      it 'tests current_dir correctly' do
        photo = Astrophoto.new('/some/dir/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
        expect(photo.current_dir).to eq('/some/dir')
      end
    end

    describe 'lights' do
      it 'initializes light fits correctly' do
        path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
        photo = Astrophoto.new(path)
        expect(photo).to have_attributes(
          type: 'Light',
          target: 'M42',
          mosaic_pane: nil,
          exposure: '1.0s',
          bin: '1',
          camera: 'T7',
          iso: '100',
          gain: nil,
          created_at: DateTime.new(2022, 5, 8, 12, 0, 0),
          ccd_temp: '-10.0C',
          image_index: '0001',
          path: path,
          filename: 'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
          telescope: nil,
          filter: nil,
          dark_flat: false,
        )
      end

      it 'initializes with mosaic pane correctly' do
        path = '/fake/path/Light_M42_1-2_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
        photo = Astrophoto.new(path)

        expect(photo.mosaic_pane).to eq('1-2')
      end

      it 'initializes with gain correctly' do
        path = '/fake/path/Light_M42_1.0s_Bin1_183MC_gain100_20220508-120000_-10.0C_0001.fit'
        photo = Astrophoto.new(path)

        expect(photo.camera).to eq('183MC')
        expect(photo.iso).to be_nil
        expect(photo.gain).to eq('100')
      end

      describe 'flatset_id' do
        it 'uses same day for lights taken before noon (end of session, early morning)' do
          photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-110000_-10.0C_0001.fit')
          expect(photo.flatset_id).to eq('20220508')
        end

        it 'uses next day for lights taken after noon (start of session, evening)' do
          photo2 = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-130000_-10.0C_0001.fit')
          expect(photo2.flatset_id).to eq('20220509')
        end
      end

      describe 'target_dir' do
        it 'fits: uses keywords for to match flats and darks' do
          photo = Astrophoto.new('/fake/Light_68 Cygni_300.0s_Bin1_183MC_gain111_20250907-222335_-10.0C_0094.fit')
          photo.telescope = 'RedCat51'
          photo.filter = 'BaaderMoon'
          expected = 'Light_68 Cygni_FLATSET_20250908_GAIN_111_EXP_300.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_183MC'
          expect(photo.target_dir).to eq(expected)
        end

        it 'raw: uses keywords for to match flats and darks' do
          photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2')
          photo.telescope = 'RedCat51'
          photo.filter = 'BaaderMoon'
          expected = 'Light_M42_FLATSET_20220509_ISO_100_EXP_1.0s_Bin_1_CCD-TEMP_-10._TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7'
          expect(photo.target_dir).to eq(expected)
        end
      end

      describe 'target_path' do
        it 'will move the file without renaming it' do
          photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
          photo.telescope = 'RedCat51'
          photo.filter = 'BaaderMoon'
          expected = 'Light_M42_FLATSET_20220509_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
          expect(photo.target_path).to eq(expected)
        end
      end
    end

    describe 'darks' do
      it 'initializes dark correctly' do
        path = '/fake/path/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
        photo = Astrophoto.new(path)
        expect(photo.type).to eq('Dark')
        expect(photo.target).to be_nil
        expect(photo.exposure).to eq('30.0s')
        expect(photo.image_index).to eq('0001')
      end

      it 'is only dark flat if explicitly set' do
        photo = Astrophoto.new('/fake/Dark_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
        expect(photo.dark_flat?).to eq(false)

        photo.dark_flat = true
        expect(photo.dark_flat?).to eq(true)
      end

      it 'is potentially a flat dark if it has a short exposure' do
        # Short exposure dark
        photo = Astrophoto.new('/fake/Dark_5.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
        expect(photo.maybe_flat_dark?).to eq(true)

        # Long exposure dark
        photo2 = Astrophoto.new('/fake/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
        expect(photo2.maybe_flat_dark?).to eq(false)

        # Already dark flat
        photo3 = Astrophoto.new('/fake/Dark_5.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
        photo3.dark_flat = true
        expect(photo3.maybe_flat_dark?).to eq(false)
      end

      describe 'target_dir' do
        it 'will move based on dark keywords' do
          photo = Astrophoto.new('/fake/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
          expected = 'Dark_ISO_100_EXP_30.0s_CCD-TEMP_-10.0C_CAMERA_T7_MONTH_2022-05'
          expect(photo.target_dir).to eq(expected)
        end

        it 'will move based on dark keywords with flatset' do
          photo = Astrophoto.new('/fake/Dark_5.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
          photo.dark_flat = true
          expected = 'DarkFlat_FLATSET_20220508_ISO_100_EXP_5.0s_Bin_1_CAMERA_T7'
          expect(photo.target_dir).to eq(expected)
        end
      end

      describe 'target_path' do
        it 'will move the file without renaming it' do
          photo = Astrophoto.new('/fake/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
          expected = 'Dark_ISO_100_EXP_30.0s_CCD-TEMP_-10.0C_CAMERA_T7_MONTH_2022-05/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
          expect(photo.target_path).to eq(expected)
        end
      end
    end

    describe 'flats' do
      it 'initializes flat correctly' do
        path = '/fake/path/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
        photo = Astrophoto.new(path)

        expect(photo.type).to eq('Flat')
      end

      describe 'flatset_id' do
        it 'uses same day for flats even if taken after noon (assumes flats taken after overnight session)' do
          photo3 = Astrophoto.new('/fake/Flat_1.0s_Bin1_T7_ISO100_20220508-130000_-10.0C_0001.fit')
          expect(photo3.flatset_id).to eq('20220508')
        end
      end

      describe 'target_dir' do
        it 'will move based on flat keywords' do
          photo = Astrophoto.new('/fake/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
          photo.telescope = 'RedCat51'
          photo.filter = 'BaaderMoon'
          expected = 'Flat_FLATSET_20220508_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7'
          expect(photo.target_dir).to eq(expected)
        end
      end

      describe 'target_path' do
        it 'will move the file without renaming it' do
          photo = Astrophoto.new('/fake/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
          photo.telescope = 'RedCat51'
          photo.filter = 'BaaderMoon'
          expected = 'Flat_FLATSET_20220508_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
          expect(photo.target_path).to eq(expected)
        end
      end
    end

    describe 'biases' do
      it 'initializes bias correctly' do
        path = '/fake/path/Bias_0.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
        photo = Astrophoto.new(path)

        expect(photo.type).to eq('Bias')
      end

      describe 'target_dir' do
        it 'will move to target directory based on bias keywords' do
          photo = Astrophoto.new('/fake/Bias_0.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
          expected = 'Bias_ISO_100_EXP_0.0s_Bin_1_CAMERA_T7_MONTH_2022-05'
          expect(photo.target_dir).to eq(expected)
        end
      end

      describe 'target_path' do
        it 'will move the file without renaming it' do
          photo = Astrophoto.new('/fake/Bias_0.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
          expected = 'Bias_ISO_100_EXP_0.0s_Bin_1_CAMERA_T7_MONTH_2022-05/Bias_0.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
          expect(photo.target_path).to eq(expected)
        end
      end
    end

    describe 'moving' do
      it 'tests already_moved? correctly' do
        photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
        expect(photo.already_moved?).to eq(false)

        # Simulate moved
        photo.path = photo.target_path
        expect(photo.already_moved?).to eq(true)
      end

      # Test move (dry run)
      it 'tests move (dry run) correctly' do
        Dir.mktmpdir do |tmpdir|
          src_file = File.join(tmpdir, 'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
          File.write(src_file, 'fake data')
          photo = Astrophoto.new(src_file)
          photo.telescope = 'RedCat51'
          photo.filter = 'BaaderMoon'

          photo.move(true) # dry run

          expect(File).to exist(src_file)
          expect(File).not_to exist(photo.target_path)
        end
      end

      # Test move (actual, in temp dir)
      it 'tests move (actual, in temp dir) correctly' do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            src_file = 'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
            File.write(src_file, 'fake data')
            photo = Astrophoto.new(src_file)
            photo.telescope = 'RedCat51'
            photo.filter = 'BaaderMoon'

            photo.move(false) # actual move

            expect(File).to exist(photo.target_path)
            expect(File).not_to exist(src_file)
          end
        end
      end
    end
  end
end

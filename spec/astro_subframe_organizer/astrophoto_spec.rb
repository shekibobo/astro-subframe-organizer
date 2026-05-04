# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

module AstroSubframeOrganizer
  describe Astrophoto do
    # All specs use real FITS files created by FitsFactory in a temp directory.
    # FitsHeaderParser reads the headers and normalizes them to match the same
    # format as FitsFilenameParser:
    #   - exposure: formatted as "300.0s", "500.0ms", "100.0us"
    #   - ccd_temp: formatted as "-10.0C"
    #   - bin:      integer from XBINNING
    #   - gain:     integer from GAIN header
    #   - iso:      integer from ISO header (DSLRs only)
    #   - camera:   string from INSTRUME
    #   - telescope: string from TELESCOP
    #   - filter:   string from FILTER

    let(:tmpdir) { Dir.mktmpdir }
    after        { FileUtils.rm_rf(tmpdir) }

    def create_fit(filename, headers: {})
      FitsFactory.create(File.join(tmpdir, filename), headers: headers)
    end

    # ---------------------------------------------------------------------------
    # Initialization
    # ---------------------------------------------------------------------------

    describe 'initialization' do
      it 'reads telescope and filter from an already-organized path' do
        # Simulates a file already moved into a structured subdirectory.
        # The FitsFilenameParser extracts telescope/filter from the directory name.
        subdir = File.join(
          tmpdir,
          'Flat_FLATSET_20220508_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7',
        )
        FileUtils.mkdir_p(subdir)
        path = FitsFactory.create(
          File.join(subdir, 'Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'),
          headers: {
            'IMAGETYP' => 'Flat',
            'EXPOSURE' => 1.0,
            'INSTRUME' => 'T7',
            'DATE-OBS' => '2022-05-08T12:00:00.000000',
            'CCD-TEMP' => -10.0,
            'XBINNING' => 1,
          },
        )

        photo = Astrophoto.new(path)

        expect(photo.telescope).to eq('RedCat51')
        expect(photo.filter).to eq('BaaderMoon')
      end

      it 'returns the current directory correctly' do
        path = create_fit(
          'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
          headers: {
            'IMAGETYP' => 'Light',
            'OBJECT' => 'M42',
            'EXPOSURE' => 1.0,
            'INSTRUME' => 'T7',
            'DATE-OBS' => '2022-05-08T12:00:00.000000',
            'CCD-TEMP' => -10.0,
            'XBINNING' => 1,
          },
        )

        photo = Astrophoto.new(path)

        expect(photo.current_dir).to eq(tmpdir)
      end
    end

    # ---------------------------------------------------------------------------
    # Light frames
    # ---------------------------------------------------------------------------

    describe 'lights' do
      let(:light_path) do
        create_fit(
          'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
          headers: {
            'IMAGETYP' => 'Light',
            'OBJECT' => 'M42',
            'EXPOSURE' => 1.0,
            'INSTRUME' => 'T7',
            'ISO' => 100,
            'DATE-OBS' => '2022-05-08T12:00:00.000000',
            'CCD-TEMP' => -10.0,
            'XBINNING' => 1,
            'TELESCOP' => nil,
            'FILTER' => nil,
          },
        )
      end

      subject(:photo) { Astrophoto.new(light_path) }

      it 'parses all attributes correctly' do
        expect(photo).to have_attributes(
          type: 'Light',
          target: 'M42',
          mosaic_pane: nil,
          exposure: '1.0s',
          bin: 1,
          camera: 'T7',
          iso: 100,
          created_at: DateTime.new(2022, 5, 8, 12, 0, 0),
          ccd_temp: '-10.0C',
          image_index: '0001',
          filename: 'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
          telescope: nil,
          filter: nil,
          dark_flat: false,
        )
        expect(photo.path).to eq(light_path)
      end

      it 'parses mosaic pane correctly' do
        path = create_fit(
          'Light_M42_1-2_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
          headers: {
            'IMAGETYP' => 'Light',
            'OBJECT' => 'M42',
            'EXPOSURE' => 1.0,
            'INSTRUME' => 'T7',
            'DATE-OBS' => '2022-05-08T12:00:00.000000',
          },
        )

        expect(Astrophoto.new(path).mosaic_pane).to eq('1-2')
      end

      it 'parses gain-based camera correctly' do
        path = create_fit(
          'Light_M42_1.0s_Bin1_183MC_gain100_20220508-120000_-10.0C_0001.fit',
          headers: {
            'IMAGETYP' => 'Light',
            'OBJECT' => 'M42',
            'EXPOSURE' => 1.0,
            'INSTRUME' => '183MC',
            'GAIN' => 100,
            'DATE-OBS' => '2022-05-08T12:00:00.000000',
          },
        )

        photo = Astrophoto.new(path)

        expect(photo.camera).to eq('183MC')
        expect(photo.iso).to be_nil
        expect(photo.gain).to eq(100)
      end

      describe 'flatset_id' do
        it 'uses same day for lights taken before noon' do
          path = create_fit(
            'Light_M42_1.0s_Bin1_T7_ISO100_20220508-110000_-10.0C_0001.fit',
            headers: {
              'IMAGETYP' => 'Light',
              'OBJECT' => 'M42',
              'EXPOSURE' => 1.0,
              'INSTRUME' => 'T7',
              'DATE-OBS' => '2022-05-08T11:00:00.000000',
            },
          )

          expect(Astrophoto.new(path).flatset_id).to eq('20220508')
        end

        it 'uses next day for lights taken after noon' do
          path = create_fit(
            'Light_M42_1.0s_Bin1_T7_ISO100_20220508-130000_-10.0C_0001.fit',
            headers: {
              'IMAGETYP' => 'Light',
              'OBJECT' => 'M42',
              'EXPOSURE' => 1.0,
              'INSTRUME' => 'T7',
              'DATE-OBS' => '2022-05-08T13:00:00.000000',
            },
          )

          expect(Astrophoto.new(path).flatset_id).to eq('20220509')
        end
      end

      describe 'target_dir' do
        it 'builds target dir with flat/dark matching keywords for FITS files' do
          path = create_fit(
            'Light_68 Cygni_300.0s_Bin1_183MC_gain111_20250907-222335_-10.0C_0094.fit',
            headers: {
              'IMAGETYP' => 'Light',
              'OBJECT' => '68 Cygni',
              'EXPOSURE' => 300.0,
              'INSTRUME' => '183MC',
              'GAIN' => 111,
              'XBINNING' => 1,
              'DATE-OBS' => '2025-09-07T22:23:35.000000',
              'CCD-TEMP' => -10.0,
            },
          )
          photo = Astrophoto.new(path)
          photo.telescope = 'RedCat51'
          photo.filter    = 'BaaderMoon'

          expect(photo.target_dir).to eq(
            'Light_68 Cygni_FLATSET_20250908_GAIN_111_EXP_300.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_183MC',
          )
        end
      end

      describe 'target_path' do
        it 'moves the file without renaming it' do
          path = create_fit(
            'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
            headers: {
              'IMAGETYP' => 'Light',
              'OBJECT' => 'M42',
              'EXPOSURE' => 1.0,
              'INSTRUME' => 'T7',
              'ISO' => 100,
              'XBINNING' => 1,
              'DATE-OBS' => '2022-05-08T12:00:00.000000',
              'CCD-TEMP' => -10.0,
            },
          )
          photo = Astrophoto.new(path)
          photo.telescope = 'RedCat51'
          photo.filter    = 'BaaderMoon'

          expect(photo.target_path).to eq(
            'Light_M42_FLATSET_20220509_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7/' \
            'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
          )
        end
      end
    end

    # ---------------------------------------------------------------------------
    # Dark frames
    # ---------------------------------------------------------------------------

    describe 'darks' do
      let(:dark_path) do
        create_fit(
          'Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
          headers: {
            'IMAGETYP' => 'Dark',
            'EXPOSURE' => 30.0,
            'INSTRUME' => 'T7',
            'ISO' => 100,
            'DATE-OBS' => '2022-05-08T12:00:00.000000',
            'CCD-TEMP' => -10.0,
            'XBINNING' => 1,
          },
        )
      end

      it 'parses dark frame attributes correctly' do
        photo = Astrophoto.new(dark_path)

        expect(photo.type).to        eq('Dark')
        expect(photo.target).to      be_nil
        expect(photo.exposure).to    eq('30.0s')
        expect(photo.image_index).to eq('0001')
      end

      it 'is not a dark flat unless explicitly set' do
        path = create_fit(
          'Dark_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
          headers: {
            'IMAGETYP' => 'Dark',
            'EXPOSURE' => 1.0,
            'INSTRUME' => 'T7',
            'DATE-OBS' => '2022-05-08T12:00:00.000000',
          },
        )
        photo = Astrophoto.new(path)

        expect(photo.dark_flat?).to eq(false)
        photo.dark_flat = true
        expect(photo.dark_flat?).to eq(true)
      end

      it 'identifies short-exposure darks as potential flat darks' do
        short_path = create_fit(
          'Dark_5.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
          headers: {
            'IMAGETYP' => 'Dark',
            'EXPOSURE' => 5.0,
            'INSTRUME' => 'T7',
            'DATE-OBS' => '2022-05-08T12:00:00.000000',
          },
        )
        long_path = create_fit(
          'Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0002.fit',
          headers: {
            'IMAGETYP' => 'Dark',
            'EXPOSURE' => 30.0,
            'INSTRUME' => 'T7',
            'DATE-OBS' => '2022-05-08T12:00:00.000000',
          },
        )

        short_photo = Astrophoto.new(short_path)
        long_photo  = Astrophoto.new(long_path)

        expect(short_photo.maybe_flat_dark?).to eq(true)
        expect(long_photo.maybe_flat_dark?).to  eq(false)

        short_photo.dark_flat = true
        expect(short_photo.maybe_flat_dark?).to eq(false)
      end

      describe 'target_dir' do
        it 'builds target dir with dark keywords' do
          photo = Astrophoto.new(dark_path)

          expect(photo.target_dir).to eq(
            'Dark_ISO_100_EXP_30.0s_CCD-TEMP_-10.0C_CAMERA_T7_MONTH_2022-05',
          )
        end

        it 'builds dark flat target dir with flatset keywords' do
          path = create_fit(
            'Dark_5.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
            headers: {
              'IMAGETYP' => 'Dark',
              'EXPOSURE' => 5.0,
              'INSTRUME' => 'T7',
              'ISO' => 100,
              'XBINNING' => 1,
              'DATE-OBS' => '2022-05-08T12:00:00.000000',
              'CCD-TEMP' => -10.0,
            },
          )
          photo = Astrophoto.new(path)
          photo.dark_flat = true

          expect(photo.target_dir).to eq(
            'DarkFlat_FLATSET_20220508_ISO_100_EXP_5.0s_Bin_1_CAMERA_T7',
          )
        end
      end

      describe 'target_path' do
        it 'moves the file without renaming it' do
          photo = Astrophoto.new(dark_path)

          expect(photo.target_path).to eq(
            'Dark_ISO_100_EXP_30.0s_CCD-TEMP_-10.0C_CAMERA_T7_MONTH_2022-05/' \
            'Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
          )
        end
      end
    end

    # ---------------------------------------------------------------------------
    # Flat frames
    # ---------------------------------------------------------------------------

    describe 'flats' do
      let(:flat_path) do
        create_fit(
          'Flat_5.0s_Bin1_T7_GAIN111_20220508-120000_-10.0C_0001.fit',
          headers: {
            'IMAGETYP' => 'Flat',
            'EXPOSURE' => 5.0,
            'INSTRUME' => 'T7',
            'GAIN' => 111,
            'DATE-OBS' => '2022-05-08T12:00:00.000000',
            'CCD-TEMP' => -10.0,
            'XBINNING' => 1,
          },
        )
      end

      it 'parses flat frame type correctly' do
        expect(Astrophoto.new(flat_path).type).to eq('Flat')
      end

      describe 'flatset_id' do
        it 'uses same day for flats even if taken after noon' do
          path = create_fit(
            'Flat_5.0s_Bin1_T7_GAIN111_20220508-130000_-10.0C_0001.fit',
            headers: {
              'IMAGETYP' => 'Flat',
              'EXPOSURE' => 5.0,
              'INSTRUME' => 'T7',
              'DATE-OBS' => '2022-05-08T13:00:00.000000',
            },
          )

          expect(Astrophoto.new(path).flatset_id).to eq('20220508')
        end
      end

      describe 'target_dir' do
        it 'builds target dir with flat keywords' do
          photo = Astrophoto.new(flat_path)
          photo.telescope = 'RedCat51'
          photo.filter    = 'BaaderMoon'

          expect(photo.target_dir).to eq(
            'Flat_FLATSET_20220508_GAIN_111_EXP_5.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7',
          )
        end
      end

      describe 'target_path' do
        it 'moves the file without renaming it' do
          photo = Astrophoto.new(flat_path)
          photo.telescope = 'RedCat51'
          photo.filter    = 'BaaderMoon'

          expect(photo.target_path).to eq(
            'Flat_FLATSET_20220508_GAIN_111_EXP_5.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7/' \
            'Flat_5.0s_Bin1_T7_GAIN111_20220508-120000_-10.0C_0001.fit',
          )
        end
      end
    end

    # ---------------------------------------------------------------------------
    # Bias frames
    # ---------------------------------------------------------------------------

    describe 'biases' do
      let(:bias_path) do
        create_fit(
          'Bias_250.0us_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
          headers: {
            'IMAGETYP' => 'Bias',
            'EXPOSURE' => 0.00025,
            'INSTRUME' => 'T7',
            'GAIN' => 111,
            'DATE-OBS' => '2022-05-08T12:00:00.000000',
            'CCD-TEMP' => -10.0,
            'XBINNING' => 1,
          },
        )
      end

      it 'parses bias frame type correctly' do
        expect(Astrophoto.new(bias_path).type).to eq('Bias')
      end

      describe 'target_dir' do
        it 'builds target dir with bias keywords' do
          expect(Astrophoto.new(bias_path).target_dir).to eq(
            'Bias_GAIN_111_EXP_250.0us_Bin_1_CAMERA_T7_MONTH_2022-05',
          )
        end
      end

      describe 'target_path' do
        it 'moves the file without renaming it' do
          expect(Astrophoto.new(bias_path).target_path).to eq(
            'Bias_GAIN_111_EXP_250.0us_Bin_1_CAMERA_T7_MONTH_2022-05/' \
            'Bias_250.0us_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
          )
        end
      end
    end

    # ---------------------------------------------------------------------------
    # Moving
    # ---------------------------------------------------------------------------

    describe 'moving' do
      let(:move_path) do
        create_fit(
          'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
          headers: {
            'IMAGETYP' => 'Light',
            'OBJECT' => 'M42',
            'EXPOSURE' => 1.0,
            'INSTRUME' => 'T7',
            'ISO' => 100,
            'XBINNING' => 1,
            'DATE-OBS' => '2022-05-08T12:00:00.000000',
            'CCD-TEMP' => -10.0,
          },
        )
      end

      it 'reports already_moved? correctly' do
        photo = Astrophoto.new(move_path)
        expect(photo.already_moved?).to eq(false)

        photo.path = photo.target_path
        expect(photo.already_moved?).to eq(true)
      end

      it 'performs a dry run without moving the file' do
        photo = Astrophoto.new(move_path)
        photo.telescope = 'RedCat51'
        photo.filter    = 'BaaderMoon'

        photo.move(true)

        expect(File).to     exist(move_path)
        expect(File).not_to exist(File.join(tmpdir, photo.target_path))
      end

      it 'moves the file to the target directory' do
        Dir.chdir(tmpdir) do
          filename = 'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
          path = FitsFactory.create(
            filename,
            headers: {
              'IMAGETYP' => 'Light',
              'OBJECT' => 'M42',
              'EXPOSURE' => 1.0,
              'INSTRUME' => 'T7',
              'ISO' => 100,
              'XBINNING' => 1,
              'DATE-OBS' => '2022-05-08T12:00:00.000000',
              'CCD-TEMP' => -10.0,
            },
          )
          photo = Astrophoto.new(path)
          photo.telescope = 'RedCat51'
          photo.filter    = 'BaaderMoon'

          photo.move(false)

          expect(File).to     exist(photo.target_path)
          expect(File).not_to exist(filename)
        end
      end
    end
  end
end

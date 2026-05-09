# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

module AstroSubframeOrganizer
  describe Organizer, :files do
    subject(:organizer) do
      described_class.new(
        type: type,
        path: test_dir,
        prompt: prompt,
        equipment_selector: equipment_selector,
      )
    end

    let(:test_dir)           { Dir.mktmpdir }
    let(:prompt)             { instance_double(TTY::Prompt) }
    let(:equipment_selector) { instance_double(AstroSubframeOrganizer::EquipmentSelector) }
    let(:type)               { AstroSubframeOrganizer::Astrophoto::DARK }

    after { FileUtils.rm_rf(test_dir) }

    # ---------------------------------------------------------------------------
    # Helpers
    # ---------------------------------------------------------------------------

    def create_fit(filename, headers: {})
      path = File.join(test_dir, filename)
      FitsFactory.create(path, headers: headers)
      path
    end

    def stub_equipment(telescope: nil, camera: 'ZWO ASI183MC Pro', filter: nil)
      allow(equipment_selector).to receive(:telescope).and_return(telescope)
      allow(equipment_selector).to receive(:camera).and_return(camera)
      allow(equipment_selector).to receive(:filter).and_return(filter)
    end

    def skip_confirm
      ENV['ASTRO_SUBFRAME_SKIP_CONFIRM'] = 'true'
    end

    before do
      skip_confirm
      stub_equipment
    end

    after do
      ENV.delete('ASTRO_SUBFRAME_SKIP_CONFIRM')
    end

    # ---------------------------------------------------------------------------
    # #fits_files
    # ---------------------------------------------------------------------------

    describe '#fits_files' do
      context 'with .fit files' do
        before { create_fit('dark_0001.fit', headers: { 'IMAGETYP' => 'Dark' }) }

        it 'finds .fit files' do
          expect(organizer.fits_files).not_to be_empty
        end

        it 'returns Astrophoto instances' do
          expect(organizer.fits_files).to all(be_a(AstroSubframeOrganizer::Astrophoto))
        end
      end

      context 'with .FIT files' do
        before do
          path = File.join(test_dir, 'dark_0001.FIT')
          FitsFactory.create(path, headers: { 'IMAGETYP' => 'Dark' })
        end

        it 'finds .FIT files' do
          expect(organizer.fits_files).not_to be_empty
        end
      end

      context 'with files in subdirectories' do
        before do
          subdir = File.join(test_dir, 'subdir')
          FileUtils.mkdir_p(subdir)
          FitsFactory.create(File.join(subdir, 'dark_0001.fit'), headers: { 'IMAGETYP' => 'Dark' })
        end

        it 'finds files recursively' do
          expect(organizer.fits_files).not_to be_empty
        end
      end

      context 'with no matching files' do
        it 'returns an empty array' do
          expect(organizer.fits_files).to be_empty
        end
      end

      context 'with mixed file types' do
        before do
          create_fit('dark_0001.fit', headers: { 'IMAGETYP' => 'Dark' })
          FileUtils.touch(File.join(test_dir, 'readme.txt'))
          FileUtils.touch(File.join(test_dir, 'image.jpg'))
        end

        it 'ignores non-raw files' do
          expect(organizer.fits_files.size).to eq(1)
        end
      end
    end

    # ---------------------------------------------------------------------------
    # #organize — dark frames
    # ---------------------------------------------------------------------------

    describe '#organize' do
      let(:type) { AstroSubframeOrganizer::Astrophoto::DARK }

      context 'with no files' do
        it 'does not raise' do
          expect { organizer.organize }.not_to raise_error
        end
      end

      context 'with a single dark frame' do
        before do
          create_fit(
            'Dark_300.0s_Bin1_183MC_gain111_20260411-131154_-10.0C_0001.fit',
            headers: {
              'IMAGETYP' => 'Dark',
              'EXPOSURE' => 300.0,
              'XBINNING' => 1,
              'INSTRUME' => 'ZWO ASI183MC Pro',
              'GAIN' => 111,
              'DATE-OBS' => '2026-04-11T13:11:54.000000',
              'CCD-TEMP' => -10.0,
            },
          )
        end

        it 'does not raise' do
          expect { organizer.organize }.not_to raise_error
        end

        it 'applies the camera from equipment_selector' do
          organizer.organize
          expect(equipment_selector).to have_received(:camera).at_least(:once)
        end
      end

      context 'with a single dark frame and dry_run: true' do
        let(:filename) { 'Dark_300.0s_Bin1_183MC_gain111_20260411-131154_-10.0C_0001.fit' }

        before do
          create_fit(
            filename,
            headers: {
              'IMAGETYP' => 'Dark',
              'EXPOSURE' => 300.0,
              'XBINNING' => 1,
              'INSTRUME' => 'ZWO ASI183MC Pro',
              'GAIN' => 111,
              'DATE-OBS' => '2026-04-11T13:11:54.000000',
              'CCD-TEMP' => -10.0,
            },
          )
        end

        it 'does not move the file' do
          organizer.organize(dry_run: true)
          expect(File).to exist(File.join(test_dir, filename))
        end
      end

      context 'with dark frames at multiple exposure lengths' do
        before do
          [300.0, 600.0].each_with_index do |exp, i|
            create_fit(
              "Dark_#{exp}s_Bin1_183MC_gain111_20260411-13#{i}154_-10.0C_000#{i + 1}.fit",
              headers: {
                'IMAGETYP' => 'Dark',
                'EXPOSURE' => exp,
                'XBINNING' => 1,
                'INSTRUME' => 'ZWO ASI183MC Pro',
                'GAIN' => 111,
                'DATE-OBS' => "2026-04-11T13:1#{i}:54.000000",
                'CCD-TEMP' => -10.0,
              },
            )
          end
        end

        it 'does not raise' do
          expect { organizer.organize }.not_to raise_error
        end
      end

      context 'when camera is not detected from headers' do
        before do
          create_fit(
            'Dark_300.0s_Bin1_0001.fit',
            headers: {
              'IMAGETYP' => 'Dark',
              'EXPOSURE' => 300.0,
              'DATE-OBS' => '2026-04-11T13:11:54.000000',
              'INSTRUME' => nil,
            },
          )
          allow(equipment_selector).to receive(:camera).and_return(nil)
          allow(equipment_selector).to receive(:choose_camera).and_return('ZWO ASI183MC Pro')
        end

        it 'prompts for a camera' do
          organizer.organize
          expect(equipment_selector).to have_received(:choose_camera)
        end
      end

      context 'when multiple cameras are detected' do
        before do
          ['ZWO ASI183MC Pro', 'ZWO ASI294MC Pro'].each_with_index do |cam, i|
            create_fit(
              "Dark_300.0s_0#{i + 1}.fit",
              headers: {
                'IMAGETYP' => 'Dark',
                'EXPOSURE' => 300.0,
                'INSTRUME' => cam,
                'DATE-OBS' => "2026-04-11T13:1#{i}:54.000000",
              },
            )
          end
          allow(equipment_selector).to receive(:camera).and_return(nil)
          allow(equipment_selector).to receive(:choose_camera).and_return('ZWO ASI183MC Pro')
        end

        it 'prompts for a camera' do
          organizer.organize
          expect(equipment_selector).to have_received(:choose_camera)
        end
      end

      context 'when ASTRO_SUBFRAME_SKIP_CONFIRM is false and all files are unmoved' do
        before do
          ENV['ASTRO_SUBFRAME_SKIP_CONFIRM'] = 'false'
          create_fit(
            'Dark_300.0s_Bin1_183MC_gain111_20260411-131154_-10.0C_0001.fit',
            headers: {
              'IMAGETYP' => 'Dark',
              'EXPOSURE' => 300.0,
              'INSTRUME' => 'ZWO ASI183MC Pro',
              'DATE-OBS' => '2026-04-11T13:11:54.000000',
              'CCD-TEMP' => -10.0,
            },
          )
          allow(prompt).to receive(:yes?).and_return(false)
        end

        it 'prompts for confirmation' do
          organizer.organize
          expect(prompt).to have_received(:yes?)
        end

        it 'skips the fileset when user declines' do
          organizer.organize
          expect(File).to exist(File.join(test_dir, 'Dark_300.0s_Bin1_183MC_gain111_20260411-131154_-10.0C_0001.fit'))
        end
      end
    end

    # ---------------------------------------------------------------------------
    # #organize — light frames
    # ---------------------------------------------------------------------------

    describe '#organize with light frames' do
      let(:type) { AstroSubframeOrganizer::Astrophoto::LIGHT }

      before do
        stub_equipment(telescope: 'RedCat51', camera: 'ZWO ASI183MC Pro', filter: 'NoFilter')
      end

      context 'with a single light frame' do
        before do
          create_fit(
            'Light_C 1_300.0s_Bin1_183MC_gain111_20260410-230651_288deg_-10.0C_0001.fit',
            headers: {
              'IMAGETYP' => 'Light',
              'OBJECT' => 'C 1',
              'EXPOSURE' => 300.0,
              'XBINNING' => 1,
              'INSTRUME' => 'ZWO ASI183MC Pro',
              'GAIN' => 111,
              'DATE-OBS' => '2026-04-10T23:06:51.000000',
              'CCD-TEMP' => -10.0,
              'ROTATANG' => 288.0,
            },
          )
        end

        it 'does not raise' do
          expect { organizer.organize }.not_to raise_error
        end

        it 'checks telescope' do
          organizer.organize
          expect(equipment_selector).to have_received(:telescope).at_least(:once)
        end

        it 'checks filter' do
          organizer.organize
          expect(equipment_selector).to have_received(:filter).at_least(:once)
        end

        it 'checks camera' do
          organizer.organize
          expect(equipment_selector).to have_received(:camera).at_least(:once)
        end
      end

      context 'when telescope is not detected' do
        before do
          create_fit(
            'Light_M31_300.0s_0001.fit',
            headers: {
              'IMAGETYP' => 'Light',
              'OBJECT' => 'M31',
              'EXPOSURE' => 300.0,
              'DATE-OBS' => '2026-04-10T23:06:51.000000',
              'TELESCOP' => nil,
            },
          )
          stub_equipment(telescope: nil, camera: 'ZWO ASI183MC Pro', filter: 'NoFilter')
          allow(equipment_selector).to receive(:choose_telescope_or_confirm).and_return('RedCat51')
        end

        it 'prompts for a telescope' do
          organizer.organize
          expect(equipment_selector).to have_received(:choose_telescope_or_confirm)
        end
      end

      context 'when filter is not detected' do
        before do
          create_fit(
            'Light_M31_300.0s_0001.fit',
            headers: {
              'IMAGETYP' => 'Light',
              'OBJECT' => 'M31',
              'EXPOSURE' => 300.0,
              'DATE-OBS' => '2026-04-10T23:06:51.000000',
            },
          )
          stub_equipment(telescope: 'RedCat51', camera: 'ZWO ASI183MC Pro', filter: nil)
          allow(equipment_selector).to receive(:choose_filter).and_return('NoFilter')
        end

        it 'prompts for a filter' do
          organizer.organize
          expect(equipment_selector).to have_received(:choose_filter)
        end
      end

      context 'with dry_run: true' do
        let(:filename) { 'Light_C 1_300.0s_Bin1_183MC_gain111_20260410-230651_288deg_-10.0C_0001.fit' }

        before do
          create_fit(
            filename,
            headers: {
              'IMAGETYP' => 'Light',
              'OBJECT' => 'C 1',
              'EXPOSURE' => 300.0,
              'INSTRUME' => 'ZWO ASI183MC Pro',
              'DATE-OBS' => '2026-04-10T23:06:51.000000',
              'CCD-TEMP' => -10.0,
            },
          )
        end

        it 'does not move the file' do
          organizer.organize(dry_run: true)
          expect(File).to exist(File.join(test_dir, filename))
        end
      end
    end

    # ---------------------------------------------------------------------------
    # #organize — flat frames
    # ---------------------------------------------------------------------------

    describe '#organize with flat frames' do
      let(:type) { AstroSubframeOrganizer::Astrophoto::FLAT }

      before do
        stub_equipment(telescope: 'RedCat51', camera: 'ZWO ASI183MC Pro', filter: 'NoFilter')
        create_fit(
          'Flat_293deg_5.0s_Bin1_183MC_gain111_20251224-111503_-10.0C_0001.fit',
          headers: {
            'IMAGETYP' => 'Flat',
            'EXPOSURE' => 5.0,
            'XBINNING' => 1,
            'INSTRUME' => 'ZWO ASI183MC Pro',
            'GAIN' => 111,
            'DATE-OBS' => '2025-12-24T11:15:03.000000',
            'CCD-TEMP' => -10.0,
            'ROTATANG' => 293.0,
          },
        )
      end

      it 'does not raise' do
        expect { organizer.organize }.not_to raise_error
      end

      it 'checks telescope' do
        organizer.organize
        expect(equipment_selector).to have_received(:telescope).at_least(:once)
      end

      it 'checks filter' do
        organizer.organize
        expect(equipment_selector).to have_received(:filter).at_least(:once)
      end
    end

    # ---------------------------------------------------------------------------
    # #organize — already moved files
    # ---------------------------------------------------------------------------

    describe '#organize with already-moved files' do
      let(:type) { AstroSubframeOrganizer::Astrophoto::DARK }

      context 'when all files are already at their target path' do
        before do
          # Create an Astrophoto whose path == target_path by placing it
          # directly in the target directory structure
          photo = instance_double(
            AstroSubframeOrganizer::Astrophoto,
            type: 'Dark',
            path: '/dest/dark_0001.fit',
            target_path: '/dest/dark_0001.fit',
            already_moved?: true,
            filename: 'dark_0001.fit',
            image_index: '0001',
            camera: 'ZWO ASI183MC Pro',
          )
          allow(AstroSubframeOrganizer::FilenameParser).to receive(:for_file).and_return(
            double(
              parse: instance_double(
                AstroSubframeOrganizer::FileMetadata,
                type: 'Dark',
                path: '/dest/dark_0001.fit',
                image_index: '0001',
              ),
            ),
          )
          allow(AstroSubframeOrganizer::FileSet).to receive(:from_files).and_return(
            [
              instance_double(
                AstroSubframeOrganizer::FileSet,
                files: [photo],
                already_moved?: true,
                all_unmoved?: false,
              ),
            ],
          )
        end

        it 'skips already-moved filesets without prompting' do
          expect(prompt).not_to receive(:yes?)
          organizer.organize
        end
      end
    end

    describe 'equipment option precedence' do
      let(:type) { AstroSubframeOrganizer::Astrophoto::LIGHT }

      before do
        create_fit(
          'Light_M42_300.0s_Bin1_183MC_gain111_20260410-230000_-10.0C_0001.fit',
          headers: {
            'IMAGETYP' => 'Light',
            'OBJECT' => 'M42',
            'EXPOSURE' => 300.0,
            'XBINNING' => 1,
            'GAIN' => 111,
            'INSTRUME' => 'ZWO ASI183MC Pro',
            'TELESCOP' => 'RedCat51',
            'FILTER' => 'BaaderMoon',
            'DATE-OBS' => '2026-04-10T23:00:00.000000',
            'CCD-TEMP' => -10.0,
          },
        )
      end

      context 'when --telescope overrides header telescope' do
        before do
          stub_equipment(telescope: 'ZhumellZ130', camera: 'ZWO ASI183MC Pro', filter: 'NoFilter')
        end

        it 'uses the CLI-provided telescope in the target path' do
          puts "equipment_selector.telescope = #{equipment_selector.telescope.inspect}"
          organizer.organize
          moved_dirs = Dir.glob(File.join(test_dir, '*/'))
          puts "moved_dirs = #{moved_dirs.inspect}"
          expect(moved_dirs.first).to include('ZhumellZ130')
        end

        it 'does not use the header telescope value in the target path' do
          organizer.organize
          moved_dirs = Dir.glob(File.join(test_dir, '*/'))
          expect(moved_dirs.first).not_to include('RedCat51')
        end

        it 'does not prompt for telescope' do
          expect(equipment_selector).not_to receive(:choose_telescope)
          expect(equipment_selector).not_to receive(:choose_telescope_or_confirm)
          organizer.organize
        end
      end

      context 'when --telescope overrides a mount name in headers (ASIAIR)' do
        before do
          stub_equipment(telescope: 'RedCat51', camera: 'ZWO ASI183MC Pro', filter: 'NoFilter')
          # Re-create the fit with EQMod Mount as TELESCOP
          create_fit(
            'Light_M42_300.0s_Bin1_183MC_gain111_20260410-230000_-10.0C_0002.fit',
            headers: {
              'IMAGETYP' => 'Light',
              'OBJECT' => 'M42',
              'EXPOSURE' => 300.0,
              'XBINNING' => 1,
              'GAIN' => 111,
              'INSTRUME' => 'ZWO ASI183MC Pro',
              'TELESCOP' => 'EQMod Mount',
              'DATE-OBS' => '2026-04-10T23:00:01.000000',
              'CCD-TEMP' => -10.0,
            },
          )
        end

        it 'uses the CLI-provided telescope in the target path' do
          organizer.organize
          moved_dirs = Dir.glob(File.join(test_dir, '*/'))
          expect(moved_dirs.first).to include('RedCat51')
        end

        it 'does not use the mount name in the target path' do
          organizer.organize
          moved_dirs = Dir.glob(File.join(test_dir, '*/'))
          expect(moved_dirs.first).not_to include('EQMod')
        end

        it 'does not prompt for telescope' do
          expect(equipment_selector).not_to receive(:choose_telescope)
          expect(equipment_selector).not_to receive(:choose_telescope_or_confirm)
          organizer.organize
        end
      end

      context 'when --camera overrides header camera' do
        before do
          stub_equipment(telescope: 'RedCat51', camera: 'ZWO ASI294MC Pro', filter: 'NoFilter')
        end

        it 'uses the CLI-provided camera in the target path' do
          organizer.organize
          moved_dirs = Dir.glob(File.join(test_dir, '*/'))
          expect(moved_dirs.first).to include('ZWO ASI294MC Pro')
        end

        it 'does not use the header camera value in the target path' do
          organizer.organize
          moved_dirs = Dir.glob(File.join(test_dir, '*/'))
          expect(moved_dirs.first).not_to include('ZWO ASI183MC Pro')
        end

        it 'does not prompt for camera' do
          expect(equipment_selector).not_to receive(:choose_camera)
          organizer.organize
        end
      end

      context 'when --filter overrides header filter' do
        before do
          stub_equipment(telescope: 'RedCat51', camera: 'ZWO ASI183MC Pro', filter: 'NBZ')
        end

        it 'uses the CLI-provided filter in the target path' do
          organizer.organize
          moved_dirs = Dir.glob(File.join(test_dir, '*/'))
          expect(moved_dirs.first).to include('NBZ')
        end

        it 'does not use the header filter value in the target path' do
          organizer.organize
          moved_dirs = Dir.glob(File.join(test_dir, '*/'))
          expect(moved_dirs.first).not_to include('BaaderMoon')
        end

        it 'does not prompt for filter' do
          expect(equipment_selector).not_to receive(:choose_filter)
          organizer.organize
        end
      end

      context 'when --filter overrides absent filter header (OSC camera)' do
        before do
          stub_equipment(telescope: 'RedCat51', camera: 'ZWO ASI183MC Pro', filter: 'NBZ')
          create_fit(
            'Light_M42_300.0s_Bin1_183MC_gain111_20260410-230000_-10.0C_0003.fit',
            headers: {
              'IMAGETYP' => 'Light',
              'OBJECT' => 'M42',
              'EXPOSURE' => 300.0,
              'INSTRUME' => 'ZWO ASI183MC Pro',
              'FILTER' => nil,
              'DATE-OBS' => '2026-04-10T23:00:02.000000',
              'CCD-TEMP' => -10.0,
            },
          )
        end

        it 'uses the CLI-provided filter in the target path' do
          organizer.organize
          moved_dirs = Dir.glob(File.join(test_dir, '*/'))
          expect(moved_dirs.first).to include('NBZ')
        end

        it 'does not prompt for filter' do
          expect(equipment_selector).not_to receive(:choose_filter)
          organizer.organize
        end
      end
    end
  end
end

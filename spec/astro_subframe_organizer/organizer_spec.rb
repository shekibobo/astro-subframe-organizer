# frozen_string_literal: true

require 'spec_helper'
require 'astro_subframe_organizer/organizer'

RSpec.describe AstroSubframeOrganizer::Organizer do
  subject(:organizer) { described_class.new(type: type, path: test_dir, cli: cli, equipment_selector: equipment_selector) }

  let(:test_dir) { Dir.mktmpdir }
  let(:cli) { class_double(CLI::UI::Prompt) }
  let(:equipment_selector) { instance_double(AstroSubframeOrganizer::EquipmentSelector) }
  let(:type)               { AstroSubframeOrganizer::Astrophoto::DARK }

  after { FileUtils.rm_rf(test_dir) }

  # Helpers

  def stub_equipment_selector(telescope: nil, filter: nil, camera: 'T7')
    allow(equipment_selector).to receive(:telescope).and_return(telescope)
    allow(equipment_selector).to receive(:filter).and_return(filter)
    allow(equipment_selector).to receive(:camera).and_return(camera)
  end

  def create_fits_file(filename)
    path = File.join(test_dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.touch(path)
    path
  end

  def stub_fileset(fileset, already_moved: false, all_unmoved: true, cameras: ['T7'], telescopes: ['RedCat51'], filters: ['NoFilter'])
    files = [
      instance_double(AstroSubframeOrganizer::Astrophoto, filename: 'first.fit', target_dir: '/dest', move: true),
      instance_double(AstroSubframeOrganizer::Astrophoto, filename: 'last.fit',  target_dir: '/dest', move: true),
    ]

    allow(fileset).to receive(:already_moved?).and_return(already_moved)
    allow(fileset).to receive(:all_unmoved?).and_return(all_unmoved)
    allow(fileset).to receive(:camera_candidates).and_return(cameras)
    allow(fileset).to receive(:telescope_candidates).and_return(telescopes)
    allow(fileset).to receive(:filter_candidates).and_return(filters)
    allow(fileset).to receive(:apply_camera!)
    allow(fileset).to receive(:apply_telescope!)
    allow(fileset).to receive(:apply_filter!)
    allow(fileset).to receive(:type).and_return(type)
    allow(fileset).to receive(:each) { |&block| files.each(&block) }
    allow(fileset).to receive(:files).and_return(files)
    allow(fileset).to receive(:current_dir).and_return(test_dir)
    fileset
  end

  def make_fileset(**kwargs)
    stub_fileset(instance_double(AstroSubframeOrganizer::FileSet), **kwargs)
  end

  # Specs

  describe '#fits_files' do
    # Expects .fit, .FIT, .cr2, .CR2 files in test_dir and subdirectories.
    # Files with other extensions should be ignored.
    context 'with a mix of file types' do
      before do
        create_fits_file('light.fit')
        create_fits_file('dark.FIT')
        create_fits_file('frame.cr2')
        create_fits_file('raw.CR2')
        create_fits_file('image.jpg')
        create_fits_file('readme.txt')
      end

      it 'finds .fit files' do
        expect(organizer.fits_files.map(&:filename)).to include('light.fit')
      end

      it 'finds .FIT files' do
        expect(organizer.fits_files.map(&:filename)).to include('dark.FIT')
      end

      it 'finds .cr2 files' do
        expect(organizer.fits_files.map(&:filename)).to include('frame.cr2')
      end

      it 'finds .CR2 files' do
        expect(organizer.fits_files.map(&:filename)).to include('raw.CR2')
      end

      it 'ignores non-raw files' do
        filenames = organizer.fits_files.map(&:filename)
        expect(filenames).not_to include('image.jpg', 'readme.txt')
      end

      it 'returns Astrophoto instances' do
        expect(organizer.fits_files).to all(be_a(AstroSubframeOrganizer::Astrophoto))
      end
    end

    context 'with files in subdirectories' do
      before { create_fits_file('subdir/nested.fit') }

      it 'finds files recursively' do
        expect(organizer.fits_files.map(&:path)).to include('subdir/nested.fit')
      end
    end

    context 'with duplicate filenames' do
      before do
        create_fits_file('frame.fit')
        create_fits_file('frame.FIT')
      end

      it 'deduplicates files' do
        filenames = organizer.fits_files.map(&:filename)
        expect(filenames.uniq).to eq(filenames)
      end
    end

    context 'with no matching files' do
      it 'returns an empty array' do
        expect(organizer.fits_files).to be_empty
      end
    end
  end

  describe '#organize' do
    before do
      allow(AstroSubframeOrganizer::FileSet).to receive(:from_files).and_return(filesets)
    end

    context 'with no filesets' do
      let(:filesets) { [] }

      it 'does not raise an error' do
        expect { organizer.organize }.not_to raise_error
      end
    end

    context 'with an already-moved fileset' do
      let(:filesets) { [make_fileset(already_moved: true)] }

      it 'skips the fileset' do
        expect(filesets.first).not_to receive(:each)
        organizer.organize
      end
    end

    context 'with an all-unmoved fileset' do
      let(:filesets) { [make_fileset(all_unmoved: true)] }

      before { stub_equipment_selector }

      context 'when user confirms move' do
        before { allow(cli).to receive(:confirm).and_return(true) }

        it 'moves the files' do
          expect(filesets.first).to receive(:each)
          organizer.organize
        end
      end

      context 'when user declines move' do
        before { allow(cli).to receive(:confirm).and_return(false) }

        it 'skips the fileset' do
          expect(filesets.first).not_to receive(:each)
          organizer.organize
        end
      end
    end

    context 'with a dark frame fileset' do
      let(:type)     { AstroSubframeOrganizer::Astrophoto::DARK }
      let(:filesets) { [make_fileset(all_unmoved: false)] }

      before do
        stub_equipment_selector
        allow(cli).to receive(:confirm).and_return(true)
      end

      it 'does not check telescope' do
        expect(equipment_selector).not_to receive(:choose_telescope)
        organizer.organize
      end

      it 'does not check filter' do
        expect(equipment_selector).not_to receive(:choose_filter)
        organizer.organize
      end

      it 'checks camera' do
        expect(filesets.first).to receive(:apply_camera!).with('T7')
        organizer.organize
      end
    end

    context 'with a light frame fileset' do
      let(:type)     { AstroSubframeOrganizer::Astrophoto::LIGHT }
      let(:filesets) { [make_fileset(all_unmoved: false)] }

      before do
        stub_equipment_selector(telescope: 'RedCat51', filter: 'NoFilter', camera: 'T7')
        allow(cli).to receive(:confirm).and_return(true)
      end

      it 'checks telescope' do
        expect(filesets.first).to receive(:apply_telescope!).with('RedCat51')
        organizer.organize
      end

      it 'checks filter' do
        expect(filesets.first).to receive(:apply_filter!).with('NoFilter')
        organizer.organize
      end

      it 'checks camera' do
        expect(filesets.first).to receive(:apply_camera!).with('T7')
        organizer.organize
      end
    end

    context 'with a flat frame fileset' do
      let(:type)     { AstroSubframeOrganizer::Astrophoto::FLAT }
      let(:filesets) { [make_fileset(all_unmoved: false)] }

      before do
        stub_equipment_selector(telescope: 'RedCat51', filter: 'NoFilter', camera: 'T7')
        allow(cli).to receive(:confirm).and_return(true)
      end

      it 'checks telescope' do
        expect(filesets.first).to receive(:apply_telescope!).with('RedCat51')
        organizer.organize
      end

      it 'checks filter' do
        expect(filesets.first).to receive(:apply_filter!).with('NoFilter')
        organizer.organize
      end
    end

    context 'with dry_run: true' do
      let(:filesets) { [make_fileset(all_unmoved: false)] }

      before do
        stub_equipment_selector
        allow(cli).to receive(:confirm).and_return(true)
      end

      it 'passes dry_run to each file move' do
        filesets.first.files.each do |file|
          expect(file).to receive(:move).with(true)
        end
        organizer.organize(dry_run: true)
      end
    end

    describe 'camera resolution' do
      let(:filesets) { [make_fileset(all_unmoved: false, cameras: cameras)] }

      before do
        stub_equipment_selector(camera: nil)
        allow(cli).to receive(:confirm).and_return(true)
      end

      context 'when equipment_selector has a camera set' do
        before { allow(equipment_selector).to receive(:camera).and_return('T7') }
        let(:cameras) { [] }

        it 'uses the equipment_selector camera without prompting' do
          expect(equipment_selector).not_to receive(:choose_camera)
          organizer.organize
        end
      end

      context 'when no camera is detected' do
        let(:cameras) { [] }

        it 'prompts to choose a camera' do
          expect(equipment_selector).to receive(:choose_camera).and_return('T7')
          organizer.organize
        end
      end

      context 'when multiple cameras are detected' do
        let(:cameras) { %w[T7 183MC] }

        it 'prompts to choose a camera' do
          expect(equipment_selector).to receive(:choose_camera).and_return('T7')
          organizer.organize
        end
      end

      context 'when exactly one camera is detected' do
        let(:cameras) { ['T7'] }

        it 'uses the detected camera without prompting' do
          expect(equipment_selector).not_to receive(:choose_camera)
          organizer.organize
        end
      end
    end

    describe 'telescope resolution' do
      let(:type)     { AstroSubframeOrganizer::Astrophoto::LIGHT }
      let(:filesets) { [make_fileset(all_unmoved: false, telescopes: telescopes)] }

      before do
        stub_equipment_selector(telescope: nil, filter: 'NoFilter', camera: 'T7')
        allow(cli).to receive(:confirm).and_return(true)
      end

      context 'when no telescope is detected' do
        let(:telescopes) { [] }

        it 'prompts to choose a telescope' do
          expect(equipment_selector).to receive(:choose_telescope).and_return('RedCat51')
          organizer.organize
        end
      end

      context 'when multiple telescopes are detected' do
        let(:telescopes) { %w[RedCat51 ZhumellZ130] }

        it 'prompts to choose a telescope' do
          expect(equipment_selector).to receive(:choose_telescope).and_return('RedCat51')
          organizer.organize
        end
      end

      context 'when exactly one telescope is detected' do
        let(:telescopes) { ['RedCat51'] }

        it 'uses the detected telescope without prompting' do
          expect(equipment_selector).not_to receive(:choose_telescope)
          organizer.organize
        end
      end
    end

    describe 'filter resolution' do
      let(:type)     { AstroSubframeOrganizer::Astrophoto::LIGHT }
      let(:filesets) { [make_fileset(all_unmoved: false, filters: filters)] }

      before do
        stub_equipment_selector(telescope: 'RedCat51', filter: nil, camera: 'T7')
        allow(cli).to receive(:confirm).and_return(true)
      end

      context 'when no filter is detected' do
        let(:filters) { [] }

        it 'prompts to choose a filter' do
          expect(equipment_selector).to receive(:choose_filter).and_return('NoFilter')
          organizer.organize
        end
      end

      context 'when multiple filters are detected' do
        let(:filters) { %w[BaaderMoon NBZ] }

        it 'prompts to choose a filter' do
          expect(equipment_selector).to receive(:choose_filter).and_return('NoFilter')
          organizer.organize
        end
      end

      context 'when exactly one filter is detected' do
        let(:filters) { ['NoFilter'] }

        it 'uses the detected filter without prompting' do
          expect(equipment_selector).not_to receive(:choose_filter)
          organizer.organize
        end
      end
    end
  end
end

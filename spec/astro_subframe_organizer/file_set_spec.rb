# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  describe FileSet, :files do
    def fixture_photo(path)
      Astrophoto.new(fixture(path))
    end

    it 'groups files by image index' do
      # We use fixtures from different directories to ensure they sort and group correctly
      files = Dir.glob(['fits/dark-blanks/**/*.fit', 'fits/light-blanks/**/*.fit'], base: FIXTURE_ROOT)
                 .map { |filepath| fixture_photo(filepath) }

      # from_files filters by type. Bias should be ignored.
      sets = FileSet.from_files(files, type: Astrophoto::DARK)

      expect(sets.size).to eq(9)
      expect(sets).to all(satisfy { |set| set.size == 30 })
    end

    it 'splits sets when equipment changes' do
      files = [
        instance_double(
          Astrophoto,
          type: 'Dark',
          path: 'a.fit',
          filename: 'a.fit',
          image_index: '1',
          camera: 'Cam A',
          telescope: 'Scope A',
          filter: 'Filter A',
          current_dir: '.',
        ),
        instance_double(
          Astrophoto,
          type: 'Dark',
          path: 'b.fit',
          filename: 'b.fit',
          image_index: '2',
          camera: 'Cam B',
          telescope: 'Scope A',
          filter: 'Filter A',
          current_dir: '.',
        ),
      ]
      allow(files[0]).to receive(:already_moved?).and_return(false)
      allow(files[1]).to receive(:already_moved?).and_return(false)

      sets = FileSet.from_files(files, type: 'Dark')
      expect(sets.size).to eq(2)
    end

    it 'detects camera candidates' do
      files = [
        fixture_photo('fits/light-blanks/Light_C 1_300.0s_Bin1_183MC_gain111_20260410-233511_288deg_-10.0C_0006.fit'),
        fixture_photo('fits/dark-blanks/Dark_30.0s_Bin1_183MC_gain111_20260411-204203_-10.0C_0022.fit'),
      ]
      set = FileSet.new(files)

      expect(set.camera_candidates).to contain_exactly('ZWO ASI183MC Pro')
      expect(set.camera).to eq('ZWO ASI183MC Pro')
    end

    it 'applies camera to all files in the set' do
      photo = fixture_photo('fits/light-blanks/Light_C 1_300.0s_Bin1_183MC_gain111_20260410-233511_288deg_-10.0C_0006.fit')
      set = FileSet.new([photo])

      set.apply_camera!('New Camera')
      expect(photo.camera).to eq('New Camera')
    end

    it 'marks all files in the set as dark flats' do
      files = Dir.glob(['fits/dark-blanks/**/Darks_1.0s_*.fit'], base: FIXTURE_ROOT)
                 .map { |filepath| fixture_photo(filepath) }
      set = FileSet.new(files)

      expect(set.files.map(&:dark_flat?)).to all(eq(false))
      set.mark_dark_flat!
      expect(set.files.map(&:dark_flat?)).to all(eq(true))
    end

    it 'detects if a set might be flat darks' do
      # Using a short exposure dark fixture
      files = [
        fixture_photo('fits/dark-blanks/Dark_1.0s_Bin1_183MC_gain111_20260411-130000_-10.0C_0001.fit'),
      ]
      set = FileSet.new(files)

      expect(set.maybe_flat_dark?).to be true
    end

    it 'detects if a set might not be flat darks' do
      # Using a short exposure dark fixture
      files = [
        fixture_photo('fits/dark-blanks/Dark_30.0s_Bin1_183MC_gain111_20260411-204203_-10.0C_0022.fit'),
      ]
      set = FileSet.new(files)

      expect(set.maybe_flat_dark?).to be false
    end
  end
end

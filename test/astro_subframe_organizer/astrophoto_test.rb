# frozen_string_literal: true

require_relative '../test_helper'

class TestAstrophoto < AstroSubframeOrganizer::Test
  def setup
    # Suppress debug output during tests
    @original_stdout = $stdout
    $stdout = StringIO.new
  end

  def teardown
    $stdout = @original_stdout
  end

  # Test initialization with a typical LIGHT FITS filename
  def test_initialize_light_fits
    path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    photo = Astrophoto.new(path)

    assert_equal 'Light', photo.type
    assert_equal 'M42', photo.target
    assert_nil photo.mosaic_pane
    assert_equal '1.0s', photo.exposure
    assert_equal '1', photo.bin
    assert_equal 'T7', photo.camera
    assert_equal '100', photo.iso
    assert_nil photo.gain
    assert_equal DateTime.new(2022, 5, 8, 12, 0, 0), photo.created_at
    assert_equal '-10.0C', photo.ccd_temp
    assert_equal '0001', photo.image_index
    assert_equal path, photo.path
    assert_equal 'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit', photo.filename
    assert_nil photo.telescope
    assert_nil photo.filter
    assert_equal false, photo.dark_flat
  end

  # Test initialization with a DARK filename
  def test_initialize_dark
    path = '/fake/path/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    photo = Astrophoto.new(path)

    assert_equal 'Dark', photo.type
    assert_nil photo.target
    assert_equal '30.0s', photo.exposure
    assert_equal '0001', photo.image_index
  end

  # Test initialization with FLAT
  def test_initialize_flat
    path = '/fake/path/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    photo = Astrophoto.new(path)

    assert_equal 'Flat', photo.type
  end

  # Test initialization with BIAS
  def test_initialize_bias
    path = '/fake/path/Bias_0.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    photo = Astrophoto.new(path)

    assert_equal 'Bias', photo.type
  end

  # Test initialization with mosaic pane
  def test_initialize_with_mosaic_pane
    path = '/fake/path/Light_M42_1-2_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    photo = Astrophoto.new(path)

    assert_equal '1-2', photo.mosaic_pane
  end

  # Test initialization with gain instead of ISO
  def test_initialize_with_gain
    path = '/fake/path/Light_M42_1.0s_Bin1_183MC_gain100_20220508-120000_-10.0C_0001.fit'
    photo = Astrophoto.new(path)

    assert_equal '183MC', photo.camera
    assert_nil photo.iso
    assert_equal '100', photo.gain
  end

  # Test initialization with already organized path (extracts telescope/filter)
  def test_initialize_already_organized
    path = '/organized/Flat_FLATSET_20220508_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    photo = Astrophoto.new(path)

    assert_equal 'RedCat51', photo.telescope
    assert_equal 'BaaderMoon', photo.filter
  end

  # Test dark_flat?
  def test_dark_flat?
    photo = Astrophoto.new('/fake/Dark_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    assert_equal false, photo.dark_flat?

    photo.dark_flat = true
    assert_equal true, photo.dark_flat?
  end

  # Test maybe_flat_dark?
  def test_maybe_flat_dark?
    # Short exposure dark
    photo = Astrophoto.new('/fake/Dark_5.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    assert_equal true, photo.maybe_flat_dark?

    # Long exposure dark
    photo2 = Astrophoto.new('/fake/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    assert_equal false, photo2.maybe_flat_dark?

    # Already dark flat
    photo3 = Astrophoto.new('/fake/Dark_5.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo3.dark_flat = true
    assert_equal false, photo3.maybe_flat_dark?
  end

  # Test flatset_id
  def test_flatset_id
    # Light before noon
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-110000_-10.0C_0001.fit')
    assert_equal '20220508', photo.flatset_id

    # Light after noon
    photo2 = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-130000_-10.0C_0001.fit')
    assert_equal '20220509', photo2.flatset_id

    # Non-light
    photo3 = Astrophoto.new('/fake/Dark_30.0s_Bin1_T7_ISO100_20220508-130000_-10.0C_0001.fit')
    assert_equal '20220508', photo3.flatset_id
  end

  # Test month
  def test_month
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    assert_equal '2022-05', photo.month
  end

  # Test target_dir for DARK
  def test_target_dir_dark
    photo = Astrophoto.new('/fake/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    expected = 'Dark_ISO_100_EXP_30.0s_CCD-TEMP_-10.0C_CAMERA_T7_MONTH_2022-05'
    assert_equal expected, photo.target_dir
  end

  # Test target_dir for DARK flat
  def test_target_dir_dark_flat
    photo = Astrophoto.new('/fake/Dark_5.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.dark_flat = true
    expected = 'DarkFlat_FLATSET_20220508_ISO_100_EXP_5.0s_Bin_1_CAMERA_T7'
    assert_equal expected, photo.target_dir
  end

  # Test target_dir for FLAT
  def test_target_dir_flat
    photo = Astrophoto.new('/fake/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'
    expected = 'Flat_FLATSET_20220508_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7'
    assert_equal expected, photo.target_dir
  end

  # Test target_dir for LIGHT FITS
  def test_target_dir_light_fits
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'
    expected = 'Light_M42_FLATSET_20220509_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7'
    assert_equal expected, photo.target_dir
  end

  # Test target_dir for LIGHT CR2
  def test_target_dir_light_cr2
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'
    expected = 'Light_M42_FLATSET_20220509_ISO_100_EXP_1.0s_Bin_1_CCD-TEMP_-10._TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7'
    assert_equal expected, photo.target_dir
  end

  # Test target_dir for BIAS
  def test_target_dir_bias
    photo = Astrophoto.new('/fake/Bias_0.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    expected = 'Bias_ISO_100_EXP_0.0s_Bin_1_CAMERA_T7_MONTH_2022-05'
    assert_equal expected, photo.target_dir
  end

  # Test target_path
  def test_target_path
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'
    expected = 'Light_M42_FLATSET_20220509_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    assert_equal expected, photo.target_path
  end

  # Test current_dir
  def test_current_dir
    photo = Astrophoto.new('/some/dir/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    assert_equal '/some/dir', photo.current_dir
  end

  # Test already_moved?
  def test_already_moved?
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    assert_equal false, photo.already_moved?

    # Simulate moved
    photo.path = photo.target_path
    assert_equal true, photo.already_moved?
  end

  # Test move (dry run)
  def test_move_dry_run
    Dir.mktmpdir do |tmpdir|
      src_file = File.join(tmpdir, 'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
      File.write(src_file, 'fake data')
      photo = Astrophoto.new(src_file)
      photo.telescope = 'RedCat51'
      photo.filter = 'BaaderMoon'

      photo.move(true) # dry run

      assert File.exist?(src_file)
      refute File.exist?(photo.target_path)
    end
  end

  # Test move (actual, in temp dir)
  def test_move_actual
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        src_file = 'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
        File.write(src_file, 'fake data')
        photo = Astrophoto.new(src_file)
        photo.telescope = 'RedCat51'
        photo.filter = 'BaaderMoon'

        photo.move(false) # actual move

        assert File.exist?(photo.target_path)
        refute File.exist?(src_file)
      end
    end
  end
end

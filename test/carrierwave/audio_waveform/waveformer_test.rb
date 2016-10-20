require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "carrierwave", "audio_waveform", "waveformer.rb"))

require "test/unit"
require "fileutils"
require "byebug"

module Helpers
  def get_fixture(file)
    File.join(File.dirname(__FILE__), "..", "..", "fixtures", file)
  end

  def get_output(file)
    File.join(File.dirname(__FILE__), "output", file)
  end

  def open_png(file)
    ChunkyPNG::Image.from_datastream(ChunkyPNG::Datastream.from_file(file))
  end
end

module CarrierWave
  module AudioWaveform
    class WaveformerTest < ::Test::Unit::TestCase
      include Helpers
      extend Helpers

      def self.cleanup
        puts "Removing existing testing artifacts..."
        Dir[get_output("*.*")].each{ |f| FileUtils.rm(f) }
        FileUtils.mkdir_p(get_output(""))
        FileUtils.rm(get_fixture("sample_2.png")) if File.exists?(get_fixture("sample_2.png"))
      end

      def test_generates_waveform_with_default_filename_in_same_directory
        Waveformer.generate(get_fixture("sample_2.wav"))
        assert File.exists?(get_fixture("sample_2.png"))

        image = open_png(get_fixture("sample_2.png"))
        assert_equal ChunkyPNG::Color.from_hex(Waveformer::DefaultOptions[:color]), image[60, 120]
        assert_equal ChunkyPNG::Color.from_hex(Waveformer::DefaultOptions[:background_color]), image[0, 0]
        FileUtils.rm(get_fixture("sample_2.png"))
      end

      def test_generates_waveform_with_custom_filename
        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("waveform_from_audio_source.png"))
        assert File.exists?(get_output("waveform_from_audio_source.png"))

        image = open_png(get_output("waveform_from_audio_source.png"))
        assert_equal ChunkyPNG::Color.from_hex(Waveformer::DefaultOptions[:color]), image[60, 120]
        assert_equal ChunkyPNG::Color.from_hex(Waveformer::DefaultOptions[:background_color]), image[0, 0]
      end

      def test_generates_waveform_from_mono_audio_source_via_peak
        Waveformer.generate(get_fixture("mono_sample.wav"), filename: get_output("waveform_from_mono_audio_source_via_peak.png"))
        assert File.exists?(get_output("waveform_from_mono_audio_source_via_peak.png"))

        image = open_png(get_output("waveform_from_mono_audio_source_via_peak.png"))
        assert_equal ChunkyPNG::Color.from_hex(Waveformer::DefaultOptions[:color]), image[60, 120]
        assert_equal ChunkyPNG::Color.from_hex(Waveformer::DefaultOptions[:background_color]), image[0, 0]
      end

      def test_generates_waveform_from_mono_audio_source_via_rms
        Waveformer.generate(get_fixture("mono_sample.wav"), filename: get_output("waveform_from_mono_audio_source_via_rms.png"), :method => :rms)
        assert File.exists?(get_output("waveform_from_mono_audio_source_via_rms.png"))

        image = open_png(get_output("waveform_from_mono_audio_source_via_rms.png"))
        assert_equal ChunkyPNG::Color.from_hex(Waveformer::DefaultOptions[:color]), image[60, 120]
        assert_equal ChunkyPNG::Color.from_hex(Waveformer::DefaultOptions[:background_color]), image[0, 0]
      end

      def test_logs_to_given_io
        File.open(get_output("waveform.log"), "w") do |io|
          Waveformer.generate(get_fixture("sample.wav"), filename: get_output("logged.png"), :logger => io)
        end

        assert_match /Generated waveform/, File.read(get_output("waveform.log"))
      end

      def test_uses_rms_instead_of_peak
        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("peak.png"))
        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("rms.png"), :method => :rms)

        rms = open_png(get_output("rms.png"))
        peak = open_png(get_output("peak.png"))

        assert_equal ChunkyPNG::Color.from_hex(Waveformer::DefaultOptions[:color]), peak[44, 43]
        assert_equal ChunkyPNG::Color.from_hex(Waveformer::DefaultOptions[:background_color]), rms[44, 43]
        assert_equal ChunkyPNG::Color.from_hex(Waveformer::DefaultOptions[:color]), rms[60, 120]
      end

      def test_is_900px_wide
        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("width-900.png"), :width => 900)

        image = open_png(get_output("width-900.png"))

        assert_equal 900, image.width
      end

      def test_is_100px_tall
        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("height-100.png"), :height => 100)

        image = open_png(get_output("height-100.png"))

        assert_equal 100, image.height
      end

      def test_has_auto_width
        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("width-auto.png"), :auto_width => 10)

        image = open_png(get_output("width-auto.png"))

        assert_equal 209, image.width
      end

      def test_has_red_background_color
        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("background_color-#ff0000.png"), :background_color => "#ff0000")

        image = open_png(get_output("background_color-#ff0000.png"))

        assert_equal ChunkyPNG::Color.from_hex("#ff0000"), image[0, 0]
      end

      def test_has_transparent_background_color
        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("background_color-transparent.png"), :background_color => :transparent)

        image = open_png(get_output("background_color-transparent.png"))

        assert_equal ChunkyPNG::Color::TRANSPARENT, image[0, 0]
      end

      def test_has_black_foreground_color
        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("color-#000000.png"), :color => "#000000")

        image = open_png(get_output("color-#000000.png"))

        assert_equal ChunkyPNG::Color.from_hex("#000000"), image[60, 120]
      end

      def test_has_red_background_color_with_transparent_foreground_cutout
        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("background_color-#ff0000+color-transparent.png"), :background_color => "#ff0000", :color => :transparent)

        image = open_png(get_output("background_color-#ff0000+color-transparent.png"))

        assert_equal ChunkyPNG::Color.from_hex("#ff0000"), image[0, 0]
        assert_equal ChunkyPNG::Color::TRANSPARENT, image[60, 120]
      end

      # Bright green is our transparency mask color, so this test ensures that we
      # don't destroy the image if the background also uses the transparency mask
      # color
      def test_has_transparent_foreground_on_bright_green_background
        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("background_color-#00ff00+color-transparent.png"), :background_color => "#00ff00", :color => :transparent)

        image = open_png(get_output("background_color-#00ff00+color-transparent.png"))

        assert_equal ChunkyPNG::Color.from_hex("#00ff00"), image[0, 0]
        assert_equal ChunkyPNG::Color::TRANSPARENT, image[60, 120]
      end

      # Test that passing a sample_width will space out the samples, leaving
      # gaps in between
      def test_has_spaced_samples_with_sample_width
        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("sample-spaced.png"), sample_width: 5)

        image = open_png(get_output("sample-spaced.png"))

        (0..4).each do |i|
          assert_equal ChunkyPNG::Color.from_hex("#00ccff"), image[i, 140]
        end
        assert_equal ChunkyPNG::Color.from_hex("#666666"), image[5, 140]
      end

      # Test that passing a sample_width with gap_width will space out the samples, leaving
      # gaps in between that are sized by gap_width
      def test_has_spaced_samples_with_sample_width_with_gap_width
        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("sample-spaced-with-gap.png"), sample_width: 1, gap_width: 3)

        image = open_png(get_output("sample-spaced-with-gap.png"))

        assert_equal ChunkyPNG::Color.from_hex("#00ccff"), image[0, 140]
        (1..3).each do |i|
          assert_equal ChunkyPNG::Color.from_hex("#666666"), image[i, 140]
        end
      end

      def test_raises_error_if_not_given_readable_audio_source
        assert_raise(Waveformer::RuntimeError) do
          Waveformer.generate(get_fixture("sample.txt"), filename: get_output("shouldnt_exist.png"))
        end
      end

      def test_overwrites_existing_waveform_if_force_is_true_and_file_exists
        FileUtils.touch get_output("overwritten.png")

        Waveformer.generate(get_fixture("sample.wav"), filename: get_output("overwritten.png"))
      end

      def test_raises_deprecation_exception_if_sox_fails_to_read_source_file
        begin
          Waveformer.generate(get_fixture("sample.txt"), filename: get_output("shouldnt_exist.png"))
        rescue Waveformer::RuntimeError => e
          assert_match /FAIL formats: no handler for given file type `txt'/, e.message
        end
      end
    end
  end
end

CarrierWave::AudioWaveform::WaveformerTest.cleanup
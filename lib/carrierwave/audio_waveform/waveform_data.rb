require 'ruby-sox'
require 'fileutils'

module CarrierWave
  module AudioWaveform
    class WaveformData
      DefaultOptions = {
        pixels_per_second: 10,
        bits: 16
      }

      # Scope these under Waveform so you can catch the ones generated by just this
      # class.
      class RuntimeError < ::RuntimeError;end;
      class ArgumentError < ::ArgumentError;end;

      class << self
        # Generate a Waveform image at the given filename with the given options.
        #
        # Available options (all optional) are:
        #
        #   :convert_to_extension_before_processing => Symbolized extension (:wav, :mp3, etc.)
        #   Useful if .wav or .mp3 isn't being passed in--you can convert to that format first.
        #
        #   :set_extension_before_processing => Symbolized extension (:wav, :mp3, etc.)
        #   This is useful because CarrierWave will send files in with the wrong extension sometimes.
        #   For instance, if this is nested under a version, that version may be an .mp3, but its parent
        #   might be .wav, so even though the version is a different extension, the file type will be read
        #   from the original file's extension (not the version file) if you don't set this parameter.
        #
        #   :pixels_per_second => The number of pixels per second to evaluate.
        #
        #   :bits => 8- or 16-bit precision
        #
        #   :logger => IOStream to log progress to.
        #
        # Example:
        #   CarrierWave::AudioWaveform::Waveformer.generate("Kickstart My Heart.wav")
        #   CarrierWave::AudioWaveform::Waveformer.generate("Kickstart My Heart.wav", :method => :rms)
        #   CarrierWave::AudioWaveform::Waveformer.generate("Kickstart My Heart.wav", :color => "#ff00ff", :logger => $stdout)
        #
        def generate(source, options={})
          options = DefaultOptions.merge(options)
          options[:filename] ||= self.generate_json_filename(source)
          old_source = source
          if options[:convert_to_extension_before_processing]
            source = generate_valid_source(source, options[:convert_to_extension_before_processing])
          elsif options[:set_extension_before_processing]
            source = generate_proper_source(source, options[:set_extension_before_processing])
          end

          raise ArgumentError.new("No source audio filename given, must be an existing sound file.") unless source
          raise ArgumentError.new("No destination filename given for waveform") unless options[:filename]
          raise RuntimeError.new("Source audio file '#{source}' not found.") unless File.exist?(source)

          @log = Log.new(options[:logger])
          @log.start!

          @log.timed("\nGenerating...") do
            stdout_str, stderr_str, status = self.generate_waveform_data(source, options)
            if stderr_str.present? && !stderr_str.include?("Recoverable")
              raise RuntimeError.new(stderr_str)
            end
          end

          if source != old_source && options[:convert_to_extension_before_processing]
            @log.out("Removing temporary file at #{source}")
            FileUtils.rm(source)
          elsif source != old_source && options[:set_extension_before_processing]
            @log.out("Renaming file at #{source}")
            old_ext = File.extname(source).gsub(/\./, '').to_sym
            generate_proper_source(source, old_ext)
          end

          @log.done!("Generated waveform data '#{options[:filename]}'")

          options[:filename]
        end

        def generate_json_filename(source)
          ext = File.extname(source)
          source_file_path_without_extension = File.join File.dirname(source), File.basename(source, ext)
          "#{source_file_path_without_extension}.json"
        end

        def generate_waveform_data(source, options = DefaultOptions)
          options[:filename] ||= self.generate_json_filename(source)
          Open3.capture3(
            "audiowaveform -i #{source} --pixels-per-second #{options[:pixels_per_second]} -b #{options[:bits]} -o #{options[:filename]}"
          )
        end

        private

        # Returns the proper file type if the one passed in was
        # wrong, or the original if it wasn't.
        def generate_proper_source(source, proper_ext)
          ext = File.extname(source)
          ext_gsubbed = ext.gsub(/\./, '')

          if ext_gsubbed != proper_ext.to_s
            filename_with_proper_extension = "#{source.chomp(File.extname(source))}.#{proper_ext}"
            File.rename source, filename_with_proper_extension
            filename_with_proper_extension
          else
            source
          end
        rescue Sox::Error => e
          raise e unless e.message.include?("FAIL formats:")
          raise RuntimeError.new("Source file #{source} could not be converted to .wav by Sox (Sox: #{e.message})")
        end

        # Returns a converted file.
        def generate_valid_source(source, proper_ext)
          ext = File.extname(source)
          ext_gsubbed = ext.gsub(/\./, '')

          if ext_gsubbed != proper_ext.to_s
            input_options = { type: ext_gsubbed }
            output_options = { type: proper_ext.to_s }
            source_filename_without_extension = File.basename(source, ext)
            output_file_path = File.join File.dirname(source), "tmp_#{source_filename_without_extension}_#{Time.now.to_i}.#{proper_ext}"
            converter = Sox::Cmd.new
            converter.add_input source, input_options
            converter.set_output output_file_path, output_options
            converter.run
            output_file_path
          else
            source
          end
        rescue Sox::Error => e
          raise e unless e.message.include?("FAIL formats:")
          raise RuntimeError.new("Source file #{source} could not be converted to .wav by Sox (Sox: #{e.message})")
        end
      end
    end

    class WaveformData
      # A simple class for logging + benchmarking, nice to have good feedback on a
      # long batch operation.
      #
      # There's probably 10,000,000 other bechmarking classes, but writing this was
      # easier than using Google.
      class Log
        attr_accessor :io

        def initialize(io=$stdout)
          @io = io
        end

        # Prints the given message to the log
        def out(msg)
          io.print(msg) if io
        end

        # Prints the given message to the log followed by the most recent benchmark
        # (note that it calls .end! which will stop the benchmark)
        def done!(msg="")
          out "#{msg} (#{self.end!}s)\n"
        end

        # Starts a new benchmark clock and returns the index of the new clock.
        #
        # If .start! is called again before .end! then the time returned will be
        # the elapsed time from the next call to start!, and calling .end! again
        # will return the time from *this* call to start! (that is, the clocks are
        # LIFO)
        def start!
          (@benchmarks ||= []) << Time.now
          @current = @benchmarks.size - 1
        end

        # Returns the elapsed time from the most recently started benchmark clock
        # and ends the benchmark, so that a subsequent call to .end! will return
        # the elapsed time from the previously started benchmark clock.
        def end!
          elapsed = (Time.now - @benchmarks[@current])
          @current -= 1
          elapsed
        end

        # Returns the elapsed time from the benchmark clock w/ the given index (as
        # returned from when .start! was called).
        def time?(index)
          Time.now - @benchmarks[index]
        end

        # Benchmarks the given block, printing out the given message first (if
        # given).
        def timed(message=nil, &block)
          start!
          out(message) if message
          yield
          done!
        end
      end
    end
  end
end

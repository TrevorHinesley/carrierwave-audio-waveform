require 'carrierwave'
require 'ruby-sox'
require 'soxi/wrapper'

module CarrierWave
  module Audio
    module ClassMethods
      extend ActiveSupport::Concern

      def convert output_format = :mp3, output_options = {}
        process convert: [ output_format, output_options ]
      end

      def watermark watermark_file_path, output_format = :mp3, output_options = {}
        process watermark: [ watermark_file_path, output_format, output_options ]
      end
    end

    def convert output_format = :mp3, output_options = {}
      format = sanitized_format(output_format)
      ext = File.extname(current_path)
      input_options = { type: ext.gsub(/\./, '') }
      current_filename_without_extension = File.basename(current_path, ext)
      tmp_path = File.join File.dirname(current_path), "tmp_#{current_filename_without_extension}_#{Time.current.to_i}.#{format}"
      convert_file(current_path, input_options, tmp_path, default_output_options(format).merge(output_options))
      File.rename tmp_path, current_path
      set_content_type format
    end

    def watermark watermark_file_path, output_format = :mp3, output_options = {}
      format = sanitized_format(output_format)
      ext = File.extname(current_path)
      watermark_ext = File.extname(watermark_file_path)
      input_options = { type: ext.gsub(/\./, '') }
      watermark_options = { type: watermark_ext.gsub(/\./, '') }
      current_filename_without_extension = File.basename(current_path, ext)

      # Normalize file to -6dB
      normalized_tmp_path = File.join File.dirname(current_path), "tmp_norm_#{current_filename_without_extension}_#{Time.current.to_i}.#{input_options[:type]}"
      convert_file(current_path, input_options, normalized_tmp_path, input_options, { gain: "-n -6" })

      # Combine normalized file and watermark, normalizing final product to 0dB
      final_tmp_path = File.join File.dirname(current_path), "tmp_wtmk_#{current_filename_without_extension}_#{Time.current.to_i}.#{format}"
      converter = Sox::Cmd.new(combine: :mix)
      converter.add_input normalized_tmp_path, input_options
      converter.add_input watermark_file_path, watermark_options
      converter.set_output final_tmp_path, default_output_options(format).merge(output_options)
      converter.set_effects({ trim: "0 #{Soxi::Wrapper.file(current_path).seconds}", gain: "-n" })
      converter.run
      File.rename final_tmp_path, current_path
      set_content_type format
    end

    private

    def convert_file input_file_path, input_options, output_file_path, output_options, fx = {}
      converter = Sox::Cmd.new
      converter.add_input input_file_path, input_options
      converter.set_output output_file_path, output_options
      converter.set_effects fx
      converter.run
    end

    def sanitized_format format
      supported_formats = [:mp3]
      if supported_formats.include?(format.to_sym)
        format.to_s
      else
        raise CarrierWave::ProcessingError.new("Unsupported audio format #{format}. Only conversion to #{supported_formats.to_sentence} allowed.")
      end
    end

    def default_output_options format
      if format.to_sym == :mp3
        {
          type: format.to_s,
          rate: 44100,
          channels: 2,
          compression: 128
        }
      else
        {
          type: format.to_s,
          rate: 44100,
          channels: 2
        }
      end
    end

    def set_content_type format
      case format.to_sym
      when :mp3
        self.file.instance_variable_set(:@content_type, "audio/mpeg3")
      end
    end
  end
end
require 'carrierwave'
require 'carrierwave/audio_waveform/waveformer'
require 'carrierwave/audio_waveform/waveform_data'

module CarrierWave
  module AudioWaveform
    module ClassMethods
      extend ActiveSupport::Concern

      def waveform options={}
        process waveform: [ options ]
      end

      def waveform_data options={}
        process waveform_data: [ options ]
      end
    end

    def waveform options={}
      cache_stored_file! if !cached?

      image_filename = Waveformer.generate(current_path, options)
      File.rename image_filename, current_path
      self.file.instance_variable_set(:@content_type, "image/png")
    end

    def waveform_data options={}
      cache_stored_file! if !cached?

      data_filename = WaveformData.generate(current_path, options)
      File.rename data_filename, current_path
      self.file.instance_variable_set(:@content_type, "application/json")
    end
  end
end

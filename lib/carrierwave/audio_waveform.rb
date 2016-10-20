require 'carrierwave'
require 'carrierwave/audio_waveform/waveformer'

module CarrierWave
  module AudioWaveform
    module ClassMethods
      extend ActiveSupport::Concern

      def waveform options={}
        process waveform: [ options ]
      end
    end

    def waveform options={}
      cache_stored_file! if !cached?

      image_filename = Waveformer.generate(current_path, options)
      File.rename image_filename, current_path
    end
  end
end
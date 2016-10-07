# CarrierWave::AudioWaveform

Generate waveform images from audio files within Carrierwave

## Installation

Add this line to your application's Gemfile:

    gem 'carrierwave-audio-waveform'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install carrierwave-audio-waveform

## Usage

Include CarrierWave::AudioWaveform into your CarrierWave uploader class:

```ruby
class AudioUploader < CarrierWave::Uploader::Base
  include CarrierWave::AudioWaveform
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

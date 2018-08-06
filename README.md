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

First, install [SoX](http://sox.sourceforge.net/) on your local environment and production servers.

Second, install [Audio Waveform](https://github.com/bbc/audiowaveform) on your local environment and production servers if you plan to generate waveform data rather than an image.

Lastly, include CarrierWave::AudioWaveform in your CarrierWave uploader class:

```ruby
class AudioUploader < CarrierWave::Uploader::Base
  include CarrierWave::AudioWaveform
end
```

See the sections below for specific implementations.

### PNG

To generate a PNG image:

```ruby
class AudioUploader < CarrierWave::Uploader::Base
  include CarrierWave::AudioWaveform
  
  version :waveform_image do
    process :waveform => [{
      background_color: :transparent,
      color: "#666",
      sample_width: 2,
      gap_width: 2,
      height: 75,
      width: 1500
    }]

    def full_filename(for_file)
      "#{super.chomp(File.extname(super))}.png"
    end
  end
end
```

#### Options

|      Parameter     |      Description    |  Permitted Values  |       Default      |
| ------------------ | ------------------- | ------------------ | ------------------ |
| `background_color`  | The image's background color | String (hex value) or `:transparent` | `:transparent` |
| `color`  | The waveform's color; Only valid when type is `:png` | String (hex value) | `"#00ccff"` (![#00ccff](https://placehold.it/15/00ccff/000000?text=+) Cyan) |
| `sample_width` | Integer specifying the sample width. If this is specified, there will be gaps (minimum of 1px wide, as specified by `gap_width`) between samples that are this wide in pixels. | Integer >= 1 |  `nil` |
| `gap_width` | Integer specifying the width of the gaps between samples. If `sample_width` is specified, this will be the size of the gaps between samples in pixels. | Integer >= 1 | `nil` |
| `height` | The image's height | Integer | `280` |
| `width` | The image's width | Integer | `1800` |
| `auto_width` | Millseconds per pixel. This will overwrite the width of the final waveform image depending on the length of the audio file. Example: `100` => 1 pixel per 100 msec; a one minute audio file will result in a width of 600 pixels | Integer | `nil` |
| `method` | The method used to read sample frames, `:peak` or `:rms`. Peak is the norm. It uses the maximum amplitude per sample to generate the waveform, so the waveform looks more dynamic. RMS is more of an average, and the waveform isn't as jerky. | Symbol (`:peak` or `:rms`) | `:peak` |
| `logger` | IOStream to log progress | IOStream | `nil` |

### Waveform Data

>**Note:** Make sure to install [Audio Waveform](https://github.com/bbc/audiowaveform) on your local environment and production servers if you plan to generate waveform data.

To generate an array of waveform data:

```ruby
class AudioUploader < CarrierWave::Uploader::Base
  include CarrierWave::AudioWaveform
  
  version :waveform_peak_data do
    process :waveform_data => [{
      convert_to_extension_before_processing: :wav,
      pixels_per_second: 10
    }]

    def full_filename(for_file)
      "#{super.chomp(File.extname(super))}.json"
    end
  end
end
```

#### Options

|      Parameter     |      Description    |  Permitted Values  |       Default      |
| ------------------ | ------------------- | ------------------ | ------------------ |
| `convert_to_extension_before_processing` | Useful if `.wav` or `.mp3` isn't being passed in as the source file--you can convert to the specified format first before reading the peaks. | Symbol (`:wav` or `:mp3`) | `nil` |
| `set_extension_before_processing` | This is useful because CarrierWave will send files in with the wrong extension sometimes. For instance, if this is nested under a version, that version may be an `.mp3`, but its parent might be `.wav`, so even though the version is a different extension, the file type will be read from the original file's extension (not the version file) if you don't set this parameter. | Symbol (`:wav` or `:mp3`) | `nil` |
| `pixels_per_second` | The number of pixels per second to evaluate. | Integer | `10` |
| `bits` | 8- or 16-bit precision | Integer (`8` or `16`) | `16` |
| `logger` | IOStream to log progress | IOStream | `nil` |

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

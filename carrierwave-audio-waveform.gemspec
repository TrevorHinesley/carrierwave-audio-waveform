# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'carrierwave/audio_waveform/version'

Gem::Specification.new do |spec|
  spec.name          = "carrierwave-audio-waveform"
  spec.version       = CarrierWave::AudioWaveform::VERSION
  spec.authors       = ["Trevor Hinesley"]
  spec.email         = ["trevor@trevorhinesley.com"]
  spec.description   = %q{CarrierWave Audio Waveform}
  spec.summary       = %q{Generate waveform images from audio files within Carrierwave}
  spec.homepage      = "https://github.com/TrevorHinesley/carrierwave-audio-waveform"
  spec.license       = "MIT"

  spec.files         = Dir["{lib}/**/*"] + ["LICENSE.txt", "README.md"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "carrierwave"
  spec.add_dependency "ruby-audio"
  spec.add_dependency "ruby-sox"
  spec.add_dependency "oily_png"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "byebug"
end
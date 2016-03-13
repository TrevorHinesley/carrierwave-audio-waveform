# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'carrierwave/audio/version'

Gem::Specification.new do |spec|
  spec.name          = "carrierwave-audio"
  spec.version       = CarrierWave::Audio::VERSION
  spec.authors       = ["Trevor Hinesley"]
  spec.email         = ["trevor@trevorhinesley.com"]
  spec.description   = %q{CarrierWave Audio}
  spec.summary       = %q{Simple SoX wrapper for CarrierWave uploader that allows audio file conversion and watermarking}
  spec.homepage      = "https://github.com/TrevorHinesley/carrierwave-audio"
  spec.license       = "MIT"

  spec.files         = Dir["{lib}/**/*"] + ["LICENSE.txt", "README.md"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'carrierwave'
  spec.add_dependency 'ruby-sox'
  spec.add_dependency 'soxi-wrapper'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
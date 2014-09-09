# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dry/config/version'

Gem::Specification.new do |spec|
  spec.name          = 'dry-config'
  spec.version       = Dry::Config::VERSION
  spec.authors       = ['Kevin Ross']
  spec.email         = ['kevin.ross@alienfast.com']
  spec.description   = %q{Simple base class for DRY environment based configurations.}
  spec.summary       = %q{Simple base class for DRY environment based configurations.}
  spec.homepage      = 'https://github.com/alienfast/dry-config'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end

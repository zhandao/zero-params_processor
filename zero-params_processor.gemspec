
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'params_processor/version'

Gem::Specification.new do |spec|
  spec.name          = 'zero-params_processor'
  spec.version       = ParamsProcessor::VERSION
  spec.authors       = ['zhandao']
  spec.email         = ['x@skippingcat.com']

  spec.summary       = 'Process parameters base on Zero-Rails_OpenApi for Rails, such as: ' \
                       'validation and type conversion'
  spec.description   = 'Process parameters base on Zero-Rails_OpenApi for Rails, such as: ' \
                       'validation and type conversion'
  spec.homepage      = "https://github.com/zhandao/zero-params_processor"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16.a'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov'

  spec.add_runtime_dependency 'zero-rails_openapi', '>= 1.5.1'
  spec.add_runtime_dependency 'rails', '>= 3'
  spec.add_runtime_dependency 'activesupport', '>= 3'
  spec.add_runtime_dependency 'multi_json'
end

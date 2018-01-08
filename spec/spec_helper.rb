require 'simplecov'
SimpleCov.start

require 'bundler/setup'
require 'action_controller'
require 'pp'
require 'params_processor'
require 'support/open_api'
require 'support/goods_controller'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  # config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

RSpec::Expectations.configuration.on_potential_false_positives = :nothing

ParamsProcessor::Config.test = true

DocConverter = ParamsProcessor::DocConverter

def set_info schema
  _schema = OpenApi.info_schema.clone
  before { DocConverter.docs = nil; OpenApi.info_schema = _schema.merge(schema) }
  after { DocConverter.docs = nil; OpenApi.info_schema = _schema}
  # before { DocConverter.docs = nil; allow(OpenApi).to receive(:info_schema).and_return(OpenApi.info_schema.merge(schema)) }
  # after { DocConverter.docs = nil }
end

def set_info! schema
  before { DocConverter.docs = nil; allow(OpenApi).to receive(:info_schema).and_return(schema) }
  after { DocConverter.docs = nil }
end

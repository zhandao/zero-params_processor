require 'spec_helper'
require 'params_processor_helper'

RSpec.describe ParamsProcessor do
  it 'has a version number' do
    expect(ParamsProcessor::VERSION).not_to be nil
  end


  desc :params_doc do
    called get: [ OpenApi.info, OpenApi.id ]
  end


  desc :validate_params! do
    called raise: false
  end
end

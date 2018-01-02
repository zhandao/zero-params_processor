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
    called by: { id: 1 }, **pass
    called by: { id: 1, info: 'info' }, **pass
    called by: { id: 'a' }, raise: :wrong_type
  end


  desc :convert_param_types do
    called by: { id: '1', info: 1 }, converted: { id: 1, info: '1' }

    context 'when param has default value' do
      set_info default: 'default'
      called by: { id: 1 }, converted: { id: 1, info: 'default' }
    end

    context 'when param has a alias' do
      set_info as: :name, default: 'name'
      called by: { id: 1 }, converted: { id: 1, name: 'name' }
    end
  end


  desc :validate_and_convert_params! do
    called by: { id: '1', info: 1 }, **pass
    called by: { id: '1', info: 1 }, converted: { id: 1, info: '1' }
  end


  # TODO: like request body
  desc :set_permitted do
    called by: { id: 1 }, pmtted: [ ]

    context 'when info is set pmt' do
      set_info permit: true
      called by: { id: 1, info: 'info' }, pmtted: [:info]
    end

    context 'when info is set not_pmt' do
      set_info not_permit: true
      called by: { id: 1, info: 'info' }, pmtted: [:id]
    end

    context 'when route_path match /{param_name}/' do
      set_path :'goods/{id}/action'
      called by: { id: 1 }, found: true
      called by: { id: 0 }, found: false
    end
  end
end

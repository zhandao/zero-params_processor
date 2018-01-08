require 'spec_helper'
require 'params_processor_helper'

RSpec.describe ParamsProcessor do
  it 'has a version number' do
    expect(ParamsProcessor::VERSION).not_to be nil
  end


  desc :params_doc do
    called get: [ OpenApi.info, OpenApi.id ].map(&:deep_stringify_keys)

    context 'when not matching routes_index' do
      called before: -> { expect(OpenApi).to receive(:routes_index).and_return({ }) }, get: [ ]
    end

    context 'when the path is not doced' do
      called before: -> { expect(OpenApi::Generator).to receive(:find_path_httpverb_by).and_return(['not_doced_path', 'post']) }, get: [ ]
    end

    context 'when the action is not doced' do
      called before: -> { expect(GoodsController::Patches).to receive(:method).and_return('NOT_DOCED_REQ_METHOD') }, get: [ ]
    end
  end


  desc :_validate_param! do
    called by: { id: 1 }, **pass
    called by: { id: 1, info: 'info' }, **pass
    called by: { id: 'a' }, raise: :wrong_type
  end


  desc :_convert_param do
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


  desc :_set_instance_var do
    context 'when route_path match /{param_name}/' do
      set_path :'goods/{id}/action'
      called by: { id: 1 }, found: true
      called by: { id: 0 }, found: false
    end
  end


  # TODO: like request body
  desc :_set_permitted do
    called by: { id: 1 }, pmtted: [ ]

    context 'when info is set pmt' do
      set_info permit: true
      called by: { id: 1, info: 'info' }, pmtted: [:info]
    end

    context 'when info is set not_pmt' do
      set_info not_permit: true
      called by: { id: 1, info: 'info' }, pmtted: [:id]
    end
  end


  desc :process_params! do
    called by: { id: '1', info: 1 }, **pass
    called by: { id: '1', info: 1 }, converted: { id: 1, info: '1' }
  end
end

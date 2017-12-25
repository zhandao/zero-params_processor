require 'spec_helper'

RSpec.describe ParamsProcessor do
  it 'has a version number' do
    expect(ParamsProcessor::VERSION).not_to be nil
  end


  describe '#params_doc' do
    it { expect(GoodsController.new.params_doc.map(&:deep_symbolize_keys)).to eq [ OpenApi.info, OpenApi.id ] }
  end

  describe '#validate_params!' do
    it { expect { GoodsController.new.validate_params! }.not_to raise_error }
  end
end

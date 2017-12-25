module Temp; cattr_accessor :type, :format end

def type type, &block
  describe "when type is #{type}" do
    set_info type: Temp.type = type
    instance_eval(&block)
  end
end

def format format, &block
  context "when format is #{format}" do
    set_info type: Temp.type, format: Temp.format = format.to_s
    instance_eval(&block)
  end
end

def given input, desc = nil,if: nil, expect:
  _if = binding.local_variable_get(:if) || { }
  schema = { type: Temp.type, format: Temp.format, **_if }.keep_if { |_k, v| v.present? }
  schema = schema.map { |k, v| "#{k} is #{v}" }.join(', and ')
  it desc || "when #{schema}: given ( #{input.inspect} ) expect to convert to ( #{expect.inspect} )" do
    schema = OpenApi.info_schema.clone
    OpenApi.info_schema.merge!(_if)
    doc = OpenApi.info
    OpenApi.info_schema = schema
    expect(ParamsProcessor::TypeConvert.(input, based_on: ParamsProcessor::ParamDocObj.new(doc))).to eq expect
  end
end

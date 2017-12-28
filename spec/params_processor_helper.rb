require 'support/good'

module Temp; cattr_accessor :msg, :g end

def desc action, &block
  describe "#{action}" do
    let(:action) { action }
    instance_eval(&block)
  end
end

%i[ validate_params! convert_param_types validate_and_convert_params! set_permitted params_doc ].each do |action|
  define_method action do |params = nil|
    (Temp.g = GoodsController.new(params)).send(action)
  end
end

def called by: params = nil, get: result = nil, raise: msg = nil, converted: nil, pmtted: nil
  it_blk = -> { expect(send(action, by)).to eq get } if get

  it_blk = -> {
    expect{ send(action, by) }.send(raise ? :to : :not_to, raise_error(ParamsProcessor::ValidationFailed, Temp.msg))
  } unless raise.nil?

  it_blk = -> do
    send(action, by)
    expect(Temp.g.params).to eq ActionController::Parameters.new(converted)
  end if converted

  it_blk = -> do
    send(action, by)
    expect(Temp.g.send(:permitted)).to eq ActionController::Parameters.new(by).permit(*pmtted)
  end if pmtted

  msg = "to get #{get}" if get
  msg = "parameters to be #{converted.inspect}" if converted
  msg = "to get permitted #{pmtted.join(', ')}" if pmtted
  msg ||= "#{'not ' unless raise}to raise ValidationFailed#{' with ' << raise.to_s if raise.is_a?(Symbol)}"
  it "after calling it, expect #{msg}" do
    Temp.msg = raise.is_a?(Symbol) ? ParamsProcessor::Config.send(raise) :  nil
    instance_exec(&it_blk)
  end
end

def pass; { raise: false } end
def fail!; { raise: true } end

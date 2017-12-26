module Temp; cattr_accessor :action end

def desc action, &block
  describe "#{action}" do
    Temp.action = action
    instance_eval(&block)
  end
end

%i[ validate_params! convert_param_types set_permitted permitted params_doc ].each do |action|
  define_method action do
    GoodsController.new.send(action)
  end
end

def called get: nil, raise: nil
  it_blk = ->(excepted) { expect(send(Temp.action)).to eq excepted  } if get
  it_blk = ->(*args) { expect{ send(Temp.action) }.send(raise ? :to : :not_to, raise_error)  } unless raise.nil?

  msg = get ? "to get #{get}" : "#{'not' unless raise} to raise anything"
  it "after calling it, expect #{msg}" do
    instance_exec(get || raise, &it_blk)
  end
end

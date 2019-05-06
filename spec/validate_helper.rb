module Temp; cattr_accessor :msg end

def _check
  ->(input, should, with, param, _if) do
    whether = should['pass'] ? :not_to : :to
    schema = OpenApi.send("#{param}_schema").clone
    OpenApi.send("#{param}_schema").merge!(_if || { })
    doc = OpenApi.send(param)
    OpenApi.send("#{param}_schema=" , schema)
    # expect { ParamsProcessor::Validate.(input, based_on: ParamsProcessor::ParamDoc.new(doc)) }
    #     .send(whether, raise_error(ParamsProcessor::ValidationFailed, (ParamsProcessor::Config.send(with) rescue with)))
    expect { ParamsProcessor::DrySchema.new([doc]).validate(input) }.send(whether, raise_error)
  end
end

def _check_all
  ->(inputs, should, with, param, _if) do
    inputs.each do |input|
      instance_exec(input, should, with, param, _if, &_check)
    end
  end
end

def check input, should:, with: nil, param: :id
  it { instance_exec(input, should, with || Temp.msg, param, &_check) }
end

alias check_id check

%i[ uuid info ].each do |p|
  define_method p do |input, description = nil, if: nil, expect: nil, all: nil, with: nil, without: nil|
    p = :id if p == :uuid
    expect ||= all
    with = with || without || Temp.msg
    with_msg = " #{expect['pass'] ? 'without' : 'with'} " << with.to_s if with
    _if = binding.local_variable_get(:if)
    description ||= "when #{_if.inspect}" if _if
    it "#{description + ': ' if description}validates #{p}( #{input.inspect} ) expect#{' all' if all} #{expect}#{with_msg}" do
      instance_exec(input, expect, with, p, _if, &(all ? _check_all : _check))
    end
  end
end

def pass; { expect: :pass } end
def fail!; { expect: :fail } end
def all_pass; { all: :pass } end
def all_fail!; { all: :fail } end

def desc action, fail_with: nil, &block
  describe ".#{action}" do
    Temp.msg = fail_with
    instance_eval(&block)
  end
end

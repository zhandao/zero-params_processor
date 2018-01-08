require 'support/good'

module Temp; cattr_accessor :msg, :g end

def desc action, &block
  describe "#{action}" do
    let(:action) { action }
    instance_eval(&block)
  end
end

%i[ process_params! _validate_param! _convert_param _set_instance_var _set_permitted params_doc ].each do |action|
  args = {
      process_params!: %i[ validate! convert set_instance_var set_permitted ],
      _validate_param!: [:validate!],
      _convert_param: [:convert],
      _set_instance_var: [:set_instance_var],
      _set_permitted: [:set_permitted]
  }
  define_method action do |params = nil|
    Temp.g = GoodsController.new(params)
    if action.in?(args.keys)
      Temp.g.send(:process_params_by, *args[action])
    else
      Temp.g.send(action)
    end
  end
end

def called before: nil,by: params = nil, get: result = nil, raise: msg = nil, converted: nil, pmtted: nil, found: nil
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
    expect(permitted = Temp.g.send(:permitted)).to eq ActionController::Parameters.new(by).permit(*pmtted)
  end if pmtted

  it_blk = -> do
    expect { send(action, by) }.send(found ? :not_to : :to, raise_error)
    expect(Temp.g.instance_variable_get('@good')).to eq Good.find_by(id: by[:id])
  end unless found.nil?

  msg = "to get #{get}" if get
  msg = "parameters to be #{converted.inspect}" if converted
  msg = "to get permitted #{pmtted.join(', ')}" if pmtted
  msg = "#{found ? 'not to' : 'to'} raise :not_found#{', and instance var @good is set' if found}" unless found.nil?
  msg ||= "#{'not ' unless raise}to raise ValidationFailed#{' with ' << raise.to_s if raise.is_a?(Symbol)}"
  it "after calling it by #{by.inspect}, expect #{msg}" do
    instance_exec(&before) if before
    Temp.msg = raise.is_a?(Symbol) ? ParamsProcessor::Config.send(raise) : nil
    instance_exec(&it_blk)
  end
end

def pass; { raise: false } end
def fail!; { raise: true } end

def set_path path
  before { DocConverter.docs = nil; allow(OpenApi).to receive(:path).and_return(path) }
  after { DocConverter.docs = nil }
end
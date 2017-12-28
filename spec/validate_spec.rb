require 'spec_helper'
require 'validate_helper'

RSpec.describe ParamsProcessor::Validate do
  desc :if_is_passed, fail_with: :not_passed do
    info nil, pass
    uuid nil, fail!
    uuid [ '', false ], all_pass
  end


  desc :if_is_present, fail_with: :is_blank do
    info nil, pass
    uuid '', pass

    context 'when not allowing blank' do
      set_info blankable: false
      info [ '', {}, [] ], all_fail!
      info [ { a: nil }, [nil], false ], all_pass
    end
  end


  desc :type, fail_with: :wrong_type do
    info nil, pass
    uuid '', 'when allowing blank', pass

    context 'when expecting for integer' do
      uuid [ '1', '-1', 1, -1, +1, 0, 123456789 ], all_pass
      uuid [ 0.5, 'a' ], all_fail!
    end

    context 'when expecting for boolean' do
      set_info type: 'boolean'
      info [ 'true', 'false', true, false, 1, 0, '1', 0 ], all_pass
      info [ 'a1', 2 ], all_fail!
    end

    context 'when expecting for array' do
      set_info type: 'array'
      info [ ], pass
    end

    context 'when expecting for object' do
      set_info type: 'object'
      info Hash.new, pass
    end

    context 'when expecting for number' do
      context 'float and double' do
        set_info type: 'number', format: 'float'
        info [ 1.2, +0.001, -12345.678, 1, 0, '1.1', '+1.1' ], all_pass
        info [ 'a', '1..1', '1.x' ], all_fail!
      end
    end

    context 'when expecting for string' do
      info 123, pass

      context 'date' do
        set_info type: 'string', format: 'date'
        info %w[ 2017-12-24 2017/12/24 ], all_pass
        info %w[ 2017 2017-2-31 ], all_fail!
        info '2017-12-24', if: { pattern: '%Y/%m/%d' }, **fail!
        info '2017/12/24', if: { pattern: '%Y/%m/%d' }, **pass
      end

      context 'date-time' do
        set_info type: 'string', format: 'date-time'
        info '2017-12-24', pass
        info [ '2017-12-24 17:21', '2017-12-24-17:21', '2017/12/24 17:21' ], all_pass
        info %w[ 2017 2017-2-31-00:00 ], all_fail!
        info '2017-12-24 17:21', if: { pattern: '%Y-%m-%d %H:%M:%S' }, **fail!
        info '2017-12-24 17:21:52', if: { pattern: '%Y-%m-%d %H:%M:%S' }, **pass
      end

      context 'base64' do
        set_info type: 'string', format: 'base64'
        info '123', fail!
        info 'dGVzdA==', pass
      end

      context 'json' do
        set_info type: 'string', format: 'json'
        info '{a:1}', fail!
        info ({ a: 1 }.to_json), pass
      end
    end
  end


  desc :size, fail_with: :wrong_size do
    info nil, pass
    uuid '', 'when allowing blank', pass
    info '1234567890', 'when size does not specify', pass

    context 'when not passing array' do
      set_info minLength: 2, maxLength: 3
      info [ 12, 123, 'aa', nil, { } ], all_pass
      info [ 1, 1234, '1234', true ], all_fail!
    end

    context 'when passing array' do
      set_info type: 'array', minItems: 2, maxItems: 3
      info [ 1, 2 ], pass
      info [ [1], [1, 2, 3, 4] ], all_fail!
    end
  end


  desc :if_is_entity, fail_with: :is_not_entity do
    info nil, pass
    uuid '', 'when allowing blank', pass
    info '1234567890', 'when entity does not specify', pass

    context 'email' do
      set_info is: 'email'
      info %w[ x@y.cn x-y@z.cn 1@2.cn a.b.c@d.e.cn xY@z.Cn ], all_pass
      info %w[ y.z @y.z x@@y.z x@y -@y.z 1@2.3 1@2.34 ], all_fail!
    end
  end


  desc :if_in_allowable_values, fail_with: :not_in_allowable_values do
    info nil, pass
    uuid '', 'when allowing blank', pass
    info '1234567890', 'when enum does not specify', pass

    context 'integer' do
      set_info type: 'integer', enum: [1, 2, 5]
      info [ 1, 2, 5, '5' ], all_pass
      info [ 0, 4, 6, -1 ], all_fail!
    end

    context 'boolean' do
      set_info type: 'boolean', enum: [true, 1]
      info [ true, 'true', 1, '1' ], all_pass
      info [ false, 0 ], all_fail!
    end

    context 'other (string)' do
      set_info enum: %w[ a b c ]
      info 'a', pass
      info "b\n", fail!
    end
  end


  desc :if_match_pattern, fail_with: :not_match_pattern do
    info nil, pass
    uuid '', 'when allowing blank', pass
    info '1234567890', 'when pattern does not specify', pass

    info 'New', if: { pattern: '^[A-Z]' }, **pass
    info 'new', if: { pattern: '^[A-Z]' }, **fail!
  end


  desc :if_is_in_range, fail_with: :out_of_range do
    info nil, pass
    uuid '', 'when allowing blank', pass
    info '1234567890', 'when range does not specify', pass

    context 'when type is not time' do
      context 'when [a, b]' do
        set_info type: 'number', format: 'float', minimum: 2.5, maximum: 4
        info [ 2.5, 3, 4.0 ], all_pass
        info [ -1, 0, 5, 2.4 ], all_fail!
      end

      context 'when (inf, b]' do
        set_info type: 'integer', maximum: 4
        info [ -99999, 0, 1, 4 ], all_pass
        info 5, fail!
      end

      context 'when [a, b)' do
        set_info type: 'number', format: 'float', minimum: 1, maximum: 5, exclusiveMaximum: true
        info [ 1, 4, 4.999 ], all_pass
        info [ 0, 5, 5.0 ], all_fail!
      end
    end

    context 'when type is time' do
      set_info format: 'date-time', minimum: '2017-1-1', maximum: '2017-12-31', exclusiveMinimum: true
      info %w[ 2017-1-2 2017-6-19 2017-12-31 ], all_pass
      info %w[ 2017-1-1 2018-12-31 ], all_fail!
    end
  end


  desc :check_each_pair do
    set_info type: 'object', properties: { id: { type: 'integer' }, name: { type: 'string' } }, required: [:id]
    info ({ id: 1, name: 'a' }), expect: :pass, without: :wrong_type
    info ({ id: 1 }), expect: :pass, without: :wrong_type
    info ({ }), expect: :fail, with: :not_passed
    info ({ name: 'a' }), expect: :fail, with: :not_passed
    info ({ id: 'a', name: 'a'}), expect: :fail, with: :wrong_type
  end


  desc :check_each_element, fail_with: :wrong_type do
    set_info type: 'array', items: { type: 'integer' }
    info [1, '2', 3], pass
    info [1, 'a', 3], fail!

    context "when the items' type is object" do
      set_info type: 'array', items: { type: 'object', properties: { id: { type: 'integer' }, name: { type: 'string' } }, required: [:id] }
      info [{ id: 1, name: 'a' }, { name: 'b', id: '2' }, { id: 3 }], pass
      info [{ }], expect: :fail, with: :not_passed
      info [{ name: 'a' }], expect: :fail, with: :not_passed
      info [{ id: 'a', name: 'a'}], fail!
    end
  end
end

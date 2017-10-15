module ParamsProcessor
  module Config
    cattr_accessor :prefix do
      'parameter'
    end

    cattr_accessor :not_passed do
      'is required'
    end

    cattr_accessor :is_blank do
      'should not be blank'
    end

    cattr_accessor :wrong_type do
      'must be'
    end

    cattr_accessor :wrong_size do
      'length must be(in)'
    end

    cattr_accessor :is_not_entity do
      'must be'
    end

    cattr_accessor :not_in_allowable_values do
      'must in'
    end

    cattr_accessor :not_match_pattern do
      'must match'
    end

    cattr_accessor :out_of_range do
      'is out of range'
    end
  end
end

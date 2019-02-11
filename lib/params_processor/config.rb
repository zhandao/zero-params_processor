# frozen_string_literal: true

require 'active_support/all'

module ParamsProcessor
  module Config
    cattr_accessor :actions do
      nil
    end

    cattr_accessor :strict_check do
      false
    end

    cattr_accessor :prefix do
      'parameter'
    end

    cattr_accessor :production_msg do
      # 'validation failed'
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

    cattr_accessor :wrong_combined_type do
      'must be'
    end

    cattr_accessor :test do
      false
    end
  end
end

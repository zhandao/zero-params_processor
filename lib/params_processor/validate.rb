require 'params_processor/config'
require 'params_processor/doc_converter'

module ParamsProcessor
  class Validate
    class << self
      def call(input, param_doc)
        input(input).check! param_doc
      end

      def input(input)
        @input   = input
        @input_s = input.to_s
        self
      end

      def check!(param_doc)
        @doc = param_doc
        check if_is_passed
        check if_is_present
        check type
        check size
        check if_is_entity
        check if_in_allowable_values
        check if_match_pattern
        check is_in_range
      end

      def if_is_passed
        Config.not_passed if @doc.required && @input.nil?
      end
      
      def if_is_present
        ;
      end
      
      def type
        case @doc.type
          when 'integer'; @input_s.match? /^[0-9]*$/
          when 'boolean'; @input_s.in? %w[true false]
          else true
        end or "#{Config.wrong_type} #{@doc.type}"
      end

      def size
        return if !@doc.size || @input.nil?
        # FIXME: 应该检查 doc 中的，而不是输入的
        if @input.is_a? Array
          @input.count >= @doc.size[0] && @input.count <= @doc.size[1]
        else
          @input_s.length >= @doc.size[0] && @input_s.length <= @doc.size[1]
        end or "#{Config.wrong_size} #{@doc.size.join('..')}}"
      end

      def if_is_entity
        return if !@doc.is || @input.nil?
        # TODO
        case @doc.is
          when 'email'; @input_s.match?(/\A[^@\s]+@[^@\s]+\z/)
          else true
        end or "#{Config.is_not_entity} #{@doc.is}"
      end

      def if_in_allowable_values
        return if !@doc.enum || @input.nil?
        case @doc.type
          when 'integer'; @doc.enum.include? input.to_i
          # when 'boolean' then @doc.enum.map(&:to_s).include? @input_s
          else @doc.enum.map(&:to_s).include? @input_s
        end or "#{Config.not_in_allowable_values} #{@doc.enum.to_s.delete('\"')}"
      end

      def if_match_pattern
        return if !@doc.pattern || @input.nil?
        unless @input_s.match? Regexp.new @doc.pattern
          "#{Config.not_match_pattern} /#{@doc.pattern}/"
        end
      end

      def is_in_range
        ;
      end

      def check msg
        raise ValidationFailed.new " `#{ @doc.name.to_sym}` ".concat(msg) if msg.is_a? String
      end
    end
  end
end

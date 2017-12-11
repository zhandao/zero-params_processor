require 'params_processor/config'
require 'params_processor/doc_converter'
require 'params_processor/param_doc_obj'
require 'params_processor/type_convert'

module ParamsProcessor
  class Validate
    class << self
      def call(input, based_on:, raise: nil)
        @error_class = raise
        input(input).check! based_on
      end

      def input(input)
        @input     = input
        @str_input = input.to_s
        self
      end

      def check!(param_doc)
        @doc = param_doc
        check (if_is_passed do
          check if_is_present
          check type
          check_each_element if @doc.type == 'array'
          check_each_pair    if @doc.type == 'object'
          check size                   if @doc.size
          check if_is_entity           if @doc.is
          check if_in_allowable_values if @doc.enum
          check if_match_pattern       if @doc.pattern
          check if_is_in_range         if @doc.range
        end)
      end

      def if_is_passed(&block)
        return [:not_passed, ''] if @doc.required && @input.nil?
        self.instance_eval(&block) unless @input.nil?
      end

      def if_is_present
        [:is_blank, ''] if !@doc.blankable && @input.blank?
      end

      # TODO: combined type
      def type
        case @doc.type
        when 'integer' then @str_input.match?(/^-?\d*$/)
        when 'boolean' then @str_input.in? %w[ true 1 false 0 ]
        when 'array'   then @input.is_a? Array
        when 'object'  then @input.is_a? ActionController::Parameters
        when 'number'  then _number_type
        when 'string'  then _string_type
        else true
        end or [:wrong_type, @doc.format.to_s]
      end

      def _number_type
        case @doc.format
        when 'float'  then @str_input.match?(/^[-+]?\d*\.?\d+$/)
        when 'double' then @str_input.match?(/^[-+]?\d*\.?\d+$/)
        else true
        end or [:wrong_type, @doc.format.to_s]
      end

      def _string_type
        return false unless @input.is_a? String

        case @doc.format
        when 'date'      then parse_time!(Date)
        when 'date-time' then parse_time!(DateTime)
        when 'base64'    then Base64.strict_decode64(@input)
        else true
        end
      rescue ArgumentError
        false
      end

      def size
        # FIXME: 应该检查 doc 中的，而不是输入的
        if @input.is_a? Array
          @input.size >= @doc.size[0] && @input.size <= @doc.size[1]
        else
          @str_input.length >= @doc.size[0] && @str_input.length <= @doc.size[1]
        end or [:wrong_size, @doc.size.join('..')]
      end

      def if_is_entity
        # TODO
        case @doc.is
        when 'email'; @str_input.match?(/\A[^@\s]+@[^@\s]+\z/)
        else true
        end or [:is_not_entity, @doc.is.to_s]
      end

      def if_in_allowable_values
        case @doc.type
        when 'integer' then @doc.enum.include? @input.to_i
        # when 'boolean' then @doc.enum.map(&:to_s).include? @str_input
        else @doc.enum.map(&:to_s).include? @str_input
        end or [:not_in_allowable_values, @doc.enum.to_s.delete('\"')]
      end

      def if_match_pattern
        unless @str_input.match?(Regexp.new(@doc.pattern))
          [:not_match_pattern, "/#{@doc.pattern}/"]
        end
      end

      def if_is_in_range
        rg = @doc.range
        fmt = fmt.tr('-', '_').camelize if (fmt = @doc.format)&.match?('date')
        min = fmt ? parse_time!(fmt, rg[:min]) : rg[:min]
        max = fmt ? parse_time!(fmt, rg[:max]) : rg[:max]
        @input = fmt ? parse_time!(fmt, @input) : @input.to_f

        left_op  = rg[:should_neq_min?] ? :< : :<=
        right_op = rg[:should_neq_max?] ? :< : :<=
        is_in_range = min&.send(left_op, @input)
        is_in_range &= @input.to_f.send(right_op, max)
        [:out_of_range, "#{min} #{left_op} x #{right_op} #{max}"] unless is_in_range
      end

      def check_each_element
        items_doc = ParamDocObj.new name: @doc.name, schema: @doc.items
        @input.each do |input|
          Validate.(input, based_on: items_doc, raise: @error_class)
        end
      end

      def check_each_pair
        required = @doc[:schema][:required]
        @doc.props.each do |name, schema|
          prop_doc = ParamDocObj.new name: name, required: required.include?(name), schema: schema
          _input = @input
          Validate.(@input[name], based_on: prop_doc, raise: @error_class)
          @input = _input
        end
      end

      def check msg
        return unless msg.is_a? Array
        @error_class.send("#{@doc.name}_#{msg.first}!") if @error_class.respond_to? "#{@doc.name}_#{msg.first}!"
        @error_class.send("#{msg.first}!") if @error_class.respond_to? msg.first
        raise ValidationFailed, Config.production_msg if Config.production_msg.present?

        msg = "#{Config.send(msg.first)}#{' ' + msg.last if msg.last.present?}"
        raise ValidationFailed, (" `#{ @doc.name.to_sym}` " << msg)
      end

      def parse_time!(cls, value = nil)
        if @doc.pattern
          cls.send(:strptime, value || @input, @doc.pattern)
        else
          cls.send(:parse, value || @input)
        end
      end
    end
  end
end

require 'multi_json'
require 'params_processor/config'
require 'params_processor/doc_converter'
require 'params_processor/param_doc'

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
          break if @input.nil?# || (@doc.blankable != false && @input.blank? && @input != false)
          check_combined_types         if @doc.combined?
          check type                   if @doc.type
          check size                   if @doc.size
          check if_is_entity           if @doc.is
          check if_in_allowable_values if @doc.enum
          check if_match_pattern       if @doc.pattern
          check if_is_in_range         if @doc.range
          check_each_element           if @doc.type == 'array'
          check_each_pair              if @doc.type == 'object'
        end)
      end

      def if_is_passed(&block)
        return [:not_passed, ''] if @doc.required && @input.nil?
        self.instance_eval(&block) unless @input.nil?
      end

      def if_is_present
        [:is_blank, ''] if @doc.blankable == false && @input.blank? && @input != false
      end

      # TODO: combined type
      def type
        case @doc.type
        when 'integer' then @str_input.match?(/^-?\d*$/)
        when 'boolean' then @str_input.in? %w[ true 1 false 0 ]
        when 'array'   then @input.is_a? Array
        when 'object'  then @input.is_a?(ActionController::Parameters) || @input.is_a?(Hash)
        when 'number'  then _number_type
        when 'string'  then _string_type
        else true # TODO
        end or [:wrong_type, @doc.format.to_s]
      end

      def _number_type
        case @doc.format
        when 'float'  then @str_input.match?(/^[-+]?\d*\.?\d+$/)
        when 'double' then @str_input.match?(/^[-+]?\d*\.?\d+$/)
        else true # TODO
        end or [:wrong_type, @doc.format.to_s]
      end

      def _string_type
        # return false unless @input.is_a? String
        case @doc.format
        when 'date'      then parse_time!(Date)
        when 'date-time' then parse_time!(DateTime)
        when 'base64'    then Base64.strict_decode64(@input)
        when 'json'      then MultiJson.load(@input)
        else Config.strict_check ? @input.is_a?(String) : true
        end
      rescue ArgumentError, MultiJson::ParseError
        false
      end

      def size
        if @doc.type.in? %w[ array object ]
          @input.size >= @doc.size[:min] && @input.size <= @doc.size[:max]
        else
          @str_input.length >= @doc.size[:min] && @str_input.length <= @doc.size[:max]
        end or [:wrong_size, @doc.size.values.join('..')]
      end

      def if_is_entity
        case @doc.is
        when 'email'; @str_input.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]{2,}\z/i)
        else true # TODO
        end or [:is_not_entity, @doc.is.to_s]
      end

      def if_in_allowable_values
        case @doc.type
        when 'integer' then @doc.enum.include?(@input.to_i)
        else @doc.enum.map(&:to_s).include?(@str_input)
        end or [:not_in_allowable_values, @doc.enum.to_s.delete('\"')]
      end

      def if_match_pattern
        unless @str_input.match?(Regexp.new(@doc.pattern))
          [:not_match_pattern, "/#{@doc.pattern}/"]
        end
      end

      def if_is_in_range
        rg = @doc.range
        fmt = @doc.format.tr('-', '_').camelize.constantize if @doc.format&.match?('date')
        min = fmt ? parse_time!(fmt, rg[:min] || '1-1-1') : rg[:min]
        max = fmt ? parse_time!(fmt, rg[:max] || '9999-12-31') : rg[:max]
        @input = fmt ? parse_time!(fmt, @input) : @input.to_f

        left_op  = rg[:should_neq_min?] ? :< : :<=
        right_op = rg[:should_neq_max?] ? :< : :<=
        is_in_range = min&.send(left_op, @input)
        is_in_range &= @input.send(right_op, max)
        [:out_of_range, "#{min} #{left_op} x #{right_op} #{max}"] unless is_in_range
      end

      def check_combined_types
        @doc.combined.each do |mode, schemas|
          results = check_each_schema(schemas)

          case mode
          when :all_of then results.all?(&:present?)
          when :one_of then results.count(true) == 1
          when :any_of then results.include?(true)
          when :not    then results.all?(&:blank?)
          end or raise ValidationFailed, " `#{@doc.name.to_sym}` #{Config.wrong_combined_type} #{mode} the specified schemas."
        end
      end

      def check_each_schema(schemas)
        results = [ ]
        strict_check = Config.strict_check.clone
        _doc, Config.strict_check = @doc, true
        schemas.each do |schema|
          doc = ParamDoc.new name: @doc.name, schema: schema
          begin
            Validate.(@input, based_on: doc, raise: @error_class)
            results << true
          rescue ValidationFailed
            results << false
          end
        end
        @doc, Config.strict_check = _doc, strict_check
        results
      end

      def check_each_element
        return if @doc.items.blank?

        _doc, _input = @doc, @input
        items_doc = ParamDoc.new name: @doc.name, schema: @doc.items
        @input.each do |input|
          Validate.(input, based_on: items_doc, raise: @error_class)
        end
        @doc, @input = _doc, _input
      end

      def check_each_pair
        return if @doc.props.blank?

        _doc = @doc
        required = (@doc[:schema][:required] || [ ]).map(&:to_s)
        @doc.props.each do |name, schema|
          prop_doc = ParamDoc.new name: name, required: required.include?(name), schema: schema
          _input = @input
          Validate.(@input[name] || @input[name.to_sym], based_on: prop_doc, raise: @error_class)
          @input = _input
        end
        @doc = _doc
      end

      def check msg
        return unless msg.is_a? Array
        @error_class.send("#{@doc.name}_#{msg.first}!") if @error_class.respond_to? "#{@doc.name}_#{msg.first}!"
        @error_class.send("#{msg.first}!") if @error_class.respond_to? msg.first
        raise ValidationFailed, Config.production_msg if Config.production_msg.present?

        test_msg = Config.send(msg.first) if Config.test
        msg = "#{Config.send(msg.first)}#{' ' + msg.last if msg.last.present?}"
        msg = " `#{@doc.name.to_sym}` " << msg
        raise ValidationFailed, test_msg || msg
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

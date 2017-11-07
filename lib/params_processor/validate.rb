require 'params_processor/config'
require 'params_processor/doc_converter'
require 'params_processor/param_doc_obj'

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
        check (if_is_passed do
          check if_is_present
          check type
          check_each_element if @doc.type == 'array'
          check_each_pair if @doc.type == 'object'
          check size
          check if_is_entity
          check if_in_allowable_values
          check if_match_pattern
          check is_in_range
        end)
      end

      def if_is_passed(&block)
        return Config.not_passed if @doc.required && @input.nil?
        self.instance_eval &block unless @input.nil?
      end

      def if_is_present
        ;
      end
      
      def type
        case @doc.type
          when 'integer'; @input_s.match? /^-[0-9]*|[0-9]*$/
          when 'boolean'; @input_s.in? %w[true false]
          when 'array';   @input.is_a? Array
          when 'object';  @input.is_a? ActionController::Parameters
          when 'number'
            case @doc.format
              when 'float'; @input_s.match? /^[0-9]*$|^[0-9]*\.[0-9]*$/
              else true
            end or "#{Config.wrong_type} #{@doc.format}"
          else true
        end or "#{Config.wrong_type} #{@doc.type}"
      end

      def size
        return unless @doc.size
        # FIXME: 应该检查 doc 中的，而不是输入的
        if @input.is_a? Array
          @input.size >= @doc.size[0] && @input.size <= @doc.size[1]
        else
          @input_s.length >= @doc.size[0] && @input_s.length <= @doc.size[1]
        end or "#{Config.wrong_size} #{@doc.size.join('..')}}"
      end

      def if_is_entity
        return unless @doc.is
        # TODO
        case @doc.is
          when 'email'; @input_s.match?(/\A[^@\s]+@[^@\s]+\z/)
          else true
        end or "#{Config.is_not_entity} #{@doc.is}"
      end

      def if_in_allowable_values
        return unless @doc.enum
        case @doc.type
          when 'integer'; @doc.enum.include? @input.to_i
          # when 'boolean' then @doc.enum.map(&:to_s).include? @input_s
          else @doc.enum.map(&:to_s).include? @input_s
        end or "#{Config.not_in_allowable_values} #{@doc.enum.to_s.delete('\"')}"
      end

      def if_match_pattern
        return unless @doc.pattern
        unless @input_s.match? Regexp.new @doc.pattern
          "#{Config.not_match_pattern} /#{@doc.pattern}/"
        end
      end

      def is_in_range
        rg = @doc.range
        return unless rg
        left_op  = rg[:should_neq_min?] ? :< : :<=
        right_op = rg[:should_neq_max?] ? :< : :<=
        in_range = rg[:min]&.send(left_op, @input.to_f)
        in_range &= @input.to_f.send(right_op, rg[:max])
        "#{Config.out_of_range} #{rg[:min]} #{left_op} x #{right_op} #{rg[:max]}" unless in_range
      end

      def check_each_element
        items_doc = ParamDocObj.new name: @doc.name, schema: @doc.items
        @input.each do |input|
          Validate.(input, items_doc)
        end
      end

      def check_each_pair
        required = @doc[:schema][:required]
        @doc.props.each do |name, schema|
          prop_doc = ParamDocObj.new name: name, required: required.include?(name), schema: schema
          _input = @input
          Validate.(@input[name], prop_doc)
          @input = _input
        end
      end

      def check msg
        raise ValidationFailed, Config.production_msg if Config.production_msg.present?
        raise ValidationFailed, (" `#{ @doc.name.to_sym}` " << msg) if msg.is_a? String
      end
    end
  end
end

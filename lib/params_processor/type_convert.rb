# frozen_string_literal: true

module ParamsProcessor
  class TypeConvert
    class << self
      def call(input, based_on:)
        @input = input
        @doc = based_on
        convert
      end

      # TODO: 循环和递归转换
      def convert
        send(@doc.type || @doc.combined_modes.first) # TODO
      rescue NoMethodError
        @input
      end

      # int32 / int64
      def integer
        @input.to_i
      end

      # float / double
      def number
        @input.to_f
      end

      def boolean
        @input.to_s.in?(%w[ true 1 ]) ? true : false
      end

      # date / date-time / base64
      def string
        case @doc.format
        when 'date'      then parse_time(Date)
        when 'date-time' then parse_time(DateTime)
        when 'base64'    then @input # Base64.strict_decode64(@input)
        when 'binary'    then @input
        else @input.to_s
        end
      end

      def array
        return @input unless @input.is_a?(String)
        @input = MultiJson.load(@input)
      end

      def object
        return @input unless @input.is_a?(String)
        @input = MultiJson.load(@input)
      end

      # combined TODO

      def all_of
        doc = ParamDoc.new name: @doc.name, schema: @doc.all_of.reduce({}, :merge)
        TypeConvert.(@input, based_on: doc)
      end

      def one_of
        doc = ParamDoc.new name: @doc.name, schema: @doc.all_of.reduce({}, :merge)
        TypeConvert.(@input, based_on: doc)
      end

      def any_of
        doc = ParamDoc.new name: @doc.name, schema: @doc.all_of.reduce({}, :merge)
        TypeConvert.(@input, based_on: doc)
      end

      def not
        @input
      end

      # helpers

      def parse_time(cls)
        if @doc.pattern
          cls.send(:strptime, @input, @doc.pattern)
        else
          cls.send(:parse, @input)
        end
      end
    end
  end
end

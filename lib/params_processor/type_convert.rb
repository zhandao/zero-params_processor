module ParamsProcessor
  class TypeConvert
    class << self
      def call(input, based_on:)
        @input = input
        @doc = based_on
        convert
      end

      def convert
        send(@doc.type)
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
        else @input.to_s
        end
      end

      def array
        @input
      end

      def object
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

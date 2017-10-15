require 'active_support/hash_with_indifferent_access'

module ParamsProcessor
  module Validate
    class ParamObj < HashWithIndifferentAccess
      # Interfaces for directly taking the processed info what we focus on.
      def range
        {
            min: self[:minimum],
            max: self[:maximum],
            should_neq_min?: self[:exclusiveMinimum] || false,
            should_neq_max?: self[:exclusiveMaximum] || false,
        }
      end

      def size
        size = if self[:type].eql? 'array'
          [self[:minItems], self[:maxItems]]
        else
          [self[:minLength], self[:maxLength]]
        end
        size.tap { |it| it[0] ||= 0; it[1] ||= Float::INFINITY }
      end

      { # INTERFACE_MAPPING
          name:     %i[ name           ],
          required: %i[ required       ],
          in:       %i[ in             ],
          enum:     %i[ schema enum    ],
          pattern:  %i[ schema pattern ],
          regexp:   %i[ schema pattern ],
          type:     %i[ schema type    ],
          is:       %i[ schema format  ],
          dft:      %i[ schema default ],
          as:       %i[ schema as      ],
      }.each do |method, path|
        define_method method do path.inject(self, &:[]) end # Get value from hash by key path
      end
      alias_method :required?, :required
    end
  end
end

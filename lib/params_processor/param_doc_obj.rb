module ParamsProcessor
  class ParamDocObj < ::ActiveSupport::HashWithIndifferentAccess
    # Interfaces for directly taking the processed info what we focus on.
    def range
      return if (schema.keys & %w[ minimum maximum ]).blank?
      {
          min: schema[:minimum] || 0,
          max: schema[:maximum] || Float::INFINITY,
          should_neq_min?: schema[:exclusiveMinimum] || false,
          should_neq_max?: schema[:exclusiveMaximum] || false
      }
    end

    def size
      return if (schema.keys & %w[ minItems maxItems minLength maxLength ]).blank?
      size = if type.eql? 'array'
               [schema[:minItems], schema[:maxItems]]
             else
               [schema[:minLength], schema[:maxLength]]
             end
      size.tap { |it| it[0] ||= 0; it[1] ||= Float::INFINITY }
    end

    { # INTERFACE_MAPPING
      name:     %i[ name              ],
      required: %i[ required          ],
      in:       %i[ in                ],
      schema:   %i[ schema            ],
      enum:     %i[ schema enum       ],
      pattern:  %i[ schema pattern    ],
      regexp:   %i[ schema pattern    ],
      type:     %i[ schema type       ],
      format:   %i[ schema format     ],
      is:       %i[ schema is         ],
      dft:      %i[ schema default    ],
      as:       %i[ schema as         ],
      items:    %i[ schema items      ],
      props:    %i[ schema properties ],
    }.each do |method, path|
      define_method method do path.reduce(self, &:[]) end # Get value from hash by key path
    end
    alias required? required
  end
end

# frozen_string_literal: true

require 'active_support/hash_with_indifferent_access'

module ParamsProcessor
  class ParamDoc < HashWithIndifferentAccess
    # Interfaces for directly taking the processed info what we focus on.
    def range
      return if (schema.keys & %w[ minimum maximum ]).blank?
      {
          min: schema[:minimum] || -Float::INFINITY,
          max: schema[:maximum] || Float::INFINITY,
          should_neq_min?: schema[:exclusiveMinimum] || false,
          should_neq_max?: schema[:exclusiveMaximum] || false
      }
    end

    def size
      return if (schema.keys & %w[ minItems maxItems minLength maxLength ]).blank?
      size = if type.in? %w[ array object ]
               [schema[:minItems], schema[:maxItems]]
             else
               [schema[:minLength], schema[:maxLength]]
             end
      { min: size[0] || 0, max: size[1] || Float::INFINITY }
    end

    def combined
      { all_of: all_of, one_of: one_of, any_of: any_of, not: not_be }.keep_if { |_k, v| !v.nil? }
    end

    def combined?; combined.present? end

    def combined_modes; combined.keys end

    def real_name; as || name end

    def doced_permit?; permit? || not_permit? end

    { # INTERFACE_MAPPING
      name:        %i[ name              ],
      required:    %i[ required          ],
      in:          %i[ in                ],
      schema:      %i[ schema            ],
      enum:        %i[ schema enum       ],
      pattern:     %i[ schema pattern    ],
      regexp:      %i[ schema pattern    ],
      type:        %i[ schema type       ],
      format:      %i[ schema format     ],
      all_of:      %i[ schema allOf      ],
      one_of:      %i[ schema oneOf      ],
      any_of:      %i[ schema anyOf      ],
      not_be:      %i[ schema not        ],
      is:          %i[ schema is_a       ],
      dft:         %i[ schema default    ],
      as:          %i[ schema as         ],
      items:       %i[ schema items      ],
      props:       %i[ schema properties ],
      blankable:   %i[ schema blankable  ],
      group:       %i[ schema group      ],
      permit?:     %i[ schema permit     ],
      not_permit?: %i[ schema not_permit ],
    }.each do |method, path|
      define_method method do self.dig(*path) end
    end
    alias required? required
  end
end

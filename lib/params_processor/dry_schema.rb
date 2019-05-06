# frozen_string_literal: true
require 'dry-schema'

module ParamsProcessor
  class DrySchema
    attr_accessor :schema

    def initialize(params)
      builder = self
      self.schema = Dry::Schema.Params do
        params.each { |param| instance_exec(param, &builder.build_validator) }
      end
    end

    def validate(input)
      errors = schema.call(input).errors.to_h
      errors.blank? or raise ValidationFailed, errors
    end

    def build_validator; -> (param) do
      param_doc = ParamDoc.new(param)
      necessity = param_doc.required? ? :required : :optional
      macro = necessity && param_doc.blankable === false ? :filled : :maybe
      type = param_doc.type.to_sym
      predicates = { }
      if (type == :array && param_doc.items.present?) || (type == :hash && param_doc.props.present?)
        send(necessity, param_doc.name).send(macro, type, predicates, &build_nested_block)
      else
        send(necessity, param_doc.name).send(macro, type, predicates)
      end
    end end

    def build_nested_block
      -> { }
    end
  end
end

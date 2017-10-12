require "params_processor/version"
require 'params_processor/validate'

module ParamsProcessor
  include Validate

  private

  # TODO: type support: string integer boolean
  def validate_params
    params_settings.each do |param_setting|
      param = @_param = ParamObj.new param_setting
      # TODO: configure
      next if param.name == 'Token'
      @_input_under_check = params[param.name.to_sym]

      it 'is required' if it_should_but_not :exist
      it must_be "#{param.type}" if it_is_not :type
      it "has length must be(in) #{param.size.join('..')}" if it_has_wrong :size # TODO: [0,1)
      it must_be "#{param.is}" if it_is_unmatched
      it "must match /#{param.pattern}/" if it_is_unmatched :regexp
      it must_in "#{param.enum}".delete('\"') if it_is_not_in :allowable_values
      # TODO: range
    end
  end

  def convert_params_type
    params_settings.each do |param_setting|
      param = ParamObj.new param_setting
      type, name = param.type, param.name.to_sym
      params[name] = param.dft if not_exist(input) && !param.dft.nil?
      input = params[name]
      params[name] =
          case type
            when 'integer'
              input.to_i
            when 'boolean'
              input.to_s.eql?('true') ? true : false
            else params[name]
          end if input.is_a? String
    end
  end

  def permitted
    params.permit(params_settings&.map { |setting| setting[:name] })
  end

  class ValidateError < StandardError
    def info; { code: 400, msg: 'parameter '.concat(message) }; end
  end
end

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
      p_setting = ParamObj.new param_setting
      type, name = p_setting.type, p_setting.name.to_sym
      # TODO: load default from db, JSON.load Floor.columns[3].default / to_json
      params[name] = p_setting.dft if not_exist(params[name]) && !p_setting.dft.nil?
      input = params[name]
      params[name] =
          case type
            when 'integer'
              input.to_i
            when 'boolean'
              input.to_s.eql?('true') ? true : false
            when 'string'
              if p_setting.is == 'date-time'
                input.match?('-') ? Time.new(*input.gsub(/ |:/, '-').split('-')) : Time.at(input.to_i)
              else
                input
              end
            else input
          end if input.is_a? String

      # mapping param key
      params[p_setting.as] = params.delete(name) if p_setting.as.present? && !params[name].nil?
    end
  end

  def set_permitted
    if @permitted.nil?
      doced_keys = params_settings&.map { |ps| ps[:schema][:as] || ps[:name] }
      params.slice(*doced_keys).each do |key, value|
        instance_variable_set("@_#{key}", value)
      end
      exist_not_permit = false
      keys = params_settings&.map do |ps|
        schema = ps[:schema]
        exist_not_permit = true if schema[:not_permit]
        schema[:permit] || schema[:not_permit] ? (schema[:as] || ps[:name]) : nil
      end.compact
      permitted_keys = doced_keys - keys if exist_not_permit
      permitted_keys = doced_keys if keys.blank?
      @permitted = params.permit(*permitted_keys)
    end
    @permitted
  end
  alias_method :permitted, :set_permitted

  class ValidateError < StandardError
    def info; { code: 400, msg: 'parameter '.concat(message) }; end
  end
end

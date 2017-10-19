require 'params_processor/version'
require 'params_processor/config'
require 'params_processor/doc_loader'
require 'params_processor/validate'

module ParamsProcessor
  include DocLoader

  private

  # TODO: type support: string integer boolean
  def validate_params!(convert = nil)
    params_doc&.each do |doc|
      @_param_doc = ParamDocObj.new doc
      input = @_param_doc.name == 'Token' ? token : params[@_param_doc.name.to_sym]
      Validate.(input, @_param_doc)
      convert_params_type if convert
    end
  end

  def validate_and_convert_params!
    validate_params! convert = true
  end

  # TODO: 循环和递归转换
  def convert_params_type
    params_doc&.each do |doc|
      p_doc = ParamDocObj.new doc
      type, name = p_doc.type, p_doc.name.to_sym
      # TODO: load default from db, JSON.load Floor.columns[3].default / to_json
      params[name] = p_doc.dft if params[name].nil? && !p_doc.dft.nil?
      input = params[name]
      params[name] =
          case type
            when 'integer'
              input.to_i
            when 'boolean'
              input.to_s.eql?('true') ? true : false
            when 'string'
              if p_doc.is == 'date-time'
                input.match?('-') ? Time.new(*input.gsub(/ |:/, '-').split('-')) : Time.at(input.to_i)
              else
                input
              end
            else input
          end if input.is_a? String

      # mapping param key
      params[p_doc.as] = params.delete(name) if p_doc.as.present? && !params[name].nil?
    end
  end

  def set_permitted
    if @permitted.nil?
      doced_keys = params_doc&.map { |ps| ps[:schema][:as] || ps[:name] }
      params.slice(*doced_keys).each do |key, value|
        # TODO: 循环和递归 permit
        value.map!(&:permit!) if value.is_a? Array #ActionController::Parameters
        instance_variable_set("@_#{key}", value)
      end
      exist_not_permit = false
      keys = params_doc&.map do |ps|
        schema = ps[:schema]
        exist_not_permit = true if schema[:not_permit]
        schema[:permit] || schema[:not_permit] ? (schema[:as] || ps[:name]) : nil
      end&.compact
      permitted_keys = doced_keys - keys if exist_not_permit
      permitted_keys = doced_keys if keys.blank?
      @permitted = params.permit(*permitted_keys)
    end
    @permitted
  end
  alias_method :permitted, :set_permitted


  class ValidationFailed < StandardError
    def info; { code: 400, msg: "#{Config.prefix}".concat(message) }; end
  end
end

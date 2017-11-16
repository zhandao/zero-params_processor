require 'params_processor/version'
require 'params_processor/config'
require 'params_processor/validate'

module ParamsProcessor

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
          when 'integer' then input.to_i
          when 'boolean' then input.to_s.eql?('true') ? true : false
          when 'string'
            if p_doc.is == 'date-time'
              input['-'] ? Time.new(*input.gsub(/ |:/, '-').split('-')) : Time.at(input.to_i)
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
    return @permitted unless @permitted.nil?

    doced_keys = params_doc&.map { |ps| ps[:schema][:as] || ps[:name] }
    params.slice(*doced_keys).each do |key, value|
      # TODO: 循环和递归 permit
      # 见 book_record 的 Doc，params[:data] = [{name..}, {name..}]，注意
      #   json 就是 ActionController::Parameters 对象，所以需要循环做一次 permit
      value.map!(&:permit!) if value.is_a?(Array) && value.first.is_a?(ActionController::Parameters)
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

  alias permitted set_permitted

  def params_doc
    $_open_apis ||= DocConverter.new $open_apis
    current_api = $api_paths_index[self.class.controller_path]
    route_path = ::OpenApi::Generator.find_path_httpverb_by(self.class.controller_path, action_name).first
    path_doc = $_open_apis[current_api][:paths][route_path]
    # 考虑没有 doc 时的 before action
    path_doc&.[](request.method.downcase)&.[](:parameters) || [ ]
  end


  class ValidationFailed < StandardError
    def info; { code: 400, msg: "#{Config.prefix}".concat(message) }; end
  end
end

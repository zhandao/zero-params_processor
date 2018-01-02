require 'params_processor/version'
require 'params_processor/config'
require 'params_processor/validate'

module ParamsProcessor
  private

  def validate_params!(convert = nil)
    params_doc&.each do |doc|
      param_doc = ParamDocObj.new doc
      input = param_doc.name == 'Token' ? token : params[param_doc.name.to_sym] # TODO: move
      error_class = "#{controller_name.camelize}Error".constantize rescue nil
      Validate.(input, based_on: param_doc, raise: error_class)
      _convert_param_type(param_doc) if convert
    end
  end

  def validate_and_convert_params!
    validate_params! convert = true
  end

  def convert_param_types # TODO: rename
    params_doc&.each { |doc| _convert_param_type(ParamDocObj.new(doc)) }
  end

  def _convert_param_type(doc)
    name = doc.name.to_sym
    params[name] = doc.dft if params[name].nil? && !doc.dft.nil?
    return if params[name].nil?

    params[name] = TypeConvert.(params[name], based_on: doc)
    # mapping param key
    params[doc.as] = params.delete(name) if doc.as.present?
  end

  # TODO?: to validate_and_convert_params!
  def set_permitted
    return if params_doc.nil?
    doced_keys = params_doc.map { |p| p[:schema][:as] || p[:name] }
    _set_instance_var(doced_keys)

    exist_not_permit = false
    keys = params_doc.map do |p|
      next unless (npmt = p[:schema][:not_permit]) || (pmt = p[:schema][:permit])
      exist_not_permit = true if npmt
      p[:schema][:as] || p[:name]
    end.compact

    keys = exist_not_permit ? doced_keys - keys : keys
    @permitted = params.permit(*keys)
  end

  def permitted; @permitted end

  def _set_instance_var(doced_keys)
    params.slice(*doced_keys).each do |key, value|
      instance_variable_set("@#{key}", value)
      _permit_hash_and_array(value)
      _auto_find_by_id(key, value) if @route_path.match?(/\{#{key}\}/)
    end
  end

  def _permit_hash_and_array(value)
    # TODO: 循环和递归 permit
    # 见 book_record 的 Doc，params[:data] = [{name..}, {name..}]，注意
    #   json 就是 ActionController::Parameters 对象，所以需要循环做一次 permit
    value.map!(&:permit!) if value.is_a?(Array) && value.first.is_a?(ActionController::Parameters)
  end

  def _auto_find_by_id(key, value)
    whos_id = (key.to_sym == :id ? controller_name : key.to_s.sub('_id', '')).singularize
    model = whos_id.camelize.constantize rescue return
    model_instance = model.find_by(id: value) || self.class.error_cls.not_found! # TODO HACK
    instance_variable_set("@#{whos_id}", model_instance)
  end

  def params_doc
    DocConverter.docs ||= DocConverter.new OpenApi.docs
    current_api = OpenApi.routes_index[self.class.controller_path]
    @route_path = OpenApi::Generator.find_path_httpverb_by(self.class.controller_path, action_name).first
    path_doc = DocConverter.docs[current_api][:paths][@route_path]
    # 考虑没有 doc 时的 before action
    doc = path_doc&.[](request.method.downcase)&.[](:parameters) || [ ]
    doc.map { |p| p.try(:deep_symbolize_keys) || p }
  end


  class ValidationFailed < StandardError
    def info; { code: 400, msg: "#{Config.prefix}".concat(message), http_status: :bad_request }; end
  end
end

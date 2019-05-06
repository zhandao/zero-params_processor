# frozen_string_literal: true

require 'open_api/config'
require 'open_api/router'

require 'params_processor/version'
require 'params_processor/validate'
require 'params_processor/type_convert'
require 'params_processor/dry_schema'

module ParamsProcessor
  cattr_accessor :docs

  private

  def process_params_by(*actions)
    return if params_doc.blank?
    pdocs = params_doc.map do |doc|
      param_doc = ParamDoc.new(doc) # TODO: performance
      _validate_param!(param_doc)  if actions.index(:validate!)
      _convert_param(param_doc)    if actions.index(:convert)
      _set_instance_var(param_doc) if actions.index(:set_instance_var)
      _group_params(param_doc)     if param_doc.group
      param_doc
    end
    _set_permitted(pdocs) if actions.index(:set_permitted)
  end

  def process_params!
    actions = Config.actions || %i[ validate! convert set_instance_var set_permitted ]
    process_params_by *actions
  end

  def _validate_param!(param_doc)
    input = param_doc.in == 'header' ? request.headers[param_doc.name.to_s] : params[param_doc.name.to_sym]
    error_class = "Error::#{controller_name.camelize}".constantize rescue nil
    Validate.(input, based_on: param_doc, raise: error_class)
  end

  def _convert_param(param_doc)
    name = param_doc.name.to_sym
    params[name] = param_doc.dft if params[name].nil? && !param_doc.dft.nil?
    return if params[name].nil?

    params[name] = TypeConvert.(params[name], based_on: param_doc)
    # mapping param key
    params[param_doc.as] = params.delete(name) if param_doc.as.present?
  end

  def _set_instance_var(param_doc)
    return if (value = params[(key = param_doc.real_name)]).nil?

    instance_variable_set("@#{key}", value)
    _permit_hash_and_array(value) if param_doc.permit?
    _auto_find_by_id(key, value) if @route_path.match?(/\{#{key}\}/) # e.g. "/examples/{id}"
  end

  def _group_params(param_doc)
    return if (value = params[(key = param_doc.real_name.to_sym)]).nil?

    instance_variable_get("@#{param_doc.group}")&.merge!(key => value) ||
        instance_variable_set("@#{param_doc.group}", key => value )
  end

  # If params[:data] == [{..}, {..}], each `{..}` in the array
  #   is an instance of ActionController::Parameters.
  # So, if :data is allowed to permit, it's values should also permit.
  def _permit_hash_and_array(value)
    value.map!(&:permit!) if value.is_a?(Array) && value.first.is_a?(ActionController::Parameters)
  end

  def _auto_find_by_id(key, value)
    whos_id = (key.to_sym == :id ? controller_name : key.to_s.sub('_id', '')).singularize
    model = whos_id.camelize.constantize rescue return
    model_instance = model.find_by(id: value) || Error::Api.not_found! # TODO HACK
    instance_variable_set("@#{whos_id}", model_instance)
  end

  def _set_permitted(params_docs)
    exist_not_permit = params_docs.map(&:not_permit?).any?(&:present?)
    keys = params_docs.map { |p| p.doced_permit? ? p.real_name : nil }.compact
    keys = exist_not_permit ? params_docs.map(&:real_name) - keys : keys
    # @permitted = params.permit(*keys) TODO
    @permitted = params.slice(*keys).to_unsafe_h
  end

  def permitted; @permitted end

  # TODO: performance
  def params_doc
    return [ ] unless (current_api = OpenApi.routes_index[self.class.controller_path])

    self.docs ||= DocConverter.new(OpenApi.docs)
    @route_path = OpenApi::Router.find_path_httpverb_by(self.class.controller_path, action_name).first
    path_doc = docs[current_api][:paths][@route_path]
    # nil check is for skipping this before_action when the action is not doced.
    path_doc&.[](request.method.downcase)&.[](:parameters) || [ ]
  end


  class ValidationFailed < StandardError
    def info; { code: 400, msg: "#{Config.prefix}" + message, http_status: :bad_request }; end
  end
end

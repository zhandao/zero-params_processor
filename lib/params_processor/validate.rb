require 'params_processor/validate/param_obj'

module ParamsProcessor
  module Validate

    private

    # TODO: type support: string integer boolean
    def validate_params
      params_settings.each do |param_setting|
        @_param = ParamObj.new param_setting
        @_input_under_check = params[@_param.name.to_sym]

        it 'is required'                   if it_should_but_not :exist
        it must_be "#{@_param.type}"               if it_is_not :type
        it "has length must be(in) #{@_param.size.join('..')}" if it_has_wrong :size # TODO: [0,1)
        it must_be "#{@_param.is}"            if it_is_unmatched
        it "must match /#{@_param.pattern}/"           if it_is_unmatched :regexp
        it must_in "#{@_param.enum}"             if it_is_not_in :allowable_values
        # TODO: range
      end
    end

    def convert_params_type
      params_settings.each do |param_setting|
        param = ParamObj.new param_setting
        type, name = param.type, param.name.to_sym
        input = params[name]
        params[name] = param.dft if not_exist(input) && !param.dft.nil?
        params[name] =
            case type
              when 'integer'
                input.to_i
              when 'boolean'
                input.to_s.eql?('true') ? true : false
              else; params[name]
            end if params[name].is_a? String
      end
    end

    # -----------

    # 此处为验证逻辑
    def it_is(what = :is)
      current_case = what
      what    = :required if what.eql? :exist
      what    = :enum if what.eql? :allowable_values
      setting = @_param.send what
      return true if not_exist(setting)

      input   = @_input_under_check
      input_s = input.to_s
      return true if !@_param.required? && not_exist(input)

      case current_case
        when :exist
          return !(setting.eql?(true) && not_exist(input))

        when :type
          case @_param.type
            when 'integer'; input_s.match? /^[0-9]*$/
            when 'boolean'; input_s.in? %w[true false]
            else; true
          end

        when :size
          if input.is_a? Array
            input.count >= setting[0] && input.count <= setting[1]
          else
            input_s.length >= setting[0] && input_s.length <= setting[1]
          end

        when :is
          # TODO
          return input_s.match?(/@/)                  if setting.eql? 'email'

        when :allowable_values
          case @_param.type
            when 'integer'; setting.include? input.to_i
            when 'boolean'; setting.map(&:to_s).include? input_s
            else; true
          end

        when :regexp
          return input_s.match? Regexp.new setting

        else
          true
      end
    end

    def it_is_not(what = :is); !it_is what; end
    alias_method :it_should_but_not, :it_is_not
    alias_method :it_is_unmatched,   :it_is_not
    alias_method :it_is_not_in,      :it_is_not
    alias_method :it_has_wrong,      :it_is_not

    def current_api
      OpenApi.apis.each do |api, settings|
        return api if settings[:root_controller].descendants.include? self.class
      end
    end

    def current_path_doc
      $open_apis.dig(current_api, :paths).each do |path, doc|
        # "/api/v1/nested/2/routes/1" will match "/api/v1/nested/.*/routes/.*"
        return doc if request.path.match? Regexp.new(path.gsub(/{[^\/]*}/, '.*'))
      end
    end

    def params_settings
      current_path_doc[request.request_method.downcase][:parameters]
    end

    def it what
      raise ValidateError.new "[#{@_param['name'].to_sym}] ".concat(what)
    end
    module_function :it
    def must_in(setting); "must in #{setting}"; end
    def must_be(setting); "must be #{setting}"; end

    # false.blank? is set to be true in Ruby core blank.rb, it would be a big problem here
    # Tip: use (not_)exist when you wanna know if it have content(not '' / [] / {} ...)
    # Compare with .nil?: .nil? cannot tell you if the obj have content, only return whether it is a NilClass
    def exist(what)
      return true if what.eql? false
      what.present?
    end
    def not_exist(what)
      !exist what
    end
    alias_method :exist?, :exist
    alias_method :not_exist?, :not_exist
  end
end
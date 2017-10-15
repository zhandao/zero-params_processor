require 'params_processor/validate/param_obj'
require 'params_processor/doc_converter'
require 'params_processor/validate/api_doc_loader'

module ParamsProcessor
  module Validate
    include ApiDocLoader

    private

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
        when 'integer' then input_s.match? /^[0-9]*$/
        when 'boolean' then input_s.in? %w[true false]
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
        return input_s.match?(/\A[^@\s]+@[^@\s]+\z/) if setting.eql? 'email'
        true
      when :allowable_values
        case @_param.type
        when 'integer' then setting.include? input.to_i
        # when 'boolean' then setting.map(&:to_s).include? input_s
        else setting.map(&:to_s).include? input_s
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

    def it what
      raise ValidateError.new "`#{@_param['name'].to_sym}` ".concat(what)
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

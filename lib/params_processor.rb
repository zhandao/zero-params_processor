require "params_processor/version"
require 'params_processor/validate'

module ParamsProcessor

  class ValidateError < StandardError
    def info; { code: 400, msg: 'parameter '.concat(message) }; end
  end
end

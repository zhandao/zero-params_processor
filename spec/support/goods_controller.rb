require 'action_controller'

class GoodsController
  include ParamsProcessor

  attr_accessor :params

  def initialize(params = { id: 1, info: 'info' })
    self.params = ActionController::Parameters.new(params || { id: 1, info: 'info' })
  end

  def self.controller_path
    'goods'
  end

  def self.error_cls
    Patches
  end

  def controller_name
    'goods'
  end

  def action_name
    'action'
  end

  def request
    Patches
  end

  module Patches
    extend self

    def method
      'POST'
    end

    def not_found!
      raise ::ParamsProcessor::ValidationFailed
    end
  end
end

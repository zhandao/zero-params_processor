class GoodsController
  include ParamsProcessor

  attr_accessor :params

  def initialize(params = { id: 1, info: 'info' })
    self.params = params
  end

  def self.controller_path
    'goods'
  end

  def action_name
    'action'
  end

  def request
    Patches
  end

  module Patches
    def self.method
      'POST'
    end
  end
end

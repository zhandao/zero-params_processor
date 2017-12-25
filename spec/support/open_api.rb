module OpenApi
  cattr_accessor :paths_index do
    { 'goods' => :zro }
  end

  module Generator
    def self.find_path_httpverb_by(ctrl_path, action)
      ['goods/action', 'post']
    end
  end

  module Temp
    cattr_accessor :id_schema, :info_schema, :id, :info
  end

  class << self
    delegate :id_schema=, :info_schema=, :id=, :info=, to: Temp

    def info_schema
      Temp.info_schema || { type: 'string' }
    end

    def id_schema
      Temp.id_schema || { type: 'integer' }
    end

    def info
      Temp.info || {
          name: :info,
          in: 'query',
          required: false,
          schema: info_schema
      }
    end

    def id
      Temp.id || {
          name: :id,
          in: 'path',
          required: true,
          schema: id_schema
      }
    end

    def json
      {
          openapi: '3.0.0',
          tags: [{ name: :Good }],
          paths: {
              'goods/action': {
                  post: {
                      operationId: :action,
                      tags: [:Good],
                      parameters: [ info, id ]
                  }
              }
          }
      }
    end

    def docs
      { zro: json }
    end
  end
end

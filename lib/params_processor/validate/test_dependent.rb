require 'active_support/hash_with_indifferent_access'

module ParamsProcessor
  module Validate
    # For testing, open this module

    # module OpenApi
    #   def self.apis
    #     {
    #         homepage_api: {
    #             root_controller: Api::V1::BaseController,
    #         }
    #     }
    #   end
    # end

    # For testing, open comment in the last line, set the global variable $open_api

    OPEN_APIS = {
    :homepage_api=>
      {
        "openapi"=>"3.0.0",
        "info"=>
          {
            "title"=>"Zero Rails APIs",
            "description"=> "API documentation of Zero-Rails Application.",
            "contact"=>
              {
                "name"=>"API Support",
                "url"=>"http://www.skippingcat.com",
                "email"=>"x@skippingcat.com"
              },
            "license"=>
              {
                "name"=>"Apache 2.0",
                "url"=>"http://www.apache.org/licenses/LICENSE-2.0.html"
              },
            "version"=>"1.0.0"
          },
        "servers"=>
          [
            {
              "url"=>"http://localhost:2333",
              "description"=>
                "Optional server description, e.g. Main (production) server"
            },
            {
              "url"=>"http://localhost:3332",
              "description"=>
                "Optional server description, e.g. Internal staging server for testing"
            }
          ],
        "security"=>[
          {
            "ApiKeyAuth"=>[]
          }
        ],
        "tags"=>[
          {
            "name"=>"Examples"
          }
        ],
        "paths"=>
          {
            "/api/v1/examples"=>
              {
                "get"=>
                  {
                    "summary"=>"(SUMMARY) this api blah blah ...",
                    "operationId"=>:index,
                    "tags"=>["Examples"],
                    "description"=> "Optional multiline or single-line Markdown-formatted description",
                    "parameters"=>
                      [
                        {
                          "name"=>:id,
                          "in"=>"query",
                          "required"=>true,
                          "description"=>"description<br/>id",
                          "schema"=>
                            {
                              "type"=>"integer",
                              "minLength"=>1,
                              "maxLength"=>2,
                              "enum"=>[0, 1, 2, 3, 4, 5],
                              "minimum"=>0,
                              "exclusiveMinimum"=>true,
                              "maximum"=>5,
                              "pattern"=>"^[0-9]$"
                            }
                        },
                        {
                          "name"=>:done,
                          "in"=>"query",
                          "required"=>true,
                          "description"=>"must be false",
                          "schema"=>{
                            "type"=>"boolean", "enum"=>[false], "default"=>true
                          }
                        },
                        {
                          "name"=>:email_addr,
                          "in"=>"query",
                          "required"=>false,
                          "description"=>"user_email_addr's desc",
                          "schema"=>
                            {
                              "type"=>"string",
                              "minLength"=>3,
                              "default"=>"zero@zero-rails.org"
                            }
                        }
                      ],
                    "responses"=>
                      {
                        "success"=>
                          {
                            "description"=>"success response",
                            "content"=>{
                              "application/json"=>{}
                            }
                          },
                        "404"=>{
                          "description"=>"can not find the name"
                        },
                        "400"=>{
                          "description"=>"param validation failure"
                        }
                      },
                    "security"=>[{"ApiKeyAuth"=>[]}]
                  }
              }
          },
        "components"=>
          {
            "securitySchemes"=>
              {
                "ApiKeyAuth"=>
                  {
                    "type"=>"apiKey", "name"=>"server_token", "in"=>"query"
                  }
              }

          }
      },
    :user_api=>
      {
        "openapi"=>"3.0.0",
        "info"=>{
          "title"=>"User", "version"=>"0.0.1"
        },
        "tags"=>[
          {
            "name"=>"Users"
          }
        ],
        "paths"=>
          {
            "/api/v1/users"=>
              {
                "get"=>
                  {
                    "summary"=>"",
                    "operationId"=>:index,
                    "tags"=>["Users"],
                    "parameters"=>
                      [
                        {
                          "name"=>:id,
                          "in"=>"query",
                          "required"=>true,
                          "schema"=>
                            {
                              "type"=>"integer",
                              "minLength"=>1,
                              "maxLength"=>2,
                              "enum"=>[0, 1, 2, 3, 4, 5],
                              "minimum"=>0,
                              "exclusiveMinimum"=>true,
                              "maximum"=>5,
                              "pattern"=>"^[0-9]$"
                            }
                        }
                      ]
                  }
              }
          }
      }
  }

    # $open_apis = HashWithIndifferentAccess.new(OPEN_APIS)
  end
end
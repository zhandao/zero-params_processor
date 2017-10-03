require 'active_support/hash_with_indifferent_access'

module ParamsProcessor
  class DocConverter < HashWithIndifferentAccess
    def initialize(inhert_hash)
      super(inhert_hash)
      convert
    end

    def convert
      self.each do |api, api_doc|
        api_doc[:paths].each do |path, path_doc|
          path_doc.each do |method, action_doc|
            # 将 form-data 提到 parameters，方便统一访问接口
            form = action_doc[:requestBody]&.[](:content)&.[]("multipart/form-data")
            if form.present?
              required = form[:schema][:required] || [ ]
              form[:schema][:properties].each do |name, prop_schema|
                (action_doc[:parameters] ||= [ ]) << {
                    name: name,
                    in: 'form',
                    required: required.include?(name),
                    schema: {
                        type: prop_schema[:type],
                    }
                }
              end
            end
          end
        end
      end
    end
  end
end
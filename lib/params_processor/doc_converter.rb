require 'active_support/hash_with_indifferent_access'

module ParamsProcessor
  class DocConverter < HashWithIndifferentAccess
    def initialize(inhert_hash)
      super(inhert_hash)
      convert
    end

    def fill_with_ref(who, ref_to)
      if who.key? '$ref'
        ref_name = who.delete('$ref').split('/').last
        who.merge! @api_components.fetch(ref_to).fetch(ref_name)
      end
    end

    def convert
      self.each do |api, api_doc|
        @api_components = api_doc[:components]
        api_doc[:paths].each do |path, path_doc|
          path_doc.each do |method, action_doc|
            # 将 Reference Obj 填充进来
            # param ref
            action_doc[:parameters]&.each do |param|
              fill_with_ref param, :parameters

              # schema ref
              # TODO: Support nested scanning
              fill_with_ref param[:schema], :schemas if param[:schema].present?
            end

            # body ref
            request_body = action_doc[:requestBody]
            fill_with_ref request_body, :requestBodies if request_body.present?
            request_body&.[](:content)&.each do |media, media_doc|
              media_doc.each do |mtype, mtype_doc|
                fill_with_ref mtype_doc, :schemas
              end
            end

            # response ref
            action_doc[:responses]&.each do |resp, resp_doc|
              fill_with_ref resp_doc, :responses
              resp_doc&.[](:content)&.each do |media, media_doc|
                media_doc.each do |mtype, mtype_doc|
                  fill_with_ref mtype_doc, :schemas
                end
              end
            end

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
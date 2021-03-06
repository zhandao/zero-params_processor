# frozen_string_literal: true

require 'active_support/hash_with_indifferent_access'

module ParamsProcessor
  class DocConverter < HashWithIndifferentAccess
    def initialize(inhert_hash = { })
      super(inhert_hash)
      convert
    end

    def fill_with_ref(who, ref_to)
      return unless who.key? '$ref'
      ref_name = who.delete('$ref').split('/').last
      who.merge! @api_components.fetch(ref_to).fetch(ref_name)
    end

    # TODO: refactor
    def convert
      return if blank?
      self.each do |_api, api_doc|
        @api_components = api_doc[:components]
        api_doc[:paths].each do |_path, path_doc|
          path_doc.each do |_method, action_doc|
            # 将 Reference Obj 填充进来
            # body ref
            request_body = action_doc[:requestBody]
            fill_with_ref request_body, :requestBodies if request_body.present?
            request_body&.[](:content)&.each do |_media, media_doc|
              media_doc.each do |mtype, mtype_doc|
                fill_with_ref mtype_doc, :schemas if mtype == 'schema'
              end
            end

            # 将 form-data 提到 parameters，方便统一访问接口
            # 在 param ref 处理之前上提，使后续可以一并将 properties 中的 schma 进行处理
            form = action_doc[:requestBody]&.[](:content)
            form = form['multipart/form-data'] || form['application/json'] if form # TODO
            if form.present?
              required = form[:schema][:required] || [ ]
              permit = form[:schema][:permit] ? true : false
              form[:schema][:properties]&.each do |name, prop_schema|
                (action_doc[:parameters] ||= [ ]) << {
                    'name' => name,
                    'in' => 'form',
                    'required' => required.include?(name),
                    'schema' => prop_schema.reverse_merge!(permit: permit),
                }
              end
            end


            # param ref
            action_doc[:parameters]&.each do |param|
              fill_with_ref param, :parameters

              # schema ref
              # TODO: Support nested scanning
              fill_with_ref param[:schema], :schemas if param[:schema].present?
            end


            # response ref
            action_doc[:responses]&.each do |_resp, resp_doc|
              fill_with_ref resp_doc, :responses
              resp_doc&.[](:content)&.each do |_media, media_doc|
                media_doc.each do |_mtype, mtype_doc|
                  fill_with_ref mtype_doc, :schemas
                end
              end
            end
          end
        end
      end
    end
  end
end

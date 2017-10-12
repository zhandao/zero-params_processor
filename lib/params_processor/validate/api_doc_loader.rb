module ParamsProcessor
  module Validate
    module ApiDocLoader
      private

      def find_match?(str_array, src)
        str_array.each { |str| return true if src.match? str.delete('Doc') }
        false
      end

      def current_api(find_doc_other_place = false)
        OpenApi.apis.each do |api, settings|
          is_descendant = settings[:root_controller].descendants.include? self.class
          if find_doc_other_place
            next if is_descendant
            find_match? settings[:root_controller].descendants.map(&:to_s), self.class.name
          else
            is_descendant
          end and return api
        end
        nil
      end

      def open_apis
        $_open_apis ||= DocConverter.new $open_apis
      end

      def current_path_doc(find_doc_other_place = false)
        open_apis.dig(current_api(find_doc_other_place), :paths)&.each do |path, doc|
          is_same_number_of_slashes = request.path.scan('/') == path.scan('/')
          # "/api/v1/nested/2/routes/1" will match "/api/v1/nested/.*/routes/.*"
          is_match_pattern = request.path.match? Regexp.new(path.gsub(/{[^\/]*}/, '.*'))
          return doc if is_same_number_of_slashes && is_match_pattern
        end
      end

      def params_settings
        path_doc = current_path_doc(true) || current_path_doc
        path_doc[request.method.downcase][:parameters]
      end
    end
  end
end

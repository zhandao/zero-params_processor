module ParamsProcessor
  module DocLoader

    private

    def find_match?(str_array, src)
      str_array.each { |str| return true if src.match? str.sub('Doc', '') }
      false
    end

    def current_api(find_doc_other_place = false)
      OpenApi::Config.docs.each do |api, settings|
        is_descendant = settings[:root_controller].descendants.include? self.class
        (if find_doc_other_place
          next if is_descendant
          find_match? settings[:root_controller].descendants.map(&:to_s), self.class.name
        else
          is_descendant
        end) and return api
      end
      nil
    end

    def open_apis
      $_open_apis ||= DocConverter.new $open_apis
    end

    def path_doc(find_doc_other_place = false)
      open_apis.dig(current_api(find_doc_other_place), :paths)&.each do |path, doc|
        same_number_of_slashes = request.path.scan('/') == path.scan('/')
        next unless same_number_of_slashes

        # "/api/v1/nested/2/routes/1" will match "/api/v1/nested/.*/routes/.*"
        match_pattern = request.path.match? Regexp.new(path.dup.gsub(/{[^\/]*}/, '.*'))
        next unless match_pattern

        match_last_word = request.path.split('/').last == path.split('/').last
        return doc if match_last_word
        @path_doc = doc
      end
    end

    def params_doc
      doc = path_doc(true) || path_doc || @path_doc
      doc[request.method.downcase]&.[](:parameters) || [ ]
    end
  end
end

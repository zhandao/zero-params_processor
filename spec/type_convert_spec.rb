require 'spec_helper'
require 'type_convert_helper'

RSpec.describe ParamsProcessor::TypeConvert do
  type :integer do
    given 1, expect: 1
    given -1, expect: -1
    given '1', expect: 1
    given '-1', expect: -1
    given 'a', expect: 0
    given '1.5', expect: 1
  end


  type :number do
    given 1, expect: 1.0
    given 1.0, expect: 1.0
    given -1, expect: -1.0
    given '0', expect: 0.0
    given 'a', expect: 0.0
  end


  type :boolean do
    given 1, expect: true
    given 0, expect: false
    given '1', expect: true
    given '0', expect: false
    given true, expect: true
    given false, expect: false
    given 'true', expect: true
    given 'false', expect: false
  end


  type :string do
    given 'a', expect: 'a'
    given 1, expect: '1'

    format :date do
      given '2017-12-25', expect: Date.parse('2017-12-25')
      given '12/25, 2017', if: { pattern: '%m/%d, %Y' }, expect: Date.strptime('12/25, 2017', '%m/%d, %Y')
    end

    format 'date-time' do
      given '2017-12-25 17:24', expect: DateTime.parse('2017-12-25 17:24')
      given '12/25, 2017 (17:24:26)', if: { pattern: '%m/%d, %Y (%H:%M:%S)' },
            expect: DateTime.strptime('12/25, 2017 (17:24:26)', '%m/%d, %Y (%H:%M:%S)')
    end
  end


  type :array do
    given [], expect: []
    given [nil], expect: [nil]
  end


  type :object do
    given ({}), expect: {}
    given ({ id: 1 }), expect: { id: 1 }
  end


  type :other do
    given 'a', 'returns itself', expect: 'a'
  end

  # TODO: combined
end

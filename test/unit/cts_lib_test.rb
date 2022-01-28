require 'test_helper'
require 'cts'

class CTSLibTest < ActiveSupport::TestCase
  context 'urn tests' do
    setup do
    end

    teardown do
    end

    should 'be edition' do
      if defined?(EXIST_HELPER_REPO)
        type = CTS::CTSLib.versionTypeForUrn('perseus', 'urn:cts:greekLang:tlg0012.tlg001.perseus-grc1').to_s
        Rails.logger.info("Type = #{type}")
        assert_equal('edition', type)
      end
    end
  end
end

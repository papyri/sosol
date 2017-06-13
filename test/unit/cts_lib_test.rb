require 'test_helper'
require 'cts'

class CTSLibTest < ActiveSupport::TestCase
  
  context "urn tests" do
    setup do
    end
    
    teardown do
    end
    
    should "be edition" do
      if defined?(EXIST_HELPER_REPO)
       type = CTS::CTSLib.versionTypeForUrn('perseus','urn:cts:greekLang:tlg0012.tlg001.perseus-grc1').to_s
       Rails.logger.info("Type = #{type}")
       assert type == 'edition'
      end
    end

    should "validate and parse and include non cts" do
      raw_uris = { 'urn:cts:greekLit:tlg0012.tlg001.perseus-grc1' => { '1.1' => 1, '2.1' => 1},
                   'urn:cts:greekLit:tlg0012.tlg001' => { '1.1' => 1, '2.1' => 1},
                   'urn:cts:thisisnonsense' => {},
                   'http://data.perseus.org/urn:cts:greekLit:tlg0012.tlg002.perseus-grc1' => { },
                   'http://someotherurl.org/abc/def' => {'any old junk' => 1 },
                   'urn:cts:greekLit:tlg0013.tlg001.perseus-grc1:1' => { '1.1' => 1 },
                   'urn:cts:greekLit:tlg0014.tlg001.perseus-grc1:1.1' => { }
                 } 
      expected = [ 'urn:cts:greekLit:tlg0012.tlg001.perseus-grc1',
                   'urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1',
                   'urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:2.1',
                   'urn:cts:greekLit:tlg0012.tlg001',
                   'urn:cts:greekLit:tlg0012.tlg001:1.1',
                   'urn:cts:greekLit:tlg0012.tlg001:2.1',
                   'urn:cts:greekLit:tlg0012.tlg002.perseus-grc1',
                   'urn:cts:greekLit:tlg0013.tlg001.perseus-grc1',
                   'urn:cts:greekLit:tlg0013.tlg001.perseus-grc1:1.1.1',
                   'urn:cts:greekLit:tlg0014.tlg001.perseus-grc1',
                   'urn:cts:greekLit:tlg0014.tlg001.perseus-grc1:1.1',
                   'http://someotherurl.org/abc/def' 
                 ]     
      assert_equal expected.sort, CTS::CTSLib.validate_and_parse(raw_uris).sort
    end
    
  end
end

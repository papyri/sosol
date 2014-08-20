require 'test_helper'
require 'xml_helper'

class XmlHelperTest < ActiveSupport::TestCase
  
  context "xml tests" do
    setup do
    end
    
    teardown do
    end
    
    should "parse bare elem bare atts" do
      xmlstr = '<root><elem attone="abc" atttwo="def" attthree="ghi"/><elem attone="abc2"/></root>'
       atts = XmlHelper::parseattributes(xmlstr, { 'elem' => ['attone', 'atttwo']})
       assert_not_nil atts['elem']
       assert_equal 2, atts['elem'].length 
       assert_not_nil atts['elem'][0]['attone']
       assert_equal 'def', atts['elem'][0]['atttwo']
       assert_equal 'abc2', atts['elem'][1]['attone']
       assert_nil atts['elem'][1]['atttwo']
    end

    should "parse ns elem bare atts" do
      xmlstr = '<root><elem xmlns="http://example.org" attone="abc" atttwo="def" attthree="ghi"/><elem attone="abc2"/></root>'
       atts = XmlHelper::parseattributes(xmlstr, { 'http://example.org elem' => ['attone', 'atttwo']})
       assert_not_nil atts['http://example.org elem']
       assert_equal 1, atts['http://example.org elem'].length 
       assert_equal 'abc', atts['http://example.org elem'][0]['attone']
    end

    should "parse ns elem ns atts" do
      xmlstr = '<root><elem xmlns="http://example.org" xmlns:pfx="http://example2.org" pfx:attone="abc" attone="def" attthree="ghi"/><elem attone="abc2"/></root>'
       atts = XmlHelper::parseattributes(xmlstr, { 'http://example.org elem' => ['http://example2.org attone', 'attthree']})
       assert_not_nil atts['http://example.org elem']
       assert_equal 1, atts['http://example.org elem'].length 
       assert_equal 'abc', atts['http://example.org elem'][0]['http://example2.org attone']
       assert_equal 'ghi', atts['http://example.org elem'][0]['attthree']
    end
  end
end

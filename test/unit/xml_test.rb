require 'test_helper'

class XmlTest < ActiveSupport::TestCase
  
  def setup
    @xml = '<abc><bait/></abc>'
    @xpath = "/abc/a[@a='a']/b[@b='b']/c[@c1='c1'][@c2='c2']"
    
    @doc = REXML::Document.new @xml
    @element = REXML::Document.new(@xml).root.elements['//abc']
    @formatter = REXML::Formatters::Default.new

    assert @doc.class == REXML::Document, 'could not create xml document from ' + @xml
    assert @element.class == REXML::Element, 'could not create xml element from ' + @xml
  end
  
  def test_rexml_xpath_fully_qualified_and_simple
    
    assert REXML::XPath::fully_qualified_and_simple?("/abc/a[@a='a']/b[@b='b']/c[@c1='c1'][@c2='c2']"), 'should be an accepted path pointing to an element'
    assert REXML::XPath::fully_qualified_and_simple?("/abc/a[@a='a']/b[@b='b']/c[@c1='c1'][@c2='c2']"), 'should be an accepted path pointing to an attribute'

    assert !REXML::XPath::fully_qualified_and_simple?("abc/a[@a='a']/b[@b='b']/c[@c1='c1'][@c2='c2']"), 'does not start from root element'
    assert !REXML::XPath::fully_qualified_and_simple?("//abc/a[@a='a']/b[@b='b']/c[@c1='c1'][@c2='c2']"), 'does not start from root element'
    #FIXME?: assert !REXML::XPath::fully_qualified_and_simple?("/abc/a[@a='a']/b[@b='b']/c[@c1='c1' && @c2='c2']"), 'contains logical operation'
    assert !REXML::XPath::fully_qualified_and_simple?("/abc::a"), 'contains child reference'
    assert !REXML::XPath::fully_qualified_and_simple?("/abc/a/b/c/text()"), 'contains text reference'
    assert !REXML::XPath::fully_qualified_and_simple?("/abc/*"), 'contains * reference'
    assert !REXML::XPath::fully_qualified_and_simple?("Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch"), '?!'

  end
  
  def test_rexml_bulldozepath

    assert REXML::XPath::fully_qualified_and_simple?(@xpath), 'xpath' + @xpath + ' doesn\'t meet the need of this test scenario'
    assert REXML::XPath::fully_qualified_and_simple?(@xpath + '/@c3'), 'xpath' + @xpath + ' doesn\'t meet the need of this test scenario'
    
    elements = []    
    elements[0] = @doc.bulldozePath @xpath
    elements[1] = @doc.bulldozePath @xpath + '/@c3'
    elements[2] = @element.bulldozePath @xpath
    elements[3] = @element.bulldozePath @xpath + '/@c3'

    elements.each { |element|

      assert_equal element.class, REXML::Element, 'xpath should return the tip element of the xpath that has been hewn into the document'
      assert_equal 'c', element.name
      assert_equal 'c1', element.attributes['c1']
      assert_equal 'c2', element.attributes['c2']
      assert_equal 'b', element.parent.name
      assert_equal 'b', element.parent.attributes['b']
      assert_equal 'a', element.parent.parent.name
      assert_equal 'a', element.parent.parent.attributes['a']
      assert_equal 'abc', element.parent.parent.parent.name
      assert_equal REXML::Element, element.elements[@xpath].class, 'newly bulldozed xpath should be retrievable afterwards'

      xmlOut = ''
      @formatter.write element.root, xmlOut
      assert_equal "<abc><bait/><a a='a'><b b='b'><c c1='c1' c2='c2' c3='...'/></b></a></abc>", xmlOut, 'wrong xml formatting'

    }
  end

end

# jruby -I test test/unit/xml_test.rb

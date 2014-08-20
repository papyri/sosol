require 'nokogiri'
module XmlHelper


  def self.getDomParser(doc,parser)
     if (parser == 'nokogiri')
         NokogiriDomParser.new(doc)
     else
         #REXML is the default for now
         REXMLDomParser.new(doc)
     end
  end
  # parse attributes from elements in a document 
  # @param [Object] docstr the document as a string
  # @param [Hash] atts Hash of name/value pairs, 
  #                    name is the fully qualified element name
  #                    value is an array of fully qualified attributes 
  # @return [Hash] a Hash of name/value pairs. the name is the attribute the
  #                    name is the fully qualified element name
  #                    value is an array of hashes for each element with
  #                    matching attributes found where the key is the
  #                    fully qualified attribute name and the value is the
  #                    value of the attribute or nil if it wasn't set 
  #                    or was empty
  def self.parseattributes(docstr,atts)
    parser = AttributeParser.new(atts)
    Nokogiri::XML::SAX::Parser.new(parser).parse(docstr)
    parser.my_return
  end

  class REXMLDomParser
    attr_accessor :my_doc, :my_root

    def initialize(doc)
      @my_doc = doc
    end

    # parses the supplied text into a Document
    # and returns the root element
    # @param [String] docstr the string to be parsed
    # @param [Boolean] disableSafe flag to indicate if safe options should 
    #                              be disabled (only for trusted content)
    # @return [Object] the root element                   
    def parseroot(disableSafe=false)
      @my_root = REXML::Document.new(@my_doc).root
    end

    def all(elem,xpath,nsmap={})
      REXML::XPath.match(elem,xpath,nsmap)
    end

    def first(elem,xpath,nsmap={})
      REXML::XPath.match(elem,xpath,nsmap).first()
    end

    def add_child_strip_ns(elem,child)
      child.namespace = nil 
      elem.add_child(child)
    end

    def make_elem(elem_name,ns=nil)
      REXML::Element.new(elem_name,ns)
    end

    def make_text_elem(elem_name,ns=nil,text='')
      elem = make_elem(elem_name,ns)
      elem.add_text(text)
      return elem
    end

    def insert_before(elem,xpath,child)
      elem.insert_before(xpath,child)
    end

    def add_child(elem,child)
      elem.add_element(child)
    end

    def add_child_strip_ns(elem,child)
      namespace = child.namespace
      if (namespace && ! namespace.nil?)
        child.delete_namespace(namespace)
      end
      elem.add_element(child)
    end

    def delete_child(elem,child_name,nsmap = {})
      elem.delete_element(child_name)
    end

    def to_s(elem = nil)
      if (elem.nil?)
        elem = @my_root
      end
      formatter = PrettySsime.new
      formatter.compact = true
      formatter.width = 2**32
      modified_xml_content = ''
      formatter.write elem, modified_xml_content
      modified_xml_content
    end
  end

  class NokogiriDomParser
    attr_accessor :my_doc, :my_root

    def initialize(doc)
      @my_doc = doc
    end

    # parses the supplied text into a Document
    # and returns the root element
    # @param [String] docstr the string to be parsed
    # @param [Boolean] disableSafe flag to indicate if safe options should 
    #                              be disabled (only for trusted content)
    # @return [Object] the root element                   
    def parseroot(disableSafe=false)
      @my_root = Nokogiri::XML::Document.parse(@my_doc){ |config|
        if (disableSafe)
          config.noblanks
        else
          config.nonet.noblanks
        end
      }.root
    end

    def all(elem,xpath,nsmap={})
      elem.xpath(xpath,nsmap)
    end

    def first(elem,xpath,nsmap={})
      elem.xpath(xpath,nsmap).first()
    end

    def delete_child(elem,child)
      child.remove()
    end

    def add_child(elem,child)
      elem.add_child(child)
    end

    def add_child_strip_ns(elem,child)
      child.namespace = nil 
      elem.add_child(child)
    end

    def make_elem(elem_name,ns=nil)
      elem  = Nokogiri::XML::Node.new(elem_name,@my_root)
      unless  (ns.nil?)
        elem.namespace = ns
      end
      elem
    end

    def make_text_elem(elem_name,ns=nil,text='')
      elem = make_elem(elem_name,ns)
      elem.content = text
      return elem
    end

    def insert_before(elem,xpath,child)
      node = elem.xpath(xpath)
      node.before(child)
    end

    def to_s(elem = nil)
      if (elem.nil?)
        elem = @my_root
      end
      elem.to_xml(:indent => 2) 
    end
  end

  class AttributeParser < Nokogiri::XML::SAX::Document

    attr_accessor :my_request, :my_return
    attr_writer :my_return
    attr_reader :my_return
  
    def initialize(atts)
      @my_request = atts
      @my_return = {}
      @my_request.keys.each do |name|
        @my_return[name] = []
      end
    end

  
    def start_element_namespace(elem, attributes = [], prefix=nil, uri=nil, ns=[])
      elem_lookup = (uri.nil? || uri == '') ? elem : uri + " " + elem
      if (@my_request[elem_lookup])
        ns_atts = {}
        attributes.each do |att|
          att_lookup = (att.uri.nil? || att.uri == '') ? att.localname : att.uri + " " + att.localname
          ns_atts[att_lookup] = att.value
        end
        ret = {}
        @my_request[elem_lookup].each do |att|
          if (ns_atts[att] && ns_atts[att] != '')
            ret[att] = ns_atts[att]
          else 
            ret[att] = nil
          end
        end
        @my_return[elem_lookup] << ret
      end
    end
  end
end

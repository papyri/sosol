module XmlHelper

  # parses the supplied text into a Document
  # and returns the root element
  # @param [String] docstr the string to be parsed
  # @param [Boolean] disableSafe flag to indicate if safe options should 
  #                              be disabled (only for trusted content)
  # @return [Object] the root element                   
  def self.parseroot(docstr,disableSafe=false)
    Nokogiri::XML::Document.parse(docstr){ |config|
        if (disableSafe)
          config.noblanks
        else
          config.nonet.noblanks
        end
    }.root
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

  def self.all(doc,xpath,nsmap={})
    doc.xpath(xpath,nsmap)
  end

  def self.first(doc,xpath,nsmap={})
    doc.xpath(xpath,nsmap).first()
  end

  # @param [String] attribute local name
  def self.attribute_local_text(elem,att)
    elem.attributes[att].value()
  end

  def self.delete_self(elem)
    elem.remove()
  end

  def self.add_child(elem,child)
    elem.add_child(child)
  end

  def self.add_child_strip_ns(elem,child)
    child.namespace = nil 
    elem.add_child(child)
  end

  def self.to_s(doc)
    doc.to_xml(:indent => 2) 
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

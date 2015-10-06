module JRubyXML
  class ParseError < ::StandardError
    attr_accessor :line, :column
    
    def initialize(line, column)
      @line = line
      @column = column
    end
    
    def to_str
      # message can have XML elements in it that we want escaped
      # move to view?
      return "Error at line #{@line}, column #{@column}: #{CGI.escapeHTML(self.message)}"
    end
  end
  
  class ParseErrorHandler
    include Java::org.xml.sax.ErrorHandler
    
    # Errors will be SAXParseException objects
    def fatalError(e)
      raise ParseError.new(e.getLineNumber, e.getColumnNumber), e.getMessage
    end
    
    def error(e)
      fatalError(e)
    end
    
    def warning(e)
    end
  end
  
  class TransformErrorListener
    include Java::javax.xml.transform.ErrorListener
    
    # Errors will be TransformerException objects
    def fatalError(e)
      locator = e.getLocator()
      raise ParseError.new(locator.getLineNumber, locator.getColumnNumber), 
        e.getMessage
    end
    
    def error(e)
      fatalError(e)
    end
    
    def warning(e)
    end
  end
  
  class TransformMessageListener < Java::net.sf.saxon.event.SequenceWriter
    
    def write(node)
      unless defined? @messages
        @messages = []
      end
      @messages <<  node.getStringValue()
    end
    
    def get_messages()
      return @messages
    end
  end
    
  # http://iso-relax.sourceforge.net/JARV/JARV.html
  class JARVValidator
    include Singleton
    
    attr_reader :verifier_factory, :schema
    
    def validate(input_source_xml_stream)
      verifier = @schema.newVerifier()
      verifier.setErrorHandler(ParseErrorHandler.new())
      verifier.verify(input_source_xml_stream)
    end
  end
  
  class TEIAValidator < JARVValidator
    def initialize
      @verifier_factory = 
        org.iso_relax.verifier.VerifierFactory.newInstance(
          "http://relaxng.org/ns/structure/1.0")
      @schema = verifier_factory.compileSchema(
        "#{Rails.root}/data/templates/tei-xl.rng")
    end
  end
  
  class TEIAPSGValidator < JARVValidator
    def initialize
      @verifier_factory = 
        org.iso_relax.verifier.VerifierFactory.newInstance(
          "http://relaxng.org/ns/structure/1.0")
      @schema = verifier_factory.compileSchema(
        "#{Rails.root}/data/templates/tei-xl-psg.rng")
    end
  end

 class RDFValidator < JARVValidator
    def initialize
      @verifier_factory = 
        org.iso_relax.verifier.VerifierFactory.newInstance(
          "http://relaxng.org/ns/structure/1.0")
      @schema = verifier_factory.compileSchema(
    "http://www.w3.org/TR/REC-rdf-syntax/rdfxml.rng")
    end
  end 
  
  class EpiDocP5Validator < JARVValidator
    def initialize
      @verifier_factory = 
        org.iso_relax.verifier.VerifierFactory.newInstance(
          "http://relaxng.org/ns/structure/1.0")
      @schema = verifier_factory.compileSchema(
        "http://www.stoa.org/epidoc/schema/8.16/tei-epidoc.rng")
    end
  end

  class EpiDocP4Validator < JARVValidator
    def initialize
      @verifier_factory = 
        org.iso_relax.verifier.VerifierFactory.newInstance(
          "http://www.w3.org/XML/1998/namespace")
      @schema = verifier_factory.compileSchema(
        "http://www.stoa.org/epidoc/dtd/6/tei-epidoc.dtd")
    end
  end
  
  class HGVEpiDocValidator < JARVValidator
    def initialize
      @verifier_factory =
        org.iso_relax.verifier.VerifierFactory.newInstance(
          "http://relaxng.org/ns/structure/1.0")
      @schema = verifier_factory.compileSchema(
        "http://www.stoa.org/epidoc/schema/8.13/tei-epidoc.rng")
    end
  end

  class PerseusTreebankValidator < JARVValidator
    def initialize
    @verifier_factory = 
        org.iso_relax.verifier.VerifierFactory.newInstance(
          "http://www.w3.org/2001/XMLSchema")
      @schema = verifier_factory.compileSchema(
        "http://nlp.perseus.tufts.edu/syntax/treebank/treebank-1.6.xsd")
    end
  end
  
  class AlpheiosAlignmentValidator < JARVValidator
    def initialize
    @verifier_factory = 
        org.iso_relax.verifier.VerifierFactory.newInstance(
          "http://www.w3.org/2001/XMLSchema")
      @schema = verifier_factory.compileSchema(
        "http://svn.code.sf.net/p/alpheios/code/xml_ctl_files/schemas/trunk/aligned-text.xsd")
    end
  end
  
  
   class SimpleMarkdownCiteValidator < JARVValidator
    def initialize
    @verifier_factory = 
        org.iso_relax.verifier.VerifierFactory.newInstance(
          "http://relaxng.org/ns/structure/1.0")
      @schema = verifier_factory.compileSchema(
        "#{Rails.root}/data/templates/smdcite.rng")
    end
  end
  
  class NamespaceContext
    include javax.xml.namespace.NamespaceContext
    
    def initialize(root_node_attribute_hash)
      @prefixes = {
        javax.xml.XMLConstants.const_get('DEFAULT_NS_PREFIX') => 
          javax.xml.XMLConstants.const_get('NULL_NS_URI'),
        javax.xml.XMLConstants.const_get('XML_NS_PREFIX') => 
          javax.xml.XMLConstants.const_get('XML_NS_URI'),
        javax.xml.XMLConstants.const_get('XMLNS_ATTRIBUTE') =>
          javax.xml.XMLConstants.const_get('XMLNS_ATTRIBUTE_NS_URI'),
        "dcterms" =>
          "http://purl.org/dc/terms/",
        "dces" => 
          "http://purl.org/dc/elements/1.1/"
      }
      root_node_attribute_hash.each_pair do |attribute_name, uri|
        if attribute_name =~ /^xmlns:/
          namespace = attribute_name.split(':').last
          if (!@prefixes[namespace])
            @prefixes[namespace] = uri
          end
        elsif attribute_name == 'xmlns'
          @prefixes[javax.xml.XMLConstants.const_get('DEFAULT_NS_PREFIX')] = uri
        end
      end
    end
    
    def getNamespaceURI(prefix)
      return @prefixes[prefix]
    end
  end

  class << self
    def input_source_from_string(input_string)
      org.xml.sax.InputSource.new(java.io.StringReader.new(input_string))
    end
    
    def stream_from_string(input_string)
      javax.xml.transform.stream.StreamSource.new(
        java.io.StringReader.new(input_string))
    end

    def stream_from_file(input_file)
      javax.xml.transform.stream.StreamSource.new(input_file)
    end
    
    def document_from_string(input_string, namespace_aware = false)
      dom_factory = javax.xml.parsers.DocumentBuilderFactory.newInstance()
      dom_factory.setNamespaceAware(namespace_aware)
      builder = dom_factory.newDocumentBuilder()
      document = builder.parse(input_source_from_string(input_string))
    end
    
    def xpath_from_string(input_string, namespace_context = nil)
      xpath_factory = javax.xml.xpath.XPathFactory.newInstance()
      xpath = xpath_factory.newXPath()
      unless namespace_context.nil?
        xpath.setNamespaceContext(namespace_context)
      end
      xpath_expression = xpath.compile(input_string)
    end
    
    def named_node_map_to_hash(named_node_map)
      if named_node_map.nil?
        return nil
      else
        result_hash = {}
        0.upto(named_node_map.getLength() - 1) do |i|
          item = named_node_map.item(i)
          result_hash[item.getNodeName()] = item.getNodeValue()
        end
        return result_hash
      end
    end
    
    def xpath_result_to_array(xpath_result)
      # xpath_result is a org.w3c.dom.NodeList
      xpath_results = []
      0.upto(xpath_result.getLength() - 1) do |i|
        item = xpath_result.item(i)
        xpath_results << {
            :name => item.getNodeName(),
            :value => item.getNodeValue(),
            :attributes => named_node_map_to_hash(item.getAttributes())
          }
      end
      return xpath_results
    end
    
    def get_xpath_namespace_context(document)
      root_xpath = xpath_from_string('/*')
      document_root = xpath_result_to_array(root_xpath.evaluate(document,
        javax.xml.xpath.XPathConstants.const_get('NODESET'))).first
      return NamespaceContext.new(document_root[:attributes])
    end

    def apply_xpath(input_document_string, input_xpath_string, namespace_aware = false)
      document = document_from_string(input_document_string, namespace_aware)
      xpath = xpath_from_string(input_xpath_string,
        namespace_aware ? get_xpath_namespace_context(document) : nil)
      
      xpath_result = xpath.evaluate(document, 
        javax.xml.xpath.XPathConstants.const_get('NODESET'))
      return xpath_result_to_array(xpath_result)
    end

    def apply_xsl_transform(xml_stream, xsl_stream, parameters = {})
      message_writer = java.io.StringWriter.new()
      transformer = get_transformer(xsl_stream)
      transformer.setErrorListener(TransformErrorListener.new())
      transformer.setMessageEmitter(TransformMessageListener.new(Java::net.sf.saxon.event.PipelineConfiguration.new(Java::net.sf.saxon.Configuration.new())))
      parameters.each do |parameter, value|
        # saxon 9.x sees a bit pickier here and throws an error
        # on params with nil values  - check for them here for backwards
        # compatibility because calling code might send nil values
        unless value.nil?
          transformer.setParameter(parameter.to_s, value)
        end
      end
      
      string_writer = java.io.StringWriter.new()
      result = javax.xml.transform.stream.StreamResult.new(string_writer)
      
      begin
        transformer.transform(xml_stream, result)
        return string_writer.toString()
      rescue NativeException => java_exception
        # For some reason Saxon doesn't seem to use the set ErrorListener
        # so we have to do all this
        xpath_exception = java_exception.cause()
        if xpath_exception.class == Java::NetSfSaxonTrans::XPathException
          sax_parse_exception = xpath_exception.getCause()
          Rails.logger.info sax_parse_exception.class
          if sax_parse_exception.class == Java::OrgXmlSax::SAXParseException
            raise ParseError.new(
                sax_parse_exception.getLineNumber,
                sax_parse_exception.getColumnNumber),
              sax_parse_exception.getMessage
          else
            raise "Unknown XPath error during SAXON transform"
          end
        else
          raise "Unknown error during SAXON transform #{xpath_exception} (#{xpath_exception.class})"
        end
      end
      
      return nil
    end
    
    # a transformation which catches xslt transform messages
    # and returns them with the transformed content
    def apply_xsl_transform_catch_messages(xml_stream, xsl_stream, parameters = {})
      message_listener = TransformMessageListener.new()
      transformer = get_transformer(xsl_stream)
      transformer.setErrorListener(TransformErrorListener.new())
      transformer.setMessageEmitter(message_listener)
      parameters.each do |parameter, value|
        unless value.nil?
          # saxon 9.x sees a bit pickier here and throws an error
          # on params with nil values  - check for them here for backwards
          # compatibility because calling code might send nil values
          transformer.setParameter(parameter.to_s, value)
        end
      end
      
      string_writer = java.io.StringWriter.new()
      result = javax.xml.transform.stream.StreamResult.new(string_writer)
      
      begin
        transformer.transform(xml_stream, result)
        return {
          :content => string_writer.toString(),
          :messages => message_listener.get_messages() }
      rescue NativeException => java_exception
        # For some reason Saxon doesn't seem to use the set ErrorListener
        # so we have to do all this
        xpath_exception = java_exception.cause()
        if xpath_exception.class == Java::NetSfSaxonTrans::XPathException
          sax_parse_exception = xpath_exception.getCause()
          Rails.logger.info sax_parse_exception.class
          if sax_parse_exception.class == Java::OrgXmlSax::SAXParseException
            raise ParseError.new(
                sax_parse_exception.getLineNumber,
                sax_parse_exception.getColumnNumber),
              sax_parse_exception.getMessage
          else
            raise "Unknown XPath error during SAXON transform"
          end
        else
          raise "Unknown error during SAXON transform #{xpath_exception} (#{xpath_exception.class})"
        end
      end
      
      return nil
    end
    
    def pretty_print(xml_stream)
      transformer = get_transformer()
      transformer.setOutputProperty(
        javax.xml.transform.OutputKeys.const_get('INDENT'), "yes")
      # transformer.setOutputProperty(
      #   "{http://xml.apache.org/xslt}indent-amount", "2")
      
      string_writer = java.io.StringWriter.new()
      result = javax.xml.transform.stream.StreamResult.new(string_writer)

      if xml_stream.class == Java::ComSunOrgApacheXercesInternalDom::DeferredDocumentImpl
        transformer.transform(
          javax.xml.transform.dom.DOMSource.new(xml_stream), result)
      else
        transformer.transform(xml_stream, result)
      end

      string_writer.toString()
    end
    
    protected
      def get_transformer(xsl_stream = nil)
        java.lang.System.setProperty("javax.xml.transform.TransformerFactory", "net.sf.saxon.TransformerFactoryImpl")

        transformer_factory = javax.xml.transform.TransformerFactory.newInstance()
        transformer_factory.setErrorListener(TransformErrorListener.new())
        
        
        if xsl_stream.nil?
          return transformer_factory.newTransformer()
        else
          return transformer_factory.newTransformer(xsl_stream)
        end
      end
  end
end

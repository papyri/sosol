module JRubyXML
  class ParseError < ::StandardError
    attr :line, :column
    
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
      raise ParseError.new(e.getLineNumber, e.getColumnNumber), e.getMessage
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
      locator = e.getLocator()
      raise ParseError.new(locator.getLineNumber, locator.getColumnNumber), 
        e.getMessage
    end
    
    def warning(e)
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
  
  class EpiDocP5Validator < JARVValidator
    def initialize
      @verifier_factory = 
        org.iso_relax.verifier.VerifierFactory.newInstance(
          "http://relaxng.org/ns/structure/1.0")
      @schema = verifier_factory.compileSchema(
        "http://epidoc.googlecode.com/files/exp-epidoc.rng")
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

    def apply_xsl_transform(xml_stream, xsl_stream)
      transformer = get_transformer(xsl_stream)
      transformer.setErrorListener(TransformErrorListener.new())
      
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
            raise "Unknown XPath error"
          end
        else
          raise "Unknown error"
        end
      end
      
      return nil
    end
    
    def pretty_print(xml_stream)
      transformer = get_transformer()
      transformer.setOutputProperty(
        javax.xml.transform.OutputKeys.const_get('INDENT'), "yes")
      transformer.setOutputProperty(
        "{http://xml.apache.org/xslt}indent-amount", "2")
      
      string_writer = java.io.StringWriter.new()
      result = javax.xml.transform.stream.StreamResult.new(string_writer)

      transformer.transform(xml_stream, result)

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
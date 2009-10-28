module JRubyXML
  # http://iso-relax.sourceforge.net/JARV/JARV.html
  class JARVValidator
    include Singleton
    
    attr_reader :verifier_factory, :schema
    
    def validate(input_source_xml_stream)
      verifier = @schema.newVerifier()
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
      java.lang.System.setProperty("javax.xml.transform.TransformerFactory", "net.sf.saxon.TransformerFactoryImpl")
  
      transformer_factory = javax.xml.transform.TransformerFactory.newInstance()
      transformer = transformer_factory.newTransformer(xsl_stream)
  
      string_writer = java.io.StringWriter.new()
      result = javax.xml.transform.stream.StreamResult.new(string_writer)

      transformer.transform(xml_stream, result)
  
      string_writer.toString()
    end
  end
end
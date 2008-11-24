module DocumentsHelper
=begin
  def valid_xml?(xml)
    begin
      REXML::Document.new(xml)
    rescue REXML::ParseException
      # Return nil if an exception is thrown
    end
  end
=end

  def get_title(xml)
    REXML::XPath.first(REXML::Document.new(xml), "/TEI.2/teiHeader/fileDesc/titleStmt/title").text
  end

  def valid_epidoc?(xml)
    parser = XML::Parser.new
    parser.string = xml
    begin
      document = parser.parse
    rescue XML::Parser::ParseError
      return false
    end
    dtd = XML::Dtd.new("-//STOA//DTD EPIDOC//EN", "/Users/ryan/source/idp2/git/protosite/app/helpers/tei-epidoc.dtd")
    document.validate(dtd)
  end
end

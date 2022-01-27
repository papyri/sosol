# frozen_string_literal: true

# Created as sub-class of DDBIdentifier because it already has the acts_as_leiden_plus
#
# Converts DDB Text Leiden+ and XML
class Leiden < DDBIdentifier
  # Converts DDB Text XML to Leiden+
  # - uses DDBIdentifier.preprocess_abs to wrap the argument in XML needed to parse in the XSUGAR grammar
  # - uses DDBIdentifier.xml2nonxml to convert the XML to Leiden+
  # - removes any Leiden+ returned due to the XML added for parsing purposes before returning Leiden+
  # - *Args*    :
  #   - +content+ -> DDB Text XML to transform to Leiden+
  # - *Returns* :
  #   - Leiden+
  def self.xml_leiden_plus(content)
    if content.include?('<ab><div') || content.include?('<ab><ab>') || content.include?('<ab><ab/>')
      # if user xml content included <div> or <ab> tag, remove the <ab> tag added in controller
      # also means no need to slice after converted
      content.slice!(/^<ab>/)
      content.slice!(%r{</ab>$})
      # add <div type="edition"> tag
      abs = DDBIdentifier.preprocess_abs(content)
      # call to convert
      transformed = DDBIdentifier.xml2nonxml(abs)
      # some parse errors are not caught (ex. <abbr/> end tag - / in wrong place) so will return a nil result
      # TODO - not sure exactly what to do but this keeps from crashing
      # remove <S=.grc from <div> tag added above
      transformed&.slice!(/^<S=.grc/)
    else
      # add <div type="edition"> tag
      abs = DDBIdentifier.preprocess_abs(content)
      # call to convert
      transformed = DDBIdentifier.xml2nonxml(abs)
      # some parse errors are not caught (ex. <abbr/> end tag - / in wrong place) so will return a nil result
      # TODO - not sure exactly what to do but this keeps from crashing
      unless transformed.nil?
        # remove <S=.grc from <div> tag added above <= and => that represents <ab> tag added in controller
        # done separately because all will have the <S= but not all will have the <= next in the Leiden+
        transformed.slice!(/^<S=.grc/)
        transformed.slice!(/^<=/)
        transformed.slice!(/=>$/)
      end
    end
    transformed
  end

  # Converts DDB Text Leiden+ to XML
  # - checks argument to see what Leiden+ needs to be added to parse in the XSUGAR grammar
  # - uses DDBIdentifier.nonxml2xml to convert the Leiden+ to XML
  # - removes namespace XML
  # - *Args*    :
  #   - +content+ -> DDB Text Leiden+ to transform to XML
  # - *Returns* :
  #   - XML
  def self.leiden_plus_xml(content)
    if content.include?('<=') # check if user input contains Leiden+ grammar for <ab> tag
      content = "<S=.grc#{content}"
      # call to convert
      tempTrans = DDBIdentifier.nonxml2xml(content)

      # remove namespace assignment or REXML barfs
      tempTrans.sub!(%r{ xmlns:xml="http://www.w3.org/XML/1998/namespace"}, '')

      # pull out XML inside the <wrapab> tag
      # transformed = REXML::XPath.match(REXML::Document.new(tempTrans), '/wrapab/[not(self::wrapab)]')
      transformed = REXML::XPath.match(REXML::Document.new(tempTrans),
                                       '/div[@type = "edition"]/[not(self::div[@type = "edition"])]')
    else
      # add Leiden+ grammar for <ab> tag so will meet minimun xSugar grammar requirement
      abs = "<S=.grc<=#{content}=>"

      # call to convert
      tempTrans = DDBIdentifier.nonxml2xml(abs)

      # remove namespace assignment or REXML barfs
      tempTrans.sub!(%r{ xmlns:xml="http://www.w3.org/XML/1998/namespace"}, '')

      # pull out XML inside the <ab> tag
      # transformed = REXML::XPath.match(REXML::Document.new(tempTrans), '/wrapab/ab/[not(self::ab)]')
      transformed = REXML::XPath.match(REXML::Document.new(tempTrans), '/div[@type = "edition"]/ab/[not(self::ab)]')
    end
    transformed
  end
end

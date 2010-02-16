class HGVIdentifier < Identifier
  # This is a superclass for HGVMetaIdentifier and HGVTransIdentifier
  # shared constants and methods. No instances of HGVIdentifier should be
  # created. Should probably be modularized and mixed in.
  
  IDENTIFIER_NAMESPACE = 'hgv'
  TEMPORARY_COLLECTION = 'SoSOL'
  
  FRIENDLY_NAME = "HGV Identifier"
  
  ROMAN_MAP = { 1 => "I",
                4 => "IV",
                5 => "V",
                9 => "IX",
                10 => "X",
                40 => "XL",
                50 => "L",
                90 => "XC",
                100 => "C",
                400 => "CD",
                500 => "D",
                900 => "CM",
                1000 => "M" }
  
  def to_roman(arabic)
    # shamelessly stolen from http://rubyquiz.com/quiz22.html
    ROMAN_MAP.keys.sort { |a, b| b <=> a }.inject("") do |roman, div|
      times, arabic = arabic.divmod(div)
      roman << ROMAN_MAP[div] * times
    end
  end
  
  def titleize
    trimmed_name = name.sub(
      /^#{NumbersRDF::PREFIX}:#{IDENTIFIER_NAMESPACE}:/,
      '')
    components = trimmed_name.split(':')
    hgv_collection_name = components[0].to_s
    hgv_volume_number = components[1].to_s
    hgv_document_numbers = components[2..-1]
    
    hgv_volume_number = to_roman(hgv_volume_number.to_i)
    
    title_array = [hgv_collection_name, hgv_volume_number]
    
    unless hgv_document_numbers.nil?
      # convert to strings
      hgv_document_numbers.map! {|dn| dn.to_s}
    
      # strip leading zeros
      hgv_document_numbers.map! {|dn| dn.sub(/^0*/,'')}
      
      # add to title array
      title_array += hgv_document_numbers
    end
    
    # convert e.g. '%20' to ' '
    title_array.map! {|dn| CGI.unescape(dn)}

    title_array.join(' ').strip
  end
  
  def temporary_path
    # path constructor for born-digital temporary SoSOL identifiers
    trimmed_name = name.sub(/^oai:papyri.info:identifiers:hgv:/, '')
    components = trimmed_name.split(':')
    return File.join(self.class::PATH_PREFIX, components[0..-2], "#{components[-1]}.xml")
  end
  
  def self.collection_names
    identifiers = NumbersRDF::NumbersHelper.identifier_to_identifiers(
      "#{NumbersRDF::PREFIX}:#{IDENTIFIER_NAMESPACE}")
    identifiers.collect{|i| CGI.unescape(i.split(':').last)}
  end
end
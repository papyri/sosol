class HGVIdentifier < Identifier
  # This is a superclass for HGVMetaIdentifier and HGVTransIdentifier
  # shared constants and methods. No instances of HGVIdentifier should be
  # created. Should probably be modularized and mixed in.
  
  IDENTIFIER_NAMESPACE = 'hgv'
  TEMPORARY_COLLECTION = 'SoSOL'
  
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
    trimmed_name = name.sub(/^oai:papyri.info:identifiers:hgv:/, '')
    components = trimmed_name.split(':')
    hgv_collection_name = components[0].to_s
    hgv_volume_number = components[1].to_s
    hgv_document_numbers = components[2..-1].map {|dn| dn.to_s}
    
    hgv_volume_number = to_roman(hgv_volume_number.to_i)
    
    # strip leading zeros
    hgv_document_numbers.map! {|dn| dn.sub(/^0*/,'')}
    
    # convert e.g. '%20' to ' '
    hgv_document_numbers.map! {|dn| CGI.unescape(dn)}

    [hgv_collection_name, hgv_volume_number, hgv_document_numbers].join(' ')
  end
  
  def temporary_path
    # path constructor for born-digital temporary SoSOL identifiers
    trimmed_name = name.sub(/^oai:papyri.info:identifiers:hgv:/, '')
    components = trimmed_name.split(':')
    return File.join(self.class::PATH_PREFIX, components)
  end
end
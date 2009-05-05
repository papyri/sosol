module DdbIdentifiersHelper
  def get_abs_from_edition_div(xml)
    processed = ''
    REXML::XPath.each(REXML::Document.new(xml), '/TEI.2/text/body/div[@type = "edition"]/ab') do |ab|
      ab.to_s.each_line do |line|
        processed += line.chomp.strip
      end
    end
    processed
  end
  
  def parse_exception_pretty_print(text, position)
    carat = '^'.rjust(position)
    text + "\n" + carat
  end
end
class HGVBiblioIdentifier < HGVMetaIdentifier
  attr_reader :bibliographies

  def self.friendly_name
    return 'Bibliography'
  end

  def self.find_by_publication_id publication_id
    return HGVMetaIdentifier.find_by_publication_id(publication_id).becomes(HGVBiblioIdentifier)
  end
  
  def self.find id
    return HGVMetaIdentifier.find(id).becomes(HGVBiblioIdentifier)
  end

  def after_initialize
    @bibliography_id_list = [:sb] # add further bilbiographies by extending the list, such as :xyz
    @xpath = "/TEI/teiHeader/fileDesc/sourceDesc/listBibl/"
    @item_list = {
      :signature            => {:multiple => false, :xpath => "idno[@type='signature']"},
      :title                => {:multiple => false, :xpath => "title[@level='a'][@type='main']"},
      :author               => {:multiple => true,  :xpath => "author"},
      :monographic_title    => {:multiple => false, :xpath => "title[@level='m'][@type='main']"},
      :series_title         => {:multiple => false, :xpath => "series/title[@level='s'][@type='main']"},
      :series_number        => {:multiple => false, :xpath => "series/biblScope[@type='volume']"},
      :editor               => {:multiple => true,  :xpath => "editor"},
      :place_of_publication => {:multiple => false, :xpath => "pubPlace"},
      :publication_date     => {:multiple => false, :xpath => "date"},
      :pagination           => {:multiple => false, :xpath => "biblScope[@type='page']"},
      :pagination_start     => {:multiple => false, :xpath => "biblScope[@type='page']/@from"},
      :pagination_end       => {:multiple => false, :xpath => "biblScope[@type='page']/@to"},
      :notes                => {:multiple => false, :xpath => "notes"}
    }

    @bibliographies = {}
    
    #@secondaryXpath = "/TEI.2/text/body/div[@type='bibliography']"
    #@secondaryItemList = {}
    #@secondaryBibliographies = {}
  end

  def set_epidoc data, comment = 'update bibliographical information'

    xml = self.content

    if xml.empty?
      raise Exception.new 'no xml content found'
    end

    doc = REXML::Document.new xml

    data.each_pair {|bibliography_id, bibliography_data| 
      docBibliography = doc.bulldozePath fullpath bibliography_id

      @item_list.each_pair { |item_key, item_options|

        path = fullpath bibliography_id, item_key
        value = bibliography_data[item_key.to_s].strip

        if multiple? item_key
          doc.elements.delete_all path

          splinters = value.split(',').select{ |splinter|
            (splinter.class == String) && (!splinter.strip.empty?)
          }

          splinters.each_index { |i|
            doc.bulldozePath(path + "[@n='" + (i + 1).to_s + "']", splinters[i].strip)
          }

        else
          doc.bulldozePath(path, value)
        end

      }

    }

    modified_xml_content = ''
    formatter = REXML::Formatters::Default.new
    formatter.write doc, modified_xml_content
    
    #f = File.new '/Users/InstPap/tmp/hgv.bgu.1.20_biblio_pretty.xml', 'w'
    #f.write modified_xml_content
    #f.close

    self.set_content(modified_xml_content, :comment => comment)
  end

  def get_epidoc_attributes
    
  end
  
  def retrieve_bibliographical_data
    doc = REXML::Document.new self.content

    @bibliographies = {}
    @bibliography_id_list.each {|bibliography_id|
      @bibliographies[bibliography_id] = {}
      @item_list.each_key {|item|
         @bibliographies[bibliography_id][item] = extract_value(doc, bibliography_id, item)
      }
    }
  end
  
  protected
  
  def fullpath bibliography_id, key = nil
    @xpath + "bibl[@id='" + bibliography_id.to_s + "']" + (key ? '/' + @item_list[key][:xpath] : '')
  end
  
  def xpath key = nil
    if key
      (@item_list.has_key?(key) && @item_list[key].has_key?(:xpath)) ? @item_list[key][:xpath] : ''
    else
      @xpath
    end
  end

  def multiple? key
    (@item_list.has_key?(key) && @item_list[key].has_key?(:multiple)) ? @item_list[key][:multiple] : true
  end
  
  def attribute_element? key
    @item_list[key][:xpath].include? '/@'
  end

  def extract_value document, bibliography, key    
    tmp = ''
    element_path = xpath + 'bibl[@id="' + bibliography.to_s + '"]/' + xpath(key)
 
    if element_path.include? '/@' # i.e. path points to an attribute rather than an element
      document.elements.each(element_path.slice(0, element_path.index('/@')) ) {|element|
        tmp = element.attributes[element_path.slice(element_path.index('/@') + 2, 100)]
      }
    else
      document.elements.each(element_path) {|element|
        if element.get_text
          tmp += element.get_text.value + ', '
        end
      }
    end      

    return tmp.sub(/, \Z/, '')
  end

end
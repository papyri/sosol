class HGVBiblioIdentifier < HGVMetaIdentifier
  attr_reader :bibliography_main, :bibliography_other, :bibliography_secondary, :xpath_main, :xpath_other,  :xpath_secondary 

  FRIENDLY_NAME = "Bibliography"

  #def self.friendly_name
  #  return 'Bibliography'
  #end

  def self.find_by_publication_id publication_id
    return HGVMetaIdentifier.find_by_publication_id(publication_id).becomes(HGVBiblioIdentifier)
  end

  def self.find id
    return HGVMetaIdentifier.find(id).becomes(HGVBiblioIdentifier)
  end

  def after_initialize
    @xpath_main = "/TEI/teiHeader/fileDesc/sourceDesc/listBibl"
    @xpath_other = "/TEI/text/body/div[@type='bibliography'][@subtype='otherPublications']/listBibl"
    @xpath_secondary = "/TEI/text/body/div[@type='bibliography'][@subtype='citations']/listBibl"

    @item_list_main = @item_list_other = @item_list_secondary = {
      :signature            => {:multiple => false, :xpath => "idno[@type='signature']"},
      :title                => {:multiple => false, :xpath => "title[@level='a'][@type='main']"},
      :author               => {:multiple => true,  :xpath => "author"},
      :monographic_title    => {:multiple => false, :xpath => "title[@level='m'][@type='main']"},
      :series_title         => {:multiple => false, :xpath => "series/title[@level='s'][@type='main']"},
      :series_number        => {:multiple => false, :xpath => "series/biblScope[@type='volume']"},
      :journal_title        => {:multiple => false, :xpath => "monogr/title[@level='j'][@type='main']"},
      :journal_number       => {:multiple => false, :xpath => "monogr/biblScope[@type='volume']"},
      :editor               => {:multiple => true,  :xpath => "editor"},
      :place_of_publication => {:multiple => false, :xpath => "pubPlace"},
      :publication_date     => {:multiple => false, :xpath => "date"},
      :pagination           => {:multiple => false, :xpath => "biblScope[@type='page']"},
      :pagination_start     => {:multiple => false, :xpath => "biblScope[@type='page']/@from"},
      :pagination_end       => {:multiple => false, :xpath => "biblScope[@type='page']/@to"},
      :notes                => {:multiple => false, :xpath => "notes"}
    }

    @bibliography_main = {}
    @bibliography_other = {}
    @bibliography_secondary = {}

    @id_list_main = [:sb] # add further bilbiographies by extending the list, such as :xyz
    @bibl_tag_other = "bibl[@type='publication'][@subtype='other']"
    @bibl_tag_secondary = "bibl"
  end

  def generate_empty_template_other
    generate_empty_template @item_list_other
  end

  def generate_empty_template_secondary
    generate_empty_template @item_list_secondary
  end

  def generate_empty_template item_list
    empty_template = {}
    item_list.each_pair {|key, value|
      empty_template[key] = ''
    }
    empty_template
  end

  def set_epidoc main, other, secondary, comment = 'update bibliographical information'

    xml = self.content

    if xml.empty?
      raise Exception.new 'no xml content found'
    end

    doc = REXML::Document.new xml

    main.each_pair {|id, data|
      store_bibliographical_data(doc, @item_list_main, data, xpath({:type => :main, :id => id}))
    }

    doc.elements.delete_all @xpath_other + '/' + @bibl_tag_other
    index = 0
    other.each_pair {|id, data|
      index += 1
      store_bibliographical_data(doc, @item_list_other, data, xpath({:type => :other, :id => index.to_s}))
    }

    doc.elements.delete_all @xpath_secondary + '/' + @bibl_tag_secondary
    index = 0
    secondary.each_pair {|id, data|
      index += 1
      store_bibliographical_data(doc, @item_list_secondary, data, xpath({:type => :secondary, :id => index.to_s}))
    }

    modified_xml_content = ''
    formatter = REXML::Formatters::Default.new
    formatter.write doc, modified_xml_content

    #f = File.new '/Users/InstPap/tmp/sosol/tmp.xml', 'w'
    #f.write modified_xml_content
    #f.close

    #g = File.new '/Users/InstPap/tmp/sosol/tmpOO.xml', 'r'
    #modified_xml_content = ''
    #g.each_line {|line|
    #  modified_xml_content += line
    #} 
    #g.close

    self.set_content(modified_xml_content, :comment => comment)
  end

  def store_bibliographical_data doc, item_list, data, base_path
    docBibliography = doc.bulldozePath base_path
    
    item_list.each_pair {|key, options|
        path = base_path + '/' + options[:xpath]
        value = data[key.to_s].strip

        if options[:multiple]
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
  end

  def get_epidoc_attributes
    
  end
  
  def retrieve_bibliographical_data
    doc = REXML::Document.new self.content

    @bibliography_main = {}
    @id_list_main.each {|id|
      @bibliography_main[id] = {}
      @item_list_main.each_key {|key|
        path = xpath({:type => :main, :id => id, :key => key})
        @bibliography_main[id][key] = extract_value(doc, path) # e.g. doc, '/TEI.../bibl.../title'
      }
    }

    @bibliography_other = {}
    doc.elements.each(xpath({:type => :other})) {|element|
      id = @bibliography_other.length + 1
      @bibliography_other[id] = {}
      @item_list_other.each_key {|key|
         path = xpath_tip(:other, key)
         @bibliography_other[id][key] = extract_value(element, path) # e.g. element, 'bibl.../title'
      }
    }

    @bibliography_secondary = {}
    doc.elements.each(xpath({:type => :secondary})) {|element|
      id = @bibliography_secondary.length + 1
      @bibliography_secondary[id] = {}
      @item_list_secondary.each_key {|key|
         path = xpath_tip(:secondary, key)
         @bibliography_secondary[id][key] = extract_value(element, path) # e.g. element, 'bibl.../title'
      }
    }

  end
  
  protected

  def extract_value document, element_path    
    tmp = ''

    if element_path.include? '/@' # i.e. path points to an attribute rather than an element
      document.elements.each(element_path.slice(0, element_path.index('/@')) ) {|element|      
        tmp = element.attributes[element_path.slice(element_path.index('/@') + 2, 100)] || ''
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

  def xpath_root type = :main
    type == :main ? @xpath_main : (type == :other ? @xpath_other : (type == :secondary ? @xpath_secondary : ''))
  end

  def xpath_base type, id = nil
    if type == :main && id
      "bibl[@id='" + id.to_s + "']"
    elsif type == :other
      @bibl_tag_other + (id ? "[@n='" + id.to_s + "']" : '')
    elsif type == :secondary
      @bibl_tag_secondary + (id ? "[@n='" + id.to_s + "']" : '')
    else
      raise Exception.new 'invalid type and id (' + type.to_s + ', ' + id.to_s + ')'
    end
  end

  def xpath_tip type, key
    if type == :main && @item_list_main.has_key?(key) && @item_list_main[key].has_key?(:xpath)
      @item_list_main[key][:xpath]
    elsif type == :other && @item_list_other.has_key?(key) && @item_list_other[key].has_key?(:xpath)
      @item_list_other[key][:xpath]
    elsif type == :secondary && @item_list_secondary.has_key?(key) && @item_list_secondary[key].has_key?(:xpath)
      @item_list_secondary[key][:xpath]
    else
      raise Exception.new 'invalid type and key (' + type.to_s + ', ' + key.to_s + ')'
    end
  end

  def xpath options = {}
    type = options[:type] || :main
    id   = options[:id]   || nil
    key  = options[:key]  || nil

    prefix = xpath_root(type)
    infix  = '/' + xpath_base(type, id)
    suffix = key ? ('/' + xpath_tip(type, key)) : ''

    prefix + infix + suffix
  end

end

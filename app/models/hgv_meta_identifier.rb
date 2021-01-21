include HgvMetaIdentifierHelper

class HGVMetaIdentifier < HGVIdentifier
  attr_accessor :configuration, :valid_epidoc_attributes

  PATH_PREFIX = 'HGV_meta_EpiDoc'

  FRIENDLY_NAME = "HGV Meta"

  # Generates HTML preview for hgv metadata using EpiDoc transformation file *start-edition.xsl*
  # - *Args*  :
  #   - +parameters+ → xsl parameter hash, e.g. +{:leiden-style => 'ddb'}+, defaults to empty hash
  #   - +xsl+ → path to xsl file, relative to +Rails.root+, e.g. +%w{data xslt epidoc my.xsl})+, defaults to +data/xslt/epidoc/start-edition.xsl+
  # - *Returns* :
  #   - result of transformation operation as provided by +JRubyXML.apply_xsl_transform+
  def preview parameters = {}, xsl = nil
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        xsl ? xsl : %w{data xslt metadata preview.xsl})),
        parameters)
  end

  after_initialize :post_initialization_configuration
  # Loads +HgvMetaConfiguration+ object (HGV xpath for EpiDoc and options for the editor) and presets valid EpiDoc attributes
  # Side effect on +@configuration+ and + @valid_epidoc_attributes+
  def post_initialization_configuration
    @configuration = HgvMetaIdentifierHelper::HgvMetaConfiguration.new #YAML::load_file(File.join(Rails.root, %w{config hgv.yml}))[:hgv][:metadata]
    @valid_epidoc_attributes = @configuration.keys
  end

  # ?
  def to_path
    if name =~ /#{self.class::TEMPORARY_COLLECTION}/
      return self.temporary_path
    else
      path_components = [ PATH_PREFIX ]
      # assume the name is e.g. hgv2302zzr
      trimmed_name = self.to_components.last # 2302zzr
      number = trimmed_name.sub(/\D/, '').to_i # 2302

      hgv_dir_number = ((number - 1) / 1000) + 1
      hgv_dir_name = "HGV#{hgv_dir_number}"
      hgv_xml_path = trimmed_name + '.xml'

      path_components << hgv_dir_name << hgv_xml_path

      # e.g. HGV_meta_EpiDoc/HGV3/2302zzr.xml
      return File.join(path_components)
    end
  end
  
  # ?
  def id_attribute
    return IDENTIFIER_NAMESPACE + 'TEMP'
  end

  # ?
  def n_attribute
    ddb = DDBIdentifier.find_by_publication_id(self.publication.id, :limit => 1)
    if ddb
      return ddb.n_attribute
    else
      return nil
    end
  end
  
  # ?
  def xml_title_text
    return "Description of document"
  end

  # Place any actions you always want to perform on HGV Meta identifier content prior to it being committed in this method
  # - *Args*  :
  #   - +content+ -> HGVMetaIdentifier XML as string
  def before_commit(content)
    HGVMetaIdentifier.preprocess(content)
  end
  
  # Applies the preprocess XSLT to 'content'
  # - *Args*  :
  #   - +content+ -> XML as string
  # - *Returns* :
  #   - modified 'content'
  def self.preprocess(content)
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt metadata preprocess.xsl})))
  end

  # Retrieves a single date item (X, Y or Z) from instance variable +self[:textDate]+
  # - *Args*  :
  #   - +date_id+ → id of wanted date item, e.g. +'X'+, +'Y'+ or +'Z'+ OR +'dateAlternativeX'+, +'dateAlternativeY'+ or +'dateAlternativeZ'+
  # - *Returns* :
  #   - date item X, Y or Z OR nil if the requested date item does not exist
  # If there is only one date item available this date item might not have any id, so if the callers asks for date item with date id +X+ the first date item will be returned, no matter whether the id machtes or not
  def get_date_item date_id    
    self[:textDate].each{|dateItem|
      if dateItem[:attributes] && dateItem[:attributes][:id] && dateItem[:attributes][:id].include?(date_id)
        return dateItem
      elsif date_id.include?('X') && self[:textDate].first == dateItem
        return dateItem
      end
    }
    return nil    
  end

  # Retrieves metadata from xml and stores the information as object attributes
  # Populates instance variable from EpiDoc xml file
  #   e.g. title: <title>Instruction to track down murderers</title> will become
  #   +self[:title] = 'Instruction to track down murderers'+
  #   e.g. content text: <keywords><term>a</term><term>b</term></keywords> will become
  #   +self[:contentText] = ['a', 'b']+
  #   e.g. date will become complicated
  # Side effect on +self+, particulary on +self[<EpiDoc attribute>]+ like +self[:title]+
  def get_epidoc_attributes
    doc = REXML::Document.new self.content

    @configuration.scheme.each_pair do |key, config|
      if config[:children] || config[:attributes]
        self.non_database_attribute[key] = get_epidoc_attributes_tree doc, config
      elsif config[:multiple]
        self.non_database_attribute[key] = get_epidoc_attributes_list doc, config
      else 
        self.non_database_attribute[key] = get_epidoc_attributes_value doc, config
      end
    end
  end

  # Looks for a certain xpath that has been configured via +hgv.yml+ and returns a value list containing all xpath matches, e.g. for +:contentText+
  # - *Args*  :
  #   - +doc+ → REXML::Element that should be searched for the respective xpath, usually a complete EpiDoc document
  #   - +config+ → a piece of configuration that holds all relevant data about the wanted item (especially the xpath to search)
  # - *Returns* :
  #   - +Array+ of simple string values, e.g. ['Schuldbrief', 'privat']
  def get_epidoc_attributes_list doc, config
    list = []
    doc.elements.each(config[:xpath]){|element|
      if element.text && !element.text.strip.empty?
        list << element.text.strip
      end
    }
    list
  end

  # Retrieves relevant data from EpiDoc and stores it within a simple tree structure, where each node may have a value plus additional attributes as well as a list of children
  # - *Args*  :
  #   - +doc+ → REXML::Element that should be searched for the respective xpath, initially the complete EpiDoc document
  #   - +config+ → a piece of configuration that holds all relevant data about the wanted item (especially the xpath to search) as well as all information necessary to retrieve its children
  # - *Returns* :
  #   - Either an +Array+ of items which contains a list of siblings for a given configuration node [0 => {:value => '', :attributes => {}, :children => {}}, 1 => {...}, 2 => {...}, ... ]
  #   - or a single item depending of was the config parameter for +:multiple+ sais (either +true+ or +false+)
  def get_epidoc_attributes_tree doc, config
    tree = []

    if config[:xpath] =~ /\A(.+)\/@([A-Za-z]+)\Z/ # for attributes
      element_xpath  = $1
      attribute_name = $2
      if parent = doc.elements[element_xpath]
        tree[tree.length] = {:value => parent.attributes[attribute_name], :attributes => {}, :children => {}}
      end
    else # for elements

      doc.elements.each(config[:xpath]){|element|
        node = {:value => '', :attributes => {}, :children => {}}

        if config[:preFlag] && element.previous_element && config[:preFlag] == element.previous_element.name # CL: CROMULENT GEO HACK
          node[:preFlag] = 'bei';
        end

        if element.name.to_s == 'origDate' # CL: CROMULENT DATE HACK
          node[:value] = element.to_s.gsub(/[\s]+/, ' ').gsub(/<\/?[^>]*>/, "").strip
        elsif element.text && !element.text.strip.empty?
          node[:value] = element.text.strip
        else
          node[:value] = config[:default]
        end

        if config[:attributes]
          config[:attributes].each_pair{|attribute_key, attribute_config|
            node[:attributes][attribute_key] = element.attributes[attribute_config[:name]] && !element.attributes[attribute_config[:name]].strip.empty? ? element.attributes[attribute_config[:name]].strip : attribute_config[:default]
            if attribute_config[:split] && node[:attributes][attribute_key] && !node[:attributes][attribute_key].empty?
              node[:attributes][attribute_key] = node[:attributes][attribute_key].split(!attribute_config[:split].empty? ? attribute_config[:split] : ' ')
            end
          }
        end

        if config[:children]
          config[:children].each_pair{|child_key, child_config|
            node[:children][child_key] = get_epidoc_attributes_tree element, child_config
          }
        end

        tree[tree.length] = node
      }

    end

    return config[:multiple] ? tree : tree.first
  end

  # Retrieves the value (the stripped text representation) of a HGV item
  # - *Args*  :
  #   - +doc+ → REXML::Document / REXML::Element which shall be analysed
  #   - +config+ → configuration snippet that was loaded from +hgv.yml+
  # - *Returns* :
  #   - +String+
  #   - If the xpath can be found with the xml document the value of the first text node will be returned
  #   - Otherwise this method will return the default value given in the configuration object (which may be just an empty string)
  # Side effect on +SIDEEFFECT+
  def get_epidoc_attributes_value doc, config
    if element = doc.elements[config[:xpath]]
      value = element.class == REXML::Attribute ? element.value : element.text
      value && !value.strip.empty? ? value.strip : config[:default]
    else
      config[:default]
    end
  end

  # Updated EpiDoc file with values from incoming post string, validates xml and commits it to the user repository
  # - *Args*  :
  #   - +attributes_hash+ → post parameters
  #   - +comment+ → comment passed in via post to describe the user's intention
  # - *Returns* :
  #   - +String+ of the SHA1 of the commit
  # Side effect on user's git repository, writes altered xml back to file
  def set_epidoc(attributes_hash, comment)
    populate_epidoc_attributes_from_attributes_hash(attributes_hash)

    epidoc = set_epidoc_attributes

    # salvage xsugar formatted text
    if hasText?(epidoc) and !hasEmptyText?(epidoc)
      epidoc = epidoc.slice(0, getTextStart(epidoc)) + salvageText + epidoc[getTextEnd(epidoc)..-1]
    end

    Rails.logger.debug epidoc

    #set_content does not validate xml (which is what epidoc is)
    #self.set_content(epidoc, :comment => comment)
    #set_xml_content validates xml
    self.set_xml_content(epidoc, :comment => comment)
  end

  def hasText? epiDocXml
    epiDocXml.index(/<div [^>]*type=["']edition["'][^>]*>/)
  end

  def hasEmptyText? epiDocXml
    epiDocXml.index(/<div [^>]*type=["']edition["'][^>]*\/>/)
  end

  def salvageText
    originalEpiDoc = content()
    originalEpiDoc.slice(getTextStart(originalEpiDoc), getTextLength(originalEpiDoc))
  end

  def getTextStart epiDocXml
    epiDocXml.index(/<div [^>]*type=["']edition["'][^>]*>/)
  end

  def getTextEnd epiDocXml
    startIndex = getTextStart epiDocXml
    currentIndex = startIndex

    if epiDocXml[startIndex..-1] =~ /^<div [^>]*type=["']edition["'][^>]*\/>/ # empty text div
      epiDocXml.index('/>', currentIndex) + '/>'.length
    else # text div with content
      scale = 1
      safetyRope = 1024
      while (scale > 0) && (safetyRope > 0)
        currentIndex = epiDocXml.index(/(<\/?div)/, currentIndex + 1)
        if epiDocXml.slice(currentIndex + 1, 1) == '/'
          scale -= 1
        else
          scale += 1
        end
        safetyRope -= 1
      end
      currentIndex + '</div>'.length
    end
  end

  def getTextLength epiDocXml
    getTextEnd(epiDocXml) - getTextStart(epiDocXml)
  end

  # ?
  def after_rename(options = {})
    if options[:update_header]
      rewritten_xml =
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(content),
          JRubyXML.stream_from_file(File.join(Rails.root,
            %w{data xslt metadata update_header.xsl})),
          :filename_text => self.to_components.last,
          :reprint_from_text => options[:set_dummy_header] ? options[:original].title : '',
          :reprent_ref_attirbute => options[:set_dummy_header] ? options[:original].to_components.last : '',
          :hybrid => options[:new_hybrid] ? options[:new_hybrid] : ''
        )
      self.set_xml_content(rewritten_xml, :comment => "Update header to reflect new identifier '#{self.name}'")
    end
  end

  # Saves the values stored within a hash object (usually generated via a webbrowser form)
  # - *Args*  :
  #   - +Hash+ +attributes_hash+ → the post parameters
  # Assumes that +@configuration+ contains fuly loaded configuration object
  # Side effect on +self[key]+ where key is any valid HGV EpiDoc key
  def populate_epidoc_attributes_from_attributes_hash attributes_hash

    @configuration.scheme.each_pair do |key, config|
      if config[:children] || config[:attributes]
        result = if config[:multiple]
          tmp = []
          unless attributes_hash[key].nil?
            attributes_hash[key].each_pair {|index, item|
              tmp[tmp.length] = populate_tree_from_attributes_hash item, config
            }
          end
          tmp
        else
          populate_tree_from_attributes_hash attributes_hash[key], config      
        end

        self[key] = result  
      elsif config[:multiple]
        self[key] = attributes_hash[key] ? attributes_hash[key].values.compact.reject {|item| item.strip.empty? }.collect{|item| item.strip } : []
      else 
        self[key] = attributes_hash[key] ? attributes_hash[key].strip : nil
      end
    end
  end


  protected

  def elementHasAnyContent? item
    if item.class == String && !item.strip.empty?
      return true
    elsif item.class == Hash && item[:value] && !item[:value].strip.empty?
      return true
    elsif item.class == Hash && item[:attributes] && !item[:attributes].values.join.strip.empty? && !(item[:attributes].values.join.strip =~ /\A[{}]+\Z/)
      return true
    elsif item.class == Hash && item[:children] && !item[:children].empty?
      item[:children].each_value{|child|
        if child.class == Array
          child.each{|sibling|
            if elementHasAnyContent? sibling
              return true
            end
          }
        elsif elementHasAnyContent? child
          return true
        end
      }
    end
    return false
  end

  def attributeHasAnyContent? item
    if item.class == String && !item.strip.empty?
      return true
    elsif item.kind_of?(Hash) && !item.values.join.strip.empty?
      return true
    end
    return false
  end

  # Recursively writes user information to EpiDoc xml
  # - *Args*  :
  #   - +parent+ → parent element, new elements will be appended to this node
  #   - +xpath+ → relative xpath that sais where to store the data
  #   - +data+ → +Array+ of items to be saved to EpiDoc, each item is a +Hash+ object may have a +:value+ and a +Hash+ of +:attributes+ as well as a +Hash+ of +:children+
  #   - +config+ → configuration as read from +hgv.yml+
  # Side effect on +parent+, adds new children
  def set_epidoc_attributes_tree parent, xpath, data, config
    child_name = xpath[/\A([\w]+)[\w\/\[\]@:=']*\Z/, 1]
    child_attributes = xpath.scan /@([\w:]+)='([\w]+)'/
    index = 1

    data.each { |item|

      if elementHasAnyContent? item

        child = REXML::Element.new child_name
        child_attributes.each{|name, value|
          child.attributes[name] = value
        }
        if data.length > 1
          child.attributes['n'] = index.to_s
          index += 1
        end

        if item.class == String && !item.strip.empty?
          child.text = item.strip
        else
          if item[:value] && !item[:value].strip.empty?
            child.text = item[:value].strip
          end

          if config[:attributes]
            config[:attributes].each_pair{|attribute_key, attribute_config|
               if item[:attributes] && attributeHasAnyContent?(item[:attributes][attribute_key])
                 attribute_value = item[:attributes][attribute_key]
                 if attribute_config[:split] && !attribute_config[:split].empty? && attribute_value.kind_of?(Hash)
                   attribute_value = attribute_value.values.join(attribute_config[:split])
                 else
                   attribute_value = attribute_value.strip
                 end
                 child.attributes[attribute_config[:name]] = attribute_value
               elsif attribute_config[:default]
                 child.attributes[attribute_config[:name]] = attribute_config[:default]
               end
            }
          end

          if config[:children] && item[:children]
            config[:children].each_pair{|grandchild_name, grandchild_config|
              if item[:children][grandchild_name]
                grandchild_data = item[:children][grandchild_name].class == Array ? item[:children][grandchild_name] : [item[:children][grandchild_name]]
                grandchild_xpath = grandchild_config[:xpath]
                set_epidoc_attributes_tree child, grandchild_xpath, grandchild_data, grandchild_config # recursion
              end
            }
          end
        end

        if (item.is_a? Hash) && item[:preFlag] # CL: CROMULENT GEO HACK
          offset = REXML::Element.new 'offset'
          offset.add_text 'bei'
          parent.add offset
        end

        if config[:xpath] == 'ptr/@target' && /\Ahttp:\/\/papyri\.info\/biblio\/\d+\Z/ =~ item[:value] # CL: CROMULENT BIBLIO ID HACK
          # set papyri.info url
          child.text = nil
          child.attributes['target'] = item[:value]

          # load ignore tags and surround them with comments
          REXML::Comment.new(' ignore - start, i.e. SoSOL users may not edit this ', parent)
          BiblioIdentifier.getRelatedItemElements(item[:value]).each{|ignore|
            parent.add ignore
          }
          REXML::Comment.new(' ignore - stop ', parent)
        end

        parent.add child

      end
    }
  end

  # Takes all HGV values stored within current object instance and writes them to EpiDoc
  # - *Returns* :
  #   - +String+ pretty EpiDoc xml format of current HGV meta data file
  # Assumes +@configuration+ member is loaded with configuration settings from +hgv.yml+
  # e.g. complex tree structure: {"children"=>{"pointer"=>{"attributes"=>{"target"=>"http://papyri.info/biblio/12345"}}, "pagination"=>{"value"=>"pp. 12-14"}}}
  # e.g. simple list: ["Brief (amtlich)", "Iesus an Vernas", "Mitteilung", "daß eine Säule im Steinbruch vollendet und zu Verladung bereit ist", "neu"]
  # e.g. simple string value: "Letter from Iesous to Vernas"
  def set_epidoc_attributes
    # load xml document
    doc = REXML::Document.new self.content

    @configuration.scheme.each_pair do |key, config|
      xpath_parent = config[:xpath][/\A([\w\/\[\]\#_@:=']+)\/([\w\/\[\]\#_@:=']+)\Z/, 1]
      xpath_child = $2 
      next if xpath_parent.nil?

      if config[:multiple]

        if self[key].empty?
          if parent = doc.elements[xpath_parent]
            parent.elements.delete_all xpath_child
            if !parent.has_elements? && parent.texts.join.strip.empty?
              parent.elements['..'].delete parent
            end
          end
        else
          if parent = doc.elements[xpath_parent]
            parent.elements.delete_all xpath_child
          else
            parent = doc.bulldozePath xpath_parent
          end

          set_epidoc_attributes_tree parent, xpath_child, self[key], config
        end

      else
        value = self[key] && !self[key].empty? ? (config[:children] || config[:attributes] ? self[key][:value] : self[key]) : nil
        
        if config[:split] && value.kind_of?(Hash)
          value = value.values.join(!config[:split].empty? ? config[:split] : ' ');
        end

        if attributeLegal? key # value && !value.empty? # CL: Biblio patch
          element = doc.bulldozePath(config[:xpath])

          if config[:xpath] =~ /@([\w]+)\Z/
            element.attributes[$1] = value
          else
            element.text = value
          end
          if config[:attributes]
            config[:attributes].each_pair {|attribute_key, attribute_config|
              element.attributes[attribute_config[:name]] = self[key][:attributes][attribute_key]
            }
          end
          
          if config[:children] # CL: Biblio patch
            config[:children].each_pair {|child_key, child_config|
              element.elements.delete_all child_config[:xpath]
              if  self[key][:children] && self[key][:children].kind_of?(Hash) && self[key][:children][child_key]
                set_epidoc_attributes_tree element, child_config[:xpath], [self[key][:children][child_key]], child_config
              end
            }
          end

        else
          if config[:xpath] =~ /\A.+\/@([A-Za-z]+)\Z/
            attribute_name = $1
            if parent = doc.elements[xpath_parent]
              parent.attributes.delete attribute_name
            end
          else
            doc.elements.delete_all config[:xpath]
          end

          if parent = doc.elements[xpath_parent]
            deleteLegacyElements parent
          end
        end

      end

    end

    # sort
    doc = sort doc

    # write back to a string
    formatter = PrettySsime.new
    formatter.compact = true
    formatter.width = 2**32
    modified_xml_content = ''
    formatter.write doc, modified_xml_content

    return modified_xml_content
  end

  def deleteLegacyElements element
    if emptyElement? element
      parent = element.parent
      if parent
        parent.delete element
        deleteLegacyElements parent
      end
    end
  end

  # checks whether an xml element is empty, in a certain sense
  # (1) it has no child elements
  # (2) it contains no meaningful text
  # (3) it has no attributes that are defined as standalone attributes, e.g. in dclp.yml or hgv.yml
  #     for DCLP there are
  #       archiveLink (/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msIdentifier/collection[@type='ancient']/@ref)
  #       bookForm (/TEI/teiHeader/fileDesc/sourceDesc/msDesc/physDesc/objectDesc/@form)
  #       columns (/TEI/teiHeader/fileDesc/sourceDesc/msDesc/physDesc/objectDesc/layoutDesc/layout/@columns)
  #       writtenLines (/TEI/teiHeader/fileDesc/sourceDesc/msDesc/physDesc/objectDesc/layoutDesc/layout/@writtenLines)
  #     and also in nested structures (which are not taken into consideration as of yet [and they are likely not needed]), such as
  #       certainty (certainty[@cert='low'][@locus='value']/@target)
  #       link (ptr/@target)
  def emptyElement? element
    hasStandaloneAttribute = false
    @configuration.toplevel_standalone_attributes.each {|key, config|
      if config[:element_name] == element.name
        if element.attributes[config[:attribute_name].to_s] && !element.attributes[config[:attribute_name].to_s].empty?
          hasStandaloneAttribute = true
        end
      end
    }
    !element.has_elements? && element.texts.join.strip.empty? && !hasStandaloneAttribute
  end

  # Tells whether a certain key is a valid HGV accessor
  # - *Args*  :
  #   - +key+ → doubted HGV key
  # - *Returns* :
  #   - +true+ if there is a local attribute by the name of +key+
  #   - +false+ otherwise
  def attributeLegal? key
   legal? self[key]
  end
  
  # Determines whether incoming user data contains any valid data or whether is consindered to be empty
  # - *Args*  :
  #   - +candide+ → test candidate to be checked for its legalness
  # - *Returns* :
  #   - +true+ if data contains simple value or if one of its attributes is set to an non-empty string, or one of its children contains valid data
  #   - +false+ otherwise
  # Recursively tests the current node as well as its children (if there are any)
  def legal? candide
    if candide
      if (candide.kind_of?(Array) || candide.kind_of?(String)) &&  !candide.empty?
        return true
      elsif candide.kind_of?(Hash)
        if candide[:value] && candide[:value].kind_of?(String) && !candide[:value].empty?
          return true
        end

        if candide[:attributes] && candide[:attributes].kind_of?(Hash)
          candide[:attributes].each_pair{|key, value|
            if value && value.kind_of?(String) && !value.empty?
              return true
            end
          }
        end

        if candide[:children] && candide[:children].kind_of?(Hash)
          candide[:children].each_pair{|key, child|
            if legal = legal?(child)
              return true
            end
          }
        end
      end
    end
    false
  end

  # Some EpiDoc nodes need to be given in a certain order (in order to represent valid EpiDoc or to suffice special HGV needs), this method sorts nodes +msIdentifier+, +altIdentifier[@type='temporary']+ for TEI:msIdentifier and +offset+ for TEI:date
  # - *Args*  :
  #   - +doc+ → REXML::Document that contains HGV EpiDoc xml which should be sorted
  # - *Returns* :
  #   - version of +doc+ with correctly ordered TEI elements
  # Side effect on +doc+
  def sort doc
    # general
    sort_paths = {
      :teiHeader => {
        :parent => '/TEI/teiHeader',
        :children => ['fileDesc', 'encodingDesc', 'profileDesc', 'revisionDesc']
      },
      :msIdentifier => {
        :parent => '/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msIdentifier',
        :children => ['placename', 'collection', 'idno', 'altIdentifier']
      },
      :altIdentifier => {
        :parent => "/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msIdentifier/altIdentifier[@type='temporary']",
        :children => ['placename', 'collection', 'idno', 'note']
      },
      :msDesc => {
        :parent => "/TEI/teiHeader/fileDesc/sourceDesc/msDesc",
        :children => ['msIdentifier', 'physDesc', 'history', 'additional']
      },
      :publicationStmt => {
        :parent => "/TEI/teiHeader/fileDesc/publicationStmt",
        :children => ['authority', 'idno', 'availability']
      }
    }

    sort_paths.each_value {|sort_path|
    
      if parent = doc.elements[sort_path[:parent]]
        sort_path[:children].each {|child_path|
          parent.elements.each(child_path){|child|
            parent.delete child
            parent.add child
          }
        }
      end
    }
    
    # date
    if @configuration.scheme[:textDate]
      doc.elements.each(@configuration.scheme[:textDate][:xpath]){|date|
        if date.elements['offset']

          hgvFormat = ''
          date.texts.each{|text|
            hgvFormat += text.value
            date.delete text  
          }
          hgvFormat = hgvFormat.gsub(/(vor|nach)( \(\?\))?/, '').strip
        
          offset = date.elements['offset[position()=1]']
          offset2 = date.elements['offset[position()=2]']
        
          date.delete offset
          date.delete offset2        
        
          if offset
            date.add_element offset
            date.add_text REXML::Text.new(' ')
          end
        
          if hgvFormat.include? ' - '
            hgvFormat = hgvFormat.split ' - '
            date.add_text REXML::Text.new(hgvFormat[0] + ' - ')
            if offset2
              date.add_element offset2
              date.add_text REXML::Text.new(' ')
            end
            date.add_text REXML::Text.new(hgvFormat[1])
          else
            date.add_text REXML::Text.new(hgvFormat)
          end

        end
      }
    end

   return doc 
  end

  # Saves a value to +self[key]+ after doing some validity checks and some data sanitisation
  # - *Args*  :
  #   - +key+ → HGV key of interesset
  #   - +value+ → value to be set
  #   - +default+ → default value, defaults to +nil+
  # - *Returns* :
  #   - sanitised value
  # Side effect on +self[key]+
  def populate_epidoc_attribute key, value, default = nil
    if !value
      value = default
    elsif value.instance_of? String
      value = !value.strip.empty? ? value.strip : default
    elsif value.class == Array
      value = value.compact.reject {|item| item.strip.empty? }.collect{|item| item.strip }
    elsif value.kind_of? Hash
      value = value.values.compact.reject {|item| item.strip.empty? }.collect{|item| item.strip }
    end
    self[key] = value    
  end

  # Uses post parameters to recursively populate an internal tree which can be used lateron for easy data access
  # - *Args*  :
  #   - +data+ → post data
  #   - +config+ → HGV configuration
  # - *Returns* :
  #   - data tree
  def populate_tree_from_attributes_hash data, config

    result_item = {
      :value => nil,
      :attributes => {},
      :children => {}
    }

    if data

      if data['value'] && !data['value'].to_s.strip.empty?
        result_item[:value] = data['value'].to_s.strip
      elsif config[:default]
        result_item[:value] = config[:default]
      end

      if config[:attributes]
        config[:attributes].each_pair{|attribute_key, attribute_config|
          if data['attributes'] && data['attributes'][attribute_key] && !data['attributes'][attribute_key].to_s.strip.empty?
            if attribute_config[:split]
              result_item[:attributes][attribute_key] = data['attributes'][attribute_key]
            else
              result_item[:attributes][attribute_key] = data['attributes'][attribute_key].to_s.strip
            end
          elsif attribute_config[:default]
            result_item[:attributes][attribute_key] = attribute_config[:default]
          end
        }
      end

      if config[:children]

        config[:children].each_pair{|child_key, child_config|
          if child_config[:multiple]
            children = []

            if data[:children]
              x = data[:children][child_key].kind_of?(Hash) ? data[:children][child_key].values : (data[:children][child_key].kind_of?(Array) ? data[:children][child_key] : [])
              
              x.each{|child|
                children[children.length] = populate_tree_from_attributes_hash child, child_config # recursion óla
              }
            end
            result_item[:children][child_key] = children
          else
            result_item[:children][child_key] = populate_tree_from_attributes_hash data['children'][child_key], child_config # recursion óla
          end
        }
      end

      if config[:preFlag] and data[:children][:offset][:value] and  data[:children][:offset][:value] == 'bei' # CL: CROMULENT GEO HACK
        result_item[:preFlag] = 'bei'
      end

   end

   result_item
  end

end

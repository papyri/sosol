class BiblioIdentifier < HGVIdentifier
  attr_accessor :configuration, :valid_epidoc_attributes

  PATH_PREFIX = 'Biblio'
  
  XML_VALIDATOR = JRubyXML::EpiDocP5Validator
  
  FRIENDLY_NAME = "Biblio"

  IDENTIFIER_NAMESPACE = 'biblio'

  XPATH = {
    :articleTitle => "/bibl/title[@level='a'][@type='main']",
    :journalTitle => "/bibl/title[@level='j'][@type='main']",
    :bookTitle => "/bibl/title[@level='m'][@type='main']",
    :supertype => "/bibl/@type",
    :subtype => "/bibl/@subtype",
    :language => "/bibl/@xml:lang",    
      
    :bp => "/bibl/idno[@type='bp']",
    :bpOld => "/bibl/idno[@type='bp_old']",
    :idp => "/bibl/@xml:id",
    :isbn => "/bibl/idno[@type='isbn']",
    :sd => "/bibl/idno[@type='sonderdruck']",
    :checklist => "/bibl/idno[@type='checklist']",

    :date => "/bibl/date",
    :edition => "/bibl/edition",
    :issue => "/bibl/biblScope[@type='issue']",
    :distributor => "/bibl/distributor",
    :paginationFrom => "/bibl/biblScope[@type='page']/@from",
    :paginationTo => "/bibl/biblScope[@type='page']/@to",
    :paginationTotal => "/bibl/note[@type='pageCount']",
    :paginationPreface => "/bibl/note[@type='prefacePageCount']",
    :illustration => "/bibl/note[@type='illustration']",
    :no => "/bibl/biblScope[@type='no']",
    :col => "/bibl/biblScope[@type='col']",
    :tome => "/bibl/biblScope[@type='tome']",
    :link => "/bibl/ptr/@target",
    :fasc => "/bibl/biblScope[@type='fasc']",
    :reedition => "/bibl/relatedItem[@type='reedition'][@subtype='reference']/bibl[@type='publication'][@subtype='other']",

    :authorList => "/bibl/author",
    :editorList => "/bibl/editor",
      
    :journalTitleShort => "/bibl/title[@level='j'][@type='short']",
    :bookTitleShort => "/bibl/title[@level='m'][@type='short']",
    
    :publisherList => "/bibl/node()[name() = 'publisher' or name() = 'pubPlace']",
    :relatedArticleList => "/bibl/relatedItem[@type='mentions']/bibl",
    :note => "/bibl/note[@resp]",
    
    :revieweeList => "/bibl/relatedItem[@type='reviews']/bibl",
    :containerList => "/bibl/relatedItem[@type='appearsIn']/bibl"
  }

  def id_attribute
    return "b#{name}"
  end

  def n_attribute
    return ''
  end

  def xml_title_text
    return ''
  end

  def to_path
    if name =~ /#{self.class::TEMPORARY_COLLECTION}/
      return self.temporary_path
    else
      path_components = [ PATH_PREFIX ]
      # assume the name is e.g. biblio/9237
      number = self.to_components.last.to_i # 9237

      dir_number = ((number - 1) / 1000) + 1
      xml_path = number.to_s + '.xml'

      path_components << dir_number.to_s << xml_path

      # e.g. Biblio/10/9237.xml
      return File.join(path_components)
    end
  end
  
  def self.XPATH key
    XPATH[key.to_sym] ? XPATH[key.to_sym] : '----'
  end

  def preview parameters = {}, xsl = nil
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        xsl ? xsl : %w{data xslt biblio start-html.xsl})),
        parameters)
  end
  
  def mutable?
    true
  end

  # Validation of identifier XML file against tei-epidoc.rng file
  # - *Args*  :
  #   - +content+ -> XML to validate if passed in, pulled from repository if not passed in
  # - *Returns* :
  #   - true/false
  def is_valid_xml?(content = nil)
    if content.nil?
      content = self.xml_content
    end
    self.class::XML_VALIDATOR.instance.validate(
      JRubyXML.input_source_from_string(wrap_xml(content)))
  end

  # Wrap biblio xml stub in biblio xml wrapper to make it valid TEI
  # - *Args*  :
  #   - +content+ -> XML to wrap
  # - *Returns* :
  #   - wrapped XML content as String
  def wrap_xml(content)
    xml_stub = REXML::Document.new(content)
    xml_wrapper = REXML::Document.new(File.new(File.join(RAILS_ROOT, ['data','templates'], 'biblio_dummy_wrapper.xml')))
    basepath = '/TEI/text/body/div[@type = "bibliography"]'
    add_node_here = REXML::XPath.first(xml_wrapper, basepath)
    add_node_here.add_element xml_stub.root

    wrapped_xml_content = ''
    xml_wrapper.write(wrapped_xml_content)

    return wrapped_xml_content
  end

  # Creates REXML object model from xml string
  def epiDoc
    REXML::Document.new(self.xml_content)
  end
  
  # Retrieves data from xml or sets empty defaults
  def after_find

    self[:articleTitle] = ''
    self[:journalTitle] = ''
    self[:journalTitleShort] = Array.new
    self[:bookTitle] = ''
    self[:bookTitleShort] = Array.new
    self[:supertype] = ''
    self[:subtype] = ''
    self[:language] = ''    
    
    self[:bp] = ''
    self[:bpOld] = ''
    self[:idp] = ''
    self[:isbn] = ''
    self[:sd] = ''
    self[:checklist] = ''

    self[:date] = ''
    self[:edition] = ''
    self[:issue] = ''
    self[:distributor] = ''
    self[:paginationFrom] = ''
    self[:paginationTo] = ''
    self[:paginationTotal] = ''
    self[:paginationPreface] = ''
    self[:illustration] = ''
    self[:note] = Array.new
    self[:reedition] = ''
    
    self[:monograph] = nil
    self[:series] = nil
    self[:journal] = nil
    self[:publisherList] = Array.new
    
    self[:authorList] = Array.new
    self[:editorList] = Array.new
    self[:revieweeList] = Array.new
    self[:containerList] = Array.new
    self[:relatedArticleList] = Array.new
    self[:originalBp] = Hash.new
    
    populateFromEpiDoc
  end
 
  # Returns a String of the SHA1 of the commit
  def set_epidoc(attributes_hash, comment)
    epiDocXml = updateFromPost(attributes_hash)

    Rails.logger.info(epiDocXml)
    self.set_xml_content(epiDocXml, :comment => comment)
  end

  def updateFromPost params
    @post = params
    @epiDoc = self.epiDoc

    updateFromPostSimple :articleTitle
    updateFromPostSimple :journalTitle
    updateFromPostSimple :bookTitle
    updateFromPostSimple :supertype
    updateFromPostSimple :subtype
    updateFromPostSimple :language
    
    updateFromPostSimple :bp
    updateFromPostSimple :bpOld
    updateFromPostSimple :idp
    updateFromPostSimple :isbn
    updateFromPostSimple :sd
    updateFromPostSimple :checklist

    updateFromPostSimple :date
    updateFromPostSimple :edition
    updateFromPostSimple :issue
    updateFromPostSimple :distributor
    updateFromPostSimple :paginationFrom
    updateFromPostSimple :paginationTo
    updateFromPostSimple :paginationTotal
    updateFromPostSimple :paginationPreface
    updateFromPostSimple :illustration
    updateFromPostSimple :no
    updateFromPostSimple :col
    updateFromPostSimple :tome
    updateFromPostSimple :link
    updateFromPostSimple :fasc
    updateFromPostSimple :reedition
    
    updateFromPostPerson :authorList
    updateFromPostPerson :editorList
    
    updateFromPostShortTitle :journalTitleShort
    updateFromPostShortTitle :bookTitleShort
    
    updateFromPostNote
   
    updateFromPostPublisher
  
    # Causes e.g.: undefined method `array' for #<BiblioIdentifier::Reviewee:0x12983349> 
    updateFromPostReviewee
   
    # Causes e.g.: undefined method `array' for #<BiblioIdentifier::Container:0x2341952a> 
    updateFromPostContainer
   
    updateFromPostRelatedArticle

    updateEpiDoc
    
    # write back to a string
    modified_xml_content = toXmlString @epiDoc

    modified_xml_content
  end
  
  def toXmlString xmlObject
    formatter = REXML::Formatters::Pretty.new
    formatter.compact = true
    formatter.width = 512
    modified_xml_content = ''
    formatter.write xmlObject, modified_xml_content
    modified_xml_content
  end
 
  def updateFromPostSimple key
    self[key] = @post[key] && @post[key].kind_of?(String) && !@post[key].strip.empty? ? @post[key].strip : nil
  end
  
  def updateFromPostPerson key
    list = []
    if @post[key] &&  @post[key].kind_of?(Hash)
      @post[key].each_pair {|index, person|
        newbie = PublicationPerson.new
        if person[:firstName] && !person[:firstName].strip.empty?
          newbie.firstName = person[:firstName].strip
        end
        if person[:lastName] && !person[:lastName].strip.empty?
          newbie.lastName = person[:lastName].strip
        end
        if person[:name] && !person[:name].strip.empty?
          newbie.name = person[:name].strip
        end
        list[list.length] = newbie
      }
    end
    self[key] = list
  end
    
  def updateFromPostShortTitle key
    list = []
    if @post[key] && @post[key].kind_of?(Hash)
      @post[key].each_pair{|index, title|
        if !title[:title].strip.empty?
          list[list.length] = ShortTitle.new(title[:title].strip, !title[:responsibility].strip.empty? ? title[:responsibility].strip : nil)
        end
      }
    end
    self[key] = list
  end

  def updateFromPostNote
    self[:note] = []
    if @post[:note] && @post[:note].kind_of?(Hash)
      @post[:note].each_pair{|index, note|
        if !note[:annotation].strip.empty?
          self[:note][self[:note].length] = Note.new(!note[:responsibility].strip.empty? ? note[:responsibility].strip : nil, note[:annotation].strip)
        end
      }
    end
  end

  def updateFromPostPublisher
    self[:publisherList] = []
    if @post[:publisherList] && @post[:publisherList].kind_of?(Hash)
      @post[:publisherList].each_pair{|index, publisher|
        if publisher[:value] && publisher[:publisherType] && !publisher[:value].strip.empty? && ['pubPlace', 'publisher'].include?(publisher[:publisherType].strip)
          self[:publisherList][self[:publisherList].length] = Publisher.new(publisher[:publisherType].strip, publisher[:value].strip)
        end
      }
    end
  end

  def updateFromPostReviewee
    updateFromPostRelatedItem :revieweeList, Reviewee
  end

  def updateFromPostContainer
    updateFromPostRelatedItem :containerList, Container
  end

  def updateFromPostRelatedItem typeX, classX
    self[typeX] = []
    if @post[typeX] && @post[typeX].kind_of?(Hash)
      @post[typeX].each_pair{|key, pointer|
        self[typeX][self[typeX].length] = classX.new(pointer)
    }
    end
  end

  def updateFromPostRelatedArticle
    self[:relatedArticleList] = []
    if @post[:relatedArticleList] && @post[:relatedArticleList].kind_of?(Hash)
      @post[:relatedArticleList].each_pair{|key, article|
        series    = article[:series]
        volume    = article[:volume]
        number    = article[:number]
        ddb       = article[:ddb]
        tm        = article[:tm]
        inventory = article[:inventory]
  
        self[:relatedArticleList][self[:relatedArticleList].length] = RelatedArticle.new(series, volume, number, ddb, tm, inventory)
      }
    end
  end
  
  def updateEpiDoc

    [:articleTitle, :journalTitle, :bookTitle, :supertype, :subtype, :language, :bp, :bpOld, :isbn, :sd, :checklist, :date, :edition, :issue, :distributor, :paginationFrom, :paginationTo, :paginationTotal, :paginationPreface, :illustration, :no, :col, :tome, :link, :fasc, :reedition].each{|key|
      attribute = nil
      path = XPATH[key]
      if path =~ /(.+)\/@([^\[\]\/]+)\Z/
        path = $1
        attribute = $2
      end
      if self[key] && !self[key].strip.empty?
        element = @epiDoc.bulldozePath path
        unless element.nil?
          if attribute
            element.attributes[attribute] = self[key]
          else
            element.text = self[key]
          end
        end
      else
        if path != '/bibl'
          @epiDoc.elements.delete_all path
        end
      end

    }

    [:authorList, :editorList].each{|key|
      @epiDoc.elements.delete_all XPATH[key]
      index = 1
      self[key].each{|person|
        element = @epiDoc.bulldozePath XPATH[key] + "[@n='" + index.to_s + "']"
        unless element.nil?
          if person.name && !person.name.empty?
            element.text = person.name
          end
          if person.firstName && !person.firstName.empty?
            child = REXML::Element.new 'forename'
            child.text = person.firstName
            element.add child
          end
          if person.lastName && !person.lastName.empty?
            child = REXML::Element.new 'surname'
            child.text = person.lastName
            element.add child
          end
        end
        index += 1
      }
    }

    @epiDoc.elements.delete_all XPATH[:publisherList]
    if self[:publisherList] && self[:publisherList].kind_of?(Array)
      basePath = XPATH[:publisherList][/\A(.+)node\(\).+\Z/, 1]
      
      index = {'pubPlace' => 1, 'publisher' => 1}
      self[:publisherList].each{|publisher|
        if publisher.value && !publisher.value.empty?
          element = @epiDoc.bulldozePath basePath + publisher.publisherType + "[@n='" + index[publisher.publisherType].to_s + "']"
          element.text = publisher.value
          index[publisher.publisherType] += 1
        end
      }
    end


   [:journalTitleShort, :bookTitleShort].each{|key|
     @epiDoc.elements.delete_all XPATH[key]
     index = 1
     self[key].each{|shorty|
       if shorty.title && !shorty.title.empty?
         element = @epiDoc.bulldozePath XPATH[key] + "[@n='" + index.to_s + "']"
         element.text = shorty.title
         if shorty.responsibility && !shorty.responsibility.empty?
           element.attributes['resp'] = shorty.responsibility
         end
         index += 1
       end
     }
     
   }

   @epiDoc.elements.delete_all XPATH[:note]
    if self[:note] && self[:note].kind_of?(Array)
      path = XPATH[:note][/\A(.+)\[@resp\]\Z/, 1]
      index = 1
      self[:note].each{|note|
        if note.annotation && !note.annotation.empty?
          element = @epiDoc.bulldozePath path + "[@n='" + index.to_s + "']"
          element.text = note.annotation
         if note.responsibility && !note.responsibility.empty?
           element.attributes['resp'] = note.responsibility
         end
         index += 1
        end
      }
    end

    updateEpiDocRelatedItem :revieweeList
    updateEpiDocRelatedItem :containerList
    
    xpathBase = XPATH[:relatedArticleList][/\A(.+)(\/bibl)\Z/, 1]
    xpathBibl = $2
    @epiDoc.elements.delete_all xpathBase
    if self[:relatedArticleList] && self[:relatedArticleList].kind_of?(Array)
      index = 1
      self[:relatedArticleList].each{|relatedArticle|

        element = @epiDoc.bulldozePath xpathBase + "[@n='" + index.to_s + "']" + xpathBibl

        if relatedArticle.series && !relatedArticle.series.empty?
          child = REXML::Element.new 'title', element
          child.attributes['level'] = 's'
          child.attributes['type'] = 'short'
          child.text = relatedArticle.series
        end

        if relatedArticle.volume && !relatedArticle.volume.empty?
          child = REXML::Element.new 'biblScope', element
          child.attributes['type'] = 'vol'
          child.text = relatedArticle.volume
        end
        
        if relatedArticle.number && !relatedArticle.number.empty?
          child = REXML::Element.new 'biblScope', element
          child.attributes['type'] = 'number'
          child.text = relatedArticle.number
        end
        
        if relatedArticle.ddb && !relatedArticle.ddb.empty?
          child = REXML::Element.new 'idno', element
          child.attributes['type'] = 'ddb'
          child.text = relatedArticle.ddb
        end
        
        if relatedArticle.tm && !relatedArticle.tm.empty?
          child = REXML::Element.new 'idno', element
          child.attributes['type'] = 'tm'
          child.text = relatedArticle.tm
        end
        
        if relatedArticle.inventory && !relatedArticle.inventory.empty?
          child = REXML::Element.new 'idno', element
          child.attributes['type'] = 'invNo'
          child.text = relatedArticle.inventory
        end        

        index += 1
      }
    end

  end
  
  def updateEpiDocRelatedItem key
    xpathBase = XPATH[key][/\A(.+)(\/bibl)\Z/, 1]
    xpathBibl = $2
    @epiDoc.elements.delete_all xpathBase
    if self[key] && self[key].kind_of?(Array)
      index = 1
      self[key].each{|relatedItem|
        element = @epiDoc.bulldozePath xpathBase + "[@n='" + index.to_s + "']" + xpathBibl
        unless element.nil?
          ptr = REXML::Element.new('ptr')
          ptr.attributes['target'] = relatedItem.pointer
          element.add ptr
          REXML::Comment.new(' ignore - start, i.e. SoSOL users may not edit this ', element)
          getRelatedItemElements(relatedItem.pointer).each{|ignore|
            element.add ignore
          }
          REXML::Comment.new(' ignore - stop ', element)
        end
        index += 1
      }
    end
  end
  
  def getRelatedItemElements biblioId
    result = []

    begin
      biblioId = biblioId[/\A[^\d]*([\d\-]+)\Z/, 1] # expecting sth like http://papyri.info/biblio/12345 or like http://papyri.info/biblio/2010-123345 or just the id, i.e. 12345 or 2010-12345
  
      git = Grit::Repo.new(CANONICAL_REPOSITORY).commits.first.tree
      biblio = git / getBiblioPath(biblioId)
      relatedItem = REXML::Document.new(biblio.data)

      result[result.length] = if relatedItem.elements["//title[@type='short']"]
        relatedItem.elements["//title[@type='short']"]
      else
        relatedItem.elements["//title"]
      end
  
      ["//author", "//pubPlace", "//date", "//editor"].each{|xpath|
        if relatedItem.elements[xpath]
          result[result.length] = relatedItem.elements[xpath]
        end
      }
      
      return result
    rescue
      return result
    end
  end

  def getBiblioPath biblioId
    if biblioId.include?('-')
      biblioId = biblioId[/\A(\d+)-(\d+)\Z/, 1]
      folder = $2
      'Biblio/' + folder + '/'  + biblioId.to_s + '.xml'
    else
      'Biblio/' + (biblioId.to_i / 1000.0).ceil.to_s + '/'  + biblioId.to_s + '.xml'
    end
  end

  protected

    def populateFromEpiDoc

      populateFromEpiDocSimple :articleTitle
      populateFromEpiDocSimple :journalTitle
      populateFromEpiDocSimple :bookTitle
      populateFromEpiDocSimple :supertype
      populateFromEpiDocSimple :subtype
      populateFromEpiDocSimple :language
      
      populateFromEpiDocSimple :bp
      populateFromEpiDocSimple :bpOld
      populateFromEpiDocSimple :idp
      populateFromEpiDocSimple :isbn
      populateFromEpiDocSimple :sd
      populateFromEpiDocSimple :checklist

      populateFromEpiDocSimple :date
      populateFromEpiDocSimple :edition
      populateFromEpiDocSimple :issue
      populateFromEpiDocSimple :distributor
      populateFromEpiDocSimple :paginationFrom
      populateFromEpiDocSimple :paginationTo
      populateFromEpiDocSimple :paginationTotal
      populateFromEpiDocSimple :paginationPreface
      populateFromEpiDocSimple :illustration
      populateFromEpiDocSimple :no
      populateFromEpiDocSimple :col
      populateFromEpiDocSimple :tome
      populateFromEpiDocSimple :link
      populateFromEpiDocSimple :fasc
      populateFromEpiDocSimple :reedition

      populateFromEpiDocPerson :authorList
      populateFromEpiDocPerson :editorList
      
      populateFromEpiDocShortTitle :journalTitleShort
      populateFromEpiDocShortTitle :bookTitleShort
      
      populateFromEpiDocNote
     
      populateFromEpiDocPublisher
     
      populateFromEpiDocReviewee
      
      populateFromEpiDocContainer
     
      populateFromEpiDocRelatedArticle
     
      populateFromEpiDocOriginalBp

    end

    def populateFromEpiDocSimple key
      attribute = nil
      path = XPATH[key]
      if path =~ /(.+)\/@([^\[\]\/]+)\Z/
        path = $1
        attribute = $2
      end
      if epiDoc.elements[path]
        if attribute
          self[key] = epiDoc.elements[path].attributes[attribute]
        else
          self[key] = epiDoc.elements[path].text
        end
      else
        self[key] = ''
      end
    end

    def populateFromEpiDocPerson key
      list = []
      path = XPATH[key]
      epiDoc.elements.each(path){|person|

        newbie = PublicationPerson.new
        indexFirst = indexLast = 0
        if element = person.elements['forename']
          newbie.firstName = element.text.strip
          indexFirst = element.index_in_parent
        end
        if element = person.elements['surname']
          newbie.lastName = element.text.strip
          indexLast = element.index_in_parent
        end
        if person.text
          newbie.name = person.text.strip
        end
        if (indexLast != 0) && (indexFirst != 0) && indexLast > indexFirst
          newbie.swap = true
        end
        list[list.length] = newbie
      }

      self[key] = list
    end
    
    def populateFromEpiDocShortTitle key
      list = []
      path = XPATH[key]
      epiDoc.elements.each(path){|title|
        list[list.length] = ShortTitle.new(title.text, title.attributes['resp'] ? title.attributes['resp'] : '')
      }
      self[key] = list
    end

    def populateFromEpiDocPublisher
      epiDoc.elements.each(XPATH[:publisherList]){|element|
        type = element.name.to_s
        value = element.text
        self[:publisherList][self[:publisherList].length] = Publisher.new(type, value)
      }
    end

    def populateFromEpiDocNote
      epiDoc.elements.each(XPATH[:note]){|element|
        if element.attributes.include?('resp')
          self[:note][self[:note].length] = Note.new(element.attributes['resp'], element.text)
        end
      }
    end

    def populateFromEpiDocReviewee
      populateFromEpiDocRelatedItem :revieweeList, Reviewee
    end

    def populateFromEpiDocContainer
      populateFromEpiDocRelatedItem :containerList, Container
    end
    
    def populateFromEpiDocRelatedItem typeX, classX
      epiDoc.elements.each(XPATH[typeX]){|bibl|
        pointer = bibl.elements['ptr'] && bibl.elements['ptr'].attributes && bibl.elements['ptr'].attributes['target'] ? bibl.elements['ptr'].attributes['target'] : ''
        ignore = {}
        
        bibl.elements.each{|child|
          
          if child.name != 'ptr'
            key = child.name.to_s
            if key == 'idno' && child.attributes && child.attributes['type']
              key = child.attributes['type']
            end

            ignore[key] = child.text ? child.text : '?'
          end
        }

        self[typeX][self[typeX].length] = classX.new(pointer, ignore)
      }
    end

    def populateFromEpiDocRelatedArticle
      epiDoc.elements.each(XPATH[:relatedArticleList]){|bibl|
        series    = bibl.elements["title[@level='s'][@type='short']"] ? bibl.elements["title[@level='s'][@type='short']"].text : ''
        volume    = bibl.elements["biblScope[@type='vol']"] ? bibl.elements["biblScope[@type='vol']"].text : ''
        number    = bibl.elements["biblScope[@type='number']"] ? bibl.elements["biblScope[@type='number']"].text : ''
        ddb       = bibl.elements["idno[@type='ddb']"] ? bibl.elements["idno[@type='ddb']"].text : ''
        tm        = bibl.elements["idno[@type='tm']"] ? bibl.elements["idno[@type='tm']"].text : ''
        inventory = bibl.elements["idno[@type='invNo']"] ? bibl.elements["idno[@type='invNo']"].text : ''

        self[:relatedArticleList][self[:relatedArticleList].length] = RelatedArticle.new(series, volume, number, ddb, tm, inventory)
      }
    end

    def populateFromEpiDocOriginalBp
      {
        'Index'         => "/bibl/seg[@type='original'][@subtype='index']",
        'Index bis'     => "/bibl/seg[@type='original'][@subtype='indexBis']",
        'Titre'         => "/bibl/seg[@type='original'][@subtype='titre']",
        'Publication'   => "/bibl/seg[@type='original'][@subtype='publication']",
        'Resumé'        => "/bibl/note[@resp='#BP']",
        'S.B. & S.E.G.' => "/bibl/seg[@type='original'][@subtype='sbSeg']",
        'C.R.'          => "/bibl/seg[@type='original'][@subtype='cr']"
      }.each_pair{|title, xpath|
        element = epiDoc.elements[xpath]
        if element && element.text && !element.text.strip.empty?
          self[:originalBp][title] = element.text.strip
        end
      }
    end
  
  class PublicationPerson
    attr_accessor :firstName, :lastName, :name, :swap
    def initialize firstName = '', lastName = '', name = '', swap = false
      @firstName = firstName
      @lastName = lastName
      @name = name
      @swap = swap
    end
  end

=begin
  class PublicationEntity
    attr_accessor :title, :titleShort, :number
    def initialize title = '', titleShort = '', number = ''
      @title = title
      @titleShort = titleShort
      @number = number
    end
  
  class Monograph < PublicationEntity
  end

  class Journal < PublicationEntity
  end

  class Series < PublicationEntity
  end

  class RevueCritique
    attr_accessor :author, :title, :year, :page
    def initialize author = '', title = '', year = '', page = ''
      @author = author
      @title = title
      @year = year
      @page = page
    end
  end
 
=end

  class RelatedItem # appearsIn, reviews
    attr_accessor :pointer, :ignoreList, :ignored
    def initialize pointer = '', ignoreList = {}
      @pointer = pointer
      @ignoreList = ignoreList
      
      @ignored = ''
      ignoreList.each_pair {|key, value|
        if !value.strip.empty?
          @ignored += key.titleize + ': ' + value.strip + ', '
        end
      }
      @ignored = @ignored[0..-3]
    end
  end
  
  class Reviewee < RelatedItem
    
  end
  
  class Container < RelatedItem
    
  end
  
  class ShortTitle
    attr_accessor :title, :responsibility
    def initialize title = '', responsibility = ''
      @title = title
      @responsibility = responsibility 
    end
  end
  
  class Note
    attr_accessor :responsibility, :annotation
    def initialize responsibility = '', annotation = ''
      @responsibility = responsibility
      @annotation = annotation
    end
  end

  class RelatedArticle
    attr_accessor :series, :volume, :number, :ddb, :tm, :inventory
    def initialize series = '', volume = '', number = '', ddb = '', tm = '', inventory = ''
      @series = series
      @volume = volume
      @number = number
      @tm = tm
      @ddb = ddb
      @inventory = inventory
    end
  end

  class Publisher
    attr_accessor :publisherType, :value
    def initialize publisherType = '', value = ''
      @publisherType = publisherType
      @value = value
    end
  end
end

# encoding: utf-8

# Model class for bibliography records as they reside in the Biblio folder of idp.data's git repository
class BiblioIdentifier < HGVIdentifier
  attr_accessor :configuration, :valid_epidoc_attributes

  # Repository file path prefix
  PATH_PREFIX = 'Biblio'
 
  
  FRIENDLY_NAME = "Biblio"

  IDENTIFIER_NAMESPACE = 'biblio'

  # A map (key → xpath) of all relevant xpaths for data lookup and storage
  XPATH = {
    :supertype => "/bibl/@type",
    :subtype => "/bibl/@subtype",
    :language => "/bibl/@xml:lang",
    :idp => "/bibl/@xml:id",
    
    :articleTitle => "/bibl/title[@level='a'][@type='main']",
    :journalTitle => "/bibl/title[@level='j'][@type='main']",
    :journalTitleShort => "/bibl/title[@level='j'][starts-with(@type, 'short')]",
    :bookTitle => "/bibl/title[@level='m'][@type='main']",
    :bookTitleShort => "/bibl/title[@level='m'][starts-with(@type, 'short')]",
    
    :seriesTitle => "/bibl/series/title[@level='s'][@type='main']",
    :seriesVolume => "/bibl/series/biblScope[@type='volume']",
    :papyrologicalSeriesTitle => "/bibl/note[@type='papyrological-series']/bibl/title[@level='s'][@type='main']",
    :papyrologicalSeriesVolume => "/bibl/note[@type='papyrological-series']/bibl/biblScope[@type='volume']",
    :papyrologicalSeriesTitleShort => "/bibl/note[@type='papyrological-series']/bibl/title[@level='s'][starts-with(@type, 'short')]",
    
    :category => "/bibl/note[@type='subject']",

    :authorList => "/bibl/author",
    :editorList => "/bibl/editor",
    
    :date => "/bibl/date",
    :publisherList => "/bibl/node()[name() = 'publisher' or name() = 'pubPlace']",

    :edition => "/bibl/edition",
    :distributor => "/bibl/distributor",
    
    :paginationFrom => "/bibl/biblScope[@type='pp']/@from",
    :paginationTo => "/bibl/biblScope[@type='pp']/@to",
    :paginationTotal => "/bibl/note[@type='pageCount']",
    :paginationPreface => "/bibl/note[@type='prefacePageCount']",
    :illustration => "/bibl/note[@type='illustration']",
    
    :no => "/bibl/biblScope[@type='no']",
    :col => "/bibl/biblScope[@type='col']",
    :tome => "/bibl/biblScope[@type='tome']",
    :link => "/bibl/ptr/@target", # !!!
    :fasc => "/bibl/biblScope[@type='fasc']",
    :reedition => "/bibl/relatedItem[@type='reedition'][@subtype='reference']/bibl[@type='publication'][@subtype='other']",
    
    :note => "/bibl/note[@resp]",
    
    :containerList => "/bibl/relatedItem[@type='appearsIn']/bibl",
    :issue => "/bibl/biblScope[@type='issue']",
    :relatedArticleList => "/bibl/relatedItem[@type='mentions']/bibl",
    :revieweeList => "/bibl/relatedItem[@type='reviews']/bibl",
    
    # :pi => "/bibl/idno[@type='pi']",
    :bp => "/bibl/idno[@type='bp']",
    :bpOld => "/bibl/idno[@type='bp_old']",
    :isbn => "/bibl/idno[@type='isbn']",
    :sd => "/bibl/idno[@type='sonderdruck']",
    :checklist => "/bibl/idno[@type='checklist']"
    
    # seg
  }
  
  XPATH_ORIGINAL = {
    'Index'         => "/bibl/seg[@type='original'][@subtype='index']",
    'Index bis'     => "/bibl/seg[@type='original'][@subtype='indexBis']",
    'Titre'         => "/bibl/seg[@type='original'][@subtype='titre']",
    'Publication'   => "/bibl/seg[@type='original'][@subtype='publication']",
    'Resumé'        => "/bibl/seg[@type='original'][@subtype='resume']",
    'S.B. & S.E.G.' => "/bibl/seg[@type='original'][@subtype='sbSeg']",
    'C.R.'          => "/bibl/seg[@type='original'][@subtype='cr']",
    'Nom'           => "/bibl/seg[@type='original'][@subtype='nom']"
  }

  # Used for template creation. See Identifier#file_template
  # - *Returns*
  #   - last identifier URI path component prefixed by 'b', for xml:id conformity
  def id_attribute
    return "b#{name.split('/').last}"
  end

  # Used for template creation. See Identifier#file_template
  # - *Returns*
  #   - empty string, unused in bibliography template
  def n_attribute
    return ''
  end

  # Used for template creation. See Identifier#file_template
  # - *Returns*
  #   - empty string, unused in bibliography template
  def xml_title_text
    return ''
  end

  # Determines the next 'SoSOL' temporary name for the associated identifier
  # This overrides the identifier superclass definition so that SoSOL-side biblio
  # id's will be e.g. papyri.info/biblio/2011-0001 instead of papyri.info/biblio/SoSOL;2011;0001
  # - starts at '1' each year
  # - *Returns* :
  #   - temporary identifier name
  def self.next_temporary_identifier
    year = Time.now.year
    latest = self.find(:all,
                       :conditions => ["name like ?", "papyri.info/#{self::IDENTIFIER_NAMESPACE}/#{year}-%"],
                       :order => "name DESC",
                       :limit => 1).first
    if latest.nil?
      # no constructed id's for this year/class
      document_number = 1
    else
      document_number = latest.to_components.last.split('-').last.to_i + 1
    end
    
    return sprintf("papyri.info/#{self::IDENTIFIER_NAMESPACE}/%04d-%04d",
                   year, document_number)
  end

  # Turns identifier into repository file path.
  # e.g.:
  # - papyri.info/biblio/18003:: Biblio/19/18003.xml
  # - papyri.info/biblio/SoSOL/2011-0001:: Biblio/SoSOL/2011/0001.xml
  # - *Returns*:
  #   - file path as string
  def to_path
    path_components = [ PATH_PREFIX ]
    if name.split('-').length > 1
      document_id = name.split('/').last
      year, document = document_id.split('-')
      xml_path = document.to_s + '.xml'
      
      # path_components will be e.g. PATH_PREFIX,SoSOL,2011,0001.xml
      path_components << self.class::TEMPORARY_COLLECTION << year << xml_path
    else
      # assume the name is e.g. biblio/9237
      number = self.to_components.last.to_i # 9237

      dir_number = ((number - 1) / 1000) + 1
      xml_path = number.to_s + '.xml'

      path_components << dir_number.to_s << xml_path
    end
    # e.g. Biblio/10/9237.xml
    return File.join(path_components)
  end
  
  # Retrieve xpath for a given key
  # - *Args*  :
  #   - +key+ → biblio key, e.g. +:articleTitle+
  # - *Returns* :
  #   - xpath as stored within +XPATH+ variable or an empty string if no xpath could be found
  def self.XPATH key
    XPATH[key.to_sym] ? XPATH[key.to_sym] : ''
  end

  # Generates a preview document by running an xsl transformation on the biblio xml document
  # - *Args*  :
  #   - +parameters+ → additional parameters to controll the transformation process (optional), should be given as a +Hash+, e.g. {'citationStyle' => 'Sammelbuch'}
  #   - +xsl+ → +String+ or +Array+, path to xsl document for the transformation, starting from +Rails.root+
  # - *Returns* :
  #   - +String+, result of xsl transformation
  def preview parameters = {}, xsl = nil
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        xsl ? xsl : %w{data xslt biblio pn-preview.xsl})),
        parameters)
  end
  
  # Checks whether the user may be allowed to edit the content of this biblio record
  # - *Returns* :
  #   - true if user may make changes to the data stored within EpiDoc
  #   - false otherwise
  # Assumes that there is no restriction to editing biblio files
  def mutable?
    true
  end

  # Validation of identifier XML file against tei-epidoc.rng file.
  # Overridden from Identifier#is_valid_xml? to wrap bibliography stub XML in EpiDoc wrapper before validation.
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
    xml_wrapper = REXML::Document.new(File.new(File.join(Rails.root, ['data','templates'], 'biblio_dummy_wrapper.xml')))
    basepath = '/TEI/text/body/div[@type = "bibliography"]'
    add_node_here = REXML::XPath.first(xml_wrapper, basepath)
    add_node_here.add_element xml_stub.root

    wrapped_xml_content = ''
    xml_wrapper.write(wrapped_xml_content)

    return wrapped_xml_content
  end

  # Creates REXML object model from xml string
  # - *Returns* :
  #   - +REXML::Document+ with biblio EpiDoc
  def epiDoc
    @epiDocX ||= REXML::Document.new(self.xml_content)
  end
  
  after_find :after_find_retrieve
  # Retrieves data from xml or sets empty defaults
  # Side effect on +self+ attributes
  def after_find_retrieve

    self[:articleTitle] = ''
    self[:journalTitle] = ''
    self[:journalTitleShort] = Array.new
    self[:seriesTitle] = ''
    self[:seriesVolume] = ''
    self[:papyrologicalSeriesTitle] = ''
    self[:papyrologicalSeriesVolume] = ''
    self[:papyrologicalSeriesTitleShort] = Array.new
    self[:category] = ''
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

  # Updates EpiDoc file with values from incoming post string, validates xml and commits it to the user repository
  # - *Args*  :
  #   - +attributes_hash+ → post parameters
  #   - +comment+ → user comment passed in via post
  # - *Returns* :
  #   - +String+ of the SHA1 of the commit
  # Side effect on user's git repository branch, writes altered xml back to file
  def set_epidoc(attributes_hash, comment)
    epiDocXml = updateFromPost(attributes_hash)

    Rails.logger.info(epiDocXml)
    self.set_xml_content(epiDocXml, :comment => comment)
  end
 
  # Commits identifier XML to the repository.
  # Overrides Identifier#set_content to reset memoized value set in BiblioIdentifier#epiDoc.
  # - *Args*  :
  #   - +content+ -> the XML you want committed to the repository
  #   - +options+ -> hash of options to pass to repository (ex. - :comment, :actor)
  # - *Returns* :
  #   - a String of the SHA1 of the commit
  def set_content(content, options = {})
    @epiDocX = nil
    super
  end

  # Updates internal EpiDoc representation from user parameters
  # - *Args*  :
  #   - +params+ → post data sent in from the client's form
  # - *Returns* :
  #   - +String+ EpiDoc xml containing altered version of the file
  # Side effect on +@post+ (contains original post data) and +@epiDoc+ (REXML::Document, updated version of the biblio record)
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
    
    updateFromPostSimple :seriesTitle
    updateFromPostSimple :seriesVolume
    updateFromPostSimple :papyrologicalSeriesTitle
    updateFromPostSimple :papyrologicalSeriesVolume
    updateFromPostSimple :category
    
    updateFromPostPerson :authorList
    updateFromPostPerson :editorList
    
    updateFromPostShortTitle :journalTitleShort
    updateFromPostShortTitle :bookTitleShort
    updateFromPostShortTitle :papyrologicalSeriesTitleShort

    updateFromPostNote

    updateFromPostPublisher

    updateFromPostReviewee
    
    updateFromPostContainer

    updateFromPostRelatedArticle

    updateEpiDoc
    
    sortEpiDoc
    
    # write back to a string
    modified_xml_content = toXmlString @epiDoc

    modified_xml_content
  end
  
  # Converts REXML::Document / ::Element into xml string
  # - *Args*  :
  #   - +xmlObject+ → REXML::Document / ::Element
  # - *Returns* :
  #   - +String+ formatted xml string using child class PrettySsime of parent class +REXML::Formatters::Pretty+
  def toXmlString xmlObject
    formatter = PrettySsime.new
    formatter.compact = true
    formatter.width = 2**32
    modified_xml_content = ''
    formatter.write xmlObject, modified_xml_content
    modified_xml_content
  end
  
  # Shifts TEI:seg tags and TEI:indo tags down to the bottom of the document
  # Assumes that @epiDoc variable contains REXML::Document of current biblio record
  # Side effect on +@epiDoc+ (changes order of elements)
  def sortEpiDoc
    finalOrder.each{|xpath|
      @epiDoc.each_element(xpath){|element|
        @epiDoc.root.delete element
        @epiDoc.root.add element
      }
    }
  end
 
  # Updates internal values from post data which are simple strings
  # - *Args*  :
  #   - +key+ → key of element of interest, e.g. +:articleTitle+
  # - *Returns* :
  #   - the new value of +self[key]+
  # Assumes +@post+ contains post data entered by the user
  # Side effect on +self[key]+
  def updateFromPostSimple key
    self[key] = @post[key] && @post[key].kind_of?(String) && !@post[key].strip.empty? ? @post[key].strip : nil
  end
  
  # Updates internal variables that contains names
  # - *Args*  :
  #   - +key+ → key of person category of interest, may be either +:authorList+ or +:editorList+
  # - *Returns* :
  #   - the new value of +self[key]+ which is an +Array+ containing all +Person+ objects that could be build from post data information
  # Assumes that post data is stored in instance variable +@post+
  # Side effect on +self[key]+
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
    
  # Updates internal variables that deal with short titles, i.e. first name, last name or a conjunction of both (short titles are actually stored as a list, but their names don't tell because they used to be a atoms)
  # - *Args*  :
  #   - +key+ → key of respective short title, may be +:journalTitleShort+ or +:bookTitleShort+
  # - *Returns* :
  #   - the new value of +self[key]+ which is an +Array+ containing all +ShortTitle+ objects that could be build from post data information
  # Assumes post data in instance variable +@post+
  # Side effect on +self[key]+
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

  # Writes post data concerning +:note+ to +self[:note]+ (is actually a list, but doesn't say so in its names because it used to be a single value)
  # Assumes that member variable +@post+ is set
  # Side effect on +self[:note]+
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

  # Writes publisher information (names and places) to +self[:publisherList]+
  # Assumes that member variable +@post+ contains post data from user form
  # Side effect on +self[:publisherList]+
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

  # Adapter method to call +updateFromPostRelatedItem+ for related items of type +Reviewee+ (i.e. articles)
  # Side effect on +self[:revieweeList]+
  def updateFromPostReviewee
    updateFromPostRelatedItem :revieweeList, Reviewee
  end

  # Adapter method to call +updateFromPostRelatedItem+ for related items of type +Container+ (i.e. journals and books)
  # Side effect on +self[:containerList]+
  def updateFromPostContainer
    updateFromPostRelatedItem :containerList, Container
  end

  # Method to retrieve post data concerning related items and stored in object variables
  # - *Args*  :
  #   - +typeX+ → key, may be +:revieweeList+ or +:containerList+
  #   - +classX+ → class name, may be +Reviewee+ or +Container+
  # Assumes valid values in member +@post+
  # Side effect on +self[:revieweeList]+ or +self[:containerList]+
  def updateFromPostRelatedItem typeX, classX
    self[typeX] = []
    if @post[typeX] && @post[typeX].kind_of?(Hash)
      @post[typeX].each_pair{|key, pointer|
        self[typeX][self[typeX].length] = classX.new(pointer)
    }
    end
  end

  # Updates related articles from data provided via post parameters
  # Assumes that @post variable contains user data from biblio form
  # Side effect on +self[:relatedArticleList]+
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
  
  # A lengthy method that is indeed a sequence of updating procedures for all data fields of the biblio record
  # Assumes that +self[key]+ contains all data (clean, complete and sanitised) necessary to update the underlying EpiDoc document, mainly uses xpaths provided in +XPATH[key]+
  # Side effect on +@epiDoc+
  def updateEpiDoc

    [:articleTitle, :journalTitle, :bookTitle, :supertype, :subtype, :language, :bp, :bpOld, :isbn, :sd, :checklist, :date, :edition, :issue, :distributor, :paginationFrom, :paginationTo, :paginationTotal, :paginationPreface, :illustration, :no, :col, :tome, :link, :fasc, :reedition, :seriesTitle, :seriesVolume, :papyrologicalSeriesTitle, :papyrologicalSeriesVolume, :category].each{|key|
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
            if key == :paginationTo
              element.text = self[key] + (self[:paginationFrom] && !self[:paginationFrom].strip.empty? ? '-' + self[:paginationFrom] : '' )
            end
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


   [:journalTitleShort, :bookTitleShort, :papyrologicalSeriesTitleShort].each{|key|
     @epiDoc.elements.delete_all XPATH[key]
     index = 1
     self[key].each{|shorty|
       if shorty.title && !shorty.title.empty?
         xpath = XPATH[key].sub("[starts-with(@type, 'short')]", "[@type='short']") # make xpath deterministic

         element = @epiDoc.bulldozePath xpath + "[@n='" + index.to_s + "']"
         element.text = shorty.title
         if shorty.responsibility && !shorty.responsibility.empty?
           element.attributes['type'] += '-' + shorty.responsibility
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
          child.attributes['type'] = 'num'
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
  
  # Method to avoid replication for related items such as, reviewees and containers, also tries to retrieve biblio record that is bein referred to and loads information from this record into the current one
  # - *Args*  :
  #   - +key+ → key of the related item that should be saved to EpiDoc, i.e. +:revieeList+ or +:containerList+
  # Assumes +@epiDoc+ contains +REXML::Document+ with biblio record
  # Side effect on +self[:revieeList]+ or +self[:containerList]+
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
  
  # Grabs another biblio file from +Sosol::Application.config.canonical_repository+'s master branch and extracts its title, author, date, etc. information
  # - *Args*  :
  #   - +biblioId+ → id of biblio record of interest
  # - *Returns* :
  #   - +Array+ of +REXML::Element+s or emtpy array if the requested record cannot be found
  def getRelatedItemElements biblioId
    result = []

    begin
      biblioId = biblioId[/\A[^\d]*([\d\-]+)\Z/, 1] # expecting sth like http://papyri.info/biblio/12345 or like http://papyri.info/biblio/2010-123345 or just the id, i.e. 12345 or 2010-12345
  
      biblio_data = Repository.new.get_file_from_branch(getBiblioPath(biblioId))
      relatedItem = REXML::Document.new(biblio_data)

      result[result.length] = if relatedItem.elements["//title[starts-with(@type, 'short')]"]
        relatedItem.elements["//title[starts-with(@type, 'short')]"]
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

  # Builds the file path for a given biblio id, e.g. Biblio/1/23.xml
  # - *Args*  :
  #   - +biblioId+ → biblioId, e.g. +12345+ for xwalked biblio records or +54321-2012+ for records created via SoSOL interface
  # - *Returns* :
  #   - +String+ file path, like +Biblio/13/12345.xml+ or +Biblio/2012/54321.xml+
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

    # Retrieves biblio information from EpiDoc fragment and stores in member variables for later and handy access
    # Side effect on +self[key]+ where key is sth. like +:articleTitle+
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

      populateFromEpiDocSimple :seriesTitle
      populateFromEpiDocSimple :seriesVolume
      populateFromEpiDocSimple :papyrologicalSeriesTitle
      populateFromEpiDocSimple :papyrologicalSeriesVolume
      populateFromEpiDocSimple :category

      populateFromEpiDocPerson :authorList
      populateFromEpiDocPerson :editorList

      populateFromEpiDocShortTitle :journalTitleShort
      populateFromEpiDocShortTitle :bookTitleShort
      populateFromEpiDocShortTitle :papyrologicalSeriesTitleShort

      populateFromEpiDocNote

      populateFromEpiDocPublisher

      populateFromEpiDocReviewee

      populateFromEpiDocContainer

      populateFromEpiDocRelatedArticle

      populateFromEpiDocOriginalBp

    end

    # Retrieves information from EpiDoc fragmet which are single values (i.e. tags that are not repeated, no lists) and which are accessible via a straightforward xpath, given in variable +XPATH[key]+
    # - *Args*  :
    #   - +key+ → key, e.g. +:link+
    # Side effect on +self[key]+
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

    # Reads author and editor information from EpiDoc and writes as objects of class +PublicationPerson+ to +self[:authorList]+ resp. +self[:editorList]+
    # - *Args*  :
    #   - +key+ → +:authorList+ or +:editorList+
    # Side effect on  +self[:authorList]+ or +self[:editorList]+
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
    
    # Populates short title attributes with objects of class +ShortTitle+ and fills them with all information that can be retrieved from EpiDoc
    # - *Args*  :
    #   - +key+ → +:journalTitleShort+ or +:bookTitleShort+
    # Side effect on +self[:journalTitleShort]+ or +self[:bookTitleShort]+
    def populateFromEpiDocShortTitle key
      list = []
      path = XPATH[key]
      epiDoc.elements.each(path){|title|
        
        responsibility = if title.attributes['type'] && title.attributes['type'].include?('-')
          title.attributes['type'].partition('-')[2]
        end

        list[list.length] = ShortTitle.new(title.text, responsibility)
      }
      self[key] = list
    end

    # Retrieves publisher information from EpiDoc, i.e. place names as well as names of persons or organisations
    # Side effect on +self[:publisherList]+
    def populateFromEpiDocPublisher
      epiDoc.elements.each(XPATH[:publisherList]){|element|
        type = element.name.to_s
        value = element.text
        self[:publisherList][self[:publisherList].length] = Publisher.new(type, value)
      }
    end

    # Scans EpiDoc document for remarks and annotation and stores them in member +self[:note]+
    # Side effect on +self[:note]+
    def populateFromEpiDocNote
      epiDoc.elements.each(XPATH[:note]){|element|
        if element.attributes.include?('resp')
          self[:note][self[:note].length] = Note.new(element.attributes['resp'], element.text)
        end
      }
    end

    # Shortcut access to method +populateFromEpiDocRelatedItem+ for reviewees
    # Side effect on +self[:revieweeList]+
    def populateFromEpiDocReviewee
      populateFromEpiDocRelatedItem :revieweeList, Reviewee
    end

    # Shortcut access to method +populateFromEpiDocRelatedItem+ for container elements (books or journals)
    # Side effect on +self[:containerList]+
    def populateFromEpiDocContainer
      populateFromEpiDocRelatedItem :containerList, Container
    end
    
    # Generic method to retrieve EpiDoc data from standard biblio structures of +TEI:relatedItem+ and save it as an +Array+ to respetive member variable
    # - *Args*  :
    #   - +typeX+ → +:revieweeList+ or +:containerList+
    #   - +classX+ → +Reviewee+  or +Container+
    # Side effect on +self[:revieweeList]+ or +self[:containerList]+
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

    # Retrieves related articles (series, volume, number, ddb, tm, inventory) from EpiDoc writes a list of +RelatedArticle+ objects to +self[:relatedArticleList]+
    # Side effect on +self[:relatedArticleList]+
    def populateFromEpiDocRelatedArticle
      epiDoc.elements.each(XPATH[:relatedArticleList]){|bibl|
        series    = bibl.elements["title[@level='s'][@type='short']"] ? bibl.elements["title[@level='s'][@type='short']"].text : ''
        volume    = bibl.elements["biblScope[@type='vol']"] ? bibl.elements["biblScope[@type='vol']"].text : ''
        number    = bibl.elements["biblScope[@type='num']"] ? bibl.elements["biblScope[@type='num']"].text : ''
        ddb       = bibl.elements["idno[@type='ddb']"] ? bibl.elements["idno[@type='ddb']"].text : ''
        tm        = bibl.elements["idno[@type='tm']"] ? bibl.elements["idno[@type='tm']"].text : ''
        inventory = bibl.elements["idno[@type='invNo']"] ? bibl.elements["idno[@type='invNo']"].text : ''

        self[:relatedArticleList][self[:relatedArticleList].length] = RelatedArticle.new(series, volume, number, ddb, tm, inventory)
      }
    end



    # Gets original BP data from EpiDoc TEI:seg[@type='original'] tags (Index, Index bis, Titre, Publication, Resumé, S.B. & S.E.G., C.R.) as well as from old or new bp id
    # Side effect on +self[:originalBp]+
    def populateFromEpiDocOriginalBp
      XPATH_ORIGINAL.each_pair{|title, xpath|
        element = epiDoc.elements[xpath]
        if element && element.text && !element.text.strip.empty?
          self[:originalBp][title] = element.text.strip
        end
      }

      if self[:bp] && !self[:bp].empty?
        self[:originalBp]['No'] = self[:bp]
      elsif self[:bpOld] && !self[:bpOld].empty?
        self[:originalBp]['Ancien No'] = self[:bpOld]
      end

    end
    
    # Build array for final sorting order of EpiDoc elements on the basis of XPATH array
    # i.e. title stuff first, legacy stuff last
    def finalOrder
      order = []

      XPATH.each_pair{|key, xpath|
        xpath = xpath.sub(/^(\/bibl\/[^\/]+)(\/.+)?$/, '\1')
        if !(xpath =~ /^\/bibl\/@[\w:]+$/)
          if xpath == "/bibl/idno[@type='bp']"
            order[order.length] = "/bibl/idno[@type='pi']"
          end
          
          if !order.include?(xpath)
            order[order.length] = xpath
          end
        end
      }
      
      XPATH_ORIGINAL.each_pair{|key, xpath|
        order[order.length] = xpath
      }

      order
    end
  
  # Data structure for personal information first name, last name, name, swap
  class PublicationPerson
    attr_accessor :firstName, :lastName, :name, :swap
    def initialize firstName = '', lastName = '', name = '', swap = false
      @firstName = firstName
      @lastName = lastName
      @name = name
      @swap = swap
    end
  end

  # Data structure for target information pointer, ignoreList and ignored (built upon ignore list, read-only)
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
  
  # Specialisation/Facade of class RelatedItem
  class Reviewee < RelatedItem
    
  end
  
  # Specialisation/Facade of class RelatedItem
  class Container < RelatedItem
    
  end
  
  # Data structure for short title information (i.e. title and responsibility/style), can be use for journals and books alike
  class ShortTitle
    attr_accessor :title, :responsibility
    def initialize title = '', responsibility = ''
      @title = title
      @responsibility = responsibility 
    end
  end
  
  # Data structure for remarks (i.e. annotation and responsibility)
  class Note
    attr_accessor :responsibility, :annotation
    def initialize responsibility = '', annotation = ''
      @responsibility = responsibility
      @annotation = annotation
    end
  end

  # Data structure for related articles, (i.e. series, volume, number, ddb, tm and inventory)
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

  # Data structure for publisher information, (i.e. publisherType which can have the values +publisher+ or +pubPlace+ and value which can be a person name, the name of an organisation or a place name)
  class Publisher
    attr_accessor :publisherType, :value
    def initialize publisherType = '', value = ''
      @publisherType = publisherType
      @value = value
    end
  end
end

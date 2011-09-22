class BiblioIdentifier < HGVIdentifier
  attr_accessor :configuration, :valid_epidoc_attributes

  PATH_PREFIX = 'Biblio'
  
  XML_VALIDATOR = JRubyXML::EpiDocP5Validator
  
  FRIENDLY_NAME = "Biblio"

  IDENTIFIER_NAMESPACE = 'biblio'

  XPATH = {
    :title => "/TEI/text/body/div/bibl/title[@level='a'][@type='main']",
    :journalTitle => "/TEI/text/body/div/bibl/title[@level='j'][@type='main']",
    :bookTitle => "/TEI/text/body/div/bibl/title[@level='m'][@type='main']",
    :supertype => "/TEI/text/body/div/bibl/@type",
    :subtype => "/TEI/text/body/div/bibl/@subtype",
    :language => "/TEI/text/body/div/bibl/@xml:lang",    
      
    :bp => "/TEI/text/body/div/bibl/idno[@type='bp']",
    :bpOld => "/TEI/text/body/div/bibl/idno[@type='bp_old']",
    :idp => "/TEI/text/body/div/bibl/@xml:id",
    :isbn => "/TEI/text/body/div/bibl/idno[@type='isbn']",
    :sd => "/TEI/text/body/div/bibl/idno[@type='sonderdruck']",
    :checklist => "/TEI/text/body/div/bibl/idno[@type='checklist']",

    :date => "/TEI/text/body/div/bibl/date",
    :edition => "/TEI/text/body/div/bibl/edition",
    :issue => "/TEI/text/body/div/bibl/biblScope[@type='issue']",
    :distributor => "/TEI/text/body/div/bibl/distributor",
    :paginationFrom => "/TEI/text/body/div/bibl/biblScope[@type='page']/@from",
    :paginationTo => "/TEI/text/body/div/bibl/biblScope[@type='page']/@to",
    :paginationTotal => "/TEI/text/body/div/bibl/note[@type='pageCount']",
    :paginationPreface => "/TEI/text/body/div/bibl/note[@type='prefacePageCount']",
    :illustration => "/TEI/text/body/div/bibl/note[@type='illustration']",
    :no => "/TEI/text/body/div/bibl/biblScope[@type='no']",
    :col => "/TEI/text/body/div/bibl/biblScope[@type='col']",
    :tome => "/TEI/text/body/div/bibl/biblScope[@type='tome']",
    :link => "/TEI/text/body/div/bibl/ptr/@target",
    :fasc => "/TEI/text/body/div/bibl/biblScope[@type='fasc']",
    :reedition => "/TEI/text/body/div/bibl/relatedItem[@type='reedition'][@subtype='reference']/bibl[@type='publication'][@subtype='other']",

    :authorList => "/TEI/text/body/div/bibl/author",
    :editorList => "/TEI/text/body/div/bibl/editor",
      
    :journalTitleShort => "/TEI/text/body/div/bibl/title[@level='j'][@type='short']",
    :bookTitleShort => "/TEI/text/body/div/bibl/title[@level='m'][@type='short']",
    
    :publisherList => "/TEI/text/body/div/bibl/node()[name() = 'publisher' or name() = 'pubPlace']",
    :relatedArticleList => "/TEI/text/body/div/bibl/relatedItem[@type='mentions']/bibl",
    :note => "/TEI/text/body/div/bibl/note[@resp]",
    
    :revieweeList => "/TEI/text/body/div/bibl/relatedItem[@type='reviews']/bibl",
    :containerList => "/TEI/text/body/div/bibl/relatedItem[@type='appearsIn']/bibl"
  }

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

  def epiDoc
    REXML::Document.new(self.xml_content)
  end
  
  def after_find
    # retrieve data from xml or set empty defaults 
    
    self[:title] = ''
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
    
    populateFromEpiDoc
  end

  protected

    def populateFromEpiDoc

      populateFromEpiDocSimple :title
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
          newbie.firstName = element.text
          indexFirst = element.index_in_parent
        end
        if element = person.elements['surname']
          newbie.lastName = element.text
          indexLast = element.index_in_parent
        end
        if person.text
          newbie.name = person.text
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
        #place = publisher.elements["placeName"] ? publisher.elements["placeName"].text : ''
        #name = publisher.elements["orgName"] ? publisher.elements["orgName"].text : ''
        self[:publisherList][self[:publisherList].length] = Publisher.new(type, value)
      }
    end

    def populateFromEpiDocNote
      epiDoc.elements.each(XPATH[:note]){|element|
        if element.attributes.length == 1
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
        volume    = bibl.elements["biblScope[@type='vol']"] ? bibl.elements["biblScoe[@type='vol']"].text : ''
        number    = bibl.elements["biblScope[@type='number']"] ? bibl.elements["biblScoe[@type='number']"].text : ''
        ddb       = bibl.elements["idno[@type='ddb']"] ? bibl.elements["idno[@type='ddb']"].text : ''
        tm        = bibl.elements["idno[@type='tm']"] ? bibl.elements["idno[@type='tm']"].text : ''
        inventory = bibl.elements["idno[@type='invNo']"] ? bibl.elements["idno[@type='invNo']"].text : ''

        self[:relatedArticleList][self[:relatedArticleList].length] = RelatedArticle.new(series, volume, number, ddb, tm, inventory)
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
    def initialize pointer = '', ignoreList = array()
      @pointer = pointer
      @ignoreList = ignoreList
      
      @ignored = ''
      ignoreList.each_pair {|key, value|
        @ignored += key.titleize + ': ' + value + ', '
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
    attr_accessor :publisher_type, :value
    def initialize publisher_type = '', value = ''
      @publisher_type = type
      @value = value
    end

    def type
      return @publisher_type
    end
  end
end
# java -jar ~/Desktop/x/saxon/saxonhe9-2-1-1j/saxon9he.jar  ~/tmp/sosol_biblio/tmp/biblioTest.xml ./start-html.xsl

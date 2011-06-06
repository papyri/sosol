class BiblioIdentifier < HGVIdentifier
  attr_accessor :configuration, :valid_epidoc_attributes

  PATH_PREFIX = 'Biblio'
  
  XML_VALIDATOR = JRubyXML::EpiDocP5Validator
  
  FRIENDLY_NAME = "Biblio"

  def preview parameters = {}, xsl = nil
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(@epiDocXml),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        xsl ? xsl : %w{data xslt biblio start-html.xsl})),
        parameters)
  end
  
  def after_initialize
    # retrieve data from xml or set empty defaults 
    
    self[:title] = ''
    self[:type] = ''
    self[:subtype] = ''
    self[:language] = ''    
    
    self[:bp] = ''
    self[:bpOld] = ''
    self[:idp] = ''
    self[:isbn] = ''
    self[:sd] = ''

    self[:date] = ''
    self[:edition] = ''
    self[:paginationFrom] = ''
    self[:paginationTo] = ''
    self[:paginationTotal] = ''
    self[:paginationPreface] = ''
    self[:illustration] = ''
    self[:note] = ''
    self[:reedition] = ''
    
    self[:monograph] = nil
    self[:series] = nil
    self[:journal] = nil
    self[:publisherList] = Array.new
    
    self[:authorList] = Array.new
    self[:editorList] = Array.new    
    self[:revueCritiqueList] = Array.new
    self[:relatedArticleList] = Array.new
    
    @epiDocFile = File.new(File.join(RAILS_ROOT, 'tmp', 'biblioTest.xml'), 'r')
    @epiDocXml = @epiDocFile.read
    @epiDocFile.rewind
    @epiDoc = REXML::Document.new(@epiDocFile)

    populateFromEpiDoc

  end

  protected

    def populateFromEpiDoc

      populateFromEpiDocSimple :title, "/TEI/text/body/div/bibl/title[@level='a'][@type='main']"
      populateFromEpiDocSimple :type, "/TEI/teiHeader/fileDesc/sourceDesc/bibl/@type"
      populateFromEpiDocSimple :subtype, "/TEI/teiHeader/fileDesc/sourceDesc/bibl/@subtype"
      populateFromEpiDocSimple :language, "/TEI/text/body/div/bibl/@xml:lang"    
      populateFromEpiDocSimple :bp, "/TEI/teiHeader/fileDesc/publicationStmt/idno[@type='bp']"
      populateFromEpiDocSimple :bpOld, "/TEI/teiHeader/fileDesc/publicationStmt/idno[@type='bp_old']"
      populateFromEpiDocSimple :idp, "/TEI/teiHeader/fileDesc/publicationStmt/idno[@type='filename']"
      populateFromEpiDocSimple :isbn, "/TEI/teiHeader/fileDesc/publicationStmt/idno[@type='isbn']"
      populateFromEpiDocSimple :sd, "/TEI/teiHeader/fileDesc/publicationStmt/idno[@type='sonderdruck']"
      populateFromEpiDocSimple :date, "/TEI/text/body/div/bibl/date"
      populateFromEpiDocSimple :edition, "/TEI/text/body/div/bibl/edition"
      populateFromEpiDocSimple :paginationFrom, "/TEI/text/body/div/bibl/biblScope[@type='page']/@from"
      populateFromEpiDocSimple :paginationTo, "/TEI/text/body/div/bibl/biblScope[@type='page']/@to"
      populateFromEpiDocSimple :paginationTotal, "/TEI/text/body/div/bibl/biblScope[@type='pageCount']"
      populateFromEpiDocSimple :paginationPreface, "/TEI/text/body/div/bibl/biblScope[@type='prefacePageCount']"
      populateFromEpiDocSimple :illustration, "/TEI/text/body/div/bibl/biblScope[@type='illustration']"
      populateFromEpiDocSimple :note, "/TEI/text/body/div/bibl/note"
      populateFromEpiDocSimple :reedition, "/TEI/text/body/div/bibl/relatedItem[@type='reedition'][@subtype='reference']/bibl[@type='publication'][@subtype='other']"
      populateFromEpiDocPerson :authorList, "/TEI/text/body/div/bibl/author"
      populateFromEpiDocPerson :editorList, "/TEI/text/body/div/bibl/editor"
      populateFromEpiDocPublisher
      populateFromEpiDocRevueCritique
      populateFromEpiDocRelatedArticle

    end

    def populateFromEpiDocSimple key, path
      attribute = nil
      if path =~ /(.+)\/@([^\[\]\/]+)\Z/
        path = $1
        attribute = $2
      end
      if @epiDoc.elements[path]
        if attribute
          self[key] = @epiDoc.elements[path].attributes[attribute]
        else
          self[key] = @epiDoc.elements[path].text
        end
      else
        self[key]='nada'
      end
    end

    def populateFromEpiDocPerson key, path
      list = []
      @epiDoc.elements.each(path){|person|

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
        if element = person.elements['persName']
          newbie.name = element.text
        end
        if (indexLast != 0) && (indexFirst != 0) && indexLast > indexFirst
          newbie.swap = true
        end
        list[list.length] = newbie
      }

      self[key] = list
    end

    def populateFromEpiDocPublisher
      @epiDoc.elements.each("/TEI/text/body/div/bibl/publisher"){|publisher|
        place = publisher.elements["placeName"] ? publisher.elements["placeName"].text : ''
        name = publisher.elements["orgName"] ? publisher.elements["orgName"] : ''
        self[:publisherList][self[:publisherList].length] = Publisher.new(place, name)
      }
    end
    
    def populateFromEpiDocRevueCritique
      @epiDoc.elements.each("/TEI/text/body/div/bibl/note[@type='revueCritique']/listBibl/bibl"){|bibl|
        author = bibl.elements["author"] ? bibl.elements["author"].text : ''
        title = bibl.elements["title"] ? bibl.elements["title"].text : ''
        year = bibl.elements["date"] ? bibl.elements["date"].text : ''
        page = bibl.elements["biblScope[@type='page']"] ? bibl.elements["biblScope[@type='page']"].text : ''
        self[:revueCritiqueList][self[:revueCritiqueList].length] = RevueCritique.new(author, title, year, page)
      }
    end
    
    def populateFromEpiDocRelatedArticle
      @epiDoc.elements.each("/TEI/text/body/div/bibl/note[@type='relatedArticles']/listBibl/bibl"){|bibl|
        series = bibl.elements["biblScoe[@type='series']"] ? bibl.elements["biblScoe[@type='series']"].text : ''
        volume = bibl.elements["biblScoe[@type='volume']"] ? bibl.elements["biblScoe[@type='volume']"].text : ''
        number = bibl.elements["biblScoe[@type='article']"] ? bibl.elements["biblScoe[@type='article']"].text : ''
        ddb = bibl.elements["idno[@type='ddb']"] ? bibl.elements["idno[@type='ddb']"].text : ''
        inventory = bibl.elements["idno[@type='invNo']"] ? bibl.elements["idno[@type='invNo']"].text : ''

        self[:relatedArticleList][self[:relatedArticleList].length] = RelatedArticle.new(series, volume, number, ddb, inventory)
      }
    end

  class PublicationEntity
    attr_accessor :title, :titleShort, :number
    def initialize title = '', titleShort = '', number = ''
      @title = title
      @titleShort = titleShort
      @number = number
    end
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
  
  class RelatedArticle
    attr_accessor :series, :volume, :number, :ddb, :inventory
    def initialize series = '', volume = '', number = '', ddb = '', inventory = ''
      @series = series
      @volume = volume
      @number = number
      @ddb = ddb
      @inventory = inventory
    end
  end
  class Publisher
    attr_accessor :place, :name
    def initialize place = '', name = ''
      @place = place
      @name = name
    end
  end
end
# java -jar ~/Desktop/x/saxon/saxonhe9-2-1-1j/saxon9he.jar  ~/tmp/sosol_biblio/tmp/biblioTest.xml ./start-html.xsl
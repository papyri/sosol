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

  def updateFromPost params
    @post = params

    updateFromPostSimple :title
    updateFromPostSimple :journalTitle
    updateFromPostSimple :bookTitle
    updateFromPostSimple :type
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
   
    updateFromPostReviewee
    
    updateFromPostContainer
   
    updateFromPostRelatedArticle

    updateEpiDoc
    
    # write back to a string
    formatter = REXML::Formatters::Pretty.new
    formatter.compact = true
    formatter.width = 512
    modified_xml_content = ''
    formatter.write @epiDoc, modified_xml_content
    
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
        if !publisher[:name].strip.empty? && ['pubPlace', 'publisher'].include?(publisher[:place].strip)
          self[:publisherList][self[:publisherList].length] = Publisher.new(publisher[:place].strip, publisher[:name].strip)
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

    [:title, :journalTitle, :bookTitle, :type, :subtype, :language, :bp, :bpOld, :isbn, :sd, :checklist, :date, :edition, :issue, :distributor, :paginationFrom, :paginationTo, :paginationTotal, :paginationPreface, :illustration, :no, :col, :tome, :link, :fasc, :reedition].each{|key|
      attribute = nil
      path = XPATH[key]
      if path =~ /(.+)\/@([^\[\]\/]+)\Z/
        path = $1
        attribute = $2
      end
      
      if self[key] && !self[key].strip.empty?
        element = @epiDoc.bulldozePath path
        if attribute
          element.attributes[attribute] = self[key]
        else
          element.text = self[key]
        end
      else
        @epiDoc.elements.delete_all path
      end
    }

    [:authorList, :editorList].each{|key|
      @epiDoc.elements.delete_all XPATH[key]
      index = 1
      self[key].each{|person|
        element = @epiDoc.bulldozePath XPATH[key] + "[@n='" + index.to_s + "']"
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
        index += 1
      }
    }

    @epiDoc.elements.delete_all XPATH[:publisherList]
    if self[:publisherList] && self[:publisherList].kind_of?(Array)
      basePath = XPATH[:publisherList][/\A(.+)node\(\).+\Z/, 1]
      
      index = {'pubPlace' => 1, 'publisher' => 1}
      self[:publisherList].each{|publisher|
        if publisher.value && !publisher.value.empty?
          element = @epiDoc.bulldozePath basePath + publisher.type + "[@n='" + index[publisher.type].to_s + "']"
          element.text = publisher.value
          index[publisher.type] += 1
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
        ptr = REXML::Element.new('ptr')
        ptr.attributes['target'] = relatedItem.pointer
        element.add ptr
        REXML::Comment.new(' ignore - start, i.e. SoSOL users may not edit this ', element)
        getRelatedItemElements(relatedItem.pointer).each{|ignore|
          element.add ignore
        }
        REXML::Comment.new(' ignore - stop ', element)
        index += 1
      }
    end
  end
  
  def getRelatedItemElements biblioId
    biblioId = biblioId[/\A[^\d]*([\d\-]+)\Z/, 1] # expecting sth like http://papyri.info/biblio/12345 or like http://papyri.info/biblio/2010-123345 or just the id, i.e. 12345 or 2010-12345

    git = Grit::Repo.new(CANONICAL_REPOSITORY).commits.first.tree
    biblio = git / getBiblioPath(biblioId)
    relatedItem = REXML::Document.new(biblio.data)

    result = []
    
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

    result
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

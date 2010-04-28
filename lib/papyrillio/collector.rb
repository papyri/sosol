module Papyrillio

  #
  # Collector
  #
  # simply loads the first files it comes across
  #

  class Collector < Papyrillio::PapyrillioBase

    def initialize
      super()
      @canonical = Grit::Repo.new(CANONICAL_REPOSITORY)
    end

    def get
      @publishees ? @publishees : retrieve;
    end

    protected
    
    def retrieve_corresponding_ddb_file hgv_document
      if hgv_document.class != REXML::Document
        hgv_document = REXML::Document.new hgv_document
      end

      ddb_file = nil

      hgv_document.elements.each("/TEI/teiHeader/fileDesc/publicationStmt/idno[@type='ddb-hybrid']") {|element|
        if element.get_text
          ddb_file_name_elements = element.get_text.value.strip.split ';'
          
          collection = ddb_file_name_elements[0] 
          volume = ddb_file_name_elements[1]
          document = ddb_file_name_elements[2]

          ddb_file_path = 'DDB_EpiDoc_XML/' + collection + '/' + # collection title like bgu or chrest.wilck
            (volume.length > 0 ? collection + '.' + volume + '/' : '') + # volume number or empty string
            collection + '.' + (volume.length > 0 ? volume + '.' : '') + document + '.xml' # document number

          ddb_file = @canonical.commits.first.tree / ddb_file_path
        end   
      }
      
      ddb_file
    end

    def retrieve
      @publishees = []
      count = 10.0

      
      hgv = @canonical.commits.first.tree / 'HGV_meta_EpiDoc'

      index = 1

      hgv.contents.select{|x|x.class == Grit::Tree}.each do |hgv_folder|

        hgv_folder.contents{|x|x.class == Grit::Blob}.each do |hgv_file|
          p = Publishee.new
          p.label = hgv_folder.name + '/' + hgv_file.name
          p.hgv_folder = hgv_folder
          p.hgv_file = hgv_file
          p.ddb_file = retrieve_corresponding_ddb_file hgv_file.data
          p.file_index = p.print_index = index
          @publishees[@publishees.length] = p
  
          log_progress (index / count * 100).round
          index += 1
          
          if index > count
            break
          end

        end

        if index > count
          break
        end

      end

      puts ''

      @publishees
    end
  end

  #
  # CollectorXpathPattern
  #
  # looks for a special pattern within a given xpath
  #
 
  class CollectorXpathPattern < Papyrillio::Collector
    attr_accessor :xpath, :pattern

    def initialize xpath, pattern
      super()
      @xpath = xpath
      @pattern = pattern
    end

    def to_s
      self.class.to_s + ': pattern[' + @pattern.to_s + '] xpath[' + @xpath.to_s + ']'
    end

    protected

    def retrieve
      @publishees = []

      canonical = Grit::Repo.new(CANONICAL_REPOSITORY)
      hgv = canonical.commits.first.tree / 'HGV_meta_EpiDoc'

      index = 1

      hgv.contents.select{|x|x.class == Grit::Tree}.each do |hgv_folder|

        hgv_folder.contents{|x|x.class == Grit::Blob}.each do |hgv_file|

          document = REXML::Document.new hgv_file.data
          document.elements.each(@xpath) {|element|
            if element.get_text
              result = element.get_text.value[@pattern, 1]

              if  result != nil
                p = Publishee.new
                p.label = result
                p.hgv_folder = hgv_folder
                p.hgv_file = hgv_file
                p.ddb_file = retrieve_corresponding_ddb_file document
                p.file_index = index
                p.print_index = result.to_i
                @publishees[@publishees.length] = p
              end

            end
          }

          log_progress (index / 56000.0  * 100.0).round()
          index += 1
        end

      end

      log_progress 100
      puts ''

      @publishees
    end

  end

end
module DclpMetaIdentifierHelper
  module DclpPublication
    
    # Assembles all valid type options for HGV provenance (+composed+, +sent+, +sold+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def DclpPublication.typeOptions
      [
        [I18n.t('publication.type.publication'),  :publication],
        [I18n.t('publication.type.reference'),      :reference]
      ]
    end
    
    # Assembles all valid type options for HGV provenance (+composed+, +sent+, +sold+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def DclpPublication.subtypeOptions
      [
        [I18n.t('publication.subtype.principal'),   :principal],
        [I18n.t('publication.subtype.partial'),     :partial],
        [I18n.t('publication.subtype.previous'),    :previous],
        [I18n.t('publication.subtype.readings'),    :readings],
        [I18n.t('publication.subtype.translation'), :translation],
        [I18n.t('publication.subtype.study'),       :study],
        [I18n.t('publication.subtype.catalogue'),   :catalogue],
        [I18n.t('publication.subtype.palaeo'),      :palaeo]
      ]
    end
    
    # Assembles all valid type options for HGV provenance (+composed+, +sent+, +sold+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def DclpPublication.ubertypeOptions1
      [
        [I18n.t('publication.ubertype.principal'),   :principal],
        [I18n.t('publication.ubertype.reference'),   :reference],
        [I18n.t('publication.ubertype.partial'),     :partial],
        [I18n.t('publication.ubertype.previous'),    :previous],
        [I18n.t('publication.ubertype.readings'),    :readings]
      ]
    end
    
    # Assembles all valid type options for HGV provenance (+composed+, +sent+, +sold+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def DclpPublication.ubertypeOptions2
      [
        [I18n.t('publication.ubertype.translation'), :translation],
        [I18n.t('publication.ubertype.study'),       :study],
        [I18n.t('publication.ubertype.catalogue'),   :catalogue],
        [I18n.t('publication.ubertype.palaeo'),      :palaeo]
      ]
    end

    # Assembles all valid type options for HGV provenance (+composed+, +sent+, +sold+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def DclpPublication.languageOptions
      [
        ['', ''],
        [I18n.t('language.de'), :de],
        [I18n.t('language.en'), :en],
        [I18n.t('language.it'), :it],
        [I18n.t('language.es'), :es],
        [I18n.t('language.la'), :la],
        [I18n.t('language.fr'), :fr]
      ]
    end

    # Data structure for publication information
    class Publication
      # +Array+ of a valid values for TEI:provenance|@type
      @@typeList          = [:publication, :reference]
      # +Array+ of a valid values for TEI:provenance|@subtype
      @@subtypeList       = [:principal, :partial, :previous, :readings, :translation, :study, :catalogue, :palaeo]
      # +Array+ of a valid values for TEI:provenance|@subtype
      @@languageList       = [:de, :en, :it, :es, :la, :fr]
      # +Array+ of all String member attributes that have a TEI equivalent
      @@atomList          = [:type, :subtype, :ubertype, :language, :link]

      attr_accessor :type, :subtype, :ubertype, :language, :link, :extraList, :preview

      # Constructor
      # - *Args*  :
      #   - +init+ → +Hash+ object containing provenance data as provided by the model class +BiblioIdentifier+, used to initialise member variables, defaults to +nil+
      # Side effect on +@type+, +@subtype+, +@date+ and +@placeList+
      def initialize init = nil
        @type      = nil
        @subtype   = nil
        @ubertype  = nil
        @language  = nil
        @link      = nil
        @extraList = []
        @preview   = nil

        if init
        
          if init[:publication]

            if init[:publication][:attributes]
              self.populateAtomFromHash init[:publication][:attributes]
            end

            #if init[:publication][:children] && init[:provenance][:children][:place]
            #  init[:provenance][:children] && init[:provenance][:children][:place].each{|place|
            #    self.addPlace(HgvGeo::Place.new(:place => place))
            #  }
            #end

          else
            self.populateAtomFromHash init
          end

        end

      end
      
      def type= value
        @type = value
      end
      
      def subtype= value
        @subtype = value
      end
      
      # Updates instance variables from a hash
      # - *Args*  :
      #   - +epiDocList+ → data contained in +BiblioIdentifier+'s +:provenance+ attribute
      # - *Returns* :
      #   - +Array+ of +HgvGeo::Provenance+ objects
      # Side effect on all member variables that are declared in +@@atomList+
      def populateAtomFromHash hash
        @@atomList.each {|member|
          self.send((member.to_s + '=').to_sym, hash[member] || nil)
        }
      end
    
    end
  end
end

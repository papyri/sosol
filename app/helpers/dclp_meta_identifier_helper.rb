module DclpMetaIdentifierHelper
  module DclpEdition
    
    # Assembles all valid type options for HGV provenance (+composed+, +sent+, +sold+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def DclpEdition.typeOptions
      [
        [I18n.t('edition.type.publication'),  :publication],
        [I18n.t('edition.type.reference'),      :reference]
      ]
    end
    
    # Assembles all valid type options for HGV provenance (+composed+, +sent+, +sold+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def DclpEdition.subtypeOptions
      [
        [I18n.t('edition.subtype.principal'),    :principal],
        [I18n.t('edition.subtype.partial'),      :partial],
        [I18n.t('edition.subtype.previous'),     :previous],
        [I18n.t('edition.subtype.readings'),     :readings],
        [I18n.t('edition.subtype.translation'),  :translation],
        [I18n.t('edition.subtype.study'),        :study],
        [I18n.t('edition.subtype.catalogue'),    :catalogue],
        [I18n.t('edition.subtype.palaeo'),       :palaeo],
        [I18n.t('edition.subtype.illustration'), :illustration]
      ]
    end

    # Assembles all valid type options for HGV provenance (+composed+, +sent+, +sold+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def DclpEdition.ubertypeOptions1
      [
        [I18n.t('edition.ubertype.principal'),   :principal],
        [I18n.t('edition.ubertype.reference'),   :reference],
        [I18n.t('edition.ubertype.partial'),     :partial],
        [I18n.t('edition.ubertype.previous'),    :previous],
        [I18n.t('edition.ubertype.readings'),    :readings]
      ]
    end
    
    # Assembles all valid type options for HGV provenance (+composed+, +sent+, +sold+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def DclpEdition.ubertypeOptions2
      [
        [I18n.t('edition.ubertype.translation'),  :translation],
        [I18n.t('edition.ubertype.study'),        :study],
        [I18n.t('edition.ubertype.catalogue'),    :catalogue],
        [I18n.t('edition.ubertype.palaeo'),       :palaeo],
        [I18n.t('edition.ubertype.illustration'), :illustration]
      ]
    end

    # Assembles all valid type options for HGV provenance (+composed+, +sent+, +sold+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def DclpEdition.languageOptions
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

    # Assembles all valid type options for HGV provenance (+composed+, +sent+, +sold+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def DclpEdition.extraOptions
      [
        [I18n.t('edition.extra.volume'),  :volume],
        [I18n.t('edition.extra.volume'),  :vol],
        [I18n.t('edition.extra.pages'),   :pp],
        [I18n.t('edition.extra.no'),      :no],
        [I18n.t('edition.extra.col'),     :col],
        [I18n.t('edition.extra.tome'),    :tome],
        [I18n.t('edition.extra.fasc'),    :fasc],
        [I18n.t('edition.extra.issue'),   :issue],
        [I18n.t('edition.extra.plate'),   :plate],
        [I18n.t('edition.extra.numbers'), :numbers],
        [I18n.t('edition.extra.pages'),   :pages],
        [I18n.t('edition.extra.page'),    :page],
        [I18n.t('edition.extra.side'),    :side],
        [I18n.t('edition.extra.generic'), :generic]
      ]
    end

    # Data structure for publication information
    class Extra
      attr_accessor :value, :type, :corresp, :from, :to
      def initialize value, type, corresp = nil, from = nil, to = nil
        @value   = value
        @type    = type.to_sym
        @corresp = corresp
        @from    = from
        @to      = to
      end
    end

    class Edition
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
        
          if init[:edition]
            if init[:edition][:attributes]
              self.populateAtomFromHash init[:edition][:attributes]
            end
            if init[:edition][:children][:extra]
              init[:edition][:children][:extra].each {|extra|
                @extraList << Extra.new(extra[:value], extra[:attributes][:type], extra[:attributes][:corresp], extra[:attributes][:from], extra[:attributes][:to])
              }
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

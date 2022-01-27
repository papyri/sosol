# Helper functions for complex EpiDoc transformations, date operations and form data for select boxes
module HgvMetaIdentifierHelper
  # Generates a random six-letter-code
  # - *Args*  :
  #   - +prefix+ → a string that should be prepended to the resulting letter code
  # - *Returns* :
  #   - +String+ random six letter code, e.g. "JCJIBF"
  def generateRandomId(prefix = '')
    prefix + (rand * 1_000_000).floor.to_s.tr('0123456789', 'ABCDEFGHIJ')
  end

  def getValueFromHashByMultidimensionalKey(hsh, key)
    # key = key.dup
    return hsh if !hsh.is_a?(Hash) || !key.is_a?(Array) || !hsh.length || !key.length || !defined?(hsh[key[0]])

    if key.length == 1
      hsh[key[0]]
    else
      getValueFromHashByMultidimensionalKey(hsh[key[0]], key[1..-1])
    end
  end

  # Reads out config/hgv.yml and stores all configuration parameters in an instance variable called +@scheme+. Adds defaults and prunes invalid configuration entries.
  class HgvMetaConfiguration
    attr_reader :scheme, :keys, :toplevel_standalone_attributes

    # Constructor laods and complements HGV configuration from +config/hgv.yml+ and prepares a list that contains all valid HGV keys
    # Assumes the existenz of configuration file +config/hgv.yml+, for further information about expected values and format see there
    # Side effect on +@scheme+ and +@keys+
    def initialize(modifier = nil)
      @scheme = YAML.load_file(File.join(Rails.root, %w[config hgv.yml]))[:hgv][:metadata]

      if modifier.instance_of?(Symbol)
        @scheme = @scheme.merge(YAML.load_file(File.join(Rails.root,
                                                         ['config', "#{modifier}.yml"]))[modifier][:metadata])
      end

      @scheme.delete_if { |_key, value| value.nil? }

      add_meta_information! @scheme

      @keys = @scheme.keys
      @scheme.each_value do |item|
        @keys += retrieve_all_keys item
      end

      @toplevel_standalone_attributes = {}
      @scheme.each do |key, config|
        if config[:xpath] =~ %r{/(\w+)(\[.+\])*?/@(\w+)\Z}
          @toplevel_standalone_attributes[key] =
            { element_name: Regexp.last_match(1), attribute_name: Regexp.last_match(3) }
        end
      end
    end

    # Recursivle retrieves all valid keys (element key, attribute keys, child keys)
    # - *Args*  :
    #   - +configuration_node+ → a single element node of the hgv configuration
    # - *Returns* :
    #   - +Array+ of string values, containing all valid keys for HGV meta data nodes, such as [:type, :subtype, :date, :place, ...] for HGV configuration node :provenance
    def retrieve_all_keys(configuration_node)
      keys = configuration_node[:attributes] ? configuration_node[:attributes].keys : []
      configuration_node[:children]&.each_pair do |key, value|
        keys += [key]
        keys += retrieve_all_keys value
      end
      keys
    end

    # Recursively adds optional attributes to configuration
    # e.g. +:optional+ defaults to +true+ whereas +:multiple+ defaults to false
    # - *Args*  :
    #   - +configuration+ → initially the complete HGV configuration, during recursion it contains the content of the children attribute
    # Side effect on +configuration+ (adds default values and missing attributes)
    def add_meta_information!(configuration)
      configuration.each_value do |element|
        add_defaults! element

        if element.keys.include? :attributes
          element[:attributes].each_value do |attribute|
            add_defaults! attribute
          end
        end

        add_meta_information! element[:children] if element.keys.include? :children
      end
    end

    # Adds optional attributes (suchs as mulplicity or default values) to a configuration item
    # - *Args*  :
    #   - +item+ → may be an element or an attribute
    # Side effect on +item+ (sets default values, adds missing attributes)
    def add_defaults!(item)
      item[:multiple] = if item.keys.include? :multiple
                          item[:multiple] ? true : false
                        else
                          false
                        end

      item[:optional] = if item.keys.include? :optional
                          item[:optional] ? true : false
                        else
                          true
                        end

      item[:default] = nil unless item.keys.include? :default

      item[:pattern] = nil unless item.keys.include? :pattern
    end

    # Retrieves the xpath for a specified HGV key if the key belongs to a top level HGV configuration node, i.e. for HGV key +:textDate+, but not for HGV key +:when+ which is a child node of +:textDate+
    # - *Args*  :
    #   - +key+ → key, e.g. +:provenance+
    # - *Returns* :
    #   - String xpath, string will be empty if xpath cannot be given for the requested key
    # Assumes that +config/hgv.yml+ has been loaded into +@scheme+
    def xpath(key)
      if @scheme.keys.include? key
        @scheme[key][:xpath]
      else
        ''
      end
    end
  end

  # Module for HGV geo data class definitions (provenance, place and geo)
  module HgvGeo
    # Data structure for provenance information
    class Provenance
      # +Array+ of a valid values for TEI:provenance|@type
      @@typeList          = %i[found observed destroyed not-found reused moved acquired sold composed
                               sent executed received located]
      # +Array+ of a valid values for TEI:provenance|@subtype
      @@subtypeList       = [:last]
      # +Array+ of all String member attributes that have a TEI equivalent
      @@atomList          = %i[type subtype date]

      attr_accessor :type, :subtype, :date, :placeList

      # Constructor
      # - *Args*  :
      #   - +init+ → +Hash+ object containing provenance data as provided by the model class +BiblioIdentifier+, used to initialise member variables, defaults to +nil+
      # Side effect on +@type+, +@subtype+, +@date+ and +@placeList+
      def initialize(init = nil)
        @type    = nil
        @subtype = nil
        @date    = nil
        @placeList = []

        if init

          if init[:provenance]

            populateAtomFromHash init[:provenance][:attributes] if init[:provenance][:attributes]

            if init[:provenance][:children] && init[:provenance][:children][:place]
              init[:provenance][:children] && init[:provenance][:children][:place].each do |place|
                addPlace(HgvGeo::Place.new(place: place))
              end
            end

          else
            populateAtomFromHash init
          end

        end
      end

      # Factory method for batch loading an +Array+ of +Provenance+ objects
      # - *Args*  :
      #   - +epiDocList+ → data contained in +BiblioIdentifier+'s +:provenance+ attribute
      # - *Returns* :
      #   - +Array+ of +HgvGeo::Provenance+ objects
      def self.getObjectList(epiDocList)
        objectList = []
        if epiDocList.present?
          epiDocList.each do |epi|
            objectList[objectList.length] = HgvGeo::Provenance.new(provenance: epi)
          end
        end
        objectList
      end

      # Updates instance variables from a hash
      # - *Args*  :
      #   - +epiDocList+ → data contained in +BiblioIdentifier+'s +:provenance+ attribute
      # - *Returns* :
      #   - +Array+ of +HgvGeo::Provenance+ objects
      # Side effect on all member variables that are declared in +@@atomList+
      def populateAtomFromHash(hash)
        @@atomList.each do |member|
          send("#{member}=".to_sym, hash[member] || nil)
        end
      end

      # Mutator method for member variable +type+
      # If value for +type+ is invalid +type+ will be set to +nil+
      # - *Args*  :
      #   - +value+ → new value for member variable +type+ (+:found+, +:observed+, +:destroyed+, etc.)
      # - *Returns* :
      #   - new value of +type+
      # Side effect on +@type+
      def type=(value)
        value = (value.instance_of?(String) ? value.to_sym : value)
        @type = (value if @@typeList.include? value)
      end

      # Mutator method for member variable +subtype+
      # If value for +subtype+ is invalid +subtype+ will be set to +nil+
      # - *Args*  :
      #   - +value+ → new value for member variable +subtype+ (+:last+)
      # - *Returns* :
      #   - new value of +subtype+
      # Side effect on +@subtype+
      def subtype=(value)
        value = value.instance_of?(String) ? value.to_sym : value
        @subtype = (value if @@subtypeList.include? value)
      end

      # Mutator method for member variable +date+
      # If value for +date+ is invalid, +date+ will be set to +nil+
      # - *Args*  :
      #   - +value+ → new value for member variable +date+ (YYYY[-MM[-DD]])
      # - *Returns* :
      #   - new value of +date+
      # Side effect on +@date+
      def date=(value)
        value = value.instance_of?(Symbol) ? value.to_s : value
        @date = (value if value =~ /\A-?\d\d\d\d(-\d\d(-\d\d)?)?\Z/)
      end

      # Mutator method for member variable +value+
      # If value for member variable +value+ is invalid it will be set to +nil+
      # - *Args*  :
      #   - +value+ → new value for member variable (only valid value is +:unknown+)
      # - *Returns* :
      #   - new value
      # Side effect on +@value+
      def value=(value)
        @value = (:unknown if value && value.to_sym == :unknown)
      end

      # Mutator method for member variable +placeList+
      # - *Args*  :
      #   - +place+ → +Place+ object that shall be appended to member variable +placeList+
      # Side effect on +@placeList+
      def addPlace(place)
        @placeList[@placeList.length] = place if place.is_a? Place
      end
    end

    # Data structure for place information
    class Place
      attr_accessor :id, :exclude, :geoList

      # Constructor
      # - *Args*  :
      #   - +init+ → +Hash+ object containing place data as provided by the model class +BiblioIdentifier+, used to initialise member variables, defaults to +nil+
      # Side effect on +@id+, +@exclude+ and +@geoList+
      def initialize(init = nil)
        @id      = nil
        @exclude = nil
        @geoList = []

        if init
          if init[:place]
            if init[:place][:attributes]
              @id = init[:place][:attributes][:id] if init[:place][:attributes][:id]
              @exclude = init[:place][:attributes][:exclude] if init[:place][:attributes][:exclude]
            end
            if init[:place][:children] && init[:place][:children][:geo]
              init[:place][:children][:geo].each do |geo|
                addGeo(GeoSpot.new(geo: geo))
              end
            end
          else
            @id = init[:id] || nil
            @exclude = init[:exclude] || nil
          end

        end
      end

      # Mutator method for member variable +geoList+
      # - *Args*  :
      #   - +geo+ → +GeoSpot+ object that shall be appended to member variable +geoList+
      # Side effect on +@geoList+
      def addGeo(geo)
        @geoList[@geoList.length] = geo if geo.instance_of?(GeoSpot)
      end
    end

    # Data structure for geo information
    class GeoSpot
      @@typeList      = %i[ancient modern]
      @@subtypeList   = %i[nome province region]
      @@offsetList    = [:near]
      @@certaintyList = [:low]

      attr_accessor :type, :subtype, :offset, :name, :certainty, :referenceList

      # Constructor
      # - *Args*  :
      #   - +init+ → +Hash+ object containing geo data as provided by the model class +BiblioIdentifier+ or a simple +Hash+ structure mapping a symbol of the same name as the member variable to a desired value, used to initialise member variables, defaults to +nil+
      # Side effect on +@type+, +@subtype+, +@offset+, +@name+, +@certainty+ and +@referenceList+ (+Array+)
      def initialize(init = nil)
        @type          = nil
        @subtype       = nil
        @offset        = nil
        @name          = nil
        @certainty     = nil
        @referenceList = []

        if init
          if init[:geo]
            if init[:geo][:attributes]
              %i[type subtype certainty].each do |member|
                send("#{member}=".to_sym, init[:geo][:attributes][member] || nil)
              end
              @referenceList = init[:geo][:attributes][:reference].split if init[:geo][:attributes][:reference]
            end
            @offset = init[:geo][:preFlag] if init[:geo][:preFlag] # CL: CROMULENT GEO HACK
            @name = init[:geo][:value] if init[:geo][:value]
          else
            @type          = init[:type]          || nil
            @subtype       = init[:subtype]       || nil
            @offset        = init[:offset]        || nil
            @name          = init[:name]          || nil
            @certainty     = init[:certainty]     || nil
            @referenceList = init[:referenceList] || []
          end
        end
      end

      # Mutator method for member variable +type+
      # If value for +type+ is invalid +type+ will be set to +nil+
      # - *Args*  :
      #   - +value+ → new value for member variable +type+ (+:ancient+, +:modern+)
      # - *Returns* :
      #   - new value of +type+
      # Side effect on +@type+
      def type=(value)
        value = value.instance_of?(String) ? value.to_sym : value
        @type = (value if @@typeList.include? value)
      end

      # Mutator method for member variable +subtype+
      # If value for +subtype+ is invalid +subtype+ will be set to +nil+
      # - *Args*  :
      #   - +value+ → new value for member variable +subtype+ (+:nome+, +:province+, +:region+)
      # - *Returns* :
      #   - new value of +subtype+
      # Side effect on +@subtype+
      def subtype=(value)
        value = value.instance_of?(String) ? value.to_sym : value
        @subtype = (value if @@subtypeList.include? value)
      end

      # Mutator method for member variable +offset+
      # If value for +offset+ is invalid +offset+ will be set to +nil+ instead
      # - *Args*  :
      #   - +value+ → new value for member variable +offset+ (+:near+)
      # - *Returns* :
      #   - new value of +offset+
      # Side effect on +@offset+
      def offset=(value)
        value = value.instance_of?(String) ? value.to_sym : value
        @offset = (value if @@offsetList.include? value)
      end

      # Mutator method for member variable +certainty+
      # If value for +certainty+ is invalid +certainty+ will be set to +nil+ instead
      # - *Args*  :
      #   - +value+ → new value for member variable +certainty+ (+:low+)
      # - *Returns* :
      #   - new value of +certainty+
      # Side effect on +@certainty+
      def certainty=(value)
        value = value.instance_of?(String) ? value.to_sym : value
        @certainty = (value if @@certaintyList.include? value)
      end

      # Accessor method for member variable +certainty+
      # - *Returns* :
      #   - true if +certainty+ is +:low+, false otherwise
      def certain?
        certainty && certainty.to_sym == :low ? true : false
      end

      # Mutator method for member variable +referenceList+
      # - *Args*  :
      #   - +value+ → +String+ object that shall be appended to member variable +referenceList+
      # Side effect on +@referenceList+
      def addReference(value)
        if value.is_a?(String) && !value.empty? && !@referenceList.include?(value)
          @referenceList[@referenceList.length] = value
        end
      end
    end
  end

  # Module for HGV publication data
  module HgvPublication
    # Assembles all possible values for publication parts, such as +S. …+ for pages or +Kol. …+ for column numbers
    # - *Returns* :
    #   - +Array+ of pairs which again are stored within an +Array+ +[[:pattern, :type], [:pattern, :type], ...]+
    def self.getTypeOptions
      [['', :generic],
       ['S. …',        :pages],
       ['(S. …)',      :pages],
       ['Z. …',        :lines],
       ['(Z. …)',      :lines],
       ['Fr. …',       :fragments],
       ['Fol. …',      :folio],
       ['inv. …',      :inventory],
       ['Inv. Nr. …',  :pages],
       ['Nr. …',       :number],
       ['Kol. …',      :columns]]
    end

    # Facade to access a publication's volume information
    # - *Args*  :
    #   - +publicationExtra+ → publication data as provided by HGV metadata model class
    # - *Returns* :
    #   - +String+ if desired information can be retrieved from current publication data
    #   - +nil+ otherwise
    def self.getVolume(publicationExtra)
      HgvPublication.get :volume, publicationExtra
    end

    # Facade to access a publication's fascicle information
    # - *Args*  :
    #   - +publicationExtra+ → publication data as provided by HGV metadata model class
    # - *Returns* :
    #   - +String+ if desired information can be retrieved from current publication data
    #   - +nil+ otherwise
    def self.getFascicle(publicationExtra)
      HgvPublication.get :fascicle, publicationExtra
    end

    # Facade to access a publication's numbers information
    # - *Args*  :
    #   - +publicationExtra+ → publication data as provided by HGV metadata model class
    # - *Returns* :
    #   - +String+ if desired information can be retrieved from current publication data
    #   - +nil+ otherwise
    def self.getNumbers(publicationExtra)
      HgvPublication.get :numbers, publicationExtra
    end

    # Facade to access a publication's side information
    # - *Args*  :
    #   - +publicationExtra+ → publication data as provided by HGV metadata model class
    # - *Returns* :
    #   - +String+ if desired information can be retrieved from current publication data
    #   - +nil+ otherwise
    def self.getSide(publicationExtra)
      HgvPublication.get :side, publicationExtra
    end

    # Facade to access a typed bit of information from a publication
    # - *Args*  :
    #   - +type+ → type to extract (+:volume+, +fascicle+, +numbers+, +side+)
    #   - +publicationExtra+ → publication data as provided by HGV metadata model class
    # - *Returns* :
    #   - +String+ if desired information can be retrieved from current publication data
    #   - +nil+ otherwise
    def self.get(type, publicationExtra)
      publicationExtra&.each do |biblScope|
        if biblScope[:attributes] && biblScope[:attributes][:type] && biblScope[:attributes][:type].to_s == type.to_s
          return biblScope[:value]
        end
      end
      nil
    end

    # Populates handy +Array+ from complex EpiDoc structure
    # - *Args*  :
    #   - +publicationExtra+ → publication data as provided by HGV metadata model class
    # - *Returns* :
    #   - +Array+ containing all publication attributes that are NOT volume, fascicle, numbers or side
    #   - [{:type => ..., :value => ...}, {:type => ..., :value => ...}, ...]
    def self.getExtras(publicationExtra)
      extras = []
      publicationExtra&.each do |biblScope|
        if biblScope[:attributes] && biblScope[:attributes][:type] && !%i[volume fascicle numbers
                                                                          side].include?(biblScope[:attributes][:type].to_sym)
          extras[extras.length] = { type: biblScope[:attributes][:type], value: biblScope[:value] }
        end
      end
      extras
    end

    # Builds a chain of publication features that need to append to a publication's title in order to tell the whole story
    # - *Args*  :
    #   - +publicationExtra+ → publication data as provided by HGV metadata model class
    # - *Returns* :
    #   - +String+ that concatenates all bits publication attributes by interspersing a blank
    def self.getTitleTail(publicationExtra)
      title = ''
      publicationExtra&.each do |biblScope|
        title += "#{biblScope[:value]} " if biblScope[:value]
      end
      title
    end
  end

  # Module for the formatting of HGV geo data, uses data structures that are provided by the +HgvGeo+ module
  module HgvProvenance
    # Formats a given list of +Place+ objects according to HGV style
    # - *Args*  :
    #   - +placeList+ → +Array+ of +Place+ objects
    # - *Returns* :
    #   - formatted place +String+, +"<ORT1>, <ORT2> oder <ORT3>"+
    def self.formatPlaceList(placeList)
      result = ''

      placeList.each_index do |placeIndex|
        result << HgvProvenance.formatGeoList(placeList[placeIndex].geoList)

        result << if placeIndex < placeList.length - 1
                    if placeIndex == placeList.length - 2
                      ' oder '
                    elsif placeIndex < placeList.length - 2
                      ', '
                    else
                      ''
                    end
                  else
                    ''
                  end
      end

      result
    end

    # Formats a given list of +GeoSpot+ objects according to HGV style
    # - *Args*  :
    #   - +geoList+ → +Array+ of +GeoSpot+ objects
    # - *Returns* :
    #   - formatted geo +String+, +"<MODERN SETTLEMENT> bei <ANCIENT SETTLEMENT>, (<ANCIENT NOME>, <ANCIENT REGION> ?)"+
    def self.formatGeoList(geoList)
      result = ''

      ancient = geoList.select do |geo|
        [:settlement, nil].include?(geo.subtype) && geo.type == :ancient ? true : false
      end.shift
      modern = geoList.select do |geo|
        [:settlement, nil].include?(geo.subtype) && geo.type == :modern ? true : false
      end.shift
      province = geoList.select do |geo|
        [:province].include?(geo.subtype) && geo.type == :ancient ? true : false
      end.shift
      nome      = geoList.select { |geo| [:nome].include?(geo.subtype) && geo.type == :ancient ? true : false }.shift
      region    = geoList.select { |geo| [:region].include?(geo.subtype) && geo.type == :ancient ? true : false }.shift

      if ancient && modern
        if ancient.offset
          result << HgvProvenance.formatGeoSpot(modern)
          result << ' '
          result << HgvProvenance.formatGeoSpot(ancient)
        else
          result << HgvProvenance.formatGeoSpot(ancient)
          result << ' (= '
          result << HgvProvenance.formatGeoSpot(modern)
          result << ')'
        end
      elsif ancient
        result << HgvProvenance.formatGeoSpot(ancient)
      elsif modern
        result << HgvProvenance.formatGeoSpot(modern)
      end

      if province || nome || region
        result << ' (' if ancient || modern

        provinceNomeAndRegion = ''
        [province, nome, region].compact.each do |geoSpot|
          provinceNomeAndRegion << if geoSpot.offset
                                     ' '
                                   else
                                     ', '
                                   end
          provinceNomeAndRegion << HgvProvenance.formatGeoSpot(geoSpot)
        end

        result << (provinceNomeAndRegion =~ /[^, ].*$/ ? provinceNomeAndRegion[/[^, ].*$/] : '')

        result << ')' if ancient || modern
      end

      result
    end

    # Formats a single +GeoSpot+ object according to HGV style
    # - *Args*  :
    #   - +geoSpot+ → +GeoSpot+ object
    # - *Returns* :
    #   - formatted geo +String+, +"bei <ORT> ?"+
    def self.formatGeoSpot(geoSpot)
      result = ''
      result << (geoSpot.offset ? 'bei ' : '')
      result << (geoSpot.name || '')
      result << (geoSpot.certainty ? ' ?' : '')
      result
    end

    # Formats a list of +Provenance+ objects according to HGV style
    # - *Args*  :
    #   - +provenanceList+ → list +Provenance+ objects
    # - *Returns* :
    #   - formatted provenance +String+, +"Fundort: <ORT1>; zuletzt gesichtet: bei <ORT2> ?"+
    def self.format(provenanceList)
      provenanceList = HgvGeo::Provenance.getObjectList(provenanceList)
      result = ''

      if provenanceList && !provenanceList.empty?

        provenanceList.each do |provenance|
          begin
            result << 'zuletzt ' if provenance.subtype == :last

            result << {
              found: 'Fundort',
              observed: 'gesichtet',
              destroyed: 'zerstört',
              'not-found': 'verschollen',
              reused: 'wiederverwendet',
              moved: 'bewegt',
              acquired: 'erworben',
              sold: 'verkauft',
              composed: 'Schreibort',
              sent: 'Zielort',
              executed: 'Ort der Ausführung',
              received: 'Empfangsort',
              # :located => 'Betreffort',
              composition: 'Schreibort',
              destination: 'Zielort',
              execution: 'Ort der Ausführung',
              receipt: 'Empfangsort',
              reuse: 'Wiederverwendung'
            }[provenance.type]

            result << ': '
          rescue StandardError
          end

          result << HgvProvenance.formatPlaceList(provenance.placeList)

          if provenance.date
            result << ' - '
            result << HgvFormat.formatDateFromIsoParts(provenance.date)
          end

          result << '; '
        end

        result = result[0..-3]

      else
        result = 'unbekannt'
      end

      result
    end

    # Assembles all valid certainty options for HGV provenance (+low+)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.certaintyOptions
      [
        ['', ''],
        [I18n.t('provenance.certainty.low'), :low]
      ]
    end

    # Assembles all valid type options for HGV provenance (+composed+, +sent+, +sold+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.typeOptions
      [
        ['', ''],
        [I18n.t('provenance.type.composed'),  :composed],
        [I18n.t('provenance.type.sent'),      :sent],
        [I18n.t('provenance.type.executed'),  :executed],
        [I18n.t('provenance.type.received'),  :received],
        [I18n.t('provenance.type.located'),   :located],
        [I18n.t('provenance.type.found'),     :found],
        [I18n.t('provenance.type.observed'),  :observed],
        [I18n.t('provenance.type.destroyed'), :destroyed],
        [I18n.t('provenance.type.not-found'), :'not-found'],
        [I18n.t('provenance.type.reused'),    :reused],
        [I18n.t('provenance.type.acquired'),  :acquired],
        [I18n.t('provenance.type.sold'),      :sold],
        [I18n.t('provenance.type.moved'),     :moved]
      ]
    end

    # Assembles all valid subtype options for HGV provenance (+last+)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.subtypeOptions
      [
        ['', ''],
        [I18n.t('provenance.subtype.last'), :last]
      ]
    end

    # Assembles all valid subtype options for HGV geo spot (+ancient+, +modern+)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.epochOptions
      [
        [I18n.t('provenance.epoch.ancient'), :ancient],
        [I18n.t('provenance.epoch.modern'),  :modern]
      ]
    end

    # Assembles all valid territory (subtype) options for HGV geo spot (+nome+, +region+)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.territoryOptions
      [
        ['', ''],
        [I18n.t('provenance.territory.nome'),     :nome],
        [I18n.t('provenance.territory.province'), :province],
        [I18n.t('provenance.territory.region'),   :region]
      ]
    end

    # Assembles all valid offset options for HGV geo spot (+near+)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.offsetOptions
      [
        ['', ''],
        [I18n.t('provenance.offset.near'), 'bei']
      ]
    end
  end

  # Module for HGV date transformations and option values
  module HgvDate
    # Assembles all valid precision options for HGV date (+ca.+)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.precisionOptions
      [['', ''],
       [I18n.t('date.ca'), :ca]]
    end

    # Assembles all valid month qualifiers for HGV date (+beginning+, +middle+, +end+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.monthOptions
      [['', ''],
       [I18n.t('date.beginning'), :beginning],
       [I18n.t('date.beginningCirca'), :beginningCirca],
       [I18n.t('date.middle'), :middle],
       [I18n.t('date.middleCirca'), :middleCirca],
       [I18n.t('date.end'), :end],
       [I18n.t('date.endCirca'), :endCirca]]
    end

    # Assembles all valid year qualifiers for HGV date (+beginning+, +middle+, +end+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.yearOptions
      [['', ''],
       [I18n.t('date.beginning'), :beginning],
       [I18n.t('date.beginningCirca'), :beginningCirca],
       [I18n.t('date.firstHalf'), :firstHalf],
       [I18n.t('date.firstHalfCirca'), :firstHalfCirca],
       [I18n.t('date.firstHalfToMiddle'), :firstHalfToMiddle],
       [I18n.t('date.firstHalfToMiddleCirca'), :firstHalfToMiddleCirca],
       [I18n.t('date.middle'), :middle],
       [I18n.t('date.middleCirca'), :middleCirca],
       [I18n.t('date.middleToSecondHalf'), :middleToSecondHalf],
       [I18n.t('date.middleToSecondHalfCirca'), :middleToSecondHalfCirca],
       [I18n.t('date.secondHalf'), :secondHalf],
       [I18n.t('date.secondHalfCirca'), :secondHalfCirca],
       [I18n.t('date.end'), :end],
       [I18n.t('date.endCirca'), :endCirca]]
    end

    # Assembles all valid century qualifiers for HGV date (+beginning+, +middle+, +end+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.centuryOptions
      [['', ''],
       [I18n.t('date.beginning'), :beginning],
       [I18n.t('date.beginningCirca'), :beginningCirca],
       [I18n.t('date.beginningToMiddle'), :beginningToMiddle],
       [I18n.t('date.beginningToMiddleCirca'), :beginningToMiddleCirca],
       [I18n.t('date.firstHalf'), :firstHalf],
       [I18n.t('date.firstHalfCirca'), :firstHalfCirca],
       [I18n.t('date.firstHalfToMiddle'), :firstHalfToMiddle],
       [I18n.t('date.firstHalfToMiddleCirca'), :firstHalfToMiddleCirca],
       [I18n.t('date.middle'), :middle],
       [I18n.t('date.middleCirca'), :middleCirca],
       [I18n.t('date.middleToSecondHalf'), :middleToSecondHalf],
       [I18n.t('date.middleToSecondHalfCirca'), :middleToSecondHalfCirca],
       [I18n.t('date.secondHalf'), :secondHalf],
       [I18n.t('date.secondHalfCirca'), :secondHalfCirca],
       [I18n.t('date.middleToEnd'), :middleToEnd],
       [I18n.t('date.middleToEndCirca'), :middleToEndCirca],
       [I18n.t('date.end'), :end],
       [I18n.t('date.endCirca'), :endCirca]]
    end

    # Assembles all valid offset options for HGV date (+before+, +after+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.offsetOptions
      [['', ''],
       [I18n.t('date.before'), :before],
       [I18n.t('date.after'), :after],
       [I18n.t('date.beforeUncertain'), :beforeUncertain],
       [I18n.t('date.afterUncertain'), :afterUncertain]]
    end

    # Assembles all valid certainty options for HGV date (+low+, +day+, +month+, +year+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.certaintyOptions
      [['', ''],
       [I18n.t('date.certaintyLow'), :low],
       [I18n.t('date.dayUncertain'), :day],
       [I18n.t('date.monthUncertain'), :month],
       [I18n.t('date.yearUncertain'), :year],
       [I18n.t('date.dayAndMonthUncertain'), :day_month],
       [I18n.t('date.monthAndYearUncertain'), :month_year],
       [I18n.t('date.dayAndYearUncertain'), :day_year],
       [I18n.t('date.dayMonthAndYearUncertain'), :day_month_year]]
    end

    # Get ISO formatted year ([-]YYYY)
    # - *Args*  :
    #   - +century+ → signed integer, e.g. -5
    #   - +centuryQualifier+ → qualifies which part of the century is of interest, e.g. +:beginning+, may be +nil+
    #   - +chron+ → +:chronMin+ or +:chronMax+
    # - *Returns* :
    #   - +String+, e.g. +-0476+
    # e.g. HgvDate.getYearIso(-5, :beginning, :chronMax) => "-0476"
    def self.getYearIso(century, centuryQualifier, chron)
      century = century.to_i

      yearModifier = {
        chronMin: {
          nil => 0,
          :beginning => 0,
          :beginningToMiddle => 0,
          :firstHalf => 0,
          :firstHalfToMiddle => 25,
          :middle => 25,
          :middleToSecondHalf => 50,
          :secondHalf => 50,
          :middleToEnd => 25,
          :end => 75
        },
        chronMax: {
          nil => 0,
          :beginning => -75,
          :beginningToMiddle => -50,
          :firstHalf => -50,
          :firstHalfToMiddle => -50,
          :middle => -25,
          :middleToSecondHalf => -25,
          :secondHalf => 0,
          :middleToEnd => 0,
          :end => 0
        }
      }[chron][centuryQualifier ? centuryQualifier.to_s.sub('Circa', '').to_sym : nil]

      year = if chron == :chronMax
               if century.positive?
                 ((century * 100) + yearModifier).to_s.rjust(4,
                                                             '0')
               else
                 (((century + 1) * 100) + yearModifier - 1).abs.to_s.rjust(
                   4, '0'
                 )
               end
             elsif century.negative?
               ((century * 100) + yearModifier).abs.to_s.rjust(4,
                                                               '0')
             else
               (((century - 1) * 100) + yearModifier + 1).to_s.rjust(
                 4, '0'
               )
             end

      (century.negative? ? '-' : '') + year
    end

    # Get ISO formatted month (MM)
    # - *Args*  :
    #   - +month+ +String+, that contains a number, e.g. 5, may be +nil+
    #   - +yearQualifier+ → qualifies which part of the year is of interest, e.g. +:beginning+, may be +nil+
    #   - +chron+ → +:chronMin+ or +:chronMax+
    # - *Returns* :
    #   - +String+, e.g. +05+
    # e.g. HgvDate.getMonthIso(nil, :end, :chronMin) => "10"
    def self.getMonthIso(month, yearQualifier, chron)
      if month
        month.rjust(2, '0')
      else
        {
          chronMin: {
            nil => nil,
            :beginning => '01',
            :firstHalf => '01',
            :firstHalfToMiddle => '04',
            :middle => '04',
            :middleToSecondHalf => '07',
            :secondHalf => '07',
            :end => '10'
          },
          chronMax: {
            nil => nil,
            :beginning => '03',
            :firstHalf => '06',
            :firstHalfToMiddle => '06',
            :middle => '09',
            :middleToSecondHalf => '09',
            :secondHalf => '12',
            :end => '12'
          }
        }[chron][yearQualifier ? yearQualifier.to_s.sub('Circa', '').to_sym : nil]
      end
    end

    # Get ISO formatted day (DD)
    # - *Args*  :
    #   - +day+ +String+ or +Integer+, that contains a number, e.g. 31, may be +nil+
    #   - +month+ +String+ or +Integer+, that contains a number, e.g. 5, may be +nil+
    #   - +year+ +String+ or +Integer+, that contains a number, e.g. 200, may be +nil+
    #   - +monthQualifier+ → qualifies which part of the year is of interest, e.g. +:beginning+, may be +nil+
    #   - +chron+ → +:chronMin+ or +:chronMax+
    # - *Returns* :
    #   - +String+, e.g. +31+
    # e.g. HgvDate.getDayIso(nil, 7, :end, :chronMax) => "31"
    def self.getDayIso(day, month, year, monthQualifier, chron)
      if day
        day.to_s.rjust(2, '0')
      else
        m = month.to_i
        y = year.to_i
        day_max = if m
                    if m == 2
                      (y && (y % 4).zero? && (((y % 100) != 0) || (y % 400).zero?) ? 29 : 28)
                    elsif m < 8
                      m.even? ? 30 : 31
                    else
                      (m.even? ? 31 : 30)
                    end
                  else
                    31
                  end

        {
          chronMin: {
            nil => nil,
            :beginning => '01',
            :middle => '11',
            :end => '21'
          },
          chronMax: {
            nil => nil,
            :beginning => '10',
            :middle => '20',
            :end => day_max.to_s
          }
        }[chron][monthQualifier ? monthQualifier.to_s.sub('Circa', '').to_sym : nil]
      end
    end

    # Finds the century of a given year
    # - *Args*  :
    #   - +year+ +Integer+ value, e.g. -1234
    # - *Returns* :
    #   - +Integer+, e.g. +-13+
    # e.g. HgvDate.getCentury(-1234) => "-13"
    def self.getCentury(year)
      if year
        ((year.abs / 100) + ((year.abs % 100).zero? ? 0 : 1)) * (year.positive? ? 1 : -1)
      end
    end

    # Finds the corresponding century qualifier of a given year range
    # - *Args*  :
    #   - +year+ +Integer+ value of first year
    #   - +year2+ +Integer+ value of second year
    # - *Returns* :
    #   - +Symbol+, e.g. +:middle+
    # e.g. HgvDate.getCenturyQualifier(126, 175) => :middle
    def self.getCenturyQualifier(year, year2)
      return nil if !year || !year2

      century = HgvDate.getCentury year
      century2 = HgvDate.getCentury year2
      tens = year.abs.to_s.rjust(2, '0')[-2..-1].to_i * (year.abs / year)
      tens2 = year2.abs.to_s.rjust(2, '0')[-2..-1].to_i * (year2.abs / year2)

      if century == century2
        {
          [1, 25] => :beginning,
          [26, 50] => :firstHalfToMiddle,
          [51, 75] => :middleToSecondHalf,
          [76, 0] => :end,
          [1, 50] => :firstHalf,
          [26, 75] => :middle,
          [51, 0] => :secondHalf,
          [1, 75] => :beginningToMiddle,
          [26, 0] => :middleToEnd,

          [0, -76] => :beginning,
          [-75, -51] => :firstHalfToMiddle,
          [-50, -26] => :middleToSecondHalf,
          [-25, -1] => :end,
          [0, -51] => :firstHalf,
          [-75, -26] => :middle,
          [-50, -1] => :secondHalf,
          [0, -26] => :beginningToMiddle,
          [-75, -1] => :middleToEnd
        }[[tens, tens2]]
      else
        [
          {
            # 1 => :beginning,
            26 => :middle,
            51 => :secondHalf,
            76 => :end,

            # 0 => :beginning,
            -75 => :middle,
            -50 => :secondHalf,
            -25 => :end
          }[tens],
          {
            25 => :beginning,
            50 => :fisrtHalf,
            75 => :middle,
            # 0 => :end,

            -76 => :beginning,
            -51 => :firstHalf,
            -26 => :middle
            #-1 => :end
          }[tens2]
        ]
      end
    end

    # Finds the corresponding year qualifier of a given month range
    # - *Args*  :
    #   - +month+ +Integer+ value of first month, may be +nil+
    #   - +month2+ +Integer+ value of second month, may be +nil+
    # - *Returns* :
    #   - +Symbol+, e.g. +:middle+, or +nil+ if no match is found
    # e.g. HgvDate.getYearQualifier(5, 8) => :summer
    def self.getYearQualifier(month = nil, month2 = nil)
      if month && month2
        {
          [1, 2] => :lateWinter,
          [2, 5] => :spring,
          [5, 8] => :summer,
          [8, 11] => :autumn,
          [11, 12] => :earlyWinter,
          [1, 6] => :firstHalf,
          [4, 9] => :middle,
          [7, 12] => :secondHalf,
          [1, 3] => :beginning,
          [4, 6] => :fistHalfToMiddle,
          [7, 9] => :middleToFirstHalf,
          [10, 12] => :end
        }[[month, month2]]
      elsif month
        {
          1 => :beginning,
          2 => :spring,
          4 => :middle,
          5 => :summer,
          7 => :secondHalf,
          8 => :autumn,
          10 => :end,
          11 => :earlyWinter
        }[month]
      elsif month2
        {
          2 => :lateWinter,
          3 => :beginning,
          5 => :spring,
          6 => :firstHalf,
          8 => :summer,
          9 => :middle,
          11 => :autumn,
          12 => :end
        }[month2]
      end
    end

    # Finds the corresponding month qualifier of a given day range
    # - *Args*  :
    #   - +day+ +Integer+ value of first day, may be +nil+
    #   - +day2+ +Integer+ value of second day, may be +nil+
    # - *Returns* :
    #   - +Symbol+, e.g. +:middle+, or +nil+ if no match is found
    # e.g. HgvDate.getMonthQualifier(11, 20) => :middle
    def self.getMonthQualifier(day = nil, day2 = nil)
      if day && day2
        {
          [1, 10] => :beginning,
          [11, 20] => :middle,
          [21, 28] => :end # CL
        }[[day, day2]]
      elsif day
        {
          1 => :beginning,
          11 => :middle,
          21 => :end
        }[day]
      elsif day2
        {
          10 => :beginning,
          20 => :middle,
          28 => :end # CL
        }[day2]
      end
    end

    # Finds the corresponding month qualifier of a given day range
    # - *Args*  :
    #   - +iso+ ISO formatted date +String+
    #   - +regex+ regular expression
    # - *Returns* :
    #   - +Integer+ extract of ISO data, first match of regular expression or nil if no ISO formatted date is given or if no match can be made
    # e.g. HgvDate.extractFromIso('1884-08-28', /\A(-?\d\d\d\d)/) => 1884
    def self.extractFromIso(iso, regex)
      if iso
        iso =~ regex ? iso[regex, 1].to_i : nil
      end
    end

    # Facade for HgvDate.extractFromIso
    # - *Args*  :
    #   - +iso+ ISO formatted date +String+
    # - *Returns* :
    #   - +Integer+ year part of the ISO string
    # e.g. HgvDate.yearFromIso('1884-08-28') => 1884
    def self.yearFromIso(iso)
      HgvDate.extractFromIso iso, /\A(-?\d\d\d\d)/
    end

    # Facade for HgvDate.extractFromIso
    # - *Args*  :
    #   - +iso+ ISO formatted date +String+
    # - *Returns* :
    #   - +Integer+ month part of the ISO string
    # e.g. HgvDate.monthFromIso('1884-08-28') => 8
    def self.monthFromIso(iso)
      HgvDate.extractFromIso iso, /\A-?\d\d\d\d-(\d\d)/
    end

    # Facade for HgvDate.extractFromIso
    # - *Args*  :
    #   - +iso+ ISO formatted date +String+
    # - *Returns* :
    #   - +Integer+ day part of the ISO string
    # e.g. HgvDate.dayFromIso('1884-08-28') => 28
    def self.dayFromIso(iso)
      HgvDate.extractFromIso iso, /\A-?\d\d\d\d-\d\d-(\d\d)\Z/
    end

    # Provides an empty HGV date item
    # - *Returns* :
    #   - flat +Hash+ structure with all relevant date keys, i.e. century, year, month, day, certainty, offset etc.
    def self.getEmptyHgvItem
      {
        c: nil, y: nil, m: nil, d: nil, cx: nil, yx: nil, mx: nil, offset: nil, precision: nil, ca: false,
        c2: nil, y2: nil, m2: nil, d2: nil, cx2: nil, yx2: nil, mx2: nil, offset2: nil, precision2: nil, ca2: false,
        certainty: nil,
        unknown: nil,
        error: nil,
        empty: nil
      }
    end

    # Provides an empty HGV EpiDoc date item
    # - *Returns* :
    #   - nested +Hash+ structure with all relevant date keys, i.e. century, year, month, day, certainty, offset etc.
    def self.getEmptyEpidocItem
      {
        value: nil,
        attributes: {
          id: nil,
          when: nil,
          notBefore: nil,
          notAfter: nil,
          certainty: nil,
          precision: nil
        },
        children: {
          offset: [],
          precision: [],
          certainty: []
        }
      }
    end

    # Precision making process
    # - *Args*  :
    #   - +precision+ → circa
    #   - +cx+ → century qualifier
    #   - +yx+ → year qualifier
    #   - +mx+ → month qualifier
    # - *Returns* :
    #   - +Symbol+ of combined precision :low, :medium, :lowlow
    # HgvDate.getPrecision('ca', nil, nil, nil) => :medium
    def self.getPrecision(precision, cx, yx, mx)
      ca = precision || cx&.to_s&.include?('Circa') || yx&.to_s&.include?('Circa') || mx&.to_s&.include?('Circa')
      vague = cx || yx || mx
      if ca && vague
        :lowlow
      else
        (if ca
           :medium
         else
           (vague ? :low : nil)
         end)
      end
    end

    # Transforms EpiDoc structure provided by +HgvIdentifier+ class (nested values, attributes, children) into a simple +Hash+ structure (flat map of key as and values)
    # - *Args*  :
    #   - +date_item+ → date information
    # - *Returns* :
    #   - +Hash+ of date information
    # for examples see unit test for HGV date operations (test/uni/date_test.rb)
    def self.epidocToHgv(date_item)
      t = HgvDate.getEmptyHgvItem

      if date_item.nil? # simple case: no date
        t[:empty] = true
        return t
      end

      if date_item[:value] == 'unbekannt' # simple case: date is specified as unknown
        t[:unknown] = true
        return t
      end

      # complex case: process date information
      begin
        if date_item && date_item[:attributes]

          # date1
          iso = date_item[:attributes][:when] || (date_item[:attributes][:notBefore] || date_item[:attributes][:notAfter])
          if iso
            t[:y] = yearFromIso iso
            t[:m] = monthFromIso iso
            t[:d] = dayFromIso iso

            # date2
            t[:y2] = yearFromIso date_item[:attributes][:notAfter]
            t[:m2] = monthFromIso date_item[:attributes][:notAfter]
            t[:d2] = dayFromIso date_item[:attributes][:notAfter]

            if date_item[:children]
              # ca.
              if date_item[:attributes][:precision] == 'medium'
                t[:ca] = t[:ca2] = true
              elsif date_item[:children][:precision]
                date_item[:children][:precision].each do |precision|
                  if precision[:attributes] && precision[:attributes][:degree] && ['0.1',
                                                                                   '0.5'].include?(precision[:attributes][:degree])
                    if precision[:attributes][:match]
                      if precision[:attributes][:match].include?('notBefore')
                        t[:ca] = true
                      elsif precision[:attributes][:match].include?('notAfter')
                        t[:ca2] = true
                      end
                    else
                      t[:ca] = t[:ca2] = true
                    end
                  end
                end
              end

              # qualifier
              isVague = isVague2 = false
              if date_item[:attributes][:precision] == 'low'
                isVague = isVague2 = true
              elsif date_item[:children][:precision]
                date_item[:children][:precision].each do |precision|
                  if precision[:attributes] && (!precision[:attributes][:degree] || (precision[:attributes][:degree] && [
                    '0.1', '0.3'
                  ].include?(precision[:attributes][:degree])))
                    if precision[:attributes][:match]
                      if precision[:attributes][:match].include?('notBefore')
                        isVague = true
                      elsif precision[:attributes][:match].include?('notAfter')
                        isVague2 = true
                      end
                    else
                      isVague = isVague2 = true
                    end
                  end
                end
              end

              if isVague || isVague2

                # century
                if isVague && t[:y] && !t[:m] && !t[:d]

                  t[:c] = HgvDate.getCentury t[:y] # century no. 1

                  if isVague2 && t[:y2] && !t[:m2] && !t[:d2]
                    t[:c2] = HgvDate.getCentury t[:y2] # century no. 2
                  end

                  cx = HgvDate.getCenturyQualifier t[:y], t[:y2] # century qualifier (beginning, middle, end)
                  if cx.instance_of? Array
                    t[:cx], t[:cx2] = cx
                  else
                    t[:cx] = cx
                  end

                  if t[:c] == t[:c2]
                    t[:c2] = nil # combine century no.1 and no.2
                  end

                  t[:y] = t[:y2] = nil # kill years
                end

                # year
                if isVague && t[:y] && t[:m] && !t[:d]
                  if isVague2 && t[:y2] && t[:m2] && !t[:d2]
                    if t[:y] == t[:y2]
                      t[:yx] = HgvDate.getYearQualifier t[:m], t[:m2] # combine date no. 1 and date no. 2
                      t[:y2] = t[:m] = t[:m2] = nil
                    else
                      t[:yx] = HgvDate.getYearQualifier t[:m]
                      t[:yx2] = HgvDate.getYearQualifier nil, t[:m2]
                      t[:m] = t[:m2] = nil
                    end
                  else
                    t[:yx] = HgvDate.getYearQualifier t[:m]
                    t[:m] = nil
                  end
                elsif isVague2 && t[:y2] && t[:m2] && !t[:d2]
                  t[:yx2] = HgvDate.getYearQualifier nil, t[:m2]
                  t[:m2] = nil
                end

                # month
                if isVague && t[:y] && t[:m] && t[:d]
                  if isVague2 && t[:y2] && t[:m2] && t[:d2]
                    if t[:y] == t[:y2] && t[:m] == t[:m2]
                      t[:mx] = HgvDate.getMonthQualifier t[:d], t[:d2] # combine date no. 1 and date no. 2
                      t[:y2] = t[:m2] = t[:d] = t[:d2] = nil
                    else
                      t[:mx] = HgvDate.getMonthQualifier t[:d]
                      t[:mx2] = HgvDate.getMonthQualifier nil, t[:d2]
                      t[:d] = t[:d2] = nil
                    end
                  else
                    t[:mx] = HgvDate.getMonthQualifier t[:d]
                    t[:d] = nil
                  end
                elsif isVague2 && t[:y2] && t[:m2] && t[:d2]
                  t[:mx2] = HgvDate.getMonthQualifier nil, t[:d2]
                  t[:d2] = nil
                end

                # ...(?)
                t.each_pair do |k, v|
                  next unless k.to_s.include?('x') && v

                  t[k] = "#{v}Circa".to_sym if k.to_s.include?('2') ? t[:ca2] : t[:ca]
                end
              end

              # precision
              t[:precision] = if !t.reject do |k, v|
                                   k.to_s.include?('2') || v.nil?
                                 end.keys.join.include?('x') && t[:ca]
                                :ca
                              end
              t[:precision2] = if !t.reject do |k, v|
                                    !k.to_s.include?('2') || v.nil?
                                  end.keys.join.include?('x') && t[:ca2] && (t[:c2] || t[:y2] || t[:m2] || t[:d2])
                                 :ca
                               end

              # offset
              date_item[:children][:offset]&.each_index do |i|
                offset = date_item[:children][:offset][i][:attributes][:type]
                position = date_item[:children][:offset][i][:attributes][:position]
                attribute = "offset#{position == '2' ? '2' : ''}".to_sym

                t[attribute] = offset.to_sym

                next unless date_item[:children][:certainty]

                date_item[:children][:certainty].each do |certainty|
                  if certainty[:attributes] && certainty[:attributes][:match] && certainty[:attributes][:match] == "../offset[@type='#{offset}']"
                    t[attribute] = "#{t[attribute]}Uncertain".to_sym
                  end
                end
              end

              # certainties

              if date_item[:attributes][:certainty]
                t[:certainty] = date_item[:attributes][:certainty].to_sym
              elsif date_item[:children][:certainty]
                cert = { days: 0, months: 0, years: 0 }
                date_item[:children][:certainty].each do |certainty|
                  next unless certainty[:attributes] && certainty[:attributes][:match]

                  cert.each_key do |key|
                    cert[key] += 1 if certainty[:attributes][:match].include? key.to_s[0..-2]
                  end
                end
                if cert.values.join.to_i.positive?
                  t[:certainty] = cert.delete_if { |_k, v| v.zero? }
                                      .keys
                                      .collect { |i| i.to_s[0..-2] }
                                      .join('_')
                                      .to_sym # CL support for plurals goes here
                end
              end

              # kill doublets and left overs

              t[:y2] = (t[:y2] == t[:y] ? nil : t[:y2])
              t[:m2] = (t[:m2] == t[:m] ? nil : t[:m2])
              t[:d2] = (t[:d2] == t[:d] ? nil : t[:d2])
              t[:precision2] = (!t[:d2] && !t[:m2] && !t[:y2] && !t[:c2] ? nil : t[:precision2])

            end

          end
        end
      rescue StandardError => e
        t[:error] = "#{e.class}: #{e.message} (#{e.backtrace.inspect})" # $!, $ERROR_INFO
      end

      t
    end

    # Generate HGV EpiDoc like structure for precision information (see config/hgv.yml)
    # - *Args*  :
    #   - +degree+ → degree of precision
    #   - +match+ → qualifier for precision range
    # - *Returns* :
    #   - nested +Hash+ set
    def self.getPrecisionItem(degree, match = nil)
      {
        value: nil,
        children: {},
        attributes: {
          match: match,
          degree: degree
        }
      }
    end

    # Generate HGV EpiDoc like structure for certainty information (see config/hgv.yml)
    # - *Args*  :
    #   - +match+ → qualifier for certainty range
    # - *Returns* :
    #   - nested +Hash+ set
    def self.getCertaintyItem(match)
      {
        value: nil,
        children: {},
        attributes: {
          match: match
        }
      }
    end

    # Generate HGV EpiDoc like structure for offset information (see config/hgv.yml)
    # - *Args*  :
    #   - +offset+ → +:before+, +:after+, +:beforeUncertain+, +:afterUncertain+
    #   - +position+ → tells whether the offset belongs to the lower part of the date range or to the upper
    # - *Returns* :
    #   - nested +Hash+ set
    def self.getOffsetItem(offset, position)
      offset = offset.to_sym
      {
        value: { before: 'vor', after: 'nach', beforeUncertain: 'vor (?)',
                 afterUncertain: 'nach (?)' }[offset],
        children: {},
        attributes: {
          type: offset.to_s.sub('Uncertain', ''),
          position: position
        }
      }
    end

    # Transforms simple +Hash+ structure (flat map of key as and values) into EpiDoc structure that can be digested by +HgvIdentifier+ class (nested values, attributes, children)
    # - *Args*  :
    #   - +date_item+ → date information
    # - *Returns* :
    #   - nested +Hash+ of date information
    # for examples see unit test for HGV date operations (test/uni/date_test.rb)
    def self.hgvToEpidoc(date_item)
      t = HgvDate.getEmptyEpidocItem

      # date it X, Y, Z
      t[:attributes][:id] = date_item[:id]

      # unknown
      if date_item[:unknown]
        t[:value] = 'unbekannt'
        return t
      end

      if date_item[:c] # centuries
        date_item.delete :precision # centuries may not have a precision
        date_item.delete :precision2
        t[:attributes][:notBefore] = HgvDate.getYearIso date_item[:c], date_item[:cx], :chronMin
        t[:attributes][:notAfter] = if date_item[:c2]
                                      HgvDate.getYearIso date_item[:c2], date_item[:cx2], :chronMax
                                    else
                                      HgvDate.getYearIso date_item[:c], date_item[:cx], :chronMax
                                    end

        ca = date_item[:cx]&.to_s&.include?('Circa') ? true : false
        ca2 = date_item[:cx2]&.to_s&.include?('Circa') ? true : false

        if ca && ca2
          t[:children][:precision][t[:children][:precision].length] = HgvDate.getPrecisionItem '0.1'
        elsif ca
          t[:children][:precision][t[:children][:precision].length] = HgvDate.getPrecisionItem '0.1', '../@notBefore'
          t[:children][:precision][t[:children][:precision].length] = HgvDate.getPrecisionItem '0.3', '../@notAfter'
        elsif ca2
          t[:children][:precision][t[:children][:precision].length] = HgvDate.getPrecisionItem '0.3', '../@notBefore'
          t[:children][:precision][t[:children][:precision].length] = HgvDate.getPrecisionItem '0.1', '../@notAfter'
        else
          t[:attributes][:precision] = 'low'
        end
      else # year, month, day
        y = { nil => '', 0 => '-' }[date_item[:y] =~ /-/] + date_item[:y].sub('-', '').rjust(4, '0')
        m = HgvDate.getMonthIso date_item[:m], date_item[:yx], :chronMin
        d = HgvDate.getDayIso date_item[:d], date_item[:m], y, date_item[:mx], :chronMin

        date = y + (if m
                      "-#{m}#{d ? "-#{d}" : ''}"
                    else
                      ''
                    end)

        # only one date
        if !date_item[:y2] && !date_item[:m2] && !date_item[:d2] && !date_item[:yx] && !date_item[:mx]
          attribute = if date_item[:offset]
                        date_item[:offset].include?('before') ? :notAfter : :notBefore
                      else
                        :when
                      end
          t[:attributes][attribute] = date
        else
          t[:attributes][:notBefore] = date

          y2 = if date_item[:y2]
                 { nil => '',
                   0 => '-' }[date_item[:y2] =~ /-/] + date_item[:y2].sub('-', '').rjust(4, '0')
               else
                 y
               end
          m2 = HgvDate.getMonthIso((date_item[:m2] || (date_item[:d2] ? date_item[:m] : nil)),
                                   (date_item[:yx2] || (y2 == y ? date_item[:yx] : nil)), :chronMax)
          d2 = HgvDate.getDayIso date_item[:d2], (date_item[:m] || nil), y2,
                                 (date_item[:mx] || date_item[:mx2]), :chronMax

          date2 = y2 + (if m2
                          "-#{m2}#{d2 ? "-#{d2}" : ''}"
                        else
                          ''
                        end)

          t[:attributes][:notAfter] = date2
        end

        # precision
        precision = HgvDate.getPrecision(date_item[:precision], date_item[:cx], date_item[:yx], date_item[:mx])
        precision2 = HgvDate.getPrecision(date_item[:precision2], date_item[:cx2], date_item[:yx2], date_item[:mx2])

        if precision && ((precision == precision2) || ([t[:attributes][:when], t[:attributes][:notBefore],
                                                        t[:attributes][:notAfter]].compact.length == 1))
          if precision == :lowlow
            t[:children][:precision][t[:children][:precision].length] = HgvDate.getPrecisionItem '0.1'
          else
            t[:attributes][:precision] = precision
          end
        elsif precision
          t[:children][:precision][t[:children][:precision].length] =
            HgvDate.getPrecisionItem(if precision == :low
                                       nil
                                     else
                                       (precision == :medium ? '0.5' : '0.1')
                                     end,
                                     t[:attributes][:when] ? '../@when' : '../@notBefore')
        end
        if precision2
          t[:children][:precision][t[:children][:precision].length] =
            HgvDate.getPrecisionItem(if precision2 == :low
                                       nil
                                     else
                                       (precision2 == :medium ? '0.5' : '0.1')
                                     end, '../@notAfter')
        end

      end

      # offset
      if date_item[:offset]
        t[:children][:offset][t[:children][:offset].length] = HgvDate.getOffsetItem date_item[:offset], 1
      end

      if date_item[:offset2]
        t[:children][:offset][t[:children][:offset].length] = HgvDate.getOffsetItem date_item[:offset2], 2
      end

      # offset certainty
      if date_item[:offset]&.to_s&.include?('Uncertain')
        t[:children][:certainty][t[:children][:certainty].length] =
          HgvDate.getCertaintyItem "../offset[@type='#{date_item[:offset].to_s.sub('Uncertain', '')}']"
      end

      if date_item[:offset2]&.to_s&.include?('Uncertain')
        t[:children][:certainty][t[:children][:certainty].length] =
          HgvDate.getCertaintyItem "../offset[@type='#{date_item[:offset2].to_s.sub('Uncertain', '')}']"
      end

      # certainty
      if date_item[:certainty] # global uncertainty
        if [:low, 'low'].include? date_item[:certainty]
          t[:attributes][:certainty] = 'low'
        else # uncertainty for day, month or year
          date_item[:certainty].to_s.split('_').each do |dayMonthYear|
            match = "../#{dayMonthYear}-from-date(@#{t[:attributes][:when] ? 'when' : 'notBefore'})" # cl: support for plurals would go here
            t[:children][:certainty][t[:children][:certainty].length] = HgvDate.getCertaintyItem match
          end
        end
      end

      # hgv format
      t[:value] = HgvFormat.formatDate date_item

      t
    end
  end

  # Module for transformations and option values for HGV mentioned date
  module HgvMentionedDate
    # Assembles all valid uncertainty options for HGV mentioned dates (+dayUncertain+, +dayAndMonthUncertain+, etc.)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.certaintyOptions
      [['', ''], ['(?)', 'low'], [I18n.t('date.dayUncertain'), 'day'],
       [I18n.t('date.dayAndMonthUncertain'), 'day_month'], [I18n.t('date.monthUncertain'), 'month'], [I18n.t('date.monthAndYearUncertain'), 'month_year'], [I18n.t('date.yearUncertain'), 'year']]
    end

    # Assembles all valid date alternatives for HGV mentioned dates (+dateAlternativeX+, +dateAlternativeY+, +dateAlternativeZ+)
    # - *Returns* :
    #   - +Array+ of +Array+s that can be used with rails' +options_for_select+ method
    def self.dateIdOptions
      [['', ''], ['X', '#dateAlternativeX'], ['Y', '#dateAlternativeY'], ['Z', '#dateAlternativeZ']]
    end

    # Transforms EpiDoc structure provided by +HgvIdentifier+ class (nested values, attributes, children) into a simple +Hash+ structure (flat map of key as and values)
    # - *Args*  :
    #   - +mentioned_date+ → list of date information
    # - *Returns* :
    #   - +Array+ of +Hash+s containing date information
    def self.dateInformation(mentioned_date)
      data = []

      mentioned_date.each do |item|
        data_item = { date: '', ref: '', certainty: '', certaintyPicker: '', dateId: '', comment: '',
                      annotation: '', when: '', whenDayCertainty: '', whenMonthCertainty: '', whenYearCertainty: '', notBefore: '', notBeforeDayCertainty: '', notBeforeMonthCertainty: '', notBeforeYearCertainty: '', notAfter: '', notAfterDayCertainty: '', notAfterMonthCertainty: '', notAfterYearCertainty: '' }
        if item[:children]
          item[:children].each_pair do |key, value|
            data_item[key] = value && value[:value] ? value[:value] : ''
          end
          if item[:children][:date] && item[:children][:date][:attributes]
            item[:children][:date][:attributes].each_pair do |key, value|
              data_item[key] = value || ''
            end
          end
          if item[:children][:date] && item[:children][:date][:children] && item[:children][:date][:children][:certainty]
            item[:children][:date][:children][:certainty].each do |certainty|
              if certainty[:attributes]
                if certainty[:attributes][:relation]
                  data_item[:dateId] = certainty[:attributes][:relation]
                elsif certainty[:attributes][:match]
                  key = certainty[:attributes][:match][/@(when|notBefore|notAfter)/,
                                                       1] + certainty[:attributes][:match][/(year|month|day)-from-date/,
                                                                                           1].capitalize + 'Certainty'
                  data_item[key.to_sym] = 'low'
                end
              end
            end

            data_item[:certaintyPicker] = data_item.select do |k, v|
                                            k.to_s.include?('Certainty') && k.to_s[/(Day|Month|Year)/] && !v.empty?
                                          end.collect { |v| v[0].to_s.include?('Certainty') ? v[0].to_s[/(Day|Month|Year)/].downcase : nil }.compact.uniq.sort.join('_')
            data_item[:certaintyPicker] =
              data_item[:certaintyPicker].empty? ? data_item[:certainty] : data_item[:certaintyPicker]

          end
        end
        data[data.length] = data_item
      end

      data
    end
  end

  # Module for the generation of HGV stylish date strings
  module HgvFormat
    # Generates pretty date format from a bunch of ISO dates
    # - *Args*  :
    #   - +isoWhen+ → ISO date
    #   - +isoNotBefore+ → ISO date, may be nil
    #   - +isoNotAfter+ → ISO date, may be nil
    #   - +certainty+ → may be nil
    # - *Returns* :
    #   - format +String+
    # e.g. HgvFormat.formatDateFromIsoParts('1884-08-28') => "28. Aug. 1884"
    def self.formatDateFromIsoParts(isoWhen, isoNotBefore = nil, isoNotAfter = nil, certainty = nil)
      date_item = {}

      date1 = if isoWhen && !isoWhen.empty?
                isoWhen
              else
                (isoNotBefore && !isoNotBefore.empty? ? isoNotBefore : nil)
              end

      if date1
        date_item[:y] = date1[/^(-?\d\d\d\d)/, 1]
        date_item[:m] = date1[/^-?\d\d\d\d-(\d\d)/, 1]
        date_item[:d] = date1[/^-?\d\d\d\d-\d\d-(\d\d)/, 1]

        date2 = isoNotAfter && !isoNotAfter.empty? ? isoNotAfter : nil

        if date2
          date_item[:y2] = date2[/^(-?\d\d\d\d)/, 1]
          date_item[:m2] = date2[/^-?\d\d\d\d-(\d\d)/, 1]
          date_item[:d2] = date2[/^-?\d\d\d\d-\d\d-(\d\d)/, 1]
        end
      end

      date_item[:certainty] = certainty if certainty

      HgvFormat.formatDate date_item
    end

    # Generates pretty date format from a date item
    # - *Args*  :
    #   - +date_item+ → Hash structure with date information
    # - *Returns* :
    #   - format +String+
    # e.g. HgvFormat.formatDate({:y => 1884, :m => 8, :d => 28}) => "28. Aug. 1884"
    def self.formatDate(date_item)
      precision = HgvFormat.formatPrecision date_item[:precision]
      certainty = HgvFormat.formatCertainty date_item[:certainty]

      date1 = formatDatePart(
        date_item[:c],
        date_item[:y2].nil? && (date_item[:m2] || date_item[:d2]) ? nil : date_item[:y],
        date_item[:m2].nil? && date_item[:d2] ? nil : date_item[:m],
        date_item[:d],
        date_item[:cx],
        date_item[:yx],
        date_item[:mx],
        date_item[:offset]
      )

      date2 = formatDatePart(
        date_item[:c2],
        date_item[:y2].nil? && (date_item[:m2] || date_item[:d2]) ? date_item[:y] : date_item[:y2],
        date_item[:m2].nil? && date_item[:d2] ? date_item[:m] : date_item[:m2],
        date_item[:d2],
        date_item[:cx2],
        date_item[:yx2],
        date_item[:mx2],
        date_item[:offset2]
      )

      (precision ? "#{precision} " : '') +
        (date2 && date2.include?(' v.Chr.') ? date1.sub(/ v\.Chr\./, '') : date1) +
        (date2 && !date2.empty? ? " - #{date2}" : '') +
        (certainty ? " #{certainty}" : '')
    end

    # Generates pretty date format from various bits of information (century, year, month, day, qualifiers and offsets)
    # - *Args*  :
    #   - +c+ → century, may be nil
    #   - +y+ → year, may be nil
    #   - +m+ → month, may be nil
    #   - +d+ → day, may be nil
    #   - +cq+ → century qualifier, may be nil
    #   - +yq → year qualifier, may be nil
    #   - +mq+ → month qualifier, may be nil
    #   - +offset+ → offset, may be nil
    # - *Returns* :
    #   - format +String+ (may be empty)
    # e.g. HgvFormat.formatDatePart(nil, 1884, 8, 28) => "28. Aug. 1884"
    # e.g. HgvFormat.formatDatePart 5 => "V"
    def self.formatDatePart(c = nil, y = nil, m = nil, d = nil, cq = nil, yq = nil, mq = nil, offset = nil)
      offset = formatOffset offset
      m      = formatMonth m
      d      = formatDay d
      y      = formatYear y
      c      = formatCentury c
      mq     = formatMonthQualifier mq
      yq     = formatYearQualifier yq
      cq     = formatCenturyQualifier cq

      ((offset ? "#{offset} " : '') +
        (d ? "#{d} " : '') +
        (mq ? "#{mq} " : '') +
        (m ? "#{m} " : '') +
        (yq ? "#{yq} " : '') +
        (y ? "#{y} " : '') +
        (cq ? "#{cq} " : '') +
        (c || '')).strip
    end

    # Generates pretty format for offset values
    # - *Args*  :
    #   - +offset+ → :before, :after, :beforeUncertain or :afterUncertain
    # - *Returns* :
    #   - format +String+ or +nil+ if nothing fits
    # e.g. HgvFormat.formatOffset(:afterUncertain) => "nach (?)"
    def self.formatOffset(offset)
      HgvFormat.format offset, {
        before: 'vor',
        after: 'nach',
        beforeUncertain: 'vor (?)',
        afterUncertain: 'nach (?)'
      }
    end

    # Generates pretty format for offset values
    # - *Args*  :
    #   - +offset+ → :before, :after, :beforeUncertain or :afterUncertain
    # - *Returns* :
    #   - format +String+ or +nil+ if nothing fits
    # e.g. HgvFormat.formatOffset(:afterUncertain) => "nach (?)"
    def self.formatCertainty(certainty)
      HgvFormat.format certainty, {
        low: '(?)',
        day: '(Tag unsicher)',
        month: '(Monat unsicher)',
        year: '(Jahr unsicher)',
        day_month: '(Monat und Tag unsicher)',
        month_year: '(Jahr und Monat unsicher)',
        day_year: '(Jahr und Tag unsicher)',
        day_month_year: '(Jahr, Monat und Tag unsicher)'
      }
    end

    # Generates pretty format for date precision
    # - *Args*  :
    #   - +precision+ → :ca
    # - *Returns* :
    #   - format +String+ or +nil+ if nothing fits
    # e.g. HgvFormat.formatPrecision(:ca) => "ca."
    def self.formatPrecision(precision)
      HgvFormat.format precision, {
        ca: 'ca.'
      }
    end

    # Generates pretty format for day information
    # - *Args*  :
    #   - +day+ → +String+ or +Integer+ number
    # - *Returns* :
    #   - format +String+ or +nil+ if it cannot be converted
    # e.g. HgvFormat.formatDay(28) => "28."
    def self.formatDay(day)
      day&.to_i&.positive? ? "#{day.to_i}." : nil
    end

    # Generates pretty format for month information
    # - *Args*  :
    #   - +month+ → +String+ or +Integer+ number
    # - *Returns* :
    #   - format +String+ or +nil+ if it cannot be converted
    # e.g. HgvFormat.formatMonth 8 => "Aug."
    def self.formatMonth(month)
      months = ['', 'Jan.', 'Febr.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.']
      month&.to_i&.positive? && month.to_i < 13 ? months[month.to_i] : nil
    end

    # Generates pretty format for year information
    # - *Args*  :
    #   - +year+ → +String+ or +Integer+ number
    # - *Returns* :
    #   - format +String+ or +nil+ if it cannot be converted
    # e.g. HgvFormat.formatYear(-1884) => "1884 v.Chr."
    def self.formatYear(year)
      if year && year.to_i != 0
        year.to_i.abs.to_s + (year.to_i.negative? ? ' v.Chr.' : '')
      end
    end

    # Generates pretty format for century information
    # - *Args*  :
    #   - +century+ → +String+ or +Integer+ number
    # - *Returns* :
    #   - format +String+ or +nil+ if it cannot be converted
    # e.g. HgvFormat.formatCentury(19) => "XIX"
    def self.formatCentury(century)
      if century && century.to_i != 0
        century.to_i.abs.roman.to_s + (century.to_i.negative? ? ' v.Chr.' : '')
      end
    end

    # Generates pretty format for month qualifier
    # - *Args*  :
    #   - +q+ → +Symbol+, month qualifier, e.g. +:beginning+, +:middle+ or +:end+
    # - *Returns* :
    #   - format +String+ or +nil+ if it cannot be converted
    # e.g.  HgvFormat.formatMonthQualifier(:endCirca) => "Ende (?)"
    def self.formatMonthQualifier(q)
      HgvFormat.format q, {
        beginning: 'Anfang',
        middle: 'Mitte',
        end: 'Ende',
        beginningCirca: 'Anfang (?)',
        middleCirca: 'Mitte (?)',
        endCirca: 'Ende (?)'
      }
    end

    # Generates pretty format for year qualifier
    # - *Args*  :
    #   - +q+ → +Symbol+, year qualifier, e.g. +:beginning+, +:middle+ or +:end+
    # - *Returns* :
    #   - format +String+ or +nil+ if it cannot be converted
    # e.g.  HgvFormat.formatYearQualifier(:middleToSecondHalfCirca) => "Mitte - 2. Hälfte (?)"
    def self.formatYearQualifier(q)
      HgvFormat.format q, {
        beginning: 'Anfang',
        firstHalf: '1. Hälfte',
        firstHalfToMiddle: '1. Hälfte - Mitte',
        middle: 'Mitte',
        middleToSecondHalf: 'Mitte - 2. Hälfte',
        secondHalf: '2. Hälfte',
        end: 'Ende',
        beginningCirca: 'Anfang (?)',
        firstHalfCirca: '1. Hälfte (?)',
        firstHalfToMiddleCirca: '1. Hälfte - Mitte (?)',
        middleCirca: 'Mitte (?)',
        middleToSecondHalfCirca: 'Mitte - 2. Hälfte (?)',
        secondHalfCirca: '2. Hälfte (?)',
        endCirca: 'Ende (?)'
      }
    end

    # Generates pretty format for century qualifier
    # - *Args*  :
    #   - +q+ → +Symbol+, century qualifier, e.g. +:beginning+, +:middle+ or +:end+
    # - *Returns* :
    #   - format +String+ or +nil+ if it cannot be converted
    # e.g.  HgvFormat.formatCenturyQualifier(:beginningToMiddle) => "Anfang - Mitte"
    def self.formatCenturyQualifier(q)
      HgvFormat.format q, {
        beginning: 'Anfang',
        beginningToMiddle: 'Anfang - Mitte',
        firstHalf: '1. Hälfte',
        firstHalfToMiddle: '1. Hälfte - Mitte',
        middle: 'Mitte',
        middleToSecondHalf: 'Mitte - 2. Hälfte',
        secondHalf: '2. Hälfte',
        middleToEnd: 'Mitte - Ende',
        end: 'Ende',
        beginningCirca: 'Anfang (?)',
        beginningToMiddleCirca: 'Anfang - Mitte (?)',
        firstHalfCirca: '1. Hälfte (?)',
        firstHalfToMiddleCirca: '1. Hälfte - Mitte (?)',
        middleCirca: 'Mitte (?)',
        middleToSecondHalfCirca: 'Mitte - 2. Hälfte (?)',
        secondHalfCirca: '2. Hälfte (?)',
        middleToEndCirca: 'Mitte - Ende (?)',
        endCirca: 'Ende (?)'
      }
    end

    # Helper function to retrieve a key from a list
    # - *Args*  :
    #   - +key+ → +String+ or +Symbol+
    #   - +list+ → +Hash+
    # - *Returns* :
    #   - list item at position of +key+ or nil if this position cannot be accessed
    # e.g.  HgvFormat.format(:a, {:a => 'A', :b => 'B'}) => "A"
    def self.format(key, list)
      begin
        key = key.to_sym
      rescue StandardError
        key = nil
      end

      list[key]
    end
  end

  # Module to turn HGV date vague qualifiers (beginning, middle, end, late, early) into hard values
  module HgvFuzzy
    # Wrapper function for getChron which gets rid of all values for month and day which were not explicitely set by the user
    # - *Args*  :
    #   - +c+ → century, may be nil
    #   - +y+ → year, may be nil
    #   - +m+ → month, may be nil
    #   - +d+ → day, may be nil
    #   - +cq+ → century qualifier, may be nil
    #   - +yq → year qualifier, may be nil
    #   - +mq+ → month qualifier, may be nil
    #   - +chron+ → :chron, :chronMax, :chronMin, defaults to :chron if not specified
    # - *Returns* :
    #   - HGV formatted date +String+
    # e.g. HgvFuzzy.getChronSimple('6', '543', '2', '1', '', '', '', :chronMin) => "0543-02-01"
    def self.getChronSimple(c, y, m, d, cq, yq, mq, chron = :chron)
      if chron == :chron && c.to_i != 0
        ''
      else
        intelligent_date = getChron c, y, m, d, cq, yq, mq, chron

        # throw away month and day if they were not explicitely set by the user
        if m.to_i.zero?
          intelligent_date[0..-7]
        elsif d.to_i.zero?
          intelligent_date[0..-4]
        else
          intelligent_date
        end
      end
    end

    # Generates HGV formatted date +String+ from date bits
    # - *Args*  :
    #   - +c+ → +Integer+ or +String+ representation of century, may be nil or empty
    #   - +y+ → +Integer+ or +String+ representation of year, may be nil or empty
    #   - +m+ → +Integer+ or +String+ representation of month, may be nil or empty
    #   - +d+ → +Integer+ or +String+ representation of day, may be nil or empty
    #   - +cq+ → century qualifier +String+, may be nil or empty
    #   - +yq → year qualifier +String+, may be nil or empty
    #   - +mq+ → month qualifier +String+, may be nil or empty
    #   - +chron+ → :chron, :chronMax, :chronMin, defaults to :chron if not specified
    # - *Returns* :
    #   - HGV formatted date +String+
    # e.g. HgvFuzzy.getChron('', '1976', '2', '', '', '', 'end', :chronMax) => "1976-02-29"
    def self.getChron(c, y, m, d, cq, yq, mq, chron = :chron)
      c = c.to_i == 0 ? nil : c.to_i
      y = y.to_i == 0 ? nil : y.to_i
      m = m.to_i == 0 ? nil : m.to_i
      d = d.to_i == 0 ? nil : d.to_i

      epoch = year = month = day = nil

      year_modifier = {
        chron: {
          '' => 13,
          'beginning' => 13,
          'first_half' => 13,
          'first_half_to_middle' => 38,
          'middle' => 38,
          'middle_to_second_half' => 63,
          'second_half' => 63,
          'end' => 87
        },
        chronMin: {
          '' => 0,
          'beginning' => 0,
          'first_half' => 0,
          'first_half_to_middle' => 25,
          'middle' => 25,
          'middle_to_second_half' => 50,
          'second_half' => 50,
          'end' => 75
        },
        chronMax: {
          '' => 0,
          'beginning' => -75,
          'first_half' => -50,
          'first_half_to_middle' => -50,
          'middle' => -25,
          'middle_to_second_half' => -25,
          'second_half' => 0,
          'end' => 0
        }
      }[chron][cq]

      month_modifier = {
        chron: {
          '' => '02',
          'beginning' => '02',
          'first_half' => '03',
          'first_half_to_middle' => '05',
          'middle' => '06',
          'middle_to_second_half' => '08',
          'second_half' => '09',
          'end' => '11'
        },
        chronMin: {
          '' => '01',
          'beginning' => '01',
          'first_half' => '01',
          'first_half_to_middle' => '04',
          'middle' => '04',
          'middle_to_second_half' => '07',
          'second_half' => '07',
          'end' => '10'
        },
        chronMax: {
          '' => '12',
          'beginning' => '03',
          'first_half' => '06',
          'first_half_to_middle' => '06',
          'middle' => '09',
          'middle_to_second_half' => '09',
          'second_half' => '12',
          'end' => '12'
        }
      }[chron][yq]

      m ||= month_modifier.to_i
      day_max = if m
                  if m == 2
                    (y && (y % 4).zero? && (((y % 100) != 0) || (y % 400).zero?) ? 29 : 28)
                  elsif m < 8
                    m.even? ? 30 : 31
                  else
                    (m.even? ? 31 : 30)
                  end
                else
                  31
                end
      day_modifier = {
        chron: {
          '' => '04',
          'beginning' => '04',
          'middle' => '15',
          'end' => '26'
        },
        chronMin: {
          '' => '01',
          'beginning' => '01',
          'middle' => '11',
          'end' => '21'
        },
        chronMax: {
          '' => day_max.to_s,
          'beginning' => '10',
          'middle' => '20',
          'end' => day_max.to_s
        }
      }[chron][mq]

      if y
        epoch = y.negative? ? '-' : ''
        year = y.abs.to_s.rjust(4, '0')
      elsif c
        epoch = c.negative? ? '-' : ''
        year = if chron == :chronMax
                 if c.positive?
                   ((c * 100) + year_modifier).to_s.rjust(4,
                                                          '0')
                 else
                   (((c + 1) * 100) + year_modifier - 1).abs.to_s.rjust(
                     4, '0'
                   )
                 end
               elsif c.negative?
                 ((c * 100) + year_modifier).abs.to_s.rjust(4,
                                                            '0')
               else
                 (((c - 1) * 100) + year_modifier + 1).to_s.rjust(
                   4, '0'
                 )
               end
      else
        return '' # if we have no year there is no go
      end

      month = if m
                m.to_s.rjust(2, '0')
              else
                month_modifier
              end

      day = if d
              d.to_s.rjust(2, '0')
            else
              day_modifier
            end

      "#{epoch}#{year}-#{month}-#{day}"
    end

    # Short cut for HgvFuzzy.getChron ... :chronMin
    # - *Args*  :
    #   - +c+ → +Integer+ or +String+ representation of century, may be nil or empty
    #   - +y+ → +Integer+ or +String+ representation of year, may be nil or empty
    #   - +m+ → +Integer+ or +String+ representation of month, may be nil or empty
    #   - +d+ → +Integer+ or +String+ representation of day, may be nil or empty
    #   - +cq+ → century qualifier +String+, may be nil or empty
    #   - +yq → year qualifier +String+, may be nil or empty
    #   - +mq+ → month qualifier +String+, may be nil or empty
    # - *Returns* :
    #   - HGV formatted date +String+
    def self.getChronMin(c, y, m, d, cq, yq, mq)
      HgvFuzzy.getChron c, y, m, d, cq, yq, mq, :chronMin
    end

    # Short cut for HgvFuzzy.getChron ... :chronMax
    # - *Args*  :
    #   - +c+ → +Integer+ or +String+ representation of century, may be nil or empty
    #   - +y+ → +Integer+ or +String+ representation of year, may be nil or empty
    #   - +m+ → +Integer+ or +String+ representation of month, may be nil or empty
    #   - +d+ → +Integer+ or +String+ representation of day, may be nil or empty
    #   - +cq+ → century qualifier +String+, may be nil or empty
    #   - +yq → year qualifier +String+, may be nil or empty
    #   - +mq+ → month qualifier +String+, may be nil or empty
    # - *Returns* :
    #   - HGV formatted date +String+
    def self.getChronMax(c, y, m, d, cq, yq, mq)
      HgvFuzzy.getChron c, y, m, d, cq, yq, mq, :chronMax
    end
  end
end

# ruby.brian-amberg.de
class Integer
  # Used for Integer to Roman conversion. (#roman)
  @@roman_values_assoc = %w[I IV V IX X XL L XC C CD D CM
                            M].zip([1, 4, 5, 9, 10, 40, 50, 90, 100, 400, 500, 900, 1000]).reverse

  # Used for Roman to Integer conversion. (Integer#roman)
  @@roman_values = @@roman_values_assoc.each_with_object({}) do |(r, a), h|
    h[r] = a
  end

  # Spits out the number as a roman number
  def roman
    return "-#{(-self).roman}" if negative?
    return '' if zero?

    @@roman_values_assoc.each { |(i, v)| return(i + (self - v).roman) if v <= self }
  end

  # Returns a roman number string
  def self.roman(roman)
    last = roman[-1, 1]
    roman.reverse.split('').inject(0) do |result, c|
      if @@roman_values[c] < @@roman_values[last]
        result -= @@roman_values[c]
      else
        last = c
        result += @@roman_values[c]
      end
    end
  end
end

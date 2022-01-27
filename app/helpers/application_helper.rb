# frozen_string_literal: true

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def rpx_signin_url(signin_method = 'signin')
    dest = if ENV['RAILS_ENV'] == 'production'
             url_for controller: :rpx, action: :login_return, only_path: false, protocol: 'https'
           else
             url_for controller: :rpx, action: :login_return, only_path: false
           end
    @rpx.signin_url(dest, signin_method)
  end

  def rpx_associate_url(signin_method = 'signin')
    dest = if ENV['RAILS_ENV'] == 'production'
             url_for controller: :rpx, action: :associate_return, only_path: false, protocol: 'https'
           else
             url_for controller: :rpx, action: :associate_return, only_path: false
           end
    @rpx.signin_url(dest, signin_method)
  end

  def rpx_widget_url
    "#{@rpx.base_url}/openid/v2/widget"
  end

  def clippy(textarea_id)
    [
      javascript_include_tag('clipboard'),
      %(<button type="button" id="copy-#{textarea_id}" data-clipboard-target="##{textarea_id}">Copy to Clipboard</button>),
      %{<script type="text/javascript">new ClipboardJS('#copy-#{textarea_id}');</script>}
    ].join("\n").html_safe
  end
end

require 'rexml/document'

class PrettySsime < REXML::Formatters::Pretty
  # http://stackoverflow.com/questions/4203180
  # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/rexml/rdoc/REXML/Formatters/Pretty.html
  # File rexml/formatters/pretty.rb, line 87
  # remove leading and trailing whitespaces from text string
  # wrap text only if wanted (@width > 0)
  # use member variable @width for text wrapping (not hard coded 80)
  # don't replace all linebreaks by spaces, just reduce them to at most one linefeed per break
  def write_text(node, output)
    s = node.to_s.strip
    s.gsub!(/(\t| )+/, ' ')
    s.gsub!(/\s*(\r|\n)+\s*/, "\r")
    s.squeeze!(' ')
    s = wrap(s, @width - @level) if @width.positive?
    s = indent_text(s, @level, ' ', true)
    output << (' ' * @level + s)
  end
end

module REXML
  class XPath
    @@breakXpathIntoLumps = {}

    # Breaks a given xpath into a sequence of individual tags and attributes
    # - *Args*  :
    #   - +xpath+ → sth. like /abc/a[@a='a']/b[@b='b']/c[@c1='c1'][@xml:c2='c2']/@c3
    # - *Returns* :
    #   - +Hash+ +Array+ of xpath bits, e.g. [{:xpath => ..., :element => ..., :attributes => ...}, ...]
    # e.g. REXML::XPath.breakXpathIntoLumps("/abc/a[@a='a']/b[@b='b']/c[@c1='c1'][@xml:c2='c2']/@c3") => [{:xpath=>"/abc", :element=>"abc", :attributes=>{}}, {:xpath=>"/abc/a[@a='a']", :element=>"a", :attributes=>{"a"=>"a"}}, {:xpath=>"/abc/a[@a='a']/b[@b='b']", :element=>"b", :attributes=>{"b"=>"b"}}, {:xpath=>"/abc/a[@a='a']/b[@b='b']/c[@c1='c1'][@xml:c2='c2']", :element=>"c", :attributes=>{"c1"=>"c1", "xml:c2"=>"c2"}}, {:xpath=>"/abc/a[@a='a']/b[@b='b']/c[@c1='c1'][@xml:c2='c2']/@c3", :element=>"@c3", :attributes=>{}}]
    # TODO: refactor to underscore
    def self.breakXpathIntoLumps(xpath)
      key = xpath.hash

      unless @@breakXpathIntoLumps.include? key
        lumps = []
        lumpPath = ''

        xpath.split('/').delete_if { |item| (item == '') || !item }.each do |item|
          attributes = {}
          item.scan(/\[@([^=]+)=["']([^\]]+)["']\]/) { |match| attributes[match[0]] = match[1] }

          lumps[lumps.length] = {
            xpath: lumpPath += "/#{item}",
            element: item.include?('[') ? item[0, item.index('[')] : item,
            attributes: attributes
          }
        end
        @@breakXpathIntoLumps[key] = lumps
      end
      @@breakXpathIntoLumps[key]
    end

    # Checks whether xpath is fully qualified from root to tip and whether it is free of functional logic and pattern matching
    # - *Args*  :
    #   - +xpath+ → sth. like /abc/a[@a='a']/b[@b='b']/c[@c1='c1'][@xml:c2='c2']/@c3
    # - *Returns* :
    #   - true if xpath is fully qualified and simple
    #   - false otherwise
    # e.g. REXML::XPath.fully_qualified_and_simple?("/abc/a[@a='a']/b[@b='b']/c[@c1='c1'][@xml:c2='c2']/@c3") => true
    def self.fully_qualified_and_simple?(xpath)
      matchdata = %r{(\A((/\w+)(\[@[\w:]+='[^\]]+'\])*)+(/@[\w:]+)?\Z)}.match(xpath)
      matchdata && (matchdata.to_s == xpath)
    end
  end
end

module REXML
  class Document
    # Passthrough to class method +bulldoze_path+
    # - *Args*  :
    #   - +xpath+ → desired xpath +STRING+
    #   - +value+ → desired value +STRING+ or +nil+ if no value shall be set
    # - *Returns* :
    #   - +REXML::Element+ (newly created or found)
    # TODO: refactor to underscore and !
    def bulldozePath(xpath, value = nil)
      REXML::Element.bulldoze_path self, xpath, value
    end
  end
end

module REXML
  class Element
    # Passthrough to class method +bulldoze_path+
    # - *Args*  :
    #   - +xpath+ → desired xpath +STRING+
    #   - +value+ → desired value +STRING+ or +nil+ if no value shall be set
    # - *Returns* :
    #   - +REXML::Element+ (newly created or found)
    # TODO: refactor to underscore and !
    def bulldozePath(xpath, value = nil)
      REXML::Element.bulldoze_path self, xpath, value
    end

    # Chisels an xpath into an existing xml document/element, traces that are already there will be used, missing traces will be built
    # - *Args*  :
    #   - +element+ → +REXML::Element+ which shall be used a starting point for the xpath trace
    #   - +xpath+ → that shall be hewn into an existing +REXML+ data structure /abc/a[@a='a']/b[@b='b']/c[@c1='c1'][@xml:c2='c2']/@c3
    #   - +value+ → optional, if specified, value of the xpath's tip element will be set
    # - *Returns* :
    #   - +REXML::Element+ tip object of the xpath
    def self.bulldoze_path(element, xpath, value = nil)
      raise "invalid xpath for bulldozing (#{xpath})" unless REXML::XPath.fully_qualified_and_simple? xpath

      if xpath.include? '/@'
        element_xpath = xpath.slice(0, xpath.index('/@'))
        attribute_name = xpath.slice(xpath.index('/@') + 2, 100)
        attribute_value = (value || '...')

        element = bulldoze_path element, element_xpath
        element.attributes[attribute_name] = attribute_value

        if element
          return element
        else
          raise "Unable to get element for #{xpath}"
        end
      end

      head = nil

      if element.elements[xpath].class != REXML::Element
        Rails.logger.debug("unable to find xpath #{xpath}")
        element.to_s
        lumps = REXML::XPath.breakXpathIntoLumps xpath
        lumps.each do |lump|
          if element.elements[lump[:xpath]].instance_of?(REXML::Element)
            head = element.elements[lump[:xpath]]
          elsif head.instance_of?(REXML::Element)
            head = head.add_element lump[:element], lump[:attributes]
          end
        end
      else
        head = element.elements[xpath]
      end

      head.text = value if head && value

      head || raise("Unable to create element from #{xpath}")
    end
  end
end

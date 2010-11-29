# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def rpx_signin_url(signin_method='signin')
    dest = url_for :controller => :rpx, :action => :login_return, :only_path => false
    @rpx.signin_url(dest, signin_method)
  end

  def rpx_associate_url(signin_method='signin')
    dest = url_for :controller => :rpx, :action => :associate_return, :only_path => false
    @rpx.signin_url(dest, signin_method)
  end

  def rpx_widget_url
    @rpx.base_url + '/openid/v2/widget'
  end
  
  def clippy(textarea_id, bgcolor='#FFFFFF')
    html = <<-EOF
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
              width="110"
              height="14"
              id="clippy" >
      <param name="movie" value="#{compute_public_path('clippy.swf','flash')}"/>
      <param name="allowScriptAccess" value="always" />
      <param name="quality" value="high" />
      <param name="scale" value="noscale" />
      <param name="FlashVars" value="id=#{textarea_id}" />
      <param name="bgcolor" value="#{bgcolor}">
      <embed src="#{compute_public_path('clippy.swf','flash')}"
             width="110"
             height="14"
             name="clippy"
             quality="high"
             wmode="opaque"
             allowScriptAccess="always"
             type="application/x-shockwave-flash"
             pluginspage="http://www.macromedia.com/go/getflashplayer"
             FlashVars="id=#{textarea_id}"
             bgcolor="#{bgcolor}"
      />
      </object>
    EOF
  end
end

require 'rexml/document'

class REXML::XPath

  public

  @@breakXpathIntoLumps = {}

  def self.breakXpathIntoLumps xpath # todo refactor to underscore
    key = xpath.hash
    
    if !@@breakXpathIntoLumps.include? key
      lumps = []
      lumpPath = ''

      xpath.split('/').delete_if{|item| (item == '') || (!item)}.each {|item|

      attributes = {}
      item.scan(/\[@([^=]+)=["']([^\]]+)["']\]/) {|match| attributes[match[0]] = match[1]}

      lumps[lumps.length] = {
        :xpath => lumpPath += '/' + item,
        :element => item.include?('[') ? item[0, item.index('[')] : item,
        :attributes => attributes
        }
      }
      @@breakXpathIntoLumps[key] = lumps
    end
    @@breakXpathIntoLumps[key]
  end

  # checks whether xpath is fully qualified from root to tip
  # and whether it is free of functional logic and pattern matching
  # sth. like would be ok: /abc/a[@a='a']/b[@b='b']/c[@c1='c1'][@xml:c2='c2']/@c3

  def self.fully_qualified_and_simple? xpath
    matchdata = /(\A((\/\w+)(\[@[\w:]+='[\w\.\- ]+'\])*)+(\/@[\w:]+)?\Z)/.match(xpath)
    matchdata && (matchdata.to_s == xpath)
  end

end

class REXML::Document

  public

  def bulldozePath xpath, value = nil # todo refactor to underscore and !
    REXML::Element::bulldoze_path self, xpath, value
  end

end

class REXML::Element

  public

  def bulldozePath xpath, value = nil # todo refactor to underscore and !
    REXML::Element::bulldoze_path self, xpath, value
  end

  def self.bulldoze_path element, xpath, value = nil

    if !REXML::XPath::fully_qualified_and_simple? xpath
      raise Exception.new 'invalid xpath for bulldozing (' + xpath + ')'
    end

    if xpath.include? '/@'
      element_xpath = xpath.slice(0, xpath.index('/@'))
      attribute_name = xpath.slice(xpath.index('/@') + 2, 100)
      attribute_value =  (value ? value : "...")
      
      element = self.bulldoze_path element, element_xpath
      element.attributes[attribute_name] = attribute_value
      
      return element
    end
    
    head = nil

    if element.elements[xpath].class != REXML::Element
      lumps = REXML::XPath::breakXpathIntoLumps xpath
      lumps.each do |lump|
        if element.elements[lump[:xpath]].class == REXML::Element
          head = element.elements[lump[:xpath]]
        elsif head.class == REXML::Element
          head = head.add_element lump[:element], lump[:attributes]
        end
      end
    else
      head = element.elements[xpath]
    end
    
    if head && value
      head.text = value
    end

    return head
  end

end
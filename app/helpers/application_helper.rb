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
end

require 'rexml/document'

class REXML::XPath

  public

  @@breakXpathIntoLumps = {}

  def self.breakXpathIntoLumps xpath
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

end

class REXML::Document

  public

  #todo: defend against evil parameterisation, currently assumes valid and fully qualified xpath string
  def bulldozePath xpath
    if self.elements[xpath].class != REXML::Element
      lumps = REXML::XPath::breakXpathIntoLumps xpath
      head = nil
      lumps.each do |lump|
        if self.elements[lump[:xpath]].class == REXML::Element
          head = self.elements[lump[:xpath]]
        elsif head.class == REXML::Element
          head = head.add_element lump[:element], lump[:attributes]
        end
      end
    end
  end

end
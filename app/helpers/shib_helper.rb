module ShibHelper
  
  def self.shib_enabled?
    idps = get_idp_list()
    return idps.size > 0
  end
  
  def self.get_idp_list
    unless defined? @idps
      @idps = Hash.new
      idpconfig = YAML::load(ERB.new(File.new(File.join(RAILS_ROOT, %w{config shibboleth.yml})).read).result)[Rails.env][:shibboleth][:idps]
      idpconfig.keys.each do |k|
        @idps[idpconfig[k][:display_name]] = k
      end
    end
    return @idps
  end
end
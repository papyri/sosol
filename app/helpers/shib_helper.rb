module ShibHelper
  
  # returns true if configured with at least one Shibboleth IdP
  def self.shib_enabled?
    idps = get_idp_list()
    return idps.size > 0
  end
  
  # returns the number of configured IdPs
  def self.num_idps
    idps = get_idp_list()
    return idps.size 
  end
  
  # returns a hash of configured IdPs that can be used to populate a Select list
  def self.get_idp_hash
    unless defined? @idps
      @idps = Hash.new
      idpconfig = YAML::load(ERB.new(File.new(File.join(RAILS_ROOT, %w{config shibboleth.yml})).read).result)[Rails.env][:shibboleth][:idps]
      idpconfig.keys.each do |k|
        @idps[idpconfig[k][:display_name]] = k,idpconfig[k]
      end
    end
    return @idps
  end
  
  # returns a list of configured IdPs that can be used to present logos for each IdP 
  def self.get_idp_list
    unless defined? @idps
      @idps = []
      idpconfig = YAML::load(ERB.new(File.new(File.join(RAILS_ROOT, %w{config shibboleth.yml})).read).result)[Rails.env][:shibboleth][:idps]
      idpconfig.keys.each do |k|
        @idps << { :key => k, :display_name => idpconfig[k][:display_name], :logo => idpconfig[k][:logo]}
      end
    end
    return @idps
  end
end
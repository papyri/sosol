# helper methods to trigger site-specific functionality
module SiteHelper

  def self.is_perseids?
    Sosol::Application.config.site_name == 'Perseids'
  end

end

# helper methods to trigger site-specific functionality
module SiteHelper

  def self.show_community_pubs?
    begin
      Sosol::Application.config.site_show_community_pubs
    rescue
      false
    end
  end

  def self.show_assigned_pubs?
    begin
      Sosol::Application.config.site_show_assigned_pubs
    rescue
      false
    end
  end

  def self.hide_events?
    begin
      Sosol::Application.config.site_hide_events
    rescue
      true
    end
  end

  def self.keep_comments?
    begin
      Sosol::Application.config.site_keep_comments
    rescue
      false
    end
  end

end

# helper methods to trigger site-specific functionality
module SiteHelper

  def self.show_community_pubs?
    (defined?(Sosol::Application.config.site_show_community_pubs)).nil? || Sosol::Application.config.site_show_community_pubs
  end

  def self.show_assigned_pubs?
    (defined?(Sosol::Application.config.site_show_assigned_pubs)).nil? || Sosol::Application.config.site_show_assigned_pubs
  end

  def self.show_events?
    (defined?(Sosol::Application.config.site_show_events).nil? || Sosol::Application.config.site_show_community_events
  end

  def self.keep_comments?
    (defined?(Sosol::Application.config.site_keep_comments)).nil? || Sosol::Application.config.site_keep_comments
  end

end

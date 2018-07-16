Sosol::Application.config.middleware.use Rack::Attack

class Rack::Attack
  # Block suspicious requests for '/etc/password' or wordpress specific paths.
  # After 1 blocked request in 10 minutes, block all requests from that IP for 60 minutes.
  Rack::Attack.blacklist('fail2ban pentesters') do |req|
    # `filter` returns truthy value if request fails, or if it's from a previously banned IP
    # so the request is blocked
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", :maxretry => 1, :findtime => 10.minutes, :bantime => 60.minutes) do
      # The count for the IP is incremented if the return value is truthy
      CGI.unescape(req.query_string) =~ %r{/etc/passwd} ||
      req.path.include?('/etc/passwd') ||
      req.path.include?('wp-admin') ||
      req.path.include?('wp-login') ||
      req.path.include?('cgi-bin') ||
      req.path.include?('.cgi') ||
      req.path.include?('.php') ||
      req.path.include?('scripts')
    end
  end

  ### Throttle Spammy Clients ###

  # If any single client IP is making tons of requests, then they're
  # probably malicious or a poorly-configured scraper. Either way, they
  # don't deserve to hog all of the app server's CPU. Cut them off!
  #
  # Note: If you're serving assets through rack, those requests may be
  # counted by rack-attack and this throttle may be activated too
  # quickly. If so, enable the condition to exclude them from tracking.

  # Throttle all requests by IP (60rpm)
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  # throttle('req/ip', :limit => 30, :period => 1.minutes) do |req|
  #   req.ip unless req.path.start_with?('/reconcile')
  # end
end

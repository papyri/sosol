# frozen_string_literal: true

# Taken from: http://tinyurl.com/kqyeyh
# Enables cap deploy:web:disable/enable with servers such as Passenger
# Used as a before_filter in ApplicationController
module MaintenanceMode
  protected

  def disabled?
    maintfile = "#{::Rails.root}/public/system/maintenance.html"
    send_file maintfile, type: 'text/html; charset=utf-8', disposition: 'inline' if FileTest.exist?(maintfile)
  end
end

# Taken from: http://tinyurl.com/kqyeyh
# Enables cap deploy:web:disable/enable with servers such as Passenger
# Used as a before_filter in ApplicationController
module MaintenanceMode
protected
  def disabled?
    maintfile = RAILS_ROOT + "/public/system/maintenance.html"
    if FileTest::exist?(maintfile)
      send_file maintfile, :type => 'text/html; charset=utf-8', :disposition => 'inline'
    end
  end
end
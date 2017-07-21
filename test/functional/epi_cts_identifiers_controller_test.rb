require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('EpiCTSIdentifier')
  class EpiCtsIdentifiersControllerTest < ActionController::TestCase
    def setup
      ApplicationController::prepend_view_path 'app/views_perseids'
      @creator = FactoryGirl.create(:user, :name => "Creator")
      @request.session[:user_id] = @creator.id
      @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")
        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master
      @cts_identifier = EpiCTSIdentifier.new_from_template(@publication,'epifacs','urn:cts:greekEpi:igvii.2543-2545.test','edition','grc')
    end
    
    def teardown
      @request.session[:user_id] = nil
      @creator.destroy
      @publication.destroy
    end
     
  end
end

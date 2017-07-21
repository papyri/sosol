require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('CitationCTSIdentifier')
  class CtsPublicationsControllerTest < ActionController::TestCase
    def setup
      ApplicationController::prepend_view_path 'app/views_perseids'
      @user = FactoryGirl.create(:user, :name => "Creator")
      @request.session[:user_id] = @user.id
    end
    
    def teardown
      @request.session[:user_id] = nil
      @user.destroy
    end
    
    
    def test_should_accept_link_from_known_agent
      get :create_from_agent, :agent => "http://www.eagle-network.eu", :id =>"q5016", :lang => 'de'
      assert_equal 1, assigns(:publication).identifiers.select{ | i | i.respond_to?(:urn_attribute) && i.urn_attribute == "urn:cts:pdlepi:eagle.tm179252.perseids-de-#{Time.now.year}-1" }.size
    end  
    
    def test_should_report_conflicting_identifier_linked_urn
      get :create_from_linked_urn, :urn => "urn:cts:test:tg1.wk2.perseus-grc1", :collection => 'perseids-test'
      assert_equal 1, assigns(:publication).identifiers.select{ | i | i.respond_to?(:urn_attribute) && i.urn_attribute == 'urn:cts:test:tg1.wk2.perseus-grc1' }.size
      get :create_from_linked_urn, :urn => "urn:cts:test:tg1.wk2.perseus-grc1", :collection => 'perseids-test'
      assert_equal 1, assigns(:publication).identifiers.select{ | i | i.respond_to?(:urn_attribute) && i.urn_attribute == 'urn:cts:test:tg1.wk2.perseus-grc1' }.size
    end
    
    def test_should_report_conflicting_identifier_from_selector
      get :create_from_selector, :edition_urn => "urn:cts:test:tg1.wk2.perseus-grc1", :CTSIdentifierCollectionSelect => 'perseids-test'
      assert_equal nil , flash[:error]
      assert_equal "Publication was successfully created." , flash[:notice]
      assert_equal 1, assigns(:publication).identifiers.select{ | i | i.respond_to?(:urn_attribute) && i.urn_attribute == 'urn:cts:test:tg1.wk2.perseus-grc1' }.size
      get :create_from_selector, :edition_urn => "urn:cts:test:tg1.wk2.perseus-grc1", :CTSIdentifierCollectionSelect => 'perseids-test'
      assert_equal 1, assigns(:publication).identifiers.select{ | i | i.respond_to?(:urn_attribute) && i.urn_attribute == 'urn:cts:test:tg1.wk2.perseus-grc1' }.size
     
    end

  end
end

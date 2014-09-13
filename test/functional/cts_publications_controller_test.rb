require 'test_helper'

class CtsPublicationsControllerTest < ActionController::TestCase
  def setup
    @user = Factory(:user)
    @request.session[:user_id] = @user.id
  end
  
  def teardown
    @request.session[:user_id] = nil
    @user.destroy
  end
  
  
  def test_should_accept_link_from_known_agent
    get :create_from_agent, :agent => "http://www.eagle-network.eu", :id =>"q5016", :lang => 'de'
    assert_equal 1, assigns(:publication).identifiers.select{ | i | i.respond_to?(:urn_attribute) && i.urn_attribute == 'urn:cts:pdlepi:eagle.tm179252.perseids-de-2014-1' }.size
  end  
  
  def test_should_report_conflicting_identifier_linked_urn
    get :create_from_linked_urn, :urn => "urn:cts:test:tg1.wk2.perseus-grc1", :collection => 'testepi'
    assert_equal 1, assigns(:publication).identifiers.select{ | i | i.respond_to?(:urn_attribute) && i.urn_attribute == 'urn:cts:test:tg1.wk2.perseus-grc1' }.size
    get :create_from_linked_urn, :urn => "urn:cts:test:tg1.wk2.perseus-grc1", :collection => 'testepi'
    assert_equal 1, assigns(:publication).identifiers.select{ | i | i.respond_to?(:urn_attribute) && i.urn_attribute == 'urn:cts:test:tg1.wk2.perseus-grc1' }.size
  end
  
  def test_should_report_conflicting_identifier_from_selector
    get :create_from_selector, :edition_urn => "urn:cts:test:tg1.wk2.perseus-grc1", :CTSIdentifierCollectionSelect => 'testepi'
    assert_equal 1, assigns(:publication).identifiers.select{ | i | i.respond_to?(:urn_attribute) && i.urn_attribute == 'urn:cts:test:tg1.wk2.perseus-grc1' }.size
    get :create_from_selector, :edition_urn => "urn:cts:test:tg1.wk2.perseus-grc1", :CTSIdentifierCollectionSelect => 'testepi'
    assert_equal 1, assigns(:publication).identifiers.select{ | i | i.respond_to?(:urn_attribute) && i.urn_attribute == 'urn:cts:test:tg1.wk2.perseus-grc1' }.size
   
  end

  def test_should_not_be_conflicting_identifier_from_selector
    
  end
  
end

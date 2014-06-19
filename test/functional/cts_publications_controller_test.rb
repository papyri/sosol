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
  
  def test_should_reject_link_from_unknown_agent
    http://www.eagle-network.eu/wiki/index.php/Special:EntityData/Q5016.xml
  end
  
  def test_should_fail_link_with_invalid_urn
    get :create_from_uri, :uri => "http://www.eagle-network.eu/wiki/index.php/Special:EntityData/Q3272.xml"
    
  end
  
  def test_should_accept_link_from_known_agent
    get :create_from_uri, :uri => "http://www.eagle-network.eu/wiki/index.php/Special:EntityData/Q5016.xml"
    assert_equal 1, assigns(:publication).identifiers.select{ | i | i.respond_to?(:urn_attribute) && i.urn_attribute == 'urn:cts:tm:179252.HD029889.TempTrans-de-2014-1' }.size
  end  
  
  def test_should_report_conflicting_identifier_linked_urn
    get :create_from_linked_urn, :urn => "urn:cts:test:tg1.wk2.perseus-grc1", :collection => 'testepi'
    assert_equal 1, assigns(:publication).identifiers.select{ | i | i.respond_to?(:urn_attribute) && i.urn_attribute == 'urn:cts:test:tg1.wk2.perseus-grc1' }.size
    get :create_from_linked_urn, :urn => "urn:cts:test:tg1.wk2.perseus-grc1", :collection => 'testepi'
    assert_equal 1, assigns(:publication).identifiers.select{ | i | i.respond_to?(:urn_attribute) && i.urn_attribute == 'urn:cts:test:tg1.wk2.perseus-grc1' }.size
  end
  
  def test_should_report_conflicting_identifier_from_selector
   
  end

  def test_should_report_conflicting_identifier_from_uri
    
  end
  
  def test_should_not_be_conflicting_identifier_from_uri
    
  end
  
  def test_should_not_be_conflicting_identifier_from_selector
    
  end
  
  def test_should_fail_to_retrieve_from_uri
  
  end
  
  def test_should_succeed_to_retrieve_from_uri
    
  end
  
  def test_should_fail_missing_urn_from_uri
    
  end
  
  def test_should_fail_missing_pubtype_from_uri
    
  end
  
  def test_should_fail_invalid_content_from_uri
    
  end

end

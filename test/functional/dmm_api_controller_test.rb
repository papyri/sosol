require 'test_helper'

class DmmApiControllerTest < ActionController::TestCase
  def setup
    @creator = Factory(:user, :name => "Creator")
    @request.session[:user_id] = @creator.id
    @valid_tb = File.read(File.join(File.dirname(__FILE__), 'data', 'validtb.xml'))

  end
  
  def teardown
    @request.session[:user_id] = nil
    @creator.destroy
  end
   
  def test_should_create_publication_and_treebank_identifier
    @request.env['RAW_POST_DATA'] = @valid_tb
    post :api_item_create, :identifier_type => 'TreebankCite'
    assert_match(/<item>..*?<\/item>/,@response.body) 
    assert_equal 1, assigns(:publication).identifiers.size 
  end
  
   def test_should_fail_create_duplicate_identifier
    @request.env['RAW_POST_DATA'] = @valid_tb
    post :api_item_create, :identifier_type => 'TreebankCite'
    assert_match(/<item>..*?<\/item>/,@response.body) 
    assert_equal 1, assigns(:publication).identifiers.size 
    post :api_item_create, :identifier_type => 'TreebankCite', :init_value => "urn:cts:latinLit:tg.work.edition:1.1"
    assert_match(/<error>Conflicting identifier/,@response.body) 
    assert_equal 1, assigns(:publication).identifiers.size
  end
  
    
end

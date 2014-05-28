require 'test_helper'

class EpiCtsIdentifiersControllerTest < ActionController::TestCase
  def setup
    @creator = Factory(:user, :name => "Creator")
    @request.session[:user_id] = @creator.id
    @publication = Factory(:publication, :owner => @creator, :creator => @creator, :status => "new")
      # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master
    @cts_identifier = EpiCTSIdentifier.new_from_template(@publication,'epifacs','urn:cts:greekEpi:igvii.2543-2545.test','edition','grc')
  end
  
  def teardown
    @request.session[:user_id] = nil
    @creator.destroy
    @publication.destroy
  end
   
  def test_should_require_param
    get :link_alignment,  :publication_id => @publication.id.to_s, :id => @cts_identifier.id.to_s
    assert_equal 'Missing input details for annotation.', flash[:error] 
  end
  
    
end

require 'test_helper'

class DdbIdentifiersControllerTest < ActionController::TestCase
  def setup
    @user = FactoryGirl.create(:user)
    @request.session[:user_id] = @user.id
    @publication = FactoryGirl.create(:publication, :owner => @user, :creator => @user, :status => "new")
    @publication.branch_from_master
    @identifier = DDBIdentifier.new_from_template(@publication)
  end

  def teardown
    @publication.destroy
    @user.destroy
  end


  def test_should_flash_commit_error
    @identifier.repository.class.any_instance.stubs(:commit_content).raises(Exceptions::CommitError.new("Commit failed"))
    # just make a nonsense change to the content
    content = { :xml_content => @identifier.xml_content.sub("English","Gobbleygook") }
    get :editxml, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s
    put :updatexml, :id => @identifier.id.to_s , :publication_id => @identifier.publication.id.to_s,  :comment => "test", :ddb_identifier => content
    assert_redirected_to '/publications/' + @publication.id.to_s + '/ddb_identifiers/' + @identifier.id.to_s + '/edit'
    assert_equal "Commit failed", flash[:error]
  end

end

require 'test_helper'

class DDBIdentifiersControllerTest < ActionController::TestCase
  def setup
    @user = FactoryBot.create(:user)
    @request.session[:user_id] = @user.id
    @publication = FactoryBot.create(:publication, owner: @user, creator: @user, status: 'new')
    @publication.branch_from_master
    @identifier = DDBIdentifier.new_from_template(@publication)
  end

  def teardown
    @publication.destroy
    @user.destroy
  end

  def test_should_flash_commit_error
    @identifier.repository.class.any_instance.stubs(:commit_content).raises(Exceptions::CommitError.new('Commit failed'))
    # Return mock response for Epidocinator
    Epidocinator.stubs(:apply_xsl_transform).returns('')
    Epidocinator.stubs(:validate).returns(true)
    # just make a nonsense change to the content
    content = { xml_content: @identifier.xml_content.sub('English', 'Gobbleygook') }
    get :editxml, params: { id: @identifier.id.to_s, publication_id: @identifier.publication.id.to_s }
    put :updatexml,
        params: { id: @identifier.id.to_s, publication_id: @identifier.publication.id.to_s, comment: 'test',
                  ddb_identifier: content }
    assert_redirected_to "/publications/#{@publication.id}/ddb_identifiers/#{@identifier.id}/edit"
    assert_equal 'Commit failed', flash[:error]
  end
end

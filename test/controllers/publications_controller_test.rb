require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  def setup
    @user = FactoryBot.create(:user)
    @request.session[:user_id] = @user.id
  end

  def teardown
    @request.session[:user_id] = nil
    @user.destroy
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:publications)
  end

  def test_should_create_new_batch
    assert_difference('Publication.count') do
      post :create_from_list,  params: { :pn_id_list => "papyri.info/hgv/3147   papyri.info/hgv/3148  papyri.info/hgv/3149  papyri.info/ddbdp/bgu;7;1520  papyri.info/ddbdp/bgu;7;1521 papyri.info/ddbdp/bgu;7;1522" }
      assert_equal 'Publication was successfully created.', flash[:notice]
    end
    assert_equal 6, assigns(:publication).identifiers.size 
  end
end

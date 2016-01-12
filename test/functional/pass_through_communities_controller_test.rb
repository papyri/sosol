require 'test_helper'

class PassThroughCommunitiesControllerTest < ActionController::TestCase

  def setup 
    @admin = FactoryGirl.create(:admin)
    @community_admin = FactoryGirl.create(:user)
    @user = FactoryGirl.create(:user)
    @request.session[:user_id] = @admin.id
    @community_two = FactoryGirl.create(:master_community)
    @community_two.admins << @admin
    @community = FactoryGirl.create(:pass_through_community, :pass_to => @community_two.name)
    @community.admins << @admin
  end

  def teardown
    @request.session[:user_id] = nil
    @admin.destroy
    @community_admin.destroy
    @user.destroy
    @community.destroy unless !Community.exists? @community.id
    @community_two.destroy unless !Community.exists? @community_two.id
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:communities)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pass_through_community" do
    assert_difference('PassThroughCommunity.count') do
      post :create, :pass_through_community => FactoryGirl.build(:pass_through_community).attributes.merge({"admins"=>[],"members"=>[], "pass_to" => @community_two.name})
    end

    assert_redirected_to edit_pass_through_community_path(assigns(:community))
  end

  test "should show pass_through_community" do
    get :show, id: @community
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @community
    assert_response :success
  end

  test "should update pass_through_community" do
    put :update, id: @community, pass_through_community: {  }
    assert_redirected_to edit_pass_through_community_path(assigns(:community))
  end

  test "should destroy pass_through_community" do
    assert_difference('PassThroughCommunity.count', -1) do
      delete :destroy, id: @community
    end

    assert_redirected_to :controller => 'user', :action => 'admin'
  end

  test "should not allow non-community admin changes" do 
    @request.session[:user_id] = @user.id

    get :edit, id: @community
    assert_redirected_to '/pass_through_communities'
    assert_equal "This action requires community administrator rights", flash[:error]

    put :update, id: @community
    assert_redirected_to '/pass_through_communities'
    assert_equal "This action requires community administrator rights", flash[:error]

    delete :destroy, id: @community
    assert_redirected_to '/pass_through_communities'
    assert_equal "This action requires community administrator rights", flash[:error]

  end

end

require 'test_helper'

class MasterCommunitiesControllerTest < ActionController::TestCase

  def setup 
    @admin = FactoryGirl.create(:admin)
    @user = FactoryGirl.create(:user)
    @request.session[:user_id] = @admin.id
    @community = FactoryGirl.create(:master_community)
    @community_two = FactoryGirl.create(:master_community)
  end

  def teardown
    @request.session[:user_id] = nil
    @admin.destroy
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

  test "should create master_community" do
    assert_difference('MasterCommunity.count') do
      post :create, :master_community => FactoryGirl.build(:master_community).attributes.merge({"admins"=>[],"members"=>[]})
    end

    assert_redirected_to edit_master_community_path(assigns(:community))
  end

  test "should show master_community" do
    get :show, id: @community
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @community
    assert_response :success
  end

  test "should update master_community" do
    put :update, id: @community, master_community: {  }
    assert_redirected_to edit_master_community_path(assigns(:community))
  end

  test "should destroy master_community" do
    assert_difference('MasterCommunity.count', -1) do
      delete :destroy, id: @community
    end

    assert_redirected_to :controller => 'user', :action => 'admin'
  end
  
  test "should not allow non-admin edit" do 
    @request.session[:user_id] = @user.id
    get :edit, id: @community
    assert_redirected_to '/master_communities'
    assert_equal "This action requires administrator rights", flash[:error]
  end

  test "should not allow non-admin destroy" do 
    @request.session[:user_id] = @user.id
    delete :destroy,  id: @community
    assert_redirected_to '/master_communities'
    assert_equal "This action requires administrator rights", flash[:error]
  end

  test "should not allow non-admin update" do 
    @request.session[:user_id] = @user.id
    put :update, id: @community, master_community: {  }
    assert_equal "This action requires administrator rights", flash[:error]
    assert_redirected_to '/master_communities'
  end 

  test "should not allow community admin on master community" do 
    @community.admins << @user
    @request.session[:user_id] = @user.id

    get :edit, id: @community
    assert_redirected_to '/master_communities'
    assert_equal "This action requires administrator rights", flash[:error]

    put :update, id: @community
    assert_redirected_to '/master_communities'
    assert_equal "This action requires administrator rights", flash[:error]

    delete :destroy, id: @community
    assert_redirected_to '/master_communities'
    assert_equal "This action requires administrator rights", flash[:error]

  end

end

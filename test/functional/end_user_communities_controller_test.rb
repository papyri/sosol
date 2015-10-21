require 'test_helper'

class EndUserCommunitiesControllerTest < ActionController::TestCase

  def setup 
    @admin = FactoryGirl.create(:admin)
    @community_admin = FactoryGirl.create(:user)
    @user = FactoryGirl.create(:user)
    @request.session[:user_id] = @admin.id
    @community = FactoryGirl.create(:end_user_community)
    @community.admins << @admin
    @community_two = FactoryGirl.create(:end_user_community)
    @community_two.admins << @admin
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

  test "should create end_user_community" do
    assert_difference('EndUserCommunity.count') do
      post :create, :end_user_community => FactoryGirl.build(:end_user_community).attributes.merge({"admins"=>[],"members"=>[]})
    end

    assert_redirected_to edit_end_user_community_path(assigns(:community))
  end

  test "should show end_user_community" do
    get :show, id: @community
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @community
    assert_response :success
  end

  test "should update end_user_community" do
    put :update, id: @community, end_user_community: {  }
    assert_redirected_to edit_end_user_community_path(assigns(:community))
  end

  test "should destroy end_user_community" do
    assert_difference('EndUserCommunity.count', -1) do
      delete :destroy, id: @community
    end

    assert_redirected_to :controller => 'user', :action => 'admin'
  end

  test "should allow edit of end user" do
    get :edit, id: @community
    assert_select "a[href='/end_user_communities/edit_end_user/" + @community.id.to_s + "']" 
  end


  test "should get edit end user" do
    get :edit_end_user, id: @community
    assert_response :success
  end

  test "should edit end user" do
    put :set_end_user, id: @community, user_id: @admin.id
    @community.reload
    assert_equal @admin.id, @community.end_user.id
    assert_redirected_to edit_end_user_community_path(@community)
  end

  test "should not allow non-community admin changes" do 
    @request.session[:user_id] = @user.id

    get :edit, id: @community
    assert_redirected_to '/end_user_communities'
    assert_equal "This action requires community administrator rights", flash[:error]

    get :edit_end_user, id: @community
    assert_redirected_to '/end_user_communities'
    assert_equal "This action requires community administrator rights", flash[:error]

    put :set_end_user, id: @community
    assert_redirected_to '/end_user_communities'
    assert_equal "This action requires community administrator rights", flash[:error]

    put :update, id: @community
    assert_redirected_to '/end_user_communities'
    assert_equal "This action requires community administrator rights", flash[:error]

    delete :destroy, id: @community
    assert_redirected_to '/end_user_communities'
    assert_equal "This action requires community administrator rights", flash[:error]

  end

end

require 'test_helper'

class VotesControllerTest < ActionController::TestCase
  def setup
    @user = FactoryBot.create(:user)
    @request.session[:user_id] = @user.id
    @publication = FactoryBot.create(:publication, :owner => @user)
    @vote = FactoryBot.create(:vote, :user => @user, :publication => @publication)
    @vote_two = FactoryBot.create(:vote, :user => @user, :publication => @publication)
  end
  
  def teardown
    @vote.destroy
    @vote_two.destroy
    @publication.destroy
    @user.destroy
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:votes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create vote" do
    assert_difference('Vote.count') do
      post :create, params: { :vote => { } }
    end

    assert_redirected_to vote_path(assigns(:vote))
  end

  test "should show vote" do
    get :show, params: { :id => @vote.id }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { :id => @vote.id }
    assert_response :success
  end

  test "should update vote" do
    put :update, params: { :id => @vote.id, :vote => { } }
    assert_redirected_to vote_path(assigns(:vote))
  end

  test "should destroy vote" do
    assert_difference('Vote.count', -1) do
      delete :destroy, params: { :id => @vote.id }
    end

    assert_redirected_to votes_path
  end
end

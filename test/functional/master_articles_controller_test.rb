require 'test_helper'

class MasterArticlesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:master_articles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create master_article" do
    assert_difference('MasterArticle.count') do
      post :create, :master_article => { }
    end

    assert_redirected_to master_article_path(assigns(:master_article))
  end

  test "should show master_article" do
    get :show, :id => master_articles(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => master_articles(:one).id
    assert_response :success
  end

  test "should update master_article" do
    put :update, :id => master_articles(:one).id, :master_article => { }
    assert_redirected_to master_article_path(assigns(:master_article))
  end

  test "should destroy master_article" do
    assert_difference('MasterArticle.count', -1) do
      delete :destroy, :id => master_articles(:one).id
    end

    assert_redirected_to master_articles_path
  end
end

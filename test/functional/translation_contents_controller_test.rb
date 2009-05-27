require 'test_helper'

class TranslationContentsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:translation_contents)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create translation_content" do
    assert_difference('TranslationContent.count') do
      post :create, :translation_content => { }
    end

    assert_redirected_to translation_content_path(assigns(:translation_content))
  end

  test "should show translation_content" do
    get :show, :id => translation_contents(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => translation_contents(:one).id
    assert_response :success
  end

  test "should update translation_content" do
    put :update, :id => translation_contents(:one).id, :translation_content => { }
    assert_redirected_to translation_content_path(assigns(:translation_content))
  end

  test "should destroy translation_content" do
    assert_difference('TranslationContent.count', -1) do
      delete :destroy, :id => translation_contents(:one).id
    end

    assert_redirected_to translation_contents_path
  end
end

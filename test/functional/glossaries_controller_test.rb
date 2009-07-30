require 'test_helper'

class GlossariesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:glossaries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create glossary" do
    assert_difference('Glossary.count') do
      post :create, :glossary => { }
    end

    assert_redirected_to glossary_path(assigns(:glossary))
  end

  test "should show glossary" do
    get :show, :id => glossaries(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => glossaries(:one).id
    assert_response :success
  end

  test "should update glossary" do
    put :update, :id => glossaries(:one).id, :glossary => { }
    assert_redirected_to glossary_path(assigns(:glossary))
  end

  test "should destroy glossary" do
    assert_difference('Glossary.count', -1) do
      delete :destroy, :id => glossaries(:one).id
    end

    assert_redirected_to glossaries_path
  end
end

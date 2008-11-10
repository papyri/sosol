require 'test_helper'

class DocumentsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:documents)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_document
    assert_difference('Document.count') do
      post :create, :document => { }
    end

    assert_redirected_to document_path(assigns(:document))
  end

  def test_should_show_document
    get :show, :id => documents(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => documents(:one).id
    assert_response :success
  end

  def test_should_update_document
    put :update, :id => documents(:one).id, :document => { }
    assert_redirected_to document_path(assigns(:document))
  end

  def test_should_destroy_document
    assert_difference('Document.count', -1) do
      delete :destroy, :id => documents(:one).id
    end

    assert_redirected_to documents_path
  end
end

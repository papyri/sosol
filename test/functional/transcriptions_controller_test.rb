require 'test_helper'

class TranscriptionsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:transcriptions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create transcription" do
    assert_difference('Transcription.count') do
      post :create, :transcription => { }
    end

    assert_redirected_to transcription_path(assigns(:transcription))
  end

  test "should show transcription" do
    get :show, :id => transcriptions(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => transcriptions(:one).id
    assert_response :success
  end

  test "should update transcription" do
    put :update, :id => transcriptions(:one).id, :transcription => { }
    assert_redirected_to transcription_path(assigns(:transcription))
  end

  test "should destroy transcription" do
    assert_difference('Transcription.count', -1) do
      delete :destroy, :id => transcriptions(:one).id
    end

    assert_redirected_to transcriptions_path
  end
end

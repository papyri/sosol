require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  def setup
    @event = FactoryBot.create(:event)
    @event_two = FactoryBot.create(:event)
  end

  def teardown
    @event.destroy
    @event_two.destroy
  end

  def test_should_get_index
    get :index, params: {}
    assert_response :success
    assert_not_nil assigns(:events)
  end

  def test_should_get_new
    get :new, params: {}
    assert_response :success
  end

  def test_should_create_event
    assert_difference('Event.count') do
      post :create, params: { event: { category: 'commit' } }
    end

    assert_redirected_to event_path(assigns(:event))
  end

  def test_should_show_event
    get :show, params: { id: @event.id }
    assert_response :success
  end

  def test_should_get_edit
    get :edit, params: { id: @event.id }
    assert_response :success
  end

  def test_should_update_event
    put :update, params: { id: @event.id, event: { category: 'submit' } }
    assert_redirected_to event_path(assigns(:event))
    assert_equal 'submit', @event.reload.category
  end

  def test_should_destroy_event
    assert_difference('Event.count', -1) do
      delete :destroy, params: { id: @event.id }
    end

    assert_redirected_to events_path
  end
end

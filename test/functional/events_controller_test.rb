require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  def setup
    @event = FactoryGirl.create(:event)
    @event_two = FactoryGirl.create(:event)
  end
  
  def teardown
    @event.destroy
    @event_two.destroy
  end
  
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:events)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_event
    assert_difference('Event.count') do
      post :create, :event => { :category => 'commit' }
    end

    assert_redirected_to event_path(assigns(:event))
  end

  def test_should_show_event
    get :show, :id => @event.id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => @event.id
    assert_response :success
  end

  def test_should_update_event
    put :update, :id => @event.id, :event => { }
    assert_redirected_to event_path(assigns(:event))
  end

  def test_should_destroy_event
    assert_difference('Event.count', -1) do
      delete :destroy, :id => @event.id
    end

    assert_redirected_to events_path
  end
end

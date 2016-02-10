require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  def setup
    @user = FactoryGirl.create(:user)
    @user2 = FactoryGirl.create(:user)
    @request.session[:user_id] = @user.id
    @publication = FactoryGirl.create(:publication, :owner => @user, :creator => @user, :status => "new")
    @publication.branch_from_master
    @identifier = DDBIdentifier.new_from_template(@publication)
  end

  def teardown
    @publication.destroy
    @user.destroy
    @user2.destroy
  end


  def test_can_destroy_own_general_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'general', :comment => "A silly comment", :user => @user)
    @comment.save
    assert_difference('Comment.count', -1) do
      delete :destroy, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    end
  end

  def test_can_destroy_own_review_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'review', :comment => "A silly comment", :user => @user)
    @comment.save
    assert_difference('Comment.count', -1) do
      delete :destroy, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    end
  end

  def test_cannot_destroy_own_vote_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'vote', :comment => "A silly comment", :user => @user)
    @comment.save
    delete :destroy, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    @comment.reload
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to dashboard_url
    assert_not_nil @comment
  end

  def test_cannot_destroy_own_submit_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'submit', :comment => "A silly comment", :user => @user)
    @comment.save
    delete :destroy, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    @comment.reload
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to dashboard_url
    assert_not_nil @comment
  end

  def test_cannot_destroy_own_finalizing_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'finalizing', :comment => "A silly comment", :user => @user)
    @comment.save
    delete :destroy, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    @comment.reload
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to dashboard_url
    assert_not_nil @comment
  end

  def test_cannot_destroy_others_general_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'general', :comment => "A silly comment", :user => @user2)
    @comment.save
    delete :destroy, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    @comment.reload
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to dashboard_url
    assert_not_nil @comment
  end

  def test_cannot_destroy_others_review_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'review', :comment => "A silly comment", :user => @user2)
    @comment.save
    delete :destroy, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    @comment.reload
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to dashboard_url
    assert_not_nil @comment
  end

  def test_can_edit_own_general_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'general', :comment => "A silly comment", :user => @user)
    @comment.save
    get :edittext, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    assert_response :success
  end

  def test_can_edit_own_review_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'review', :comment => "A silly comment", :user => @user)
    @comment.save
    get :edittext, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    assert_response :success
  end

  def test_cannot_edit_own_vote_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'vote', :comment => "A silly comment", :user => @user)
    @comment.save
    get :edittext, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to dashboard_url
  end

  def test_cannot_edit_own_submit_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'submit', :comment => "A silly comment", :user => @user)
    @comment.save
    get :edittext, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to dashboard_url
  end

  def test_cannot_edit_own_finalizing_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'finalizing', :comment => "A silly comment", :user => @user)
    @comment.save
    get :edittext, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to dashboard_url
  end

  def test_cannot_destroy_others_general_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'general', :comment => "A silly comment", :user => @user2)
    @comment.save
    get :edittext, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to dashboard_url
  end

  def test_cannot_destroy_others_review_comments
    @comment = Comment.new(:identifier => @identifier, :publication => @publication, :reason => 'review', :comment => "A silly comment", :user => @user2)
    @comment.save
    get :edittext, :id => @comment.id.to_s , :publication_id => @identifier.publication.id.to_s  
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to dashboard_url
  end

end

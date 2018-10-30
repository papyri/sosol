require 'test_helper'

class RepositoryTest < ActiveSupport::TestCase
  context "the canonical Repository" do
    setup do
      @repo = Repository.new
    end
    
    should "not be able to have direct commits" do
      assert_raise RuntimeError do
        @repo.commit_content('README.TXT','master','TEST','TEST',org.eclipse.jgit.lib.PersonIdent.new("TEST", "TEST"))
      end
    end
    
    should "have no master" do
      assert_nil @repo.master
    end
    
    should "have the canonical path" do
      assert_equal Sosol::Application.config.canonical_repository, @repo.path
    end
  
    should "preserve objects after alternates repository deletion" do
      # TODO: FIXME
      assert true
    end
  
  end
  
  context "a User Repository" do
    setup do
      @user = FactoryGirl.create(:user)
    end
    
    teardown do
      @user.destroy
    end
    
    should "have the same master tip as canonical after creation" do
      assert_equal @user.repository.get_head('master'),
        Repository.new.get_head('master')
    end
    
    should "update master tip before branch creation" do
      # rewind the head first
      prev_canon_commit = Repository.new.get_head('master^')
      original_master = @user.repository.get_head('master')
      @user.repository.update_ref('master', prev_canon_commit)
      # verify that we rewound the head
      assert_equal @user.repository.get_head('master'),
        prev_canon_commit
      assert_not_equal @user.repository.get_head('master'),
        original_master
      
      # create a branch
      @user.repository.create_branch('test')
      # verify that the master head was updated and used for the new branch
      assert_not_equal @user.repository.get_head('master'),
        prev_canon_commit
      assert_equal @user.repository.get_head('master'),
        Repository.new.get_head('master')
      assert_equal @user.repository.get_head('test'),
        Repository.new.get_head('master')
    end
  end
  
end

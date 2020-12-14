require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context "an existing user" do
    setup do
      @user = FactoryGirl.create(:user)
      @path = @user.repository.path
    end
    
    subject { @user }
    
    # should validate_uniqueness_of(:name).case_insensitive
    
    teardown do
      @user.destroy unless !User.exists? @user.id
    end
    
    should "have a repository" do
      assert File.exists?(@path)
    end
  
    should "delete its repository upon destruction" do
      @user.destroy
      assert !File.exists?(@path)
    end
  end
end

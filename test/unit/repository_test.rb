require 'test_helper'

class RepositoryTest < ActiveSupport::TestCase
  context "The canonical Repository" do
    setup do
      @repo = Repository.new
    end
    
    should "not be able to have direct commits" do
      assert_raise RuntimeError do
        @repo.commit_content('README.TXT','master','TEST','TEST')
      end
    end
  
  end
  
end

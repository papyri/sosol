require 'test_helper'
require 'collections_helper'

class CollectionsHelperTest < ActiveSupport::TestCase
  
  context "collections tests" do
    setup do
    end
    
    teardown do
    end

    should "add to a collection" do 
      mock_owner = stub("mockowner")
      mock_owner.stubs(:id).returns('dummyuser')
      mock_owner.stubs(:uri).returns('http://sosol.perseids.org/users/dummyuser')
      mock_topics = [ 'dummytopica', 'dummytopicb' ] 
      mock_identifier = stub("mockidentifier")
      mock_identifier.stubs(:id).returns('dummyidentifier')
      usercoll = CollectionsHelper::pid_for(mock_owner.id,mock_owner.class.to_s)
      begin
        CollectionsHelper::delete_collection(usercoll)
      rescue
      end
      user_collection = CollectionsHelper::get_user_collection(mock_owner, true)
      if user_collection
        CollectionsHelper::put_to_collection(user_collection, mock_identifier)
      end
      # add it to the subject collections
      mock_topics.each do |c|
        tcoll = CollectionsHelper::pid_for(c,'topic', 'dummyclass')
        begin
          CollectionsHelper::delete_collection(tcoll)
        rescue
        end
        topic_collection = CollectionsHelper::get_topic_collection(c, 'dummyclass', true)
        if topic_collection
          CollectionsHelper::put_to_collection(topic_collection, mock_identifier)
        end
      end
      # now delete
      mid = CollectionsHelper::pid_for(mock_identifier.id,mock_identifier.class.to_s)
      CollectionsHelper::delete_from_collection(user_collection,mid)
      #assert_not_nil(CollectionsHelper::get_user_collection(mock_owner, false))
      #mock_topics.each do |c|
      #  assert_not_nil(CollectionsHelper::get_topic_collection(c, 'dummyclass', true))
      #end
    end
    
  end
end

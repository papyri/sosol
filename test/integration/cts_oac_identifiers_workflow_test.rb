require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('CtsOACIdentifier')
  class CtsOACIdentifiersWorkflowTest < ActionController::IntegrationTest
    context "for perseids" do 

    setup do
      @creator = FactoryGirl.create(:user, :name => "Creator")
      @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")
      # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master
      @cts_identifier = EpiCTSIdentifier.new_from_template(@publication,'epifacs','urn:cts:greekEpi:igvii.2543-2545.test','edition','grc')
      @identifier = OACIdentifier.new_from_template(@publication,@cts_identifier)
    end
    
    teardown do
      begin
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          count = 0
          [ @identifier, @cts_identifier, @publication, @creator ].each do |entity|
            count = count + 1
            #assert_not_equal entity, nil, count.to_s + " cant be destroyed since it is nil."
            unless entity.nil?
              entity.reload
              entity.destroy
            end
          end
        end
      end
    end

     
    should "delete_annotation" do
      # it would be nice to test this via a post to append a new annotation
      # but it's a little hassle as it has to go through the dmm_api_controller so just rig it up manually
      creator_uri = @identifier.make_creator_uri()
      annotation_uri = @identifier.next_annotation_uri()
      @identifier.add_annotation(annotation_uri,["http://target.example.org"],["http://body.example.org"],"oa:linking",creator_uri,"http://test.example.org","adding for test")

      post 'publications/' + @publication.id.to_s + '/cts_oac_identifiers/' + @identifier.id.to_s + '/delete_annotation/?test_user_id=' + @creator.id.to_s,\
          :annotation_uri => annotation_uri
      assert redirect?
      assert_equal "Annotation Deleted",  flash.notice
    end
    
      
  end
  end
end

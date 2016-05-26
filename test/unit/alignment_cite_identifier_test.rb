require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('AlignmentCiteIdentifier')
  class AlignmentCiteIdentifierTest < ActiveSupport::TestCase
    def silence_warnings(&block)
      warn_level = $VERBOSE
      $VERBOSE = nil
      result = block.call
      $VERBOSE = warn_level
      result
    end
    
    context "identifier test" do
      setup do
        @creator = FactoryGirl.create(:user, :name => "Creator")
        @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")

        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master
        @tokenized_lat = File.read(File.join(File.dirname(__FILE__), 'responses', 'tokenized_lat.xml'))
        @oldcts = CTS::CTSLib
        silence_warnings {
          CTS::CTSLib = stub("my tokenizer")
          CTS::CTSLib.stubs(:get_tokenized_passage).returns(@tokenized_lat)
          CTS::CTSLib.stubs(:get_subref).returns('Troiae[1]-venit[1]')
        }
      end
      
      teardown do
        silence_warnings { CTS::CTSLib = @oldcts }
        unless @publication.nil?
          @publication.destroy
        end
        unless @creator.nil?
          @creator.destroy
        end
      end
         
      should "create new from template" do
        test = AlignmentCiteIdentifier.new_from_template(@publication)
        assert_not_nil test
      end
      
      should "create new from supplied" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'align1.xml'))
        test = AlignmentCiteIdentifier.new_from_supplied(@publication,"http://example.org",file,"New alignment")
        assert_not_nil test
        # title from comment uris
        assert_equal "urn:cts:greekLit:tlg0020.tlg001.perseus-grc2:1-1 and urn:cts:greekLit:tlg0020.tlg001.perseus-eng2:1-1", test.title
      end

      # TODO
      # test title from title
      # test fragment
      # test patch_content

     end  
     

  end
end

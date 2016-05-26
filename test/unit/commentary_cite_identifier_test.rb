require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('CommentaryCiteIdentifier')
  class CommentaryCiteIdentifierTest < ActiveSupport::TestCase
  
    context "identifier test" do
      setup do
        @creator = FactoryGirl.create(:user, :name => "Creator")
        @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new", :title => "pub1")
        @publication.branch_from_master
        @publication2 = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new", :title => "pub2")
        @publication2.branch_from_master

        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master
      
      end
      
      teardown do
        unless @publication.nil?
          @publication.destroy
        end
        unless @publication2.nil?
          @publication2.destroy
        end
        unless @creator.nil?
          @creator.destroy
        end
      end

      should "sequence next identifier" do
        assert_equal 1,  CommentaryCiteIdentifier.sequencer("urn:cite:perseus:pdlcomm")
      end

      should "create objects 1.1 and 2.1" do
        test1 = CommentaryCiteIdentifier.new_from_template(@publication)
        assert test1
        assert_equal "urn:cite:perseus:pdlcomm.1.1", test1.urn_attribute

        assert_equal 2,  CommentaryCiteIdentifier.sequencer("urn:cite:perseus:pdlcomm")

        test2 = CommentaryCiteIdentifier.new_from_template(@publication2)
        assert test2
        assert_equal "urn:cite:perseus:pdlcomm.2.1", test2.urn_attribute
     end
     
     should "create object 1.1" do 
      test1 = CommentaryCiteIdentifier.new_from_template(@publication)
      assert test1.urn_attribute == "urn:cite:perseus:pdlcomm.1.1"
      assert test1.to_path == "CITE_COMMENTARY_XML/perseus/pdlcomm/1/pdlcomm.1.1.oac.xml"
     end

      should "process a ro" do
        test = CommentaryCiteIdentifier.new_from_template(@publication)
        test.update_targets(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1-1.2"])
         expected = {
           'aggregates' => [ {'uri' => 'urn:cts:greekLit:tlg0012.tlg001.perseus-grc1', 'mediatype' => 'text/xml'}],
           'annotations'=> [
           {"about"=>["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1-1.2"],
            "dc:format"=>"http://data.perseus.org/rdfvocab/commentary"}]
        }
        assert_equal(expected, test.as_ro())
      end
    
     # TODO commentary length exceeded
     # TODO update commentary test
    end

  end
end

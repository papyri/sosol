require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('CommentaryCiteIdentifier')
  class CommentaryCiteIdentifierTest < ActiveSupport::TestCase
  
    context "identifier test" do
      setup do
        @creator = FactoryGirl.create(:user, :name => "Creator")
        @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")

        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master
      
      end
      
      teardown do
        unless @publication.nil?
          @publication.destroy
        end
        unless @creator.nil?
          @creator.destroy
        end
      end
     
      should "create objects 1.1 and 2.1" do 
        test1 = CommentaryCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlcomm",["urn:cts:test"])
        assert test1.urn_attribute == "urn:cite:perseus:pdlcomm.1.1"
        test2 = CommentaryCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlcomm",["urn:cts:test"])
        test3 = CommentaryCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlcomm",["urn:cts:test:1.1-1.2"])
        assert test2.urn_attribute == "urn:cite:perseus:pdlcomm.2.1"
        next_version = CommentaryCiteIdentifier.next_version_identifier(test2.urn_attribute)
        Rails.logger.info("Next Version = #{next_version}")
        assert next_version == "cite/perseus/pdlcomm.2.2"
        assert !test1.is_match?(['perseus:citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415'])
        assert test1.is_match?(['urn:cts:test'])
        assert ! test3.is_match?(['urn:cts:test:1.1-1.3'])
     end  
     
     should "create object 1.1" do 
      test1 = CommentaryCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlcomm",["urn:cts:test"])
      Rails.logger.info("TEST1 URN=#{test1.urn_attribute}")
      Rails.logger.info("TEST1 PATH=#{test1.to_path}")
      assert test1.urn_attribute == "urn:cite:perseus:pdlcomm.1.1"
      assert test1.to_path == "CITE_COMMENTARY_XML/perseus/pdlcomm/1/pdlcomm.1.1.oac.xml"
     end

      should "fail with unknown collection" do
        assert_raises(RuntimeError) {
          CommentaryCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:invalidcoll",["urn:cts:test"])
        }
      end
      
      should "create new version from existing" do
        test = CommentaryCiteIdentifier.new_from_inventory(@publication,"urn:cite:perseus:pdlcomm.1.1")
        assert test.urn_attribute == "urn:cite:perseus:pdlcomm.1.2"
        annotators = OacHelper::get_annotators(test.get_annotation())
        # TODO this should be 2 annotators
        assert annotators.length == 1
        assert annotators.grep(test.make_annotator_uri())
      end
    

      should "process a ro" do
        test = CommentaryCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlcomm",["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1-1.2"])
         expected = {
           'aggregates' => [ {'uri' => 'urn:cts:greekLit:tlg0012.tlg001.perseus-grc1', 'mediatype' => 'text/xml'}],
           'annotations'=> [
           {"about"=>["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1-1.2"],
            "dc:format"=>"http://data.perseus.org/rdfvocab/commentary"}]
        }
        assert_equal(expected, test.as_ro())
      end
    
     # TODO new version from existing version - same annotator 
     # TODO new version from existing version - new annotator (adds annotator)
     # TODO commentary length exceeded
     # TODO update commentary test
    end

  end
end

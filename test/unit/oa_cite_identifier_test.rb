require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('OaCiteIdentifier')
  class OaCiteIdentifierTest < ActiveSupport::TestCase
  
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

      context "from template" do

        setup do
          @identifier = OaCiteIdentifier.new_from_template(@publication)
        end

        teardown do
          unless @identifier.nil?
            @identifier.destroy
          end
        end

        should "find_like_identifiers handles false response from callback" do
          match_call = lambda do |p| return p.name != @identifier.name end
          matching = Identifier.find_like_identifiers("cite/perseus/pdlann",@creator,match_call)
          assert_equal [], matching
        end

        should "find_like_identifiers handles true response from callback" do
          match_call = lambda do |p| return p.name == @identifier.name end
          matching = Identifier.find_like_identifiers("cite/perseus/pdlann",@creator,match_call)
          assert_equal [@identifier], matching
        end

        should "new_from_template creates empty document" do
          assert_not_nil @identifier
          assert_equal [], @identifier.get_annotations()
        end

        should "can_import? should return false for annotations created by native apps" do
          @identifier.create_annotation("http://example.org")
          assert ! @identifier.can_import?
        end

        should "create_annotation adds a new annotation"do
          urn = @identifier.urn_attribute
          assert_equal 0, @identifier.get_annotations().size
          @identifier.create_annotation("http://example.org")
          assert_equal 1, @identifier.get_annotations().size
          test_match = Hash.new
          test_match["id"] = "http://data.perseus.org/collections/#{urn}/#1"
          test_match["target"] = "http://example.org"
          assert_equal [test_match], @identifier.matching_targets("http://example\.org")
          @identifier.create_annotation("http://example2.org")
          test_match["id"] = "http://data.perseus.org/collections/#{urn}/#2"
          test_match["target"] = "http://example2.org"
          assert_equal [test_match], @identifier.matching_targets("http://example2\.org")
        end

        should "delete_annotation deletes an existing annotation"do
          urn = @identifier.urn_attribute
          @identifier.create_annotation("http://example.org")
          assert_equal 1, @identifier.get_annotations().size
          @identifier.delete_annotation("http://data.perseus.org/collections/#{urn}/#1","deleteme")
          assert_equal 0, @identifier.get_annotations().size
        end

        should "fragment with query" do
          urn = @identifier.urn_attribute
          @identifier.create_annotation("http://example.org")
          assert_match /^<Annotation/, @identifier.fragment("uri=http://data.perseus.org/collections/#{urn}/#1")
        end

        should "fragment invalid query" do
          urn = @identifier.urn_attribute
          assert_raises(Exception){ @identifier.fragment("http://data.perseus.org/collections/#{urn}/#1") }
        end

        should "fragment not found" do
          urn = @identifier.urn_attribute
          assert_nil @identifier.fragment("uri=http://data.perseus.org/collections/#{urn}/#101")
        end

        should "append" do
          urn = @identifier.urn_attribute
          to_append = "<Annotation xmlns=\"http://www.w3.org/ns/oa#\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"><hasTarget xmlns=\"http://www.w3.org/ns/oa#\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" rdf:resource=\"http://example.org\"/>\n  <motivatedBy xmlns=\"http://www.w3.org/ns/oa#\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"/>\n  <annotatedBy xmlns=\"http://www.w3.org/ns/oa#\">\n    <Person xmlns=\"http://xmlns.com/foaf/0.1/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" rdf:about=\"http://data.perseus.org/sosol/users/Creator\"/>\n  </annotatedBy>\n  <annotatedAt xmlns=\"http://www.w3.org/ns/oa#\">2016-03-22T10:13:40-04:00</annotatedAt>\n</Annotation>"
          @identifier.patch_content(nil,"APPEND",to_append,"updatefromapi")
          assert_match /^<Annotation/, @identifier.fragment("uri=http://data.perseus.org/collections/#{urn}/#1")
        end

        should "afer_rename raises error" do
          name_before = @identifier.name
          assert_raises(Exception) {
              @identifier.rename("cite/perseus/pdlann.10.1.oac.xml")
          }
          @identifier.reload
          assert_equal name_before, @identifier.name
        end

        # TODO
        # next_annotation_uri
        # ....

      end

      context "with content" do
        setup do
          file = File.read(File.join(File.dirname(__FILE__), 'data', 'oacite1.xml'))
          @identifier = OaCiteIdentifier.new_from_supplied(@publication,
            "https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html",file,"import")
        end

        teardown do
          unless @identifier.nil?
            @identifier.destroy
          end
        end

        should "new_from_supplied creates document" do
          assert_not_nil @identifier
        end

        should "get_annotation by uri" do
          urn = @identifier.urn_attribute
          assert_not_nil @identifier.get_annotation("http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#6-1")
        end

        should "get_annotation by uri returns Nil for invalid uri" do
          urn = @identifier.urn_attribute
          assert_nil @identifier.get_annotation("http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#7-1")
        end

        should "get_annotations" do
          assert_equal 9, @identifier.get_annotations().size
        end

        should "matching_targets correctly finds target" do
          urn = @identifier.urn_attribute
          match_str = Regexp.quote("http://www.perseus.tufts.edu/hopper/morph?l=*perse%2Fwn&la=greek&can=*perse%2Fwn0&prior=a)llh/loisi")
          matching = @identifier.matching_targets(match_str)
          test_match = Hash.new
          test_match['id'] = "http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1-1"
          test_match['target'] = 'http://www.perseus.tufts.edu/hopper/morph?l=*perse%2Fwn&la=greek&can=*perse%2Fwn0&prior=a)llh/loisi'
          assert_equal test_match, matching[0]
          assert_equal 3, matching.size
        end

        should "matching_targets correctly doesn't find target" do
          match_str = Regexp.quote("http://example.org")
          matching = @identifier.matching_targets(match_str)
          assert_equal 0, matching.size
        end

        should "can_import? should return true for annotations imported from googless" do
          assert @identifier.can_import?
        end
      end

      context "cts annotation" do
        setup do
          file = File.read(File.join(File.dirname(__FILE__), 'data', 'oacite2.xml'))
          @identifier = OaCiteIdentifier.new_from_supplied(@publication,
            "",file,"import")
        end
        teardown do
          unless @identifier.nil?
            @identifier.destroy
          end
        end
        should "process a ro" do
          expected = {
            "annotations"=>
               [{"about"=>["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1"],
                 'conformsTo' => 'http://www.openannotation.org/spec/core/',
                 "mediatype"=>"application/rdf+xml",
                 "content"=>"annotations/#{@identifier.download_file_name}",
                 "createdBy"=>{"name"=> @creator.full_name, "uri"=> @creator.uri}}],
            "aggregates"=>["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1"]
          }
          assert_equal(expected, @identifier.as_ro())
        end
    
      end
    end
  end
end

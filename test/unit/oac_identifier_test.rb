require 'test_helper'

class OACIdentifierTest < ActiveSupport::TestCase
  
  context "identifier test" do
    setup do
      @creator = FactoryGirl.create(:user, :name => "CreatorA")
      @creator2 = FactoryGirl.create(:user, :name => "CreatorB")
      @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")
      # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master
      @parent = FactoryGirl.create(:EpiCTSIdentifier, :title => 'Test Text')
      @oac_identifier = OACIdentifier.new_from_template(@publication,@parent)
      @test_uri1 = 'http://data.perseus.org/annotations/abcd'
      @test_uri2 = 'http://data.perseus.org/annotations/efgh'
      @test_tb1 = 'http://data.perseus.org/citation/urn:cts:greekLang:tlg0012.tlg001.perseus-grc1:1.1'
      @test_tb2 = 'http://data.perseus.org/citation/urn:cts:greekLang:tlg0012.tlg002.perseus-grc1:1.1'
      @test_title = 'Test Annotation'
      @creator_uri = Sosol::Application.config.site_user_namespace + @creator.name
      @creator2_uri = Sosol::Application.config.site_user_namespace + @creator2.name
      @oac_identifier.add_annotation(@test_uri1,[@test_tb1],[@test_tb2],"oa:linking",@creator_uri,"test:agent",'test add annotation')
    end
    
    teardown do
      unless (@publication.nil?)
        @publication.destroy
      end
      unless (@creator.nil?)
        @creator.destroy
      end
    end
    
    should "retrieve the target by urn" do
        matches = @oac_identifier.matching_targets("#{Regexp.quote('urn:cts:greekLang:tlg0012.tlg001.perseus-grc1:1.1#')}?",@creator_uri)
        assert matches.size == 1
        Rails.logger.info("Match = #{matches.inspect}")
        assert matches[0]['target'] = @test_uri1
        
    end
    
    should "retrieve the target by edition urn" do
        assert @oac_identifier.matching_targets('urn:cts:greekLang:tlg0012.tlg001.perseus-grc1',@creator_uri).size == 1
    end
    
    should "have annotations" do 
      assert OacHelper::get_all_annotations(@oac_identifier.rdf).size > 0
      assert @oac_identifier.has_anyannotation?

    end

    should "have an annotation by creator" do 
      assert OacHelper::get_annotators(@oac_identifier.get_annotation(@test_uri1))[0] == @creator_uri
    end

    should "have one annotation by the creator" do 
      assert OacHelper::get_annotations_by_annotator(@oac_identifier.rdf,@creator_uri).size == 1
      assert @oac_identifier.get_annotations().size == 1
    end

    should "have the target" do
        Rails.logger.info("In should have")
        assert @oac_identifier.has_target?(@test_tb1,@creator_uri)
    end
    
    
    should "not have the target" do
        assert !@oac_identifier.has_target?(@test_tb2,@creator_uri)
    end
      
    should "raise an error when the annotation exists" do
      assert_raise RuntimeError do
      @oac_identifier.add_annotation(@test_uri1,[@test_tb1],[@test_tb2],@test_title,@creator_uri,nil,'test add annotation')
      end
    end
    
    should "raise an error when the annotation does not exist" do
      assert_raise RuntimeError do
      @oac_identifier.add_annotation(@test_uri1,[@test_tb2],[@test_tb2],@test_title,@creator_uri,nil,'test add annotation')
      end
    end
    
    should "find the parent identifier" do
      assert OACIdentifier.find_from_parent(@publication,@parent) == @oac_identifier
      
    end
    
    context "with a new annotation " do
      setup do
        @oac_identifier.add_annotation(@test_uri2,[@test_tb2],[@test_tb1],@test_title,@creator_uri,nil,'test add annotation')
      end
      
      should "have the new annotation" do
        assert @oac_identifier.has_target?(@test_tb2,@creator_uri)
      end   
      
      should "retrieve the annotation" do
        annotation =  @oac_identifier.get_annotation(@test_uri2)
        assert ! annotation.nil?
        assert OacHelper::get_targets(annotation).size == 1
        assert OacHelper::get_targets(annotation)[0] == @test_tb2
        assert OacHelper::get_bodies(annotation)[0] == @test_tb1
        assert OacHelper::get_motivation(annotation) == @test_title
        assert OacHelper::get_annotators(annotation)[0] == @creator_uri
        assert OacHelper::get_annotated_at(annotation) != ""
      end
      
      should "delete the annotation" do
        @oac_identifier.delete_annotation(@test_uri2,"test delete")
        assert @oac_identifier.get_annotation(@test_uri2).nil?
        assert ! @oac_identifier.get_annotation(@test_uri1).nil?
      end
    end
    
    context "with an updated annotation " do
      setup do
        @oac_identifier.update_annotation(@test_uri1,[@test_tb2],[@test_tb2],@test_title,@creator_uri,nil,'test update annotation')
      end
      
      should "have the updated annotation" do
        assert @oac_identifier.has_target?(@test_tb2,@creator_uri)
      end
      
      should "not have the old annotation" do
        assert !@oac_identifier.has_target?(@test_tb1,@creator_uri)
      end   
    end
    
    context "with an external agent " do
      setup do 
        @oac_identifier.add_annotation(@test_uri2,[@test_tb2],[@test_tb1],@test_title,@creator_uri,'http://myannottool.org','test add annotation')
      end
      
      should "not allow update from nil agent" do
        orig =  @oac_identifier.get_annotation(@test_uri2)
        update = @oac_identifier.get_annotation(@test_uri1)
        assert ! @oac_identifier.can_update?(orig,update)
      end
    end
  end
end

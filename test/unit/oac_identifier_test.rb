require 'test_helper'

class OACIdentifierTest < ActiveSupport::TestCase
  
  context "identifier test" do
    setup do
      @original_site_identifiers = Sosol::Application.config.site_identifiers
      Sosol::Application.config.site_identifiers = (@original_site_identifiers.split(',') | %w{OACIdentifier TeiCTSIdentifier}).join(',')

      @creator = FactoryGirl.create(:user, :name => "Creator")
      @creator2 = FactoryGirl.create(:user, :name => "Creator2")
      @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")
      # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master
      @parent = FactoryGirl.create(:TeiCTSIdentifier, :title => 'Test Text')
      @oac_identifier = OACIdentifier.new_from_template(@publication,@parent)
      @test_uri1 = 'http://data.perseus.org/annotations/abcd'
      @test_uri2 = 'http://data.perseus.org/annotations/efgh'
      @test_tb1 = 'http://data.perseus.org/citation/urn:cts:greekLang:tlg0012.tlg001.perseus-grc1:1.1'
      @test_tb2 = 'http://data.perseus.org/citation/urn:cts:greekLang:tlg0012.tlg002.perseus-grc1:1.1'
      @test_title = 'Test Annotation'
      @creator_uri = ActionDispatch::Integration::Session.new(Sosol::Application).url_for(:host => Sosol::Application.config.site_user_namespace, :controller => 'user', :action => 'show', :user_name => @creator.name, :only_path => false)
      @creator2_uri = ActionDispatch::Integration::Session.new(Sosol::Application).url_for(:host => Sosol::Application.config.site_user_namespace, :controller => 'user', :action => 'show', :user_name => @creator2.name, :only_path => false)
      @oac_identifier.add_annotation(@test_uri1,[@test_tb1],@test_tb2,@test_title,@creator_uri,'test add annotation')
    end
    
    teardown do
      @publication.destroy
      @creator.destroy
      @creator2.destroy
      Sosol::Application.config.site_identifiers = @original_site_identifiers
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
    
    should "have the target" do
        assert @oac_identifier.has_target?(@test_tb1,@creator_uri)
    end
    
    
    should "not have the target" do
        assert !@oac_identifier.has_target?(@test_tb2,@creator_uri)
    end
      
    should "raise an error when the annotation exists" do
      assert_raise RuntimeError do
      @oac_identifier.add_annotation(@test_uri1,[@test_tb1],@test_tb2,@test_title,@creator_uri,'test add annotation')
      end
    end
    
    should "raise an error when the annotation does not exist" do
      assert_raise RuntimeError do
      @oac_identifier.add_annotation(@test_uri1,[@test_tb2],@test_tb2,@test_title,@creator_uri,'test add annotation')
      end
    end
    
    should "find the parent identifier" do
      assert OACIdentifier.find_from_parent(@publication,@parent) == @oac_identifier
      
    end
    
    context "with a new annotation " do
      setup do
        @oac_identifier.add_annotation(@test_uri2,[@test_tb2],@test_tb1,@test_title,@creator_uri,'test add annotation')
      end
      
      should "have the new annotation" do
        assert @oac_identifier.has_target?(@test_tb2,@creator_uri)
      end   
      
      should "retrieve the annotation" do
        annotation =  @oac_identifier.get_annotation(@test_uri2)
        assert ! annotation.nil?
        assert @oac_identifier.get_targets(annotation).size == 1
        assert @oac_identifier.get_targets(annotation)[0] == @test_tb2
        assert @oac_identifier.get_body(annotation) == @test_tb1
        assert @oac_identifier.get_title(annotation) == @test_title
        assert @oac_identifier.get_creator(annotation) == @creator_uri
        assert @oac_identifier.get_created(annotation) != ""
      end
      
      should "delete the annotation" do
        @oac_identifier.delete_annotation(@test_uri2,"test delete")
        assert @oac_identifier.get_annotation(@test_uri2).nil?
        assert ! @oac_identifier.get_annotation(@test_uri1).nil?
      end
    end
    
    context "with an updated annotation " do
      setup do
        @oac_identifier.update_annotation(@test_uri1,[@test_tb1],@test_tb2,@test_title,@creator2_uri,'test update annotation')
      end
      
      should "have the updated annotation" do
        assert @oac_identifier.has_target?(@test_tb1,@creator2_uri)
      end
      
      should "not have the old annotation" do
        assert !@oac_identifier.has_target?(@test_tb2,@creator_uri)
      end   
    end
    
  end
end

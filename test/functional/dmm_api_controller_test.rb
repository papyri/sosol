require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('TreebankCiteIdentifier')
  class DmmApiControllerTest < ActionController::TestCase
    def setup
      @creator = FactoryGirl.create(:user, :name => "Creator")
      @creatorb = FactoryGirl.create(:user, :name => "CreatorB")
      @request.session[:user_id] = @creator.id
      @valid_tb = File.read(File.join(File.dirname(__FILE__), 'data', 'validtb.xml'))
      @valid_align = File.read(File.join(File.dirname(__FILE__), 'data', 'validalign.xml'))
    end
    
    def teardown
      @request.session[:user_id] = nil
      @creator.destroy
    end
     
    def test_should_create_publication_and_treebank_identifier
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      assert_match(/<item>..*?<\/item>/,@response.body) 
      assert_equal 1, assigns(:publication).identifiers.size 
    end
    
    def test_should_create_publication_and_alignment_identifier
      @request.env['RAW_POST_DATA'] = @valid_align
      post :api_item_create, :identifier_type => 'AlignmentCite'
      assert_match(/<item>..*?<\/item>/,@response.body) 
      assert_equal 1, assigns(:publication).identifiers.size 
    end

    def test_should_succeed_update
      @request.env['RAW_POST_DATA'] = @valid_align
      post :api_item_create, :identifier_type => 'AlignmentCite'
      assert_equal 1, assigns(:publication).identifiers.size 
      identifier = assigns(:publication).identifiers[0]
      @request.env['RAW_POST_DATA'] = @valid_align
      post :api_item_patch, :identifier_type => 'AlignmentCite', :id => identifier.id.to_s, :q => 's=1'
      assert_response(:success)
    end

    def test_should_fail_update_invalid_user
      @request.env['RAW_POST_DATA'] = @valid_align
      post :api_item_create, :identifier_type => 'AlignmentCite'
      assert_equal 1, assigns(:publication).identifiers.size 
      identifier = assigns(:publication).identifiers[0]
      @request.env['RAW_POST_DATA'] = @valid_align
      @request.session[:user_id] = @creatorb.id
      post :api_item_patch, :identifier_type => 'AlignmentCite', :id => identifier.id.to_s
      assert_response(403)
    end
    
    
     def test_should_fail_create_duplicate_identifier_using_init
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      assert_match(/<item>..*?<\/item>/,@response.body) 
      assert_equal 1, assigns(:publication).identifiers.size 
      post :api_item_create, :identifier_type => 'TreebankCite', :init_value => "urn:cts:latinLit:tg.work.edition:1.1"
      assert_match(/error.*?conflicting/,@response.body) 
      assert_equal 1, assigns(:publication).identifiers.size
    end

     def test_should_fail_create_duplicate_identifier_using_post
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      assert_equal 1, assigns(:publication).identifiers.size 
      post :api_item_create, :identifier_type => 'TreebankCite'
      assert_match(/error.*?conflicting/,@response.body) 
      assert_equal 1, assigns(:publication).identifiers.size
    end
    
    def test_should_treebank_identifier_in_existing_publication
      @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")
        # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite', :publication_id => @publication.id.to_s
      assert_match(/<item>..*?<\/item>/,@response.body)   
      assert_equal 1, @publication.identifiers.size
    end

    def test_should_succeed_comment_create
      @request.env['RAW_POST_DATA'] = @valid_align
      post :api_item_create, :identifier_type => 'AlignmentCite'
      post :api_item_comments_post, :identifier_type => 'AlignmentCite', :id => assigns(:publication).identifiers[0].id.to_s, :comment=>"test", :reason => "review"
      assert_match(/"comment_id":(.*?),/,@response.body)
      
    end

    def test_should_succeed_comment_update_owner_user
      @request.env['RAW_POST_DATA'] = @valid_align
      post :api_item_create, :identifier_type => 'AlignmentCite'
      post :api_item_comments_post, :identifier_type => 'AlignmentCite', :id => assigns(:publication).identifiers[0].id.to_s, :comment=>"test", :reason => "review"
      comment_id = @response.body.match(/"comment_id":(.*?),/).captures
      post :api_item_comments_post, :identifier_type => 'AlignmentCite', :id => assigns(:publication).identifiers[0].id.to_s, :comment_id => comment_id, :comment=>"test update", :reason => "review"
      assert_match(/"comment_id":#{comment_id}/,@response.body)
      assert_match(/"comment":"test update"/,@response.body)
    end

    def test_should_fail_invalid_reason
      @request.env['RAW_POST_DATA'] = @valid_align
      post :api_item_create, :identifier_type => 'AlignmentCite'
      post :api_item_comments_post, :identifier_type => 'AlignmentCite', :id => assigns(:publication).identifiers[0].id.to_s, :comment=>"test", :reason => "spam"
      assert_response(:error)
    end

    def test_should_set_default_reason
      @request.env['RAW_POST_DATA'] = @valid_align
      post :api_item_create, :identifier_type => 'AlignmentCite'
      post :api_item_comments_post, :identifier_type => 'AlignmentCite', :id => assigns(:publication).identifiers[0].id.to_s, :comment=>"test"
      assert_match(/"reason":"general"/,@response.body)
    end


    # TODO TEST BOARD OWNERSHIP UPDATE and COMMENT

  end
end

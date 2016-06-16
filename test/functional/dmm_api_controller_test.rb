require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('TreebankCiteIdentifier')
  class DmmApiControllerTest < ActionController::TestCase
    def setup
      @creator = FactoryGirl.create(:user, :name => "Creator")
      @creatorb = FactoryGirl.create(:user, :name => "CreatorB")
      @request.session[:user_id] = @creator.id
      @valid_tb = File.read(File.join(File.dirname(__FILE__), 'data', 'validtb.xml'))
      @valid_align = File.read(File.join(File.dirname(__FILE__), 'data', 'validalign.xml'))
      @update_tb = File.read(File.join(File.dirname(__FILE__), 'data', 'updatetb.xml'))
      @valid_oa = File.read(File.join(File.dirname(__FILE__), 'data', 'validoa.xml'))
      @oa_append = File.read(File.join(File.dirname(__FILE__), 'data', 'oaappend.xml'))
    end
    
    def teardown
      @request.session[:user_id] = nil
      @creator.destroy
    end
     
    def test_should_create_publication_and_treebank_identifier
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      assert_match(/<item>..*?<\/item>/,@response.body) 
      assert_not_nil assigns(:publication)
      assert_not_nil assigns(:identifier)
    end
    
    #def test_should_create_publication_and_alignment_identifier
    #  @request.env['RAW_POST_DATA'] = @valid_align
    #  post :api_item_create, :identifier_type => 'AlignmentCite'
    #  assert_match(/<item>..*?<\/item>/,@response.body) 
    #  assert_equal 1, assigns(:publication).identifiers.size 
    #end

    def test_should_succeed_update
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      assert_not_nil assigns(:publication)
      assert_not_nil assigns(:identifier)
      @request.env['RAW_POST_DATA'] = @update_tb
      post :api_item_patch, :identifier_type => 'TreebankCite', :id => assigns(:identifier).id.to_s
      assert_response(:success)
    end

    def test_should_succeed_append
      @request.env['RAW_POST_DATA'] = @valid_oa
      post :api_item_create, :identifier_type => 'OaCite'
      assert_not_nil assigns(:publication)
      assert_not_nil assigns(:identifier)
      assert_equal 1, assigns(:identifier).get_annotations().size
      @request.env['RAW_POST_DATA'] = @oa_append
      post :api_item_append, :identifier_type => 'OaCite', :id => assigns(:identifier).id.to_s
      assert_response(:success)
      assert_equal 2, assigns(:identifier).get_annotations().size
    end

    def test_should_fail_update_invalid_user
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      assert_not_nil assigns(:publication)
      assert_not_nil assigns(:identifier)
      @request.env['RAW_POST_DATA'] = @valid_tb
      @request.session[:user_id] = @creatorb.id
      post :api_item_patch, :identifier_type => 'TreebankCite', :id => assigns(:identifier).id.to_s
      assert_response(403)
    end

    def test_should_fail_update_commit_failure
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      assert_not_nil assigns(:publication)
      assert_not_nil assigns(:identifier)
      @request.env['RAW_POST_DATA'] = @update_tb
      assigns(:identifier).repository.class.any_instance.stubs(:commit_content).raises(Exceptions::CommitError.new("Commit failed"))
      post :api_item_patch, :identifier_type => 'TreebankCite', :id => assigns(:identifier).id.to_s
      assert_response(500)
    end
    
    
     def test_should_create_duplicate_identifier_using_post
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      assert_not_nil assigns(:identifier)
      assert_not_nil assigns(:publication)
      post :api_item_create, :identifier_type => 'TreebankCite'
      assert_response(200)
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
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      post :api_item_comments_post, :identifier_type => 'TreebankCite', :id => assigns(:identifier).id.to_s, :comment=>"test", :reason => "review"
      assert_match(/"comment_id":(.*?),/,@response.body)
    end

    def test_should_succeed_comment_get
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      post :api_item_comments_post, :identifier_type => 'TreebankCite', :id => assigns(:identifier).id.to_s, :comment=>"test", :reason => "review"
      get :api_item_comments_get, :identifier_type => 'TreebankCite', :id => assigns(:identifier).id.to_s
      assert_response(:success)
      comments = JSON.parse(@response.body)
      assert_not_nil(comments[0]['comment_id'])
      assert_not_nil(comments[0]['created_at'])
      assert_not_nil(comments[0]['updated_at'])
      assert_equal(@creator.human_name,comments[0]['user'])
      assert_equal('review',comments[0]['reason'])
      assert_equal('test',comments[0]['comment'])
    end


    def test_should_succeed_comment_update_owner_user
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      post :api_item_comments_post, :identifier_type => 'TreebankCite', :id => assigns(:identifier).id.to_s, :comment=>"test", :reason => "review"
      comment_id = @response.body.match(/"comment_id":(.*?),/).captures
      post :api_item_comments_post, :identifier_type => 'TreebankCite', :id => assigns(:identifier).id.to_s, :comment_id => comment_id, :comment=>"test update", :reason => "review"
      assert_match(/"comment_id":#{comment_id}/,@response.body)
      assert_match(/"comment":"test update"/,@response.body)
    end

    def test_should_fail_invalid_reason
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      post :api_item_comments_post, :identifier_type => 'TreebankCite', :id => assigns(:identifier).id.to_s, :comment=>"test", :reason => "spam"
      assert_response(:error)
    end

    def test_should_set_default_reason
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      post :api_item_comments_post, :identifier_type => 'TreebankCite', :id => assigns(:identifier).id.to_s, :comment=>"test"
      assert_match(/"reason":"general"/,@response.body)
    end

    def test_should_return_api_item_info
      @request.env['RAW_POST_DATA'] = @valid_oa
      post :api_item_create, :identifier_type => 'OaCite'
      assert_not_nil assigns(:publication)
      assert_not_nil assigns(:identifier)
      get :api_item_info, :identifier_type => 'OaCite', :id => assigns(:identifier).id.to_s, :format => 'json'
      assert_response(:success)
      json = JSON.parse(response.body)
      assert_not_nil json['tokenizer']
      assert_not_nil json['cts_services']
      assert_not_nil json['target_links']
      assert_not_nil json['target_links']['commentary']
    end

    def test_item_return_to_item
      @request.env['RAW_POST_DATA'] = @valid_tb
      post :api_item_create, :identifier_type => 'TreebankCite'
      get :api_item_return, :identifier_type => 'TreebankCite', :id => assigns(:identifier.id.to_s), :item_action => 'edit'
      assert_redirected_to polymorphic_url([assigns(:identifier).publication, assigns(:identifier)]), :action => 'edit'
    end

    def test_item_return_to_item
      get :api_item_return
      assert_redirected_to dashboard_url
    end
  end
end

require 'test_helper'
require 'ddiff'

class MasterCommunityWorkflowTest < ActionController::IntegrationTest
  def compare_publications(a,b)

    pubs_are_matched = true
    a.identifiers.each do |aid|
      id_has_match = false
      b.identifiers.each do |bid|
        if (aid.class.to_s == bid.class.to_s && aid.title == bid.title)
          if (aid.xml_content == bid.xml_content)
            id_has_match = true
            Rails.logger.debug "Identifier match found"
          else
            if aid.xml_content == nil
              Rails.logger.debug a.title + " has nill " + aid.class.to_s + " identifier"
            end
            if bid.xml_content == nil
              Rails.logger.debug b.title + " has nill " + bid.class.to_s + " identifier"
            end
            Rails.logger.debug "Identifier diffs for " + a.title + " " + b.title + " " + aid.class.to_s + " " +  aid.title
            log_diffs(aid.xml_content.to_s, bid.xml_content.to_s )
            #Rails.logger.debug "full xml a " + aid.xml_content
            #Rails.logger.debug "full xml b " + bid.xml_content
          end
        end
      end

      if !id_has_match
        pubs_are_matched = false
        Rails.logger.debug "--Mis matched publication. Id " + aid.title + " " + aid.class.to_s + " is different"
      end
    end

    if pubs_are_matched
      Rails.logger.debug "Publications are matched"
    end
  end

  def log_diffs(a, b)
    a_to_b_diff = a.diff(b)

    plus_str = ""
    minus_str = ""
    a_to_b_diff.diffs.each do |d|
      d.each do |mod|
        if mod[0] == "+"
          plus_str = plus_str + mod[2].chr
        else
          minus_str = minus_str + mod[2].chr
        end
      end
    end

    Rails.logger.debug "added " + plus_str
    Rails.logger.debug "removed " + minus_str

  end

  setup do
    Rails.logger.level = 0
    Rails.logger.debug "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx master community testing setup xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    # master community for the board
    @community = FactoryGirl.create(:master_community, :is_default => true, :allows_self_signup => true )
    #a user to put on the boards
    @board_user = FactoryGirl.create(:user, :name => "board_man_bob")
    @board_user_2 = FactoryGirl.create(:user, :name => "board_man_alice")
    #a user to submit publications
    @creator_user = FactoryGirl.create(:user, :name => "creator_bob")
    #an end user to recieve the "finalized" publication
    @end_user = FactoryGirl.create(:user, :name => "end_bob")

    #set up the boards, and vote
    @meta_board = FactoryGirl.create(:hgv_meta_community_board, :title => "meta", :community => @community)


    #the board memeber
    @meta_board.users << @board_user

    #the vote
    @meta_decree = FactoryGirl.create(:count_decree,
                                      :board => @meta_board,
                                      :trigger => 1.0,
                                      :action => "approve",
                                      :choices => "ok")
    @meta_board.decrees << @meta_decree

    @text_board = FactoryGirl.create(:community_board, :title => "text", :community => @community)
    #the board memeber

    @text_board.users << @board_user
    #the vote
    @text_decree = FactoryGirl.create(:count_decree,
                                      :board => @text_board,
                                      :trigger => 1.0,
                                      :action => "approve",
                                      :choices => "ok")
    @text_board.decrees << @text_decree

    @translation_board = FactoryGirl.create(:hgv_trans_community_board, :title => "translation", :community => @community)

    #the board memeber
    @translation_board.users << @board_user
    #the vote
    @translation_decree = FactoryGirl.create(:count_decree,
                                             :board => @translation_board,
                                             :trigger => 1.0,
                                             :action => "approve",
                                             :choices => "ok")
    @translation_board.decrees << @translation_decree

    #set board order
    @meta_board.rank = 1
    @text_board.rank = 2
    @translation_board.rank = 3

    # setup additional communities for testing submit options

    @community_end_user = FactoryGirl.create(:user, :name => "community_man_bob")
    @closed_community = FactoryGirl.create(:end_user_community, :is_default => false, :allows_self_signup => false, :end_user_id => @community_end_user.id )
    @open_community = FactoryGirl.create(:end_user_community, :is_default => false, :allows_self_signup => true, :end_user_id => @community_end_user.id )
    @meta_community_board1 = FactoryGirl.create(:hgv_meta_community_board, :title => "meta", :community => @closed_community)
    @meta_community_board2 = FactoryGirl.create(:hgv_meta_community_board, :title => "meta", :community => @open_community)
  end

  teardown do
    begin
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        count = 0
        [ @board_user, @board_user_2, @creator_user, @end_user, @meta_board, @text_board, @translation_board, @community ].each do |entity|
          count = count + 1
          unless entity.nil?
            entity.reload
            entity.destroy
          end
        end
      end
    end
  end

  should "user creates and submits publication to sosol"  do
    Rails.logger.debug "BEGIN TEST: user creates and submits publication to master community"

    assert_not_equal nil, @meta_board, "Meta board not created"
    assert_not_equal nil, @text_board, "Text board not created"
    assert_not_equal nil, @translation_board, "Translation board not created"

    #create a publication with a session
    open_session do |publication_session|
      #publication_session.data
      Rails.logger.debug "---Create A New Publication---"

      publication_session.post 'publications/create_from_templates' + '?test_user_id=' + @creator_user.id.to_s

      Rails.logger.debug "--flash is: " + publication_session.flash.inspect

      @publication = @creator_user.publications.first

      @publication.log_info
    end

    Rails.logger.debug "---Publication Created---"
    Rails.logger.debug  "--identifier count is: " + @publication.identifiers.count.to_s

    an_array = @publication.identifiers
    Rails.logger.debug  "--identifier length via array is: " + an_array.length.to_s

    Rails.logger.debug "---Identifiers for publication " + @publication.title + " are:"

    @publication.identifiers.each do |pi|
      Rails.logger.debug "-identifier-"
      Rails.logger.debug "title is: " +  pi.title
      Rails.logger.debug "was it modified?: " + pi.modified?.to_s
      Rails.logger.debug "xml:"
      Rails.logger.debug pi.xml_content
    end

    Rails.logger.debug "---Testing Submittable Communities---"
    get 'publications/' + @publication.id.to_s + '?test_user_id=' + @creator_user.id.to_s 
    assert assigns(:submittable_communities)
    assert assigns(:signup_communities)
    assert assigns(:confirm_communities)

    assert_equal [@open_community.id], assigns(:signup_communities)
    assert_equal [@community.id, @open_community.id,0], assigns(:submittable_communities).values
    assert_equal [], assigns(:confirm_communities)

    open_session do |submit_session|

      submit_session.post 'publications/' + @publication.id.to_s + '/submit/?test_user_id=' + @creator_user.id.to_s +
         "&community[id]=#{@community.id.to_s}", :submit_comment => "I made a new pub"
      assert_equal "Publication submitted to #{@community.friendly_name}.", flash[:notice]

      Rails.logger.debug "--flash is: " + submit_session.flash.inspect
    end
    @publication.reload

    assert_equal @community, @publication.community, "Community is NIL but should be set to default community"

    #now meta should have it
    assert_equal "submitted", @publication.status, "Publication status not submitted " + @publication.community_id.to_s + " id "

    #meta board should have 1 publication, others should have 0
    meta_publications = Publication.find(:all, :conditions => { :owner_id => @meta_board.id, :owner_type => "Board" } )
    assert_equal 1, meta_publications.length, "Meta does not have 1 publication but rather, " + meta_publications.length.to_s + " publications"

    text_publications = Publication.find(:all, :conditions => { :owner_id => @text_board.id, :owner_type => "Board" } )
    assert_equal 0, text_publications.length, "Text does not have 0 publication but rather, " + text_publications.length.to_s + " publications"

    translation_publications = Publication.find(:all, :conditions => { :owner_id => @translation_board.id, :owner_type => "Board" } )
    assert_equal 0, translation_publications.length, "Translation does not have 0 publication but rather, " + translation_publications.length.to_s + " publications"

    Rails.logger.debug "Meta Board has publication"
    #vote on it
    meta_publication = meta_publications.first

    assert !meta_publication.creator_commits.empty?, "submitted publication should have creator commits"

    #find meta identifier
    meta_identifier = nil
    meta_publication.identifiers.each do |id|
      if @meta_board.controls_identifier?(id)
        meta_identifier = id
      end
    end

    assert_not_nil  meta_identifier, "Did not find the meta identifier"
    assert meta_identifier.content, "meta_identifier should have content"

    Rails.logger.debug "Found meta identifier, will vote on it"

    open_session do |meta_session|
      meta_session.post 'publications/vote/' + meta_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, \
        :comment => { :comment => "I agree meta is great", :user_id => @board_user.id, :publication_id => meta_identifier.publication.id, :identifier_id => meta_identifier.id, :reason => "vote" }, \
        :vote => { :publication_id => meta_identifier.publication.id.to_s, :identifier_id => meta_identifier.id.to_s, :user_id => @board_user.id.to_s, :board_id => @meta_board.id.to_s, :choice => "ok" }

      Rails.logger.debug "--flash is: " + meta_session.flash.inspect
      
    end
        
    #reload the publication to get the vote associations to go thru?
    meta_publication.reload

    vote_str = "Votes on meta are: "
    meta_publication.votes.each do |v|
      vote_str = vote_str + v.choice
    end
    Rails.logger.debug  vote_str
    Rails.logger.debug meta_publication.inspect
    Rails.logger.debug meta_publication.children.inspect

    assert_equal 1, meta_publication.votes.length, "Meta publication should have one vote"
    assert_equal 1, meta_publication.children.length, "Meta publication should have one child"

    #vote should have changed publication to approved and put to finalizer
    assert_equal "approved", meta_publication.status, "Meta publication not approved after vote"
    Rails.logger.debug "--Meta publication approved"

    meta_final_publication = meta_publication.find_finalizer_publication
    assert_equal meta_final_publication.status, "finalizing", "Board user's publication is not for finalizing"
    Rails.logger.debug "---Finalizer has publication"

    #call finalize on publication controller

    meta_final_identifier = nil
    meta_final_publication.identifiers.each do |id|
      if @meta_board.controls_identifier?(id)
        meta_final_identifier = id
      end
    end

    assert meta_final_identifier.content, "finalizing publication's identifier should have content"
    assert meta_final_publication.needs_rename?, "finalizing publication should need rename before being renamed"

    Rails.logger.info('meta_final_identifier')
    Rails.logger.info(meta_final_identifier.inspect)
    # do rename
    open_session do |meta_rename_session|
      meta_rename_session.put 'publications/' + meta_final_publication.id.to_s + '/hgv_meta_identifiers/' + meta_final_identifier.id.to_s + '/rename/?test_user_id='  + @board_user.id.to_s,
        :new_name => 'papyri.info/hgv/0000000000'
    end

    meta_final_publication.reload
    meta_final_identifier.reload
    Rails.logger.info('meta_final_publication')
    Rails.logger.info(meta_final_publication.inspect)
    Rails.logger.info(meta_final_identifier.inspect)
    assert !meta_final_publication.needs_rename?, "finalizing publication should not need rename after being renamed"

    open_session do |meta_finalize_session|

      meta_finalize_session.post 'publications/' + meta_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
        :comment => 'I agree meta is great and now it is final'

      Rails.logger.debug "--flash is: " + meta_finalize_session.flash.inspect
      Rails.logger.debug "----session data is: " + meta_finalize_session.session.to_hash.inspect
      Rails.logger.debug meta_finalize_session.body
    end

    meta_final_publication.reload
    assert_equal "finalized", meta_final_publication.status, "Meta final publication not finalized"

    Rails.logger.debug "Meta committed"

    #compare the publications
    #final should have comments and votes

    meta_publication.reload
    meta_publication.log_info
    meta_final_publication.reload
    meta_final_publication.log_info
    Rails.logger.debug "Compare board with board publication"
    compare_publications(meta_publication, meta_publication)
    Rails.logger.debug "Compare board with finalizer publication"
    compare_publications(meta_publication, meta_final_publication)
    Rails.logger.debug "Compare user with finalizer publication"
    compare_publications(@creator_user.publications.first, meta_final_publication)

    #=================================TEXT BOARD==========================================
    #now text board should have it

    #meta board should have 1 publication
    meta_publications = Publication.find(:all, :conditions => { :owner_id => @meta_board.id, :owner_type => "Board" } )
    assert_equal 1, meta_publications.length, "Meta does not have 1 publication but rather, " + meta_publications.length.to_s + " publications"

    #text board should have 1 publication
    text_publications = Publication.find(:all, :conditions => { :owner_id => @text_board.id, :owner_type => "Board" } )
    assert_equal 1, text_publications.length, "Text does not have 0 publication but rather, " + text_publications.length.to_s + " publications"

    #translation board should have 0 publication
    translation_publications = Publication.find(:all, :conditions => { :owner_id => @translation_board.id, :owner_type => "Board" } )
    assert_equal 0, translation_publications.length, "Translation does not have 0 publication but rather, " + translation_publications.length.to_s + " publications"

    #vote on it
    text_publication = text_publications.first

    #find text identifier
    text_identifier = nil
    text_publication.identifiers.each do |id|
      if @text_board.controls_identifier?(id)
        text_identifier = id
      end
    end

    assert_not_nil  text_identifier, "Did not find the text identifier"

    Rails.logger.debug "Found text identifier, will vote on it"

    open_session do |text_session|

      text_session.post 'publications/vote/' + text_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, \
        :comment => { :comment => "I agree text is great", :user_id => @board_user.id, :publication_id => text_identifier.publication.id, :identifier_id => text_identifier.id, :reason => "vote" }, \
        :vote => { :publication_id => text_identifier.publication.id.to_s, :identifier_id => text_identifier.id.to_s, :user_id => @board_user.id.to_s, :board_id => @text_board.id.to_s, :choice => "ok" }
      Rails.logger.debug "--flash is: " + text_session.flash.inspect
    end
        
    #reload the publication to get the vote associations to go thru?
    text_publication.reload

    assert_equal 1, text_publication.votes.length, "Text publication should have one vote"
    Rails.logger.debug "After text publication voting, origin has children:"
    Rails.logger.debug text_publication.origin.children.inspect
    assert_equal 1, text_publication.children.length, "Text publication should have one child"

    #vote should have changed publication to approved and put to finalizer
    assert_equal "approved", text_publication.status, "Text publication not approved after vote"
    Rails.logger.debug "--Text publication approved"

    #now finalizer should have it, only one person on board so it should be them
    finalizer_publications = @board_user.publications
    assert_equal 2, finalizer_publications.length, "Finalizer does not have a new (text) publication to finalize"

    text_final_publication = text_publication.find_finalizer_publication

    assert_not_nil text_final_publication, "Publicaiton does not have text finalizer"
    Rails.logger.debug "---Finalizer has text publication"

    text_final_identifier = nil
    text_final_publication.identifiers.each do |id|
      if @text_board.controls_identifier?(id)
        text_final_identifier = id
      end
    end
    assert_not_nil text_final_identifier, "Finalizer does not have controlled identifier"

    assert text_final_publication.needs_rename?, "finalizing publication should need rename before being renamed"

    # try to finalize without rename
    open_session do |text_finalize_session|
      text_finalize_session.post 'publications/' + text_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
      :comment => 'I agree text is great and now it is final'

      Rails.logger.debug "--flash is: " + text_finalize_session.flash.inspect
      Rails.logger.debug "----session data is: " + text_finalize_session.session.to_hash.inspect
      Rails.logger.debug text_finalize_session.body

      Rails.logger.debug "--flash is: " + text_finalize_session.flash.inspect
    end

    text_final_publication.reload
    assert_not_equal "finalized", text_final_publication.status, "Text final publication finalized when it should be blocked by rename guard"

    # do rename
    open_session do |text_rename_session|
      text_rename_session.put 'publications/' + text_final_publication.id.to_s + '/ddb_identifiers/' + text_final_identifier.id.to_s + '/rename/?test_user_id='  + @board_user.id.to_s,
        :new_name => 'papyri.info/ddbdp/bgu;1;000', :set_dummy_header => false
    end

    text_final_publication.reload
    assert !text_final_publication.needs_rename?, "finalizing publication should not need rename after being renamed"

    # actually finalize now that we've renamed
    open_session do |text_finalize_session|

      text_finalize_session.post 'publications/' + text_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
        :comment => 'I agree text is great and now it is final'

      Rails.logger.debug "--flash is: " + text_finalize_session.flash.inspect
      Rails.logger.debug "----session data is: " + text_finalize_session.session.to_hash.inspect
      Rails.logger.debug text_finalize_session.body

      Rails.logger.debug "--flash is: " + text_finalize_session.flash.inspect
    end

    text_final_publication.reload
    assert_equal "finalized", meta_final_publication.status, "Text final publication not finalized"

    Rails.logger.debug "---Text publication Finalized"

    current_creator_publication = @creator_user.publications.first
    current_creator_publication.reload

    current_creator_publication.log_info

    text_final_publication.reload
    text_final_publication.log_info

    @publication.destroy

    # @balmas this is all a bit of a hack to  test that the identifiers in the newly created and
    # finalized  publication are indeed committed to master -- I think since it's not going to
    # be in the numbers server we can't go through a controller method here 
    test_identifier_path = current_creator_publication.identifiers.first.to_path
    test_identifier_n = current_creator_publication.identifiers.first.n_attribute
    Rails.logger.debug "--- Checking master repository for " + test_identifier_path
    @publication = Publication.new()
    @publication.owner = @creator_user
    @publication.creator = @creator_user
    @publication.repository.update_master_from_canonical
    assert ! @publication.repository.get_file_from_branch(test_identifier_path, 'master').blank?
    @publication.destroy
  end
end

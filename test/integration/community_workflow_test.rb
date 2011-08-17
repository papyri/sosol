require 'test_helper'
require 'ddiff'

#require File.dirname(__FILE__) + '/session_set_controller'

class CommunityWorkflowTest < ActionController::IntegrationTest
  context "for idp3" do

=begin
    
    should "be a test result of somesort" do
      
      assert_equal 5, 7
    end
=end
    
    context "community testing" do
      setup do
        Rails.logger.level = 0
        Rails.logger.info "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx setup xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        #a user to put on the boards
        @board_user = Factory(:user, :name => "board_man_bob")
        @board_user_2 = Factory(:user, :name => "board_man_alice")   
        #a user to submit publications
        @creator_user = Factory(:user, :name => "creator_bob") 
        #an end user to recieve the "finalized" publication
        @end_user = Factory(:user, :name => "end_bob")
        
        
        #set up the community
        @test_community = Factory(:community, 
                                  :name => "test_community", 
                                  :friendly_name => "testy", 
                                  :abbreviation => "tc", 
                                  :description => "a comunity for testing"
                                  )
        @test_community.members << @end_user
        
        
        #set up the boards, and vote
        #@meta_board = Factory(:community_meta_board, :title => "meta", :community_id => @test_community.id)
        @meta_board = Factory(:hgv_meta_board, :title => "meta", :community_id => @test_community.id)

        #the board memeber
        @meta_board.users << @board_user
        #@meta_board.users << @board_user_2

        #the vote
        @meta_decree = Factory(:count_decree,
                :board => @meta_board,
                :trigger => 1.0,
                :action => "approve",
                :choices => "ok"                
                )
        @meta_board.decrees << @meta_decree
        
        #add board to community                
        @test_community.boards << @meta_board
        

        
        #@text_board = Factory(:community_text_board, :title => "text", :community_id => @test_community.id)
        @text_board = Factory(:board, :title => "text", :community_id => @test_community.id)
        #the board memeber
        @text_board.users << @board_user
        #the vote
        @text_decree = Factory(:count_decree,
                :board => @text_board,
                :trigger => 1.0,
                :action => "approve",
                :choices => "ok"
                )
        @text_board.decrees << @text_decree
        #add board to community                
        @test_community.boards << @text_board

        
        #@translation_board = Factory(:community_translation_board, :title => "translation", :community_id => @test_community.id)
        @translation_board = Factory(:hgv_trans_board, :title => "translation", :community_id => @test_community.id)
        
        #the board memeber
        @translation_board.users << @board_user
        #the vote
        @translation_decree = Factory(:count_decree,
                :board => @translation_board,
                :trigger => 1.0,
                :action => "approve",
                :choices => "ok"
                )
        @translation_board.decrees << @translation_decree
        
        #add board to community                
        @test_community.boards << @translation_board

        #set board order
        @meta_board.rank = 1
        @text_board.rank = 2
        @translation_board.rank = 3
=begin        
        count = 0
         [ @board_user, @board_user_2, @creator_user, @end_user, @meta_board, @text_board, @translation_board, @test_community ].each do |entity|
         count = count + 1 
         assert entity, count.to_s + " was not created."
         end
=end
      end
      
      teardown do
begin        
        count = 0
        [ @board_user, @board_user_2, @creator_user, @end_user, @meta_board, @text_board, @translation_board, @test_community ].each do |entity| 
          count = count + 1
          #assert_not_equal entity, nil, count.to_s + " cant be destroyed since it is nil." 
          unless entity.nil?
            entity.destroy
          end
        end
end
      end
 
=begin      
    should "have boards and community" do
      
        assert_not_equal nil, @meta_board, "Community meta board not created"
        assert_not_equal nil, @text_board, "Community text board not created"
        assert_not_equal nil, @translation_board, "Community translation board not created"
        #assert false, @translation_board.title +  " is the name of the board." + @translation_board.community_id.to_s + " rank is " + @translation_board.rank.to_s
        #assert false, @meta_board.title +  " is the name of the meta board." + @meta_board.community_id.to_s + " rank is " + @meta_board.rank.to_s
        
        assert_not_equal nil, @test_community, "Community not created"
        #assert false, @test_community.name
    end
=end      
      
     should "user creates and submits publication to community"  do
       Rails.logger.info "BEGIN TEST: user creates and submits publication to community"
=begin       
       choices = "Choices: "
       @meta_board.decrees.each do |d|
         choices = choices + d.choices.to_s
       end
       assert false, choices
=end

       assert_not_equal nil, @test_community, "Community not created"
      
       
       
       
              
       
       
       #create a publication with a session
       open_session do |publication_session|
        Rails.logger.info "---Create A New Publication---"
         publication_session.post 'publications/create_from_templates' + '?test_user_id=' + @creator_user.id.to_s
              
         Rails.logger.info "--flash is: " + publication_session.flash.inspect
         
         @publication = @creator_user.publications.first
         
         output_publication_info(@publication)
       end
       

       
       #create a publication

      # Rails.logger.info "---Create A New Publication---"
      # @publication = Publication.new_from_templates(@creator_user)
       
      # @publication.reload
       
       Rails.logger.info "---Publication Created---"
       Rails.logger.info  "--identifier count is: " + @publication.identifiers.count.to_s
       
       an_array = @publication.identifiers
       Rails.logger.info  "--identifier length via array is: " + an_array.length.to_s
       
       Rails.logger.info "---Identifiers for publication " + @publication.title + " are:"
       
       @publication.identifiers.each do |pi|
         Rails.logger.info "-identifier-"
         Rails.logger.info "title is: " +  pi.title 
         Rails.logger.info "was it modified?: " + pi.modified?.to_s
         Rails.logger.info "xml:"
         Rails.logger.info pi.xml_content
       end
       
       
       #submit to community
       #set community id (this would normally be done via the controller)
       @publication.community_id =  @test_community.id
       @publication.save
       
       @publication.reload
       @publication.submit
       
       Rails.logger.info "Community is " + @test_community.name
       
       
       #now meta should have it
       assert_equal "submitted", @publication.status, "Publication status not submitted " + @publication.community_id.to_s + " id "
      
       #meta board should have 1 publication, others should have 0
       meta_publications = Publication.find(:all, :conditions => { :owner_id => @meta_board.id, :owner_type => "Board" } )
       assert_equal 1, meta_publications.length, "Meta does not have 1 publication but rather, " + meta_publications.length.to_s + " publications"
       
       text_publications = Publication.find(:all, :conditions => { :owner_id => @text_board.id, :owner_type => "Board" } )
       assert_equal 0, text_publications.length, "Text does not have 0 publication but rather, " + text_publications.length.to_s + " publications"
       
       translation_publications = Publication.find(:all, :conditions => { :owner_id => @translation_board.id, :owner_type => "Board" } )
       assert_equal 0, translation_publications.length, "Translation does not have 0 publication but rather, " + translation_publications.length.to_s + " publications"
       
         
      
       Rails.logger.info "Community Meta Board has publication" 
       #vote on it
       meta_publication = meta_publications.first 
       
       #assert_not_nil @publication.owner.repository.repo.get_head(@publication.branch), "creator repo head is nil"
       #assert_not_nil meta_publication.owner.repository.repo.get_head(meta_publication.branch), "meta repo head is nil"       
       
       #find meta identifier
       meta_identifier = nil
       meta_publication.identifiers.each do |id|
         if @meta_board.controls_identifier?(id)
            meta_identifier = id    
         end
       end
       
       assert_not_nil  meta_identifier, "Did not find the meta identifier"
       
       Rails.logger.info "Found meta identifier, will vote on it"

=begin       
       @meta_vote = Factory(:vote,
              :publication_id => meta_identifier.publication.id,
              :identifier_id => meta_identifier.id,
              :user => @board_user,
              :board => @meta_board,
              :choice => "ok"
              )
=end       
 
=begin
       open_session do |meta_session|
         
       
       @meta_vote = Factory(:vote,
              :publication_id => meta_identifier.publication.id,
              :identifier_id => meta_identifier.id,
              :user => @board_user,
              :board => @meta_board,
              :choice => "ok"
              )
       
       
         meta_vote_comment = Factory(:comment, 
                 :comment => "I agree meta is great", 
                 :user_id => @board_user.id, 
                 :publication_id => meta_identifier.publication.id,
                 :identifier_id => meta_identifier.id, 
                 :reason => "vote" 
                )
         
         meta_session.post 'publications/vote/' + meta_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, :comment => meta_vote_comment

       end
=end
       
       open_session do |meta_session|

         meta_session.post 'publications/vote/' + meta_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, \
              :comment => { :comment => "I agree meta is great", :user_id => @board_user.id, :publication_id => meta_identifier.publication.id, :identifier_id => meta_identifier.id, :reason => "vote" }, \
              :vote => { :publication_id => meta_identifier.publication.id.to_s, :identifier_id => meta_identifier.id.to_s, :user_id => @board_user.id.to_s, :board_id => @meta_board.id.to_s, :choice => "ok" }
              
         Rails.logger.info "--flash is: " + meta_session.flash.inspect              
       end
              
       
       
       
       #reload the publication to get the vote associations to go thru?
       meta_publication.reload
       
       #Rails.logger.level = 0
=begin       
       Factory(:vote,
              :publication_id => meta_publication.id,
              :identifier_id => meta_identifier.id,
              :user => @board_user_2,
              :board => @meta_board,
              :choice => "ok"
              )
       assert_equal 2, meta_publication.votes.length, "no vote on publication" 
=end
       
       vote_str = "Votes on meta are: "
       meta_publication.votes.each do |v|
         vote_str = vote_str + v.choice
       end
       Rails.logger.info  vote_str
       #assert false, vote_str
       
=begin      
       Rails.logger.info "Repo heads for meta board publication are:"
       @creator_user.repository.repo.heads.each do |head|
         #head_list = head_list + head
         Rails.logger.info "head: " + head.name
       end
=end
       
       #vote should have changed publication to approved and put to finalizer
       assert_equal "approved", meta_publication.status, "Meta publication not approved after vote"
       Rails.logger.info "--Meta publication approved"
       
       
       #now finalizer should have it, only one person on board so it should be them
       finalizer_publications = @board_user.publications
       meta_final_publication = finalizer_publications.first
       assert_equal meta_final_publication.status, "finalizing", "Board user's publication is not for finalizing"
       Rails.logger.info "---Finalizer has publication"
       
       #todo fixme just use this to get publiction.  meta_publication.find_finalizer_publication
       
       #call finalize on publication controller
       #publication_controller.finalize only needs publication id and optional comment
       
=begin       
       #s = open_session# do |s|
        open_session do |s|
        #@current_user = @board_user
         
         #s.get '/testing_session', :key=>'user_id', :value=> @board_user.id
         
        # Rails.logger.info "--Sign In--"
        # Rails.logger.info s.body
         
         
          
         # s.session.data[:user_id] = @board_user.id
         #s.session.data[:user_info] = @board_user.id
         
         
         
         meta_final_comment = Factory(:comment, 
                 :comment => "this meta is great", 
                 :user_id => @board_user.id, 
                 :identifier_id => meta_final_publication.identifiers.first.id,   #this may not be the correct value 
                 :reason => "finalize", 
                 :publication_id => meta_final_publication.id
                )
         
          s.post 'publications/' + meta_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, :comment => meta_final_comment
        # Rails.logger.info "--flash is: " + s.flash
         Rails.logger.info "----session data is: " + s.session.data.inspect
         
         Rails.logger.info s.body
       
         
       end
=end       
       open_session do |meta_finalize_session|

        meta_finalize_session.post 'publications/' + meta_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
          :comment => 'I agree meta is great and now it is final'
     
         Rails.logger.info "--flash is: " + meta_finalize_session.flash.inspect
         Rails.logger.info "----session data is: " + meta_finalize_session.session.data.inspect       
         Rails.logger.info meta_finalize_session.body

       end       
       
       
       
=begin
       Rails.logger.info "------------DOING REQUEST-----------"
       @request = ActionController::TestRequest.new
       @request.session[:user_id] = @board_user.id
       
       Rails.logger.info "BODY"
       Rails.logger.info @request.body
   
       @current_user = @board_user
        
       
       post 'publications/' + meta_final_publication.id.to_s + '/finalize'
      
       #assert false, flash[:notice]
=end
       
       meta_final_publication.reload
       assert_equal "finalized", meta_final_publication.status, "Meta final publication not finalized"
       
       
       Rails.logger.info "Meta committed"
       #meta_final_publication.finalize


       #compare the publications
       #final should have comments and votes
       
       meta_publication.reload
       output_publication_info(meta_publication)
       meta_final_publication.reload
       output_publication_info(meta_final_publication)
       Rails.logger.info "Compare board with board publication"
       compare_publications(meta_publication, meta_publication)
       Rails.logger.info "Compare board with finalizer publication"
       compare_publications(meta_publication, meta_final_publication)
       Rails.logger.info "Compare user with finalizer publication"
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
       
       Rails.logger.info "Found text identifier, will vote on it"
       
=begin       
       @text_vote = Factory(:vote,
              :publication_id => text_identifier.publication.id,
              :identifier_id => text_identifier.id,
              :user => @board_user,
              :board => @text_board,
              :choice => "ok"
              )
=end
       open_session do |text_session|

         text_session.post 'publications/vote/' + text_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, \
              :comment => { :comment => "I agree text is great", :user_id => @board_user.id, :publication_id => text_identifier.publication.id, :identifier_id => text_identifier.id, :reason => "vote" }, \
              :vote => { :publication_id => text_identifier.publication.id.to_s, :identifier_id => text_identifier.id.to_s, :user_id => @board_user.id.to_s, :board_id => @text_board.id.to_s, :choice => "ok" }
              
         Rails.logger.info "--flash is: " + text_session.flash.inspect              
       end
       
       
       
       #reload the publication to get the vote associations to go thru?
       text_publication.reload
       
       
       #vote should have changed publication to approved and put to finalizer
       assert_equal "approved", text_publication.status, "Text publication not approved after vote"
       Rails.logger.info "--Text publication approved"
       
       
       #now finalizer should have it, only one person on board so it should be them
       finalizer_publications = @board_user.publications
       assert_equal 2, finalizer_publications.length, "Finalizer does not have a new (text) publication to finalize"

       text_final_publication = text_publication.find_finalizer_publication
       assert_not_nil text_final_publication, "Publicaiton does not have text finalizer"
       Rails.logger.info "---Finalizer has text publication"

=begin
        open_session do |s| 
                   
        text_final_comment = Factory(:comment, 
                 :comment => "this text is great", 
                 :user_id => @board_user.id, 
                 :identifier_id => text_final_publication.identifiers.first.id,   #this may not be the correct value 
                 :reason => "finalize", 
                 :publication_id => text_final_publication.id
                )
         
         s.post 'publications/' + text_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, :comment => text_final_comment
         Rails.logger.info "----session data from text finalize is: " + s.session.data.inspect
         
         Rails.logger.info s.body
       
         
       end
=end       
       
       open_session do |text_finalize_session|

        text_finalize_session.post 'publications/' + text_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
          :comment => 'I agree text is great and now it is final'
     
         Rails.logger.info "--flash is: " + text_finalize_session.flash.inspect
         Rails.logger.info "----session data from text finalize is:" + text_finalize_session.session.data.inspect       
         Rails.logger.info text_finalize_session.body

         Rails.logger.info "--flash is: " + text_finalize_session.flash.inspect      
       end
       
       
        
       text_final_publication.reload
       assert_equal "finalized", meta_final_publication.status, "Text final publication not finalized"
       
       Rails.logger.info "---Text publication Finalized"

      
      current_creator_publication = @creator_user.publications.first
      current_creator_publication.reload
      
      output_publication_info (current_creator_publication )
      
      meta_final_publication.reload
      output_publication_info (meta_final_publication)
       
       #assert_equal @meta_board.publications.first.origin, @publication, "Meta board does not have publications"
       @publication.destroy
       
       Rails.logger.info "ENDED TEST: user creates and submits publication to community"
     end
      
      def compare_publications(a,b)
        
        pubs_are_matched = true
        a.identifiers.each do |aid|
          id_has_match = false
          b.identifiers.each do |bid|
            if (aid.class.to_s == bid.class.to_s && aid.title == bid.title)
              if (aid.xml_content == bid.xml_content)
                id_has_match = true
                Rails.logger.info "Identifier match found"
              else
                if aid.xml_content == nil
                  Rails.logger.info a.title + " has nill " + aid.class.to_s + " identifier"
                end
                if bid.xml_content == nil
                  Rails.logger.info b.title + " has nill " + bid.class.to_s + " identifier"
                end
                Rails.logger.info "Identifier diffs for " + a.title + " " + b.title + " " + aid.class.to_s + " " +  aid.title
                log_diffs(aid.xml_content.to_s, bid.xml_content.to_s )
                #Rails.logger.info "full xml a " + aid.xml_content
                #Rails.logger.info "full xml b " + bid.xml_content
              
              end
            end
          
          end
          
          if !id_has_match
            pubs_are_matched = false
            Rails.logger.info "--Mis matched publication. Id " + aid.title + " " + aid.class.to_s + " is different"
            
          end
        
        end
        
        
        if pubs_are_matched
          Rails.logger.info "Publications are matched"  
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
        
        Rails.logger.info "added " + plus_str
        Rails.logger.info "removed " + minus_str
        
      end
      
      def output_publication_info(publication)
        Rails.logger.info "-----Publication Info-----"
        Rails.logger.info "--Owner: " + publication.owner.name
        Rails.logger.info "--Title: " + publication.title
        Rails.logger.info "--Status: " + publication.status
        Rails.logger.info "--content"
        
        publication.identifiers.each do |id|
          Rails.logger.info "---ID title: " + id.title
          Rails.logger.info "---ID class:" + id.class.to_s
          Rails.logger.info "---ID content:"
          if id.xml_content
            Rails.logger.info id.xml_content
          else
            Rails.logger.info "NO CONTENT!"
          end
          #Rails.logger.info "== end Owner: " + publication.owner.name
        end
        Rails.logger.info "==end Owner: " + publication.owner.name
        Rails.logger.info "=====End Publication Info====="
      end
      
      
    end
    
    
  end
  context "for IDP2" do
    setup do
      @ddb_board = Factory(:board, :title => 'DDbDP Editorial Board')
    
      3.times do |i|
        @ddb_board.users << Factory(:user)
      end
      
      Factory(:percent_decree,
              :board => @ddb_board,
              :trigger => 50.0,
              :action => "approve",
              :choices => "yes no defer")
      Factory(:percent_decree,
              :board => @ddb_board,
              :trigger => 50.0,
              :action => "reject",
              :choices => "reject")
      Factory(:count_decree,
              :board => @ddb_board,
              :trigger => 1.0,
              :action => "graffiti",
              :choices => "graffiti")
      
      @james = Factory(:user, :name => "James")
      
      @hgv_meta_board = Factory(:hgv_meta_board, :title => 'HGV metadata')
      @hgv_trans_board = Factory(:hgv_trans_board, :title => 'Translations')
      
      @hgv_meta_board.users << @james
      @hgv_trans_board.users << @james
      
      @submitter = Factory(:user, :name => "Submitter")
    end
    
    teardown do
      ( @ddb_board.users + [ @james, @submitter,
        @ddb_board, @hgv_meta_board, @hgv_trans_board ] ).each {|entity| entity.destroy}
    end
    
    def generate_board_vote_for_decree(board, decree, identifier, user)
      Factory(:vote,
              :publication_id => identifier.publication.id,
              :identifier_id => identifier.id,
              :user => user,
              :choice => (decree.get_choice_array)[rand(
                decree.get_choice_array.size)])
    end
    
    
    def generate_board_votes_for_action(board, action, identifier)
      decree = board.decrees.detect {|d| d.action == action}
      vote_count = 0
      if decree.tally_method == Decree::TALLY_METHODS[:percent]
        while (((vote_count.to_f / decree.board.users.length)*100) < decree.trigger) do
          generate_board_vote_for_decree(board, decree, identifier, board.users[vote_count])
          vote_count += 1
        end
      elsif decree.tally_method == Decree::TALLY_METHODS[:count]
        while (vote_count.to_f < decree.trigger) do
          generate_board_vote_for_decree(board, decree, identifier, board.users[vote_count])
          vote_count += 1
        end
      end
    end

    context "a publication" do
      setup do
        @publication = Factory(:publication, :owner => @submitter, :creator => @submitter, :status => "new")
        
        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master
      end
      
      teardown do
        @publication.destroy
      end
      
      context "submitted with only DDB modifications" do
        setup do
          @new_ddb = DDBIdentifier.new_from_template(@publication)
          @publication.reload
          @publication.submit
        end
        
        should "be copied to the DDB board" do
          assert_equal @publication, @ddb_board.publications.first.parent
          assert_equal @publication.children, @ddb_board.publications
          assert_equal @ddb_board, @publication.children.first.owner
        end

        should "not be copied to the HGV boards" do
          assert_equal 0, @hgv_meta_board.publications.length
          assert_equal 0, @hgv_trans_board.publications.length
        end
        
        context "voted 'approve'" do
          setup do
            @new_ddb_submitted = @ddb_board.publications.first.identifiers.first
            generate_board_votes_for_action(@ddb_board, "approve", @new_ddb_submitted)
          end
          
          should "have two 'approve' votes" do
            assert_equal 2, @new_ddb_submitted.votes.select {|v| %{yes no defer}.include?(v.choice)}.length
          end
          
          should "be copied to a finalizer" do
            assert_equal 1, @ddb_board.publications.first.children.length
            finalizing_publication = @ddb_board.publications.first.children.first
            assert_equal "finalizing", finalizing_publication.status
            assert_equal User, finalizing_publication.owner.class
          end
        end # approve
        
        context "voted 'reject'" do
          setup do
            @new_ddb_submitted = @ddb_board.publications.first.identifiers.first
            generate_board_votes_for_action(@ddb_board, "reject", @new_ddb_submitted)
          end

          should "have two 'reject' vote comments" do
            # assert_equal 2, @new_ddb_submitted.votes.select {|v| %{reject}.include?(v.choice)}.length
          end

          should "be copied back to the submitter" do
          end
          
          should "be deleted from editorial board" do
            assert !Publication.exists?(@new_ddb_submitted.id)
          end
        end # reject
      end # DDB-only
    end
  end
end
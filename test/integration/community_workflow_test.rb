require 'test_helper'
require 'ddiff'

#require File.dirname(__FILE__) + '/session_set_controller'

class CommunityWorkflowTest < ActionController::IntegrationTest
  context "for community" do

=begin
    
    should "be a test result of somesort" do
      
      assert_equal 5, 7
    end
=end
    
    context "community testing" do
      setup do
        Rails.logger.level = :debug
        Rails.logger.debug "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx community testing setup xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        Rails.logger.debug "*************are we in debug mode***************"
        #a user to put on the boards
        @board_user = Factory(:user, :name => "board_man_freaky_bob")
        @board_user_2 = Factory(:user, :name => "board_man_freaky_alice")   
        #a user to submit publications
        @creator_user = Factory(:user, :name => "creator_freaky_bob") 
        #an end user to recieve the "finalized" publication
        @end_user = Factory(:user, :name => "end_freaky_bob")
        
        @community_user = Factory(:user, :name => "community_freaky_bob")
        
        @trash_user = Factory(:user, :name => "just_to_make_another_publication")
        
        #set up the community
        @test_community = Factory(:community, 
                                  :name => "test_freaky_community", 
                                  :friendly_name => "testy", 
                                  :abbreviation => "tc", 
                                  :description => "a comunity for testing"
                                  )
        @test_community.members << @community_user
        @test_community.end_user_id = @end_user.id
        @test_community.save
        
        
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

        Rails.logger.debug "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz community testing setup complete zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
      end
      
      teardown do
        Rails.logger.debug "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx community testing teardown begin xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
begin        
        
        count = 0
        [ @board_user, @board_user_2, @creator_user, @end_user, @community_user, @trash_user, @meta_board, @text_board, @translation_board, @test_community ].each do |entity| 
          count = count + 1
          #assert_not_equal entity, nil, count.to_s + " cant be destroyed since it is nil." 
          unless entity.nil?
            entity.destroy
          end
        end
end
        Rails.logger.debug "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz community testing teardown complete zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
      end
 

     should "user creates and submits publication to community"  do
       Rails.logger.debug "BEGIN TEST: user creates and submits publication to community"      

Rails.logger.debug "---Meta board controlls: "
@meta_board.identifier_classes.each do |mic|
  Rails.logger.debug mic
end

       assert_not_equal nil, @test_community, "Community not created"
       
      assert_not_nil @trash_user, "No Trash user created"
        #for testing create a publication so the next one will be another number create a publication with a session
       open_session do |trash_publication_session|
        Rails.logger.debug "---Create A New Trash Publication---"
         trash_publication_session.post 'publications/create_from_templates' + '?test_user_id=' + @trash_user.id.to_s
              
         Rails.logger.debug "--flash is: " + trash_publication_session.flash.inspect
         
         @trash_publication = @trash_user.publications.first
         
         @trash_publication.log_info
       end



       #create a publication with a session
       open_session do |publication_session|
        Rails.logger.debug "---Create A New Publication---"
         publication_session.post 'publications/create_from_templates' + '?test_user_id=' + @creator_user.id.to_s
              
         Rails.logger.debug "--flash is: " + publication_session.flash.inspect
         
         @publication = @creator_user.publications.first
         
         @publication.log_info
       end
       
       #create a publication
       
       #Rails.logger.debug "---Publication Created---"
       #Rails.logger.debug  "--identifier count is: " + @publication.identifiers.count.to_s
       
       #an_array = @publication.identifiers
       #Rails.logger.debug  "--identifier length via array is: " + an_array.length.to_s
       
       Rails.logger.debug "---Identifiers for publication " + @publication.title + " are:"
       
       @publication.identifiers.each do |pi|
         Rails.logger.debug "-identifier-"
         Rails.logger.debug "title is: " +  pi.title 
         Rails.logger.debug "was it modified?: " + pi.modified?.to_s
        # Rails.logger.debug "xml:"
        # Rails.logger.debug pi.xml_content
       end
       
       
       #submit to community
       #set community id (this would normally be done via the controller)
       #@publication.community_id =  @test_community.id
       #@publication.save
       
       #@publication.reload
       #@publication.submit
       
       
       Rails.logger.debug "---Submit Publication---"
       open_session do |submit_session|

         submit_session.post 'publications/' + @publication.id.to_s + '/submit/?test_user_id=' + @creator_user.id.to_s, \
              :submit_comment => "I made a new pub", :community => { :id => @test_community.id.to_s }
              
         Rails.logger.debug "--flash is: " + submit_session.flash.inspect              
       end
       @publication.reload       
       
       Rails.logger.debug "---Publication Submitted to Community: " + @publication.community.name
       
       #Rails.logger.debug "Community is " + @test_community.name
        
       
       #now meta should have it
       assert_equal "submitted", @publication.status, "Publication status not submitted " + @publication.community_id.to_s + " id "
      
       Rails.logger.debug "---Publication Submitted---"
       #meta board should have 1 publication, others should have 0
       meta_publications = Publication.find(:all, :conditions => { :owner_id => @meta_board.id, :owner_type => "Board" } )
       assert_equal 1, meta_publications.length, "Meta does not have 1 publication but rather, " + meta_publications.length.to_s + " publications"
       
       text_publications = Publication.find(:all, :conditions => { :owner_id => @text_board.id, :owner_type => "Board" } )
       assert_equal 0, text_publications.length, "Text does not have 0 publication but rather, " + text_publications.length.to_s + " publications"
       
       translation_publications = Publication.find(:all, :conditions => { :owner_id => @translation_board.id, :owner_type => "Board" } )
       assert_equal 0, translation_publications.length, "Translation does not have 0 publication but rather, " + translation_publications.length.to_s + " publications"
       
         
      
       Rails.logger.debug "Community Meta Board has publication" 
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
       
       Rails.logger.debug "Found meta identifier, will vote on it"

       open_session do |meta_session|

         meta_session.post 'publications/vote/' + meta_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, \
              :comment => { :comment => "I vote to agree meta is great", :user_id => @board_user.id, :publication_id => meta_identifier.publication.id, :identifier_id => meta_identifier.id, :reason => "vote" }, \
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
  
       
       #vote should have changed publication to approved and put to finalizer
       assert_equal "approved", meta_publication.status, "Meta publication not approved after vote"
       Rails.logger.debug "--Meta publication approved"
       
       
       #now finalizer should have it, only one person on board so it should be them
       #finalizer_publications = @board_user.publications
       #meta_final_publication = finalizer_publications.first

       meta_final_publication = meta_publication.find_finalizer_publication
       
       assert_equal meta_final_publication.status, "finalizing", "Board user's publication is not for finalizing"
       Rails.logger.debug "---Meta Finalizer has publication"
       

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
       #meta_final_publication.finalize


       #compare the publications
       #final should have comments and votes
       Rails.logger.debug "++++++++USER PUBLICATION++++++"
       @creator_user.publications.first.log_info
       
       meta_publication.reload
       Rails.logger.debug "++++++++meta BOARD PUBLICATION++++++"
       meta_publication.log_info
       
       meta_final_publication.reload
       Rails.logger.debug "++++++++meta FINAL PUBLICATION++++++"
       meta_final_publication.log_info
       
       Rails.logger.debug "Compare board with board publication"
       compare_publications(meta_publication, meta_publication)
       Rails.logger.debug "Compare board with finalizer publication"
       compare_publications(meta_publication, meta_final_publication)
       
       
       Rails.logger.debug "Compare user with meta finalizer publication"
       compare_publications(@creator_user.publications.first, meta_final_publication)


       end_publication = @end_user.publications.first
       assert_nil end_publication, "--Community end user has a publication before they should (after meta has been finalized)"
       
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
              :comment => { :comment => "I vote since I yippppppp agree text is great", :user_id => @board_user.id, :publication_id => text_identifier.publication.id, :identifier_id => text_identifier.id, :reason => "vote" }, \
              :vote => { :publication_id => text_identifier.publication.id.to_s, :identifier_id => text_identifier.id.to_s, :user_id => @board_user.id.to_s, :board_id => @text_board.id.to_s, :choice => "ok" }
              
         Rails.logger.debug "--flash is: " + text_session.flash.inspect              
       end
       
       
       
       #reload the publication to get the vote associations to go thru?
       text_publication.reload
       
       
       #vote should have changed publication to approved and put to finalizer
       assert_equal "approved", text_publication.status, "Text publication not approved after vote"
       Rails.logger.debug "--Text publication approved"
       
       
       #now finalizer should have it, only one person on board so it should be them
       finalizer_publications = @board_user.publications
       assert_equal 2, finalizer_publications.length, "Finalizer does not have a new (text) publication to finalize"

       text_final_publication = text_publication.find_finalizer_publication
       assert_not_nil text_final_publication, "Publicaiton does not have text finalizer"
       Rails.logger.debug "---Finalizer has text publication"

       
       open_session do |text_finalize_session|

        text_finalize_session.post 'publications/' + text_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
          :comment => 'I agree woooooooo text is great and now it is final'
     
         Rails.logger.debug "--flash is: " + text_finalize_session.flash.inspect
         Rails.logger.debug "----session data from text finalize is:" + text_finalize_session.session.to_hash.inspect       
         Rails.logger.debug text_finalize_session.body

         Rails.logger.debug "--flash is: " + text_finalize_session.flash.inspect      
       end
       
       
        
       text_final_publication.reload
       assert_equal "finalized", meta_final_publication.status, "Text final publication not finalized"
       
       Rails.logger.debug "---Text publication Finalized"

      
      current_creator_publication = @creator_user.publications.first
      current_creator_publication.reload
      
      current_creator_publication.log_info
      
      meta_final_publication.reload
      meta_final_publication.log_info
      
      #text_final_publication.reload
      text_final_publication.log_info
      
      Rails.logger.debug "Compare user with text finalizer publication"
      compare_publications(@creator_user.publications.first, text_final_publication)

       
       
       #check that end user now has the publication
       end_publication = @end_user.publications.first
       assert_not_nil end_publication, "--Community end user has no publications"
       #assert_equal @meta_board.publications.first.origin, @publication, "Meta board does not have publications"
       
       compare_publications(@creator_user.publications.first, @end_user.publications.first)
       @publication.destroy
       
       Rails.logger.debug "ENDED TEST: user creates and submits publication to community"
     end
      
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
            Rails.logger.debug "--Mis matched publication. Id " + aid.title + " " + aid.class.to_s + " are different"
            
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
  
end
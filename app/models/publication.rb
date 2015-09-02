# encoding: utf-8

#A publication is the basic object of the editorial workflow. The publication consists of a collection of identifiers.
#The publication has a branch which contains the identifiers.
#A user creates a publication. Modifies the publication and submits it to the boards.
#Each board will get a copy of the user's publication (the origin publication) to work with.
#Upon approval, the finalizer will receive a copy of the publication to work with.
#The finalizer's, and board's copies are all children of the origin copy.
#
#This class contains many of the methods that controls the workflow for the publication.
#Examples are:
#- publicaiton creation
#- copying of a publication
#- changeing the status of a publication
#- determining which board examines the publication
#- determining voting outcome
#- commiting to canon


require 'jgit_tree'
require 'shellwords'

class Publication < ActiveRecord::Base


  PUBLICATION_STATUS = %w{ new editing submitted approved finalizing committed archived }

  validates_presence_of :title, :branch

  belongs_to :creator, :polymorphic => true
  belongs_to :owner, :polymorphic => true

  belongs_to :community

  has_many :children, :class_name => 'Publication', :foreign_key => 'parent_id'
  belongs_to :parent, :class_name => 'Publication'

  has_many :identifiers, :dependent => :destroy
  has_many :events, :as => :target, :dependent => :destroy
  has_many :votes, :dependent => :destroy
  has_many :comments

  validates_uniqueness_of :title, :scope => [:owner_type, :owner_id, :status]
  validates_uniqueness_of :branch, :scope => [:owner_type, :owner_id]

  validates_each :branch do |model, attr, value|
    # Excerpted from git/refs.c:
    # Make sure "ref" is something reasonable to have under ".git/refs/";
    # We do not like it if:
    if value =~ /^\./ ||    # - any path component of it begins with ".", or
       value =~ /\.\./ ||   # - it has double dots "..", or
       value =~ /[~^: ]/ || # - it has [..], "~", "^", ":" or SP, anywhere, or
       value =~ /\/$/ ||    # - it ends with a "/".
       value =~ /\.lock$/   # - it ends with ".lock"
      model.errors.add(attr, "Branch \"#{value}\" contains illegal characters")
    end
    # not yet handling ASCII control characters
  end

  scope :other_users, lambda{ |title, id| {:conditions => [ "title = ? AND creator_id != ? AND ( status = 'editing' OR status = 'submitted' )", title, id] }        }

  #inelegant way to pass this info, but it works
  attr_accessor :recent_submit_sha

  def print
    # get preview of each identifier
    tmp = {}
    identifiers.each{|identifier|
      tmp[identifier.class.to_s.to_sym] = identifier.preview({'meta-style' => 'sammelbuch', 'leiden-style' => 'ddbdp'}, %w{data xslt epidoc start-odf.xsl})
    }

    Rails.logger.info('---------------DDB xml ---------------------')

    Rails.logger.info tmp[:DDBIdentifier].to_s

    Rails.logger.info('------------------------------------')

    #merge xml
    meta = REXML::Document.new tmp[:HGVMetaIdentifier]
    text = REXML::Document.new tmp[:DDBIdentifier]

    Rails.logger.info('---------------DDB xml document---------------------')

    Rails.logger.info text.elements["//office:document-content/office:body/office:text"].to_s

    Rails.logger.info('------------------------------------')

    elder = meta.elements["//office:document-content/office:body/office:text/text:p[@text:style-name='Sammelbuch-Kopf']"]
    text.elements["//office:document-content/office:body/office:text"].each_element {|text_element|

    Rails.logger.info('**** found['+text_element.class.inspect+']')

      meta.elements["//office:document-content/office:body/office:text"].insert_after(elder, text_element)
      elder = text_element

    }

    # output string
    formatter = REXML::Formatters::Default.new
    #formatter.compact = true
    #formatter.width = 512
    xml = ''
    formatter.write meta, xml

    xml
  end

  #Populates the publication's list of identifiers.
  #Input identifiers can be in the form of
  # * an array of strings such as: papyri.info/ddbdp/bgu;7;1504
  # * a single string such as: papyri.info/ddbdp/bgu;7;1504
  #publication title is named using first identifier
  def populate_identifiers_from_identifiers(identifiers, original_title = nil)

    self.repository.update_master_from_canonical
    # Coming in from an identifier, build up a publication
    if identifiers.class == String
      # have a string, need to build relation
      identifiers = NumbersRDF::NumbersHelper.identifier_to_identifiers(identifiers)
    end

    if identifiers.class == Array
      #identifiers is now an array of strings like:  papyri.info/ddbdp/bgu;7;1504
      identifiers = NumbersRDF::NumbersHelper.identifiers_to_hash(identifiers)
    end
    # identifiers is now (or was always) a hash with IDENTIFIER_NAMESPACE (hgv, tm, ddbdp etc)
    # as the keys and the string papyri.info/ddbdp/bgu;7;1504 as the value


    #title is first identifier in list
    #but added the option to set the title to whatever the caller wants
    if nil == original_title
      original_title = identifier_to_ref(identifiers.values.flatten.first)
    else
      original_was_nil = true;
    end
    self.title = original_title

    Sosol::Application.config.site_identifiers.split(",").each do |identifier_name|

      ns = identifier_name.constantize::IDENTIFIER_NAMESPACE
      if identifiers.has_key?(ns)
        identifiers[ns].each do |identifier_string|
          identifier_class = Object.const_get(identifier_name)
          temp_id = identifier_class.new(:name => identifier_string)
          # make sure we have a path on master before forking it for this publication
          unless (self.repository.get_file_from_branch(temp_id.to_path, 'master').blank?)
            # 2012-09-17 BALMAS it might be good to have an option to raise an error if we couldn't
            # branch from the master repo? But not for optional secondary identifiers (e.g. annotations)?
            self.identifiers << temp_id
            if ( self.title == original_title )
              self.title = temp_id.titleize
            end
          end # if master blank?
        end # do
      end # if
    end # do

    #reset the title to what the caller wants
    if original_was_nil
      self.title = original_title
    end
    # Use HGV hack for now
    # if identifiers.has_key?('hgv') && identifiers.has_key?('trismegistos')
    #   identifiers['trismegistos'].each do |tm|
    #     tm_nr = NumbersRDF::NumbersHelper.identifier_to_components(tm).last
    #     self.identifiers << HGVMetaIdentifier.new(
    #       :name => "#{identifiers['hgv'].first}",
    #       :alternate_name => "hgv#{tm_nr}")
    #
    #     # Check if there's a trans, if so, add it
    #     translation = HGVTransIdentifier.new(
    #       :name => "#{identifiers['hgv'].first}",
    #       :alternate_name => "hgv#{tm_nr}"
    #     )
    #     if !(Repository.new.get_file_from_branch(translation.to_path).nil?)
    #       self.identifiers << translation
    #     end
    #   end
    # end
  end

  # If branch hasn't been specified, create it from the title before
  # validation, replacing spaces with underscore.
  # TODO: do a branch rename inside before_validation_on_update?
  before_validation do |publication|
    publication.branch ||= title_to_ref(publication.title)
  end

  # Should check the owner's repo to make sure the branch doesn't exist and halt if so
  before_create do |publication|
    if publication.owner.repository.branches.include?(publication.branch)
      return false
    end
  end

  after_destroy do |publication|
    publication.owner.repository.delete_branch(publication.branch)
  end

  #Outputs publication information and content to the Rails logger.
   def log_info
        Rails.logger.info "-----Publication Info-----"
        Rails.logger.info "--Owner: " + self.owner.name
        Rails.logger.info "--Title: " + self.title
        Rails.logger.info "--Status: " + self.status
        Rails.logger.info "--content"

        self.identifiers.each do |id|
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
        Rails.logger.info "==end Owner: " + self.owner.name
        Rails.logger.info "=====End Publication Info====="
    end


  #Examines publication to see which board the publication should be submitted to next.
  #Boards are sorted by rank. Each board, in order of rank, will check to see if they control any of the publication's modified and editing identifiers.
  #If so, then the publication is submitted to that board.
  #
  #When there are no more identifiers to be submitted, then the publication is marked as committed.
  def submit_to_next_board

    #note: all @recent_submit_sha conde here added because it was here before, not sure if this is still needed
    @recent_submit_sha = ''

    #determine which ids are ready to be submitted (modified, editing...)
    submittable_identifiers = identifiers.select { |id| id.modified? && (id.status == 'editing')}

    Rails.logger.info "---Submittable identifiers are: "
    submittable_identifiers.each do |log_si|
      Rails.logger.info "     " + log_si.class.to_s + "   " + log_si.title
    end


    #check if we are part of a community

    if is_community_publication?
      boards = Board.ranked_by_community_id( self.community.id )
    else
      boards = Board.ranked
    end

    #check each board in order by priority rank
    boards.each do |board|

    #if board.community == publication.community
    boards_identifiers = submittable_identifiers.select { |id| board.controls_identifier?(id) }
    if boards_identifiers.length > 0
      #submit to that board
      Rails.logger.info "---Submittable Board identifiers are: "
      boards_identifiers.each do |log_sbi|
        Rails.logger.info "     " + log_sbi.class.to_s + "   " + log_sbi.title
      end

      # submit each submitting_identifier
      boards_identifiers.each do |submitting_identifier|
            submitting_identifier.status = "submitted"
            submitting_identifier.save!

            #make the most recent sha for the identifier available...is this the one we want?
            @recent_submit_sha = submitting_identifier.get_recent_commit_sha
          end

          #copy the repo, models, etc... to the board
          boards_copy = copy_to_owner(board)
          boards_copy.status = "voting"
          boards_copy.save!



          #trigger emails
          board.send_status_emails("submitted", self)

          #update status on user copy
          self.change_status("submitted")
          self.save!

          #problem here in that comment will be added to the returned id, but there may be many ids.....
          #todo move where the comment is being placed, need to have discussion about where comments go 2-22-2010
          return '', boards_identifiers[0].id
        end
      #end
    end


    Rails.logger.debug " no more parts to submit "
    #if we get to this point, there are no more boards to submit to, thus we are done
    if is_community_publication?
      if self.community.end_user.nil?
        #no end user has been set, so warn them and then what?
        #user can't submit to community if no end user, so this should not happen

      else


        #copy to  space
        Rails.logger.debug "----end user to get it"
        Rails.logger.debug self.community.end_user.name

        #community_copy = copy_to_owner( self.community.end_user)
        community_copy = copy_to_end_user()
        community_copy.status = "editing"
        community_copy.identifiers.each do |id|
          id.status = "editing"
          id.save
        end
        #TODO may need to do more status setting ? ie will the modified identifiers and status be correctly set to allow resubmit by end user?

        #disconnect the parent/origin connections
        #community_copy.parent_id = nil
        community_copy.parent = nil

        #reset the community id to be sosol
        #leave as is   community_copy.community_id = nil

        #remove the original creator id (that info is now in the git history )
        community_copy.creator_id = community_copy.owner_id

        community_copy.save!

        #mark as committed
        self.origin.change_status("committed")
        self.save
      end

    else
      #mark as committed
      self.origin.change_status("committed")
      self.save
    end


    #TODO need to return something here to prevent flash error from showing true?
    return "", nil
  end

  def  is_community_publication?
    return (self.community_id != nil)  &&  (self.community_id != 0)
  end

  #Simply pointer to submit_to_next_board method.
  def submit
    submit_to_next_board
  end

  #Creates a new publication from templates found in app/data/templates. The new publication contains a DDBIdentifier and a HGVMetaIdentifier
  #
  #*Args*:
  #-+creator+ the user who will be the owner of the publication.
  #
  #*Returns*: the new publication consiting of a DDBIdentifier and an HGVMetaIdentifier
  def self.new_from_templates(creator)
    new_publication = Publication.new(:owner => creator, :creator => creator)

    # fetch a title without creating from template
    new_publication.title = DDBIdentifier.new(:name => DDBIdentifier.next_temporary_identifier).titleize

    new_publication.status = "new" #TODO add new flag else where or flesh out new status#"new"
    new_publication.save!

    # branch from master so we aren't just creating an empty branch
    new_publication.branch_from_master

    #create the required meta data and transcriptions
    new_ddb = DDBIdentifier.new_from_template(new_publication)
    new_hgv_meta = HGVMetaIdentifier.new_from_template(new_publication)

    # go ahead and create the third so we can get rid of the create button
    #new_hgv_trans = HGVTransIdentifier.new_from_template(new_publication)

    return new_publication
  end

  #*Returns*
  #- +true+ if any of the identifiers in the publication have been modified.
  #- +false+ if none of the identifiers in the publication have been modified.
  def modified?
    retval = false
    self.identifiers.each do |i|
      retval = retval || i.modified?
    end

    retval
  end

  #Determines if publication is in 'editing' status and is able to be changed
  #*Returns*
  #- +true+ if the publication should be changed by some user.
  #- +false+ otherwise.
  def mutable?
    if self.status != "editing" # && self.status != "new"
      return false
    else
      return true
    end
  end


  #*Args*
  #- +check_user+ see if the publication is mutable by this user.
  #*Returns*
  #- +true+ if the publication should be changed by some the user specifed by check_user.
  #- +false+ otherwise.
  def mutable_by?(check_user)
    if (((self.owner.class == Board) && !(self.owner.users.include?(check_user))) ||
        (check_user != self.owner)) &&
       (!(check_user.developer || check_user.admin))
      return false
    else
      return true
    end
  end

  # TODO: rename actual branch after branch attribute rename
  after_create do |publication|
  end

  #Sets the origin status for publication identifiers that this publication's board controls. Sets are made on the origin copy.
  #
  #*Args*
  #- +status_in+ the status to be set
  def set_origin_identifier_status(status_in)
      #finalizer is a user so they dont have a board, must go up until we find a board
      board = self.find_first_board
      if board

        self.identifiers.each do |i|
          if board.identifier_classes && board.identifier_classes.include?(i.class.to_s)
            i.origin.status = status_in
            i.origin.save
          end
        end

      end
  end


  #Sets the status for publication identifiers that this publication's board controls. Sets are made on the board's copy.
  #
  #*Args*
  #- +status_in+ the status to be set
  def set_local_identifier_status(status_in)

      board = self.find_first_board
      if board

        self.identifiers.each do |i|
          if board.identifier_classes && board.identifier_classes.include?(i.class.to_s)
            i.status = status_in
            i.save
          end
        end

      end
  end

  #Convenience method to combine  set_origin_identifier_status & set_local_identifier_status methods.
  def set_origin_and_local_identifier_status(status_in)
    set_origin_identifier_status(status_in)
    set_local_identifier_status(status_in)
  end

  #Sets the board's publication identifier status. This is used when the finalizer's copy needs to change the board's copy.
  def set_board_identifier_status(status_in)
      pub = self.find_first_board_parent
      if pub
        pub.identifiers.each do |i|
          if pub.owner.identifier_classes && pub.owner.identifier_classes.include?(i.class.to_s)
            i.status = status_in
            i.save
          end
        end
      end
  end


  def change_status(new_status)
    Rails.logger.info("change_status to #{new_status} for #{self.inspect}")
    if (self.status != new_status) && !(self.head.nil?)
      old_branch_name = self.branch
      old_branch_leaf = old_branch_name.split('/').last
      new_branch_components = [old_branch_leaf]

      unless new_status == 'editing'
        new_branch_components.unshift(new_status, Time.now.strftime("%Y/%m/%d"))
      end

      if self.parent && (self.parent.owner.class == Board)
        new_branch_components.unshift(title_to_ref(self.parent.owner.title))
      end

      new_branch_name = new_branch_components.join('/')

      # prevent collisions
      if self.owner.repository.branches.include?(new_branch_name)
        new_branch_name += Time.now.strftime("-%H.%M.%S")
      end

      # wrap changes in transaction, so that if git activity raises an exception
      # the corresponding db changes are rolled back
      self.transaction do
        # set to new branch
        self.branch = new_branch_name
        # set status to new status
        self.status = new_status
        begin
          self.save!
        rescue ActiveRecord::RecordInvalid
          self.title += self.created_at.strftime(" (%Y/%m/%d-%H.%M.%S)")
          self.save!
        end
        # save succeeded, so perform actual git change
        # branch from the original branch
        self.owner.repository.create_branch(new_branch_name, old_branch_name)
        # delete the original branch
        self.owner.repository.delete_branch(old_branch_name)
      end
    end
  end

  #Sets the status to archived and renames the title with the date-time to prevent future title collisions.
  def archive
    self.change_status("archived")

    self.title = self.title + Time.now.strftime(" (%Y/%m/%d-%H.%M.%S)")
    self.save!
  end

  #Determines if the user has voted on this publication.
  #
  #*Args*
  #- +user_id+ the id for the user whose voting record we wish to test
  #*Returns*
  #- +true+ if the user for the given user_id has voted on this publication
  #- +false+ if the user for the given user_id has not voted on this publication
  def user_has_voted?(user_id)
    if self.votes
      self.votes.each do |vote|
        if vote.user_id == user_id
          return true #user has a vote on record for this publication
        end
      end
    end
    #no vote found
    return false
  end

  #This is where the main action takes place for deciding how votes are organized and what happens for vote results.
  #
  #*Args*
  #- +user_votes+ the votes to be tallied. By default, the publicaiton's own votes are used.
  #*Returns*
  #- +decree_action+ determined by the vote tally or +nil+ if no decree is triggered by the tally.
  #*Effects*
  #- Calls methods and sets status based on vote tally. See implementation for details.
  def tally_votes(user_votes = nil)
    user_votes ||= self.votes #use the publication's votes
    #here is where the action is for deciding how votes are organized and what happens for vote results
    #as of 3-11-2011 the votes are set on the identifier where the user votes & on the publication
    #once a user has voted on any identifier of a publication, then they can no longer vote on the publication
    #vote action is determined by votes on the publication
    #any modified identifiers that the board controlls will have the change desc added.
    #Future changes may be made here if the voting logic is to be separated per identifier

    #check that we are still taking votes
    if self.status != "voting"
      Rails.logger.warn("Publication#tally_votes for #{self.id} does not have status 'voting'")
      return "" #return nothing and do nothing since the voting is now over
    end

    #need to tally votes and see if any action will take place
    if self.owner_type != "Board" # || !self.owner #make sure board still exist...add error message?
      Rails.logger.warn("Publication#tally_votes for #{self.id} not owned by a Board")
      return "" #another check to make sure only the board is voting on its copy
    else
      decree_action = self.owner.tally_votes(user_votes) #since board has decrees let them figure out the vote results
    end

    Rails.logger.info("Publication#tally_votes for #{self.id} got decree_action #{decree_action}")

    # create an event if anything happened
    if !decree_action.nil? && decree_action != ''
      e = Event.new
      e.owner = self.owner
      e.target = self
      e.category = "marked as \"#{decree_action}\""
      e.save!
    end

  #----approve-----
    if decree_action == "approve"

      #set status
      self.status = "approved_pending"
      self.save
      self.set_origin_and_local_identifier_status("approved")

      #send emails
      self.owner.send_status_emails("approved", self)

      self.change_status("approved")

      #set up for finalizing
      SendToFinalizerJob.new.async.perform(self.id)
  #----reject-----
    elsif decree_action == "reject"

      #set status
      self.origin.change_status("editing")
      self.set_origin_and_local_identifier_status("editing")

      #send emails
      self.owner.send_status_emails("rejected", self)

      #do we want to copy ours back to the user?
      #TODO add copy to user
      #NOTE since they decided not to let editors edit we don't need to copy back to user 1-28-2010

      self.origin.save!

      self.destroy

  #----graffiti-----
    elsif decree_action == "graffiti"
      # @publication.send_status_emails(decree_action)
      #do destroy after email since the email may need info in the artice
      #@publication.get_category_obj().graffiti

      self.owner.send_status_emails("graffiti", self)
      #todo do we let one board destroy the entire document?
      #will this destroy all board copies....
      self.origin.destroy #need to destroy related?
      self.destroy
     # redirect_to ( dashboard_url )
      #TODO we need to walk the tree and delete everything everywhere??
      #or
      #self.submit_to_next_board

  #----uknown on none-----
    else
      #unknown action or no action
      #TODO allow board to return any action, and then call that action on the identifier, board or wherever it makes sense to allow the user to add to the class
      #if publication has comunity name, then it may make sense for that name to be linked to a mixin or such that contains custom methods
      #parse action name
    end

    return decree_action
  end

  # returns commits by publication creator - i.e. between canon branch point
  # and board branch point
  def creator_commits
    canon_branch_point = self.merge_base
    board_branch_point = self.origin.head

    rev_list = `#{self.repository.git_command_prefix} rev-list #{canon_branch_point}..#{board_branch_point}`.split("\n")
    unless $?.success?
      raise "git rev-list failure in Publication#creator_commits: #{$?.inspect}"
    end
    return rev_list
  end

  def flatten_commits(finalizing_publication, finalizer, board_members)
    # finalizing_publication.repository.fetch_objects(self.repository)

    # flatten commits by original publication creator
    # - use the submission reason as the main comment
    # - concatenate all non-empty commit messages into a list
    # - write a 'Signed-off-by:' line for each Ed. Board member
    # - rewrite the committer to the finalizer
    # - parent will be the branch point from canon (merge-base)
    # - tree will be from creator's last commit
    # - see http://idp.atlantides.org/trac/idp/wiki/SoSOL/Attribution
    # X insert a change in the XML revisionDesc header
    #   should instead happen at submit so EB sees it?

    self.owner.repository.update_master_from_canonical
    reason_comment = self.submission_reason

    board_controlled_paths = self.controlled_paths
    Rails.logger.info("Controlled Paths: #{board_controlled_paths.inspect}")

    controlled_commits = self.creator_commits.select do |creator_commit|
      Rails.logger.info("Checking Creator Commit id: #{creator_commit}")
      commit_touches_path = `#{self.repository.git_command_prefix} log #{creator_commit}^..#{creator_commit} -- #{board_controlled_paths.clone.map{|p| Shellwords.escape(p)}.join(" ")}`
      !commit_touches_path.blank?
    end

    Rails.logger.info("Controlled Commits: #{controlled_commits.inspect}")

    creator_commit_messages = [reason_comment.nil? ? '' : reason_comment.comment, '']
    controlled_commits.each do |controlled_commit|
      message = `#{self.repository.git_command_prefix} log -1 --pretty=format:%s #{controlled_commit}`.strip
      unless message.blank?
        creator_commit_messages << " - #{message}"
      end
    end

    controlled_blobs = board_controlled_paths.collect do |controlled_path|
      self.owner.repository.get_blob_from_branch(controlled_path, self.branch)
    end

    controlled_paths_blobs =
      Hash[*((board_controlled_paths.zip(controlled_blobs)).flatten)]

    Rails.logger.info("Controlled Blobs: #{controlled_blobs.inspect}")
    Rails.logger.info("Controlled Paths => Blobs: #{controlled_paths_blobs.inspect}")

    signed_off_messages = []
    board_members.each do |board_member|
      signed_off_messages << "Signed-off-by: #{board_member.author_string}"
    end

    commit_message =
      (creator_commit_messages + [''] + signed_off_messages).join("\n").chomp

    # parent commit should ALWAYS be canonical master head
    # FIXME: handle racing during finalization
    parent_commit = Repository.new.get_head('master')

    # roll a tree SHA1 by reading the canonical master tree,
    # adding controlled path blobs, then writing the modified tree
    # (happens on the finalizer's repo)
    finalizer.repository.update_master_from_canonical

    jgit_tree = JGit::JGitTree.new()
    jgit_tree.load_from_repo(finalizing_publication.repository.jgit_repo, 'master')
    inserter = finalizing_publication.repository.jgit_repo.newObjectInserter()
    controlled_paths_blobs.each_pair do |path, blob|
      unless blob.nil?
        file_id = inserter.insert(org.eclipse.jgit.lib.Constants::OBJ_BLOB, blob.to_java_string.getBytes(java.nio.charset.Charset.forName("UTF-8")))
        jgit_tree.add_blob(path, file_id.name())
      end
    end
    inserter.flush()

    tree_sha1 = jgit_tree.update_sha

    Rails.logger.info("Wrote tree as SHA1: #{tree_sha1}")

    commit = org.eclipse.jgit.lib.CommitBuilder.new()
    commit.setTreeId(org.eclipse.jgit.lib.ObjectId.fromString(tree_sha1))
    commit.setParentId(org.eclipse.jgit.lib.ObjectId.fromString(parent_commit))
    commit.setAuthor(self.creator.jgit_actor)
    commit.setCommitter(finalizer.jgit_actor)
    commit.setEncoding("UTF-8")
    commit.setMessage(commit_message)

    flattened_commit_sha1 = inserter.insert(commit).name()
    inserter.flush()
    inserter.release()

    finalizing_publication.repository.create_branch(
      finalizing_publication.branch, flattened_commit_sha1, true)

    # rewrite commits by EB
    # - write a 'Signed-off-by:' line for each Ed. Board member
    # - rewrite the committer to the finalizer
    # - change parent lineage to flattened commits
  end

  #Finalizer is a user who is responsible for preparing the publication for the final commit to canon. They will be given a copy of the publication to edit.
  #This function sets the finalizer up with a copy of the publicaiton.
  #
  #*Args*
  #- +finalizer+ user who will become the finalizer. If no finalizer given, a board member will be randomly choosen.
  #
  def send_to_finalizer(finalizer = nil)
    board_members = self.owner.users
    if finalizer.nil?
      # select a random board member to be the finalizer
      finalizer = board_members[rand(board_members.length)]

      self.remove_finalizer()
      finalizing_publication = copy_to_owner(finalizer)
      # finalizing_publication = clone_to_owner(finalizer)
      approve_decrees = self.owner.decrees.select {|d| d.action == 'approve'}
      approve_choices = approve_decrees.map {|d| d.choices.split(' ')}.flatten
      approve_votes = self.votes.select {|v| approve_choices.include?(v.choice) }
      approve_members = approve_votes.map {|v| v.user}
      self.flatten_commits(finalizing_publication, finalizer, approve_members)

      #should we clear the modified flag so we can tell if the finalizer has done anything
      # that way we will know in the future if we can change finalizersedidd
      finalizing_publication.change_status('finalizing')
      finalizing_publication.save!
    elsif board_members.include?(finalizer)
      self.change_finalizer(finalizer)
    end
  end

  #Destroys this publication's finalizer's copy.
  def remove_finalizer
    # need to find out if there is a finalizer, and take the publication from them
    # finalizer will point back to this board's publication
    current_finalizer_publication = find_finalizer_publication

    # TODO cascading comment deletes?
    if current_finalizer_publication
      current_finalizer_publication.destroy
    end
  end

  # Moves finalizing publication from one finalizer to another.
  #
  # *Args*
  # - +new_finalizer+ user who will become the finalizer
  def change_finalizer(new_finalizer)
    #need to copy finalizer's copy if they have changed anything
    old_finalizing_publication = self.find_finalizer_publication

    if old_finalizing_publication.nil?
      raise("Attempt to change finalizer on nonexistent finalize publication " + self.inspect + " .")
    end

    self.transaction do
      # clone publication database record to owner
      new_finalizing_publication = old_finalizing_publication.dup
      new_finalizing_publication.owner = new_finalizer
      new_finalizing_publication.creator = old_finalizing_publication.creator
      new_finalizing_publication.title = old_finalizing_publication.title
      new_finalizing_publication.branch = title_to_ref(new_finalizing_publication.title)
      new_finalizing_publication.parent = old_finalizing_publication.parent

      new_finalizing_publication.save!

      # copy identifiers over to new publication
      old_finalizing_publication.identifiers.each do |identifier|
        duplicate_identifier = identifier.dup
        new_finalizing_publication.identifiers << duplicate_identifier
      end

      # copy branch to new owner
      new_finalizing_publication.owner.repository.copy_branch_from_repo( old_finalizing_publication.branch, new_finalizing_publication.branch, old_finalizing_publication.owner.repository)
      new_finalizing_publication.save!

    end

    # destroy old publication (including branch)
    old_finalizing_publication.destroy

    return true
  end

  #*Returns* the +user+ who is finalizing this publication or +nil+ if no one finalizing this publication.
  def find_finalizer_user
    if find_finalizer_publication
      return find_finalizer_publication.owner
    end
    return nil
  end

  #*Returns* the finalizer's +publication+ or +nil+ if there is no finalizer.
  def find_finalizer_publication
  #returns the finalizer's publication or nil if finalizer does not exist
    Publication.find_by_parent_id( self.id, :conditions => { :status => "finalizing" })
  end

  def head
    self.owner.repository.jgit_repo.resolve(self.branch).name()
  end

  def merge_base(branch = 'master')
    merge_base_backticks = `#{self.repository.git_command_prefix} merge-base #{branch} #{self.head}`.chomp
    unless $?.success?
      raise "git merge-base failure: #{$?.inspect}"
    end
    return merge_base_backticks
  end

  #Copies changes made to this publication back to the creator's (origin) publication.
  #Preserves commit history for changes.
  #This is intended to be called from the finalizer's publication copy.
  #
  #*Args*
  #- +commit_comment+ comment object for commit
  #- +committer_user+ the user who is making the commit
  def copy_back_to_user(commit_comment, committer_user)
       #copies changes made to this (self) publication back to the creator's publication
       #this is intended to be called from the finalizer's publication copy
=begin
      Rails.logger.info "==========COMMUNITY PUBLICATION=========="
      Rails.logger.info "----Community is " + self.community.name
      Rails.logger.info "----Board is " + self.find_first_board.name
      Rails.logger.info "====creators publication begining finalize=="
      @publication.origin.log_info
=end
      #determine where to get data to build the index,
      # controlled paths are from the finalizer (this) publication
      # uncontrolled paths are from the origin publication

      controlled_paths =  Array.new(self.controlled_paths)
      #get the controlled blobs from the local branch (the finalizer's)
      #controlled_blobs are the files that the board controls and have changed
      controlled_blobs = controlled_paths.collect do |controlled_path|
        self.owner.repository.get_blob_from_branch(controlled_path, self.branch)
      end
      #combine controlled paths and blobs into a hash
      controlled_paths_blobs = Hash[*((controlled_paths.zip(controlled_blobs)).flatten)]

      #determine existing uncontrolled paths & blobs
      #uncontrolled are taken from the origin, they have not been changed by board
      origin_identifier_paths = self.origin.identifiers.collect do |i|
        i.to_path
      end
      uncontrolled_paths = origin_identifier_paths - controlled_paths
      uncontrolled_blobs = uncontrolled_paths.collect do |ucp|
        self.origin.repository.get_blob_from_branch(ucp, self.origin.branch)
      end
      uncontrolled_paths_blobs = Hash[*((uncontrolled_paths.zip(uncontrolled_blobs)).flatten)]


=begin
      Rails.logger.info "----Controlled paths for community publication are:" + controlled_paths.inspect
      Rails.logger.info "--uncontrolled paths: "  + uncontrolled_paths.inspect

      Rails.logger.info "-----Uncontrolled Blobs are:"
      uncontrolled_blobs.each do |cb|
        Rails.logger.info "-" + cb.to_s
      end
      Rails.logger.info "-----Controlled Blobs are:"
      controlled_blobs.each do |cb|
        Rails.logger.info "-" + cb.to_s
      end
=end

    jgit_tree = JGit::JGitTree.new()
    jgit_tree.load_from_repo(self.origin.owner.repository.jgit_repo, self.origin.branch)
    inserter = self.origin.owner.repository.jgit_repo.newObjectInserter()
    controlled_paths_blobs.merge(uncontrolled_paths_blobs).each_pair do |path, blob|
      unless blob.nil?
        file_id = inserter.insert(org.eclipse.jgit.lib.Constants::OBJ_BLOB, blob.to_java_string.getBytes(java.nio.charset.Charset.forName("UTF-8")))
        jgit_tree.add_blob(path, file_id.name())
      end
    end
    inserter.flush()

    jgit_tree.commit(commit_comment, committer_user.jgit_actor)

    self.origin.save
  end


  def commit_to_canon
    #commit_sha is just used to return git sha reference point for comment
    commit_sha = nil

    canon = Repository.new
    publication_sha = self.head
    canonical_sha = canon.get_head('master')

    if canon_controlled_identifiers.length > 0
      if self.merge_base(canonical_sha) == canonical_sha
        # nothing new from canon, trivial merge by updating HEAD
        # e.g. "Fast-forward" merge, HEAD is already contained in the commit
        # canon.fetch_objects(self.owner.repository)
        canon.add_alternates(self.owner.repository)
        commit_sha = canon.update_ref('master', publication_sha)

        self.change_status('committed')
        self.save!
      else
        # Both the merged commit and HEAD are independent and must be tied
        # together by a merge commit that has both of them as its parents.

        # TODO: DRY from flatten_commits
        controlled_blobs = self.canon_controlled_paths.collect do |controlled_path|
          self.owner.repository.get_blob_from_branch(controlled_path, self.branch)
        end

        controlled_paths_blobs =
          Hash[*((self.canon_controlled_paths.zip(controlled_blobs)).flatten)]

        Rails.logger.info("Controlled Blobs: #{controlled_blobs.inspect}")
        Rails.logger.info("Controlled Paths => Blobs: #{controlled_paths_blobs.inspect}")
        
        # roll a tree SHA1 by reading the canonical master tree,
        # adding controlled path blobs, then writing the modified tree
        # (happens on the finalizer's repo)
        self.owner.repository.update_master_from_canonical
        jgit_tree = JGit::JGitTree.new()
        jgit_tree.load_from_repo(self.owner.repository.jgit_repo, 'master')
        inserter = self.owner.repository.jgit_repo.newObjectInserter()
        controlled_paths_blobs.each_pair do |path, blob|
          unless blob.nil?
            file_id = inserter.insert(org.eclipse.jgit.lib.Constants::OBJ_BLOB, blob.to_java_string.getBytes(java.nio.charset.Charset.forName("UTF-8")))
            jgit_tree.add_blob(path, file_id.name())
          end
        end
        inserter.flush()

        tree_sha1 = jgit_tree.update_sha
       
        Rails.logger.info("Wrote tree as SHA1: #{tree_sha1}")

        commit_message = "Finalization merge of branch '#{self.branch}' into canonical master"

        inserter = self.owner.repository.jgit_repo.newObjectInserter()

        commit = org.eclipse.jgit.lib.CommitBuilder.new()
        commit.setTreeId(org.eclipse.jgit.lib.ObjectId.fromString(tree_sha1))
        commit.setParentIds(org.eclipse.jgit.lib.ObjectId.fromString(canonical_sha),org.eclipse.jgit.lib.ObjectId.fromString(publication_sha))
        commit.setAuthor(self.owner.jgit_actor)
        commit.setCommitter(self.owner.jgit_actor)
        commit.setEncoding("UTF-8")
        commit.setMessage(commit_message)

        finalized_commit_sha1 = inserter.insert(commit).name()
        inserter.flush()
        inserter.release()

        Rails.logger.info("commit_to_canon: Wrote finalized commit merge as SHA1: #{finalized_commit_sha1}")

        # Update our own head first
        self.owner.repository.update_ref(self.branch, finalized_commit_sha1)

        # canon.fetch_objects(self.owner.repository)
        canon.add_alternates(self.owner.repository)
        commit_sha = canon.update_ref('master', finalized_commit_sha1)

        self.change_status('committed')
        self.save!
      end

      # finalized, try to repack
      RepackCanonical.new.async.perform()
    else
      # nothing under canon control, just say it's committed
      self.change_status('committed')
      self.save!
    end
    return commit_sha
  end


  def branch_from_master
    owner.repository.create_branch(branch)
  end


  #Determines which identifiers are controlled by this publication's board.
  #*Returns*
  #- array of identifiers from this publication that are controlled by this publication's board
  #- empty array if this publication is not owned by a board or a finalizer
  def controlled_identifiers
    return self.identifiers.select do |i|
      if self.owner.class == Board
        self.owner.identifier_classes.include?(i.class.to_s)
      elsif self.status == 'finalizing'
        self.parent.owner.identifier_classes.include?(i.class.to_s)
      else
        false
      end
    end
  end



  #Determines paths for identifiers that are controlled by this publication's board.
  #*Returns*
  #- array of paths from this publication that are controlled by this publication's board
  #- empty array if this publication is not owned by a board or a finalizer
  def controlled_paths
    self.controlled_identifiers.collect do |i|
      i.to_path
    end
  end

  def canon_controlled_identifiers
    # TODO: implement a class-level var e.g. CANON_CONTROL for this
    self.controlled_identifiers
  end

  def canon_controlled_paths
    self.canon_controlled_identifiers.collect do |i|
      i.to_path
    end
  end

  def diff_from_canon
    canon = Repository.new
    canonical_sha = canon.get_head('master')
    diff = `git --git-dir="#{self.owner.repository.path}" diff --unified=5000 #{canonical_sha} #{self.head} -- #{self.controlled_paths.map{|path| "\"#{path}\""}.join(' ')}`
    return diff || ""
  end

  def needs_rename?
    self.controlled_identifiers.each do |i|
      return true if i.needs_rename?
    end
    return false
  end

  #*Returns* comment object with the publication's submit comment.
  def submission_reason
    reason = Comment.find_by_publication_id(self.origin.id, :conditions => "reason = 'submit'")
  end

  #Finds the publication with no parent. This will be the creators copy.
  #
  #*Returns* +publication+ that is the begining of the publication workflow chain.
  def origin
    # walk the parent list until we encounter one with no parent
    origin_publication = self
    while (origin_publication.parent != nil) do
      origin_publication = origin_publication.parent
    end
    return origin_publication
  end

  #*Returns* +array+ of all of this publication's children.
  def all_children
    all_child_publications = []
    self.children.each do |child_publication|
      all_child_publications << child_publication
      all_child_publications = all_child_publications + child_publication.all_children
    end
    return all_child_publications
  end

  #Destroys all board copies of a publication and resets the origin publication's status back to editing.
  #This method has two main functions. One is to allow the user to "unsubmit" their submission. The other is to "reset" a publication that is in a confused state.
  def withdraw
    original_origin = self.origin
    #if(original_origin != self) #commented out so user can withdraw there own pub, note this should not be called without checking that the pub is withdrawable
      original_origin.all_children.each do |child_publication|
        child_publication.destroy
      end
      original_origin.change_status('editing')
      original_origin.comments.each do |c|
        c.destroy
      end
      original_origin.identifiers.each do |i|
        i.status = 'editing'
        i.save!
      end
    #end
  end

  #Checks to see if user should be allowed to withdraw their submitted publication.
  #
  #*Returns*
  #- +true+ if user can withdraw publication. Currently the rule is the user can withdraw before any voting has taken place.
  #- +false+ if the user can no longer withdraw the publication.
  def allow_user_withdrawal?(user)
    #check any children publications for voting activity
    vote_count = 0;

    child_publications = self.all_children
    child_publications.each do |pub|
      vote_count += pub.votes.count
    end
   return ( vote_count < 1 ) && ( user == self.creator ) && ( self.status == 'submitted' )
  end

  #Finds the closest parent(or self) publication whose owner is a board. Returns that board.
  #
  #*Returns*
  #- +board+ that owns the publication.
  #- +nil+ if no board owned publication found.
  def find_first_board
    board_publication = self
    while (board_publication.owner_type != "Board" && board_publication != nil) do
      board_publication = board_publication.parent
    end
    if board_publication
      return board_publication.owner
    end
    return nil
  end

  #finds the closest parent publication whose owner is a board and returns that publication

  #Finds the closest parent(or self) publication whose owner is a board. Returns that publication.
  #
  #*Returns*
  #- +publication+ owned by the board.
  #- +nil+ if no board owned publication found.
  def find_first_board_parent
    board_publication = self
    while (board_publication.owner_type != "Board" && board_publication != nil) do
      board_publication = board_publication.parent
    end
    return board_publication
  end

  #total votes for the publication children in voting status
  def children_votes
    vote_total = 0
    vote_ddb = 0
    vote_meta = 0
    vote_trans = 0
    self.children.each do|x|
      if x.status == 'voting'
        x.identifiers.each do |y|
          case y
            when DDBIdentifier
              vote_ddb += y.votes.length
              vote_total += vote_ddb
            when HGVMetaIdentifier
              vote_meta += y.votes.length
              vote_total += vote_meta
            when HGVTransIdentifier
              vote_trans += y.votes.length
              vote_total += vote_trans
          end #case
        end # identifiers do
      end #if
    end #children do
    return vote_total, vote_ddb, vote_meta, vote_trans
  end

  #Creates a new publication for the new_owner that is a separate copy of this publication.
  #
  #*Args* +new_owner+ the owner for the cloned copy.
  #
  #*Returns* +publication+ that is the new copy.
  def clone_to_owner(new_owner)
    duplicate = self.dup
    duplicate.owner = new_owner
    duplicate.creator = self.creator
    duplicate.title = self.owner.name + "/" + self.title
    duplicate.branch = title_to_ref(duplicate.title)
    duplicate.parent = self
    duplicate.save!

    # copy identifiers over to new pub
    identifiers.each do |identifier|
      duplicate_identifier = identifier.dup
      duplicate.identifiers << duplicate_identifier
    end

    return duplicate
  end


  #Creates a new publication for the end_user (of a community) that is a separate copy of this publication.
  #This is similar to clone_to_owner, except the publication title is renamed to reflect the community and creator.
  #The new owner is the end_user for the publication's community.
  #
  #*Returns* +publication+ that is the new copy.
   def clone_to_end_user()
    duplicate = self.dup
    duplicate.owner = self.community.end_user
    duplicate.creator = self.community.end_user #severing direct connection to orginal publication     self.creator
    duplicate.title = self.community.name + "/" + self.creator.name + "/" + self.title #adding orginal creator to title as reminder for end_user
    duplicate.branch = title_to_ref(duplicate.title)
    duplicate.parent = self
    duplicate.save!

    # copy identifiers over to new pub
    identifiers.each do |identifier|
      duplicate_identifier = identifier.dup
      duplicate.identifiers << duplicate_identifier
    end

    return duplicate
  end

  def repository
    return self.owner.repository
  end

  #copies this publication's branch to the new_owner's branch
  #returns duplicate publication with new_owner
  def copy_to_owner(new_owner)
    duplicate = self.clone_to_owner(new_owner)

    duplicate.owner.repository.copy_branch_from_repo(
      self.branch, duplicate.branch, self.owner.repository
    )

    return duplicate
  end


  #mainly used to create new publiation title/repo name that is indicative of the publications source
  def copy_to_end_user()
    duplicate = self.clone_to_end_user()
    duplicate.owner.repository.copy_branch_from_repo(
      self.branch, duplicate.branch, self.owner.repository
    )

    return duplicate
  end
  #copy a child publication repo back to the parent repo
  def copy_repo_to_parent_repo
     #all we need to do is copy the repo back the parents repo
     self.origin.repository.copy_branch_from_repo(self.branch, self.origin.branch, self.repository)
  end

  # TODO: destroy branch on publication destroy

  # entry point identifier to use when we're just coming in from a publication
  def entry_identifier
    identifiers.first
  end

  def get_all_comments(title)
    all_built_comments = []
    xml_only_built_comments = []
    # select all comments associated with a publication title - will include from all users
    # BMA What is the purpose of limiting comments to the title rather than the id?
    @arcomments = Comment.find_by_sql("SELECT a.comment, a.user_id, a.identifier_id, a.reason, a.created_at
                                        FROM comments a, publications b
                                        WHERE b.title = '#{title}'
                                          AND a.publication_id = b.id
                                     ORDER BY a.created_at DESC")
    # add comments hash to array
    @arcomments.each do |c|
      built_comment = Comment::CombineComment.new

      built_comment.xmltype = "model"

      if c.user && c.user.name
        built_comment.who = c.user.human_name
      else
        built_comment.who = "user not filled in"
      end
      # convert date to local for consistency so work in sort below
      built_comment.when = c.created_at.getlocal

      if c.reason
        built_comment.why = c.reason
      else
        built_comment.why = "reason not filled in"
      end
      #add identifier name if available
      if c.identifier
        built_comment.why = built_comment.why + " " + c.identifier.class::FRIENDLY_NAME
      end

      if c.comment
        built_comment.comment = c.comment
      else
        built_comment.comment = "comment not filled in"
      end

      all_built_comments << built_comment
    end

    # add comments hash from each of the publication's identifiers XML file to array
    identifiers.each do |i|
      where_from = i.class::FRIENDLY_NAME
      ident_title = i.title

      ident_xml = i.xml_content
      if ident_xml
        ident_xml_xpath = REXML::Document.new(ident_xml)
        comment_path = '/TEI/teiHeader/revisionDesc'
        comment_here = REXML::XPath.first(ident_xml_xpath, comment_path)

        unless comment_here.nil?
          comment_here.each_element('//change') do |change|
            built_comment = Comment::CombineComment.new

            built_comment.xmltype = where_from

            if change.attributes["who"]
              built_comment.who = change.attributes["who"]
            else
              built_comment.who = "no who attribute"
            end

            # parse will convert date to local for consistency so work in sort below
            if change.attributes["when"]
              built_comment.when = Time.parse(change.attributes["when"])
            else
              built_comment.when = Time.parse("1988-8-8")
            end

            built_comment.why = "From "  + ident_title + " " + where_from + " XML"

            built_comment.comment = change.text

            all_built_comments << built_comment
            xml_only_built_comments << built_comment
          end #comment_here
        end #comment_here.nil?
      end # if ident_xml
    end #identifiers each
    # sort in descending date order for display
    return all_built_comments.sort_by(&:when).reverse, xml_only_built_comments.sort_by(&:when).reverse
  end

  def creatable_identifiers
    creatable_identifiers = Array.new(Identifier::IDENTIFIER_SUBCLASSES)

    #WARNING hardcoded identifier dependency hack
    #enforce creation order
    has_meta = false
    has_text = false
    has_biblio = false
    has_cts = false

    self.identifiers.each do |i|
      if i.class.to_s == "BiblioIdentifier"
        has_biblio = true
      end
      if i.class.to_s == "HGVMetaIdentifier"
        has_meta = true
      end
      if i.class.to_s == "DDBIdentifier"
       has_text = true
      end
      if i.class.to_s =~ /CTSIdentifier/
        has_cts = true
      end
    end
    if !has_text
      #cant create trans
      creatable_identifiers.delete("HGVTransIdentifier")
    end
    if !has_meta
      #cant create text
      creatable_identifiers.delete("DDBIdentifier")
      #cant create trans
      creatable_identifiers.delete("HGVTransIdentifier")
    end
    creatable_identifiers.delete("BiblioIdentifier")
    # Not allowed to create any other record in association with a BiblioIdentifier publication
    if has_biblio
      creatable_identifiers = []
    end
    #  BALMAS Creating other records in association with a CTSIdentifier publication will be enabled elsewhere
    if has_cts
      creatable_identifiers = []
    end

    #only let user create new for non-existing
    self.identifiers.each do |i|
      creatable_identifiers.each do |ci|
        if ci == i.class.to_s
          creatable_identifiers.delete(ci)
        end
      end
    end

    return creatable_identifiers
  end

  protected
    #Returns title string in form acceptable to  ".git/refs/"
    def title_to_ref(str)
      java.text.Normalizer.normalize(str.tr(' ','_'),java.text.Normalizer::Form::NFD).gsub(/\p{M}/,'')
    end

    #Returns identifier string in form acceptable to  ".git/refs/"
    def identifier_to_ref(str)
      java.text.Normalizer.normalize(str.tr(' ','_'),java.text.Normalizer::Form::NFD).gsub(/\p{M}/,'')
    end
end

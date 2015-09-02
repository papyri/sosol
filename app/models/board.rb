
##Board represents an editorial review board.
class Board < ActiveRecord::Base
  has_many :decrees, :dependent => :destroy
  has_many :emailers, :dependent => :destroy
  
  has_many :votes
  
  has_many :boards_users
  has_many :users, :through => :boards_users
  belongs_to :finalizer_user, :class_name => 'User'
  
  has_many :publications, :as => :owner, :dependent => :destroy
  has_many :events, :as => :owner

  belongs_to :community


  #board rank determines workflow order for publication
  #ranked scopes returns the boards for a given community in order of their rank
  #ranked left as default for sosol ranks
  scope :ranked, :order => 'rank ASC', :conditions => { 'community_id' => nil }
  
  scope :ranked_by_community_id,  lambda { |id_in| { :order => 'rank ASC', :conditions => [ 'community_id = ?', id_in ] } }



  # :identifier_classes is an array of identifier classes this board has
  # commit control over. This isn't done relationally because it's not a
  # relation to instances of identifiers but rather to identifier classes
  # themselves.
  serialize :identifier_classes
  
  validates_uniqueness_of :title, :case_sensitive => false, :scope => [:community_id]
  validates_presence_of :title
  
  has_repository
  
  # Workaround, repository needs owner name for now.
  def name
    return title
  end
  
  def human_name
    return title
  end
  
  after_create do |board|
    board.repository.create
  end
  
  before_destroy do |board|
    repository.destroy
  end
  
  #The original idea was to allow programmers to add whatever functionality they wanted to an identifier.
  #This functionality would be contained in a method called result_action_*.
  #When a decree is set up the list of possible result_actions would be parsed from these methods and be presented to the user in a drop down list to choose.
  #Currently (10-10-2011, CSC) I believe this is only used to make the drop down list when creating a decree. The default values are found in the identifier model.
  #
  #*Returns*
  #- string list of possible actions to be taken on an identifier (a.k.a. decree actions)
  def result_actions
    #return array of possible actions that can be implemented
    retval = []
    identifier_classes.each do |ic|
      im = ic.constantize.instance_methods
      match_expression = /(result_action_)/
      im.each do |method_name|
        if method_name =~ /(result_action_)/
          retval << method_name.to_s.sub(/(result_action_)/, "")
        end
      end
    end
    retval
    
  end
  
  #*Returns*:
  #- result_actions in a capitalized hash list for the select statement
  def result_actions_hash  
    ra = result_actions    
    ret_hash = {}
    
    #create hash
    ra.each do |v|
      ret_hash[v.sub(/_/, " ").capitalize] = v
    end
    ret_hash
  end

  
  #*Args*:
  #- +identifier+ identifier or subclass of identifier
  #*Returns*:
  #- +true+ if this board is responsible for the given identifier
  #- +false+ otherwise 
  def controls_identifier?(identifier)
    # For APIS boards there is only a single identifier class (APISIdentifier) across
    # all boards.
   if "APISIdentifier" == identifier.class.to_s
     self.identifier_classes.include?(identifier.class.to_s) && identifier.name.include?(self.title.downcase)
   else 
     self.identifier_classes.include?(identifier.class.to_s)  
   end
  end
  
  #Tallies the votes and returns the resulting decree action or returns an empty string if no decree has been triggered.
  #
  #*Args*:
  #- +votes+ the publication's votes
  #*Returns*:
  #- nil if no decree has been triggered
  #- decree action if the votes trigger a decree, if multiple decrees could be triggered by the vote count, only the first in the list will be returned.
  def tally_votes(votes)
    # NOTE: assumes board controls one identifier type, and user hasn't made
    # rules where multiple decrees can be true at once
    
    self.decrees.each do |decree|
      if decree.perform_action?(votes)
        Rails.logger.info("Board#tally_votes success on Board: #{self.inspect}\nFor decree: #{decree.inspect}\nWith votes: #{votes.inspect}")
        return decree.action
      end
    end
    
    return ""
  end #tally_votes
  

  #Will generally be called when the status of a publication is changed.
  #Emails will be sent according to emailer settings for the board.
  #
  #*Args*: 
  #- +when_to_send+ the new status of the publication.
  #- +publication+ the publication whose status has just changed.
  def send_status_emails(when_to_send, publication)

  	#search emailer for status
  	if self.emailers == nil
  	  return
  	end
    
    #find identifiers for email
    email_identifiers = Array.new
    publication.identifiers.each do |identifier|
      if self.identifier_classes.include?(identifier.class.to_s)
        email_identifiers << identifier      
      end
    end
    
    
  	self.emailers.each do |mailer|
  	
  		if mailer.when_to_send == when_to_send
  			#send the email
  			addresses = Array.new	
  			#--addresses
  			
        #board members
        if mailer.send_to_all_board_members
          self.users.each do |board_user|          
            addresses << board_user.email        
          end
        end
        
        #other sosol users
        if mailer.users
          mailer.users.each do |user|
            if user.email != nil
              addresses << user.email
            end
          end
        end
        
        #extra addresses
        if mailer.extra_addresses
          extras = mailer.extra_addresses.split(" ")
          extras.each do |extra|
            addresses << extra
          end
        end
        
        #owner address
  			if mailer.send_to_owner
  				if publication && publication.creator && publication.creator.email
  					addresses << publication.creator.email
  				end
  			end
  			
  			#--document content
  			if mailer.include_document
          document_content = ""
          email_identifiers.each do |ec|
            unless ec.nil?
              #document_content += ec.content || ""
              document_content += Identifier.find(ec[:id]).content || ""
            end
          end
  			else
  				document_content = nil
  			end
  			
  			body = mailer.message
  			
  			#TODO parse the message to add local vars
  			#votes
  			#comments        
        if mailer.include_comments  
          comment_text = ""       
          begin
            comments = Comment.find_all_by_publication_id(publication.origin.id)    
          rescue
            #do nothing no comments found
          end                        
            if comments
              comments.each do |comment|
                if comment.comment
                  comment_text += comment.comment 
                end
                comment_text += "("
                if comment.reason
                  comment_text += comment.reason 
                end
                if comment.identifier
                  comment_text += " on #{comment.identifier.title} (#{comment.identifier.class::FRIENDLY_NAME})"
                end
                if comment.user && comment.user.name
                  comment_text += " by " + comment.user.name 
                end
                comment_text += " " + comment.created_at.to_formatted_s(:db)
                comment_text += ")"
                comment_text += "\n"
              end            
              body += "\n"
              body += "Comments:\n"
              body += comment_text
            end          
        end
  			#owner
  			#status
        identifier_titles = email_identifiers.collect{|ei| ei.title}.join('; ')
        
        subject_line = publication.title + " " + identifier_titles + "-" + when_to_send
  			
  			addresses.each do |address|
  				if address && address.strip != ""
            begin
              EmailerMailer.general_email(address, subject_line, body, document_content).deliver
            rescue Exception => e
              Rails.logger.error("Error sending email: #{e.class.to_s}, #{e.to_s}")
            end
  				end
  			end
  			
  		end
  	end	
  	
  end


  #Since friendly_name is an added feature, the existing boards will not have this data, so for backward compatability we may need to make it up.
  #This method could be removed after initial deploy.
  def friendly_name=(fn)
    if fn && (fn.strip != "")
      self[:friendly_name] = fn
    else
      self[:friendly_name] = self[:title]
    end
    
  end
  
  #Since board title is used to determine repository names, the title cannot be changed after board creation.
  #This friendly_name allows the users another name that they can change at will. 
  #*Returns*:  
  #- friendly_name if it has been set. Otherwise returns title.
  def friendly_name
    fn = self[:friendly_name]
    if fn && (fn.strip != "")
      return fn
    else
      return self[:title]
    end
  end
  
  
end

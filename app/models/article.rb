class Article < ActiveRecord::Base
  include ArticlesHelper
  
  has_many :comments
  has_many :votes
  belongs_to :user
  belongs_to :master_article
  belongs_to :board
  
  #article types
  has_one :meta
  has_one :transcription
  has_one :translation
   
  # has_many :events
  validates_presence_of :content
  
  # validate :must_be_valid_xml
  # validate :must_be_valid_epidoc
  
  #article has serveral status states
  #new - user created ie does not exist elsewhere
  #edit - editing existing ie alread is in repository somewhere
  #submitted - user submitted and it is being reviewed by the board
  #accepted - board has approved
  #rejected - board rejected
  #graffiti - board hated it  
  
#edit_article_path(article)


#Returns the object represented by the article's category
  def get_category_obj()
    if self.meta
      obj = self.meta
    elsif self.transcription
      obj = self.transcription
    elsif self.translation
      obj = self.translation           
    else
      obj = nil 
    end
    
    obj   
  end
  

  
  def must_be_valid_xml
    # errors.add_to_base("Content must be valid XML") unless (valid_xml?(content) != nil)
  end

  def must_be_valid_epidoc
    errors.add_to_base("Content must be valid EpiDoc") unless valid_epidoc?(content)
  end
  
  
  
  
  
  #Check with the board to see if we want to send an email on status change.
  def send_status_emails
  	
  	#search emailer for status
  	self.board.emailers.each do |mailer|
  		#mailer_statuss = mailer.status.split(' ')
  		if mailer.status == self.status
  			#send the email
  			
  			#--addresses
  			mailer.users.each do |user|
  				addresses += " " + user.email
  			end
  			addresses += mailer.extra_addresses
  			
  			#--epidoc
  			if mailer.include_document
  				epidoc = self.get_category_obj().get_content #xml content or such... how to get??
  			else
  				epidoc = nil
  			end
  			
  			body = mailer.message
  			
  			#TODO parse the message to add local vars
  			#votes
  			
  			#comments
  			#owner
  			#status
  			#who changed status
  			subject_line = self.master_article.title + " " + self.category + "-" + self.status
  			EmailerMailer.deliver_boardmail(addresses, subject_line, body, epidoc) 
  		end
  	end	
  end
  
  
  
  
  
  
  
  
  
  
end

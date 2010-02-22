class Identifier < ActiveRecord::Base
  IDENTIFIER_SUBCLASSES = %w{ DDBIdentifier HGVMetaIdentifier HGVTransIdentifier HGVBiblioIdentifier }
  
  FRIENDLY_NAME = "Base Identifier"
  
  IDENTIFIER_STATUS = %w{ new editing submitted approved finalizing committed archived }
  
  validates_presence_of :name, :type
  
  belongs_to :publication
  
  #assume we want to delete the comments along with the identifier
  has_many :comments, :dependent => :destroy
  
  has_many :votes, :dependent => :destroy
  
  validates_inclusion_of :type,
                         :in => IDENTIFIER_SUBCLASSES
  
  require 'jruby_xml'
  
  def origin
    self.publication.origin.identifiers.detect {|i| i.name == self.name}
  end
  
  def parent
    self.publication.parent.identifiers.detect {|i| i.name == self.name}
  end
  
  def children
    child_identifiers = []
    self.publication.children.each do |child_pub|
      child_identifiers << child_pub.identifiers.detect{|i| i.name == self.name}
    end
    return child_identifiers
  end
  
  def repository
    return self.publication.nil? ? Repository.new() : self.publication.owner.repository
  end
  
  def branch
    return self.publication.nil? ? 'master' : self.publication.branch
  end
  
  def content
    return self.repository.get_file_from_branch(
      self.to_path, self.branch)
  end
  
  def is_valid_xml?(content = nil)
    if content.nil?
      content = self.content
    end
    self.class::XML_VALIDATOR.instance.validate(
      JRubyXML.input_source_from_string(content))
  end
  
  def before_commit(content)
    return content
  end
  
  def set_content(content, options = {})
    options.reverse_merge! :comment => ''
    self.repository.commit_content(self.to_path,
                                   self.branch,
                                   content,
                                   options[:comment],
                                   options[:actor])
    self.modified = true
    self.save!
  end
  
  def get_commits
    self[:commits] = 
      self.repository.get_log_for_file_from_branch(
        self.to_path, self.branch
    )
  end
  
  def to_components
    trimmed_name = NumbersRDF::NumbersHelper::identifier_to_local_identifier(self.name)
    # trimmed_name.sub!(/^\/#{self.class::IDENTIFIER_NAMESPACE}\//,'')
    components = NumbersRDF::NumbersHelper::identifier_to_components(trimmed_name)
    components.map! {|c| c.to_s}

    return components
  end
  
  def self.new_from_template(publication)
    new_identifier = self.new(:name => self.next_temporary_identifier)
    new_identifier.publication = publication
    
    new_identifier.save!
    
    initial_content = new_identifier.file_template
    new_identifier.set_content(initial_content, :comment => 'Created from SoSOL template')
    
    return new_identifier
  end
  
  def file_template
    template_path = File.join(RAILS_ROOT, ['data','templates'],
                              "#{self.class.to_s.underscore}.xml.erb")
    
    template = ERB.new(File.new(template_path).read)
    
    id = self.id_attribute
    n = self.n_attribute
    title = self.xml_title_text
    
    return template.result(binding)
  end
  
  def self.next_temporary_identifier
    year = Time.now.year
    latest = self.find(:all,
                       :conditions => ["name like ?", "papyri.info/#{self::IDENTIFIER_NAMESPACE}/#{self::TEMPORARY_COLLECTION};#{year};%"],
                       :order => "name DESC",
                       :limit => 1).first
    if latest.nil?
      # no constructed id's for this year/class
      document_number = 1
    else
      document_number = latest.to_components.last.to_i + 1
    end
    
    return sprintf("papyri.info/#{self::IDENTIFIER_NAMESPACE}/#{self::TEMPORARY_COLLECTION};%04d;%04d",
                   year, document_number)
  end
  
  def owner
    self.publication.owner
  end
  
  def mutable?
  
    #determines who can edit the identifier
    
    
    #only let the board edit if they own it
    if self.publication.owner_type == "Board" && self.publication.status == "editing"
      if self.publication.owner.identifier_classes.include?(self.class.to_s)
       return true
      end
    
    #let the finalizer edit the id the board owns  
    elsif self.publication.status == "finalizing" &&  self.publication.find_first_board.identifier_classes.include?(self.class.to_s)
      return true 
      
    #they can edit any of their stuff if it is not submitted      
    elsif self.publication.owner_type == "User" && %w{editing new}.include?(self.publication.status)
      return true 
    end
    
    return false    


   # self.publication.mutable?
  end
  


  
  def xml_content
    return self.content
  end
  
  def set_xml_content(content, options)
    options.reverse_merge!(
      :validate => true,
      :actor    => ((self.owner.class == User) ? self.owner.grit_actor : nil))
      
    content = before_commit(content)

    if options[:validate] && is_valid_xml?(content)
      self.set_content(content, options)
    end
  end
  
  #added to speed up dashboard since titleize can be slow
  def title
    if read_attribute(:title) == nil
      write_attribute(:title,titleize)
      self.save
    end
    return read_attribute(:title)
  end
  

=begin

  #caution - sending emails here might mean they are sent even if the status change does not get saved
  def status=(status_in)
    
    #see if status is actually changing
    do_send = false
    if status_in != read_attribute(:status)
      do_send = true
    end
    
    #update status
    write_attribute(:status, status_in)
    
    #check if we need to send emails
    if do_send
      send_status_emails(status_in)      
    end
  end
  
  #Check with the board to see if we want to send an email on status change.
  def send_status_emails(when_to_send)
#TODO move to board
  	#search emailer for status
  	if self.board == nil || self.board.emailers == nil
  	  return
  	end
  	self.board.emailers.each do |mailer|
  	
  		if mailer.when_to_send == when_to_send
  			#send the email
  			addresses = Array.new	
  			#--addresses
  			mailer.users.each do |user|
  				if user.email != nil
  					addresses << user.email
  				end
  			end
  			extras = mailer.extra_addresses.split(" ")
  			extras.each do |extra|
  				addresses << extra
  			end
  			if mailer.send_to_owner
  				if self.user.email != nil
  					addresses << self.user.email
  				end
  			end
  			
  			#--document content
  			if mailer.include_document
  				document_content = self.content 
  			else
  				document_content = nil
  			end
  			
  			body = mailer.message
  			
  			#TODO parse the message to add local vars
  			#votes
  			
  			#comments
  			#owner
  			#status
  			#who changed status
  			subject_line = self.publication.title + " " + self.class::FRIENDLY_NAME + "-" + self.status
  			#if addresses == nil 
  			#raise addresses.to_s + addresses.size.to_s
  			#else
  				#EmailerMailer.deliver_boardmail(addresses, subject_line, body, epidoc)   										
  			#end
  			
  			addresses.each do |address|
  				if address != nil && address.strip != ""
  					EmailerMailer.deliver_boardmail(address, subject_line, body, document_content)   										
  				end
  			end
  			
  		end
  	end	
  	
  end

=end
  

  #standard result actions 
  #NOTE none of this is currently used except for creating board
  def result_action_approve
   
    self.status = "approved"
    self.publication.send_to_finalizer
  end
  
  def result_action_reject
   
    self.status = "rejected"
  end
  
  def result_action_graffiti
    
    #delete
  end
  
=begin not used
  def result_action_finalize
  
    self.status = "finalized"
  end
=end
  
end

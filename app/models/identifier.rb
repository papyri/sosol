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
  
  # Returns a String of the SHA1 of the commit
  def set_content(content, options = {})
    options.reverse_merge! :comment => ''
    commit_sha = self.repository.commit_content(self.to_path,
                                   self.branch,
                                   content,
                                   options[:comment],
                                   options[:actor])
    self.modified = true
    self.save!
    return commit_sha
  end
  
  def get_commits
    self[:commits] = 
      self.repository.get_log_for_file_from_branch(
        self.to_path, self.branch
    )
  end
  
  #parse out most recent sha from log
  def get_recent_commit_sha
    commits = get_commits
    if commits && commits.length > 0
      return commits[0][:id].to_s
    end
    return ""
    
  end
  
  def titleize
    title = nil
    if self.class == HGVMetaIdentifier
      title = NumbersRDF::NumbersHelper::identifier_to_title(self.name)
    elsif self.class == HGVTransIdentifier
      title = NumbersRDF::NumbersHelper::identifier_to_title(
        self.name.sub(/trans/,''))
    end
    
    if title.nil?
      collection_name, volume_number, document_number =
        self.to_components.last.split(';')

      collection_name = 
        self.class.collection_names_hash[collection_name]

      # strip leading zeros
      document_number.sub!(/^0*/,'')

      title = 
       [collection_name, volume_number, document_number].join(' ')
    end
    return title
  end
  
  def to_components
    trimmed_name = NumbersRDF::NumbersHelper::identifier_to_local_identifier(self.name)
    # trimmed_name.sub!(/^\/#{self.class::IDENTIFIER_NAMESPACE}\//,'')
    components = NumbersRDF::NumbersHelper::identifier_to_components(trimmed_name)
    components.map! {|c| c.to_s}

    return components
  end
  
  def self.collection_names
    unless defined? @collection_names
      parts = NumbersRDF::NumbersHelper::identifier_to_parts([NumbersRDF::NAMESPACE_IDENTIFIER, self::IDENTIFIER_NAMESPACE].join('/'))
      @collection_names = parts.collect {|p| NumbersRDF::NumbersHelper::identifier_to_components(p).last}
    end
    return @collection_names
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
      document_number = latest.to_components.last.split(';').last.to_i + 1
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
  
  # Returns a String of the SHA1 of the commit
  def set_xml_content(content, options)
    options.reverse_merge!(
      :validate => true,
      :actor    => ((self.owner.class == User) ? self.owner.grit_actor : nil))
      
    content = before_commit(content)

    commit_sha = ""
    if options[:validate] && is_valid_xml?(content)
      commit_sha = self.set_content(content, options)
    end
    
    return commit_sha
  end
  
  #added to speed up dashboard since titleize can be slow
  def title
    if read_attribute(:title) == nil
      write_attribute(:title,titleize)
      self.save
    end
    return read_attribute(:title)
  end


  def add_change_desc(text = "")
    doc = REXML::Document.new self.xml_content
    base_path = "/TEI/teiHeader/revisionDesc"
    
    #get user name
    user_info = self.publication.creator
    if user_info.full_name && user_info.full_name.strip != ""
      who_name = user_info.full_name 
    else
      who_name = user_info.name
    end
    
    #get date now
    when_date = DateTime.now.strftime("%Y-%m-%d")
    
    #find revision node
    revision_node = REXML::XPath.first(doc, base_path)
    
    #make new change node
    change_node = REXML::Element.new("change")
    change_node.text = SITE_NAME + " " + text
    change_node.add_attribute("when", when_date)
    change_node.add_attribute("who", who_name )
    
    #add change node to revision node
    revision_node.add_element(change_node)
    self.set_xml_content(doc.to_s, :comment => '')
  end


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

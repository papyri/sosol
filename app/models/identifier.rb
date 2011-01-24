class Identifier < ActiveRecord::Base
  #TODO - is Biblio needed?
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

  #added ''&& i.type == self.type' to origin, parent, and children methods because name for meta and trans are
  #the same and was returning the meta instead of trans when processing translations
  def origin
    self.publication.origin.identifiers.detect {|i| i.name == self.name && i.type == self.type}
  end
  
  def parent
    self.publication.parent.identifiers.detect {|i| i.name == self.name && i.type == self.type}
  end
  
  def children
    child_identifiers = []
    self.publication.children.each do |child_pub|
      child_identifiers << child_pub.identifiers.detect{|i| i.name == self.name && i.type == self.type}
    end
    return child_identifiers
  end
  
  # gives origin and its children, but not self
  def relatives
    if self.origin.nil?
      return []
    else
      return [self.origin] + self.origin.children - [self]
    end
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
    
    self.publication.update_attribute(:updated_at, Time.now)
    
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
    if self.class == HGVMetaIdentifier || self.class == HGVBiblioIdentifier
      title = NumbersRDF::NumbersHelper::identifier_to_title(self.name)
    elsif self.class == HGVTransIdentifier
      title = NumbersRDF::NumbersHelper::identifier_to_title(
        self.name.sub(/trans/,''))
    end
    
    if title.nil?
      if (self.class == DDBIdentifier) || (self.name =~ /#{self.class::TEMPORARY_COLLECTION}/)
        collection_name, volume_number, document_number =
          self.to_components.last.split(';')

        collection_name = 
          self.class.collection_names_hash[collection_name]
        
        # strip leading zeros
        document_number.sub!(/^0*/,'')

        if collection_name.nil?
          title = self.name.split('/').last
        else
          title = 
           [collection_name, volume_number, document_number].reject{|i| i.blank?}.join(' ')
         end
      else # HGV with no name
        title = "HGV " + self.name.split('/').last.tr(';',' ')
      end
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
    
    template = ERB.new(File.new(template_path).read, nil, '-')
    
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
  
  def rename(new_name, options = {})
    original = self.clone
    options[:original] = original
    
    original_name = self.name
    original_path = self.to_path
    original_relatives = self.relatives

    self.transaction do
      self.name = new_name
      self.title = self.titleize
      self.save!
    
      new_path = self.to_path
      commit_message = "Rename #{self.class::FRIENDLY_NAME} from '#{original_name}' (#{original_path}) to '#{new_name}' (#{new_path})"
    
      self.repository.rename_file(original_path,
                                  new_path,
                                  self.branch,
                                  commit_message,
                                  self.owner.grit_actor)
      
      # rename origin and children
      original_relatives.each do |relative|
        relative.name = new_name
        relative.title = self.title
        relative.save!
        
        # rename the file on the relative
        relative.repository.rename_file(original_path,
                                        new_path,
                                        relative.branch,
                                        commit_message,
                                        self.owner.grit_actor)
      end
      self.after_rename(options)
    end
  end
  
  def after_rename(options = {})
  end
  
  #added to speed up dashboard since titleize can be slow
  def title
    if read_attribute(:title) == nil
      write_attribute(:title,titleize)
      self.save
    end
    return read_attribute(:title)
  end

  def add_change_desc(text = "", user_info = self.publication.creator, input_content = nil)
    doc = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(input_content.nil? ? self.xml_content : input_content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        %w{data xslt common add_change.xsl})),
      :who => user_info.human_name,
      :comment => text
    )
    
    return doc.to_s
  end

  def update_revision_desc(comment_text, user)
    commit_message = "Update revisionDesc\n\n"
    change_desc_content = self.xml_content
    
    self.parent.votes.each do |v|
      change_desc_content = add_change_desc( "Vote - " + v.choice, v.user, change_desc_content )
      commit_message += " - Vote - #{v.choice} (#{v.user.human_name})\n"
    end
    
    change_desc_content = add_change_desc( "Finalized - " + comment_text, user, change_desc_content)
    commit_message += " - Finalized - #{comment_text} (#{user.human_name})"
    
    self.set_xml_content(change_desc_content, :comment => commit_message)
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

end

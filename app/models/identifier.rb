class Identifier < ActiveRecord::Base
  IDENTIFIER_SUBCLASSES = %w{ DDBIdentifier HGVMetaIdentifier HGVTransIdentifier }
  
  validates_presence_of :name, :type
  
  belongs_to :publication
  has_many :comments
  
  validates_inclusion_of :type,
                         :in => IDENTIFIER_SUBCLASSES
  
  require 'jruby_xml'
  
  def self.friendly_name
    return "Base Identifier"
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
    trimmed_name = name.sub(/^oai:papyri.info:identifiers:#{self.class::IDENTIFIER_NAMESPACE}:/, '')
    components = trimmed_name.split(':')
    components.map! {|c| c.to_s}

    return components
  end
  
  def self.new_from_template(publication)
    new_identifier = self.new(:name => self.next_temporary_identifier)
    new_identifier.publication = publication
    
    new_identifier.save!
    
    initial_content = new_identifier.file_template
    new_identifier.set_content(initial_content, :comment => 'Created from SoSOL template', :validate => false)
    
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
                       :conditions => ["name like ?", "oai:papyri.info:identifiers:#{self::IDENTIFIER_NAMESPACE}:#{self::TEMPORARY_COLLECTION}:#{year}:%"],
                       :order => "name DESC",
                       :limit => 1).first
    if latest.nil?
      # no constructed id's for this year/class
      document_number = 1
    else
      document_number = latest.to_components.last.to_i + 1
    end
    
    return sprintf("oai:papyri.info:identifiers:#{self::IDENTIFIER_NAMESPACE}:#{self::TEMPORARY_COLLECTION}:%04d:%04d",
                   year, document_number)
  end
  
  def owner
    self.publication.owner
  end
  
  def mutable?
    self.publication.mutable?
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
  
end

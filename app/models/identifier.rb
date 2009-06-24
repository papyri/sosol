class Identifier < ActiveRecord::Base
  IDENTIFIER_SUBCLASSES = %w{ DDBIdentifier HGVMetaIdentifier HGVTransIdentifier }
  
  validates_presence_of :name, :type
  
  belongs_to :publication
  
  validates_inclusion_of :type,
                         :in => IDENTIFIER_SUBCLASSES
  
  def content
    return self.publication.owner.repository.get_file_from_branch(
      self.to_path, self.publication.branch)
  end
  
  def set_content(content, options = {})
    options.reverse_merge! :comment => ''
    self.publication.owner.repository.commit_content(self.to_path,
                                                    self.publication.branch,
                                                    content,
                                                    options[:comment])
    self.modified = true
    self.save!
  end
  
  def get_commits
    self[:commits] = 
      self.publication.owner.repository.get_log_for_file_from_branch(
        self.to_path, self.publication.branch
    )
  end
  
  def self.next_temporary_identifier
    year = Time.now.year
    latest = self.find(:all,
                       :conditions => ["name like ?", "oai:papyri.info:identifiers:#{self::IDENTIFIER_NAMESPACE}:#{self::TEMPORARY_COLLECTION}:#{year}:%"],
                       :order => "name DESC",
                       :limit => 1)
    if latest.empty?
      # no constructed id's for this year/class
      document_number = 1
    else
      document_number = latest.to_components.last.to_i + 1
    end
    
    return sprintf("oai:papyri.info:identifiers:#{self::IDENTIFIER_NAMESPACE}:#{self::TEMPORARY_COLLECTION}:%04d:%04d",
                   year, document_number)
  end
  
  def mutable?
    self.publication.mutable?
  end
  
  def xml_content
    return self.content
  end
  
  def set_xml_content(content, comment)
    self.set_content(content, :comment => comment)
  end
end

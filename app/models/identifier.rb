class Identifier < ActiveRecord::Base
  IDENTIFIER_SUBCLASSES = %w{ DDBIdentifier HGVMetaIdentifier }
  
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
  end
  
  def get_commits
    self[:commits] = 
      self.publication.owner.repository.get_log_for_file_from_branch(
        self.to_path, self.publication.branch
    )
  end
  
  def xml_content
    return self.content
  end
  
  def set_xml_content(content, comment)
    self.set_content(content, :comment => comment)
  end
end

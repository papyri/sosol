class Identifier < ActiveRecord::Base
  validates_presence_of :name, :type
  
  belongs_to :publication
  
  validates_inclusion_of :type,
                         :in => %w{ DDBIdentifier }
  
  def content
    return self.publication.user.repository.get_file_from_branch(
      self.to_path, self.publication.branch)
  end
  
  def set_content(content, options = {})
    options.reverse_merge! :comment => ''
    self.publication.user.repository.commit_content(self.to_path,
                                                    self.publication.branch,
                                                    content,
                                                    options[:comment])
  end
end

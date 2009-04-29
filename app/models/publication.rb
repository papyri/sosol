class Publication < ActiveRecord::Base
  validates_presence_of :title, :branch
  
  belongs_to :user
  has_and_belongs_to_many :identifiers
  
  validates_uniqueness_of :title, :scope => 'user_id'
  validates_uniqueness_of :branch, :scope => 'user_id'

  validates_each :branch do |model, attr, value|
    # Excerpted from git/refs.c:
    # Make sure "ref" is something reasonable to have under ".git/refs/";
    # We do not like it if:
    if value =~ /^\./ ||    # - any path component of it begins with ".", or
       value =~ /\.\./ ||   # - it has double dots "..", or
       value =~ /[~^: ]/ || # - it has [..], "~", "^", ":" or SP, anywhere, or
       value =~ /\/$/ ||    # - it ends with a "/".
       value =~ /\.lock$/   # - it ends with ".lock"
      model.errors.add(attr, "Title \"#{value}\" contains illegal characters")
    end
    # not yet handling ASCII control characters
  end
  
  # If branch hasn't been specified, create it from the title before
  # validation, replacing spaces with underscore.
  def before_validation
    self.branch ||= title_to_ref(self.title)
  end
  
  def after_create
    user.repository.create_branch(branch)
  end
  
  protected
    def title_to_ref(str)
      str.tr(' ','_')
    end
end

class Publication < ActiveRecord::Base
  validates_presence_of :title
  
  belongs_to :user
  has_and_belongs_to_many :identifiers
  
  validates_uniqueness_of :title, :scope => 'user_id'
  # Excerpted from git/refs.c:
  #   Make sure "ref" is something reasonable to have under ".git/refs/";
  #   We do not like it if:
  #
  #   - any path component of it begins with ".", or
  #   - it has double dots "..", or
  #   - it has ASCII control character, "~", "^", ":" or SP, anywhere, or
  #   - it ends with a "/".
  #   - it ends with ".lock"
  validates_each :title do |model, attr, value|
    if value =~ /\.lock$/ ||
       value =~ /\/$/ ||
       value =~ /\.\./ ||
       value =~ /[~^: ]/ ||
       value =~ /^\./
      model.errors.add(attr, "Title \"#{value}\" contains illegal characters")
    end
  end
  
  # Spaces are a special case which we want to replace with underscore,
  # do this before validation so that we validate and save the underscored
  # version
  def before_validation
    self.title = title_to_ref(self.title)
  end
  
  def after_create
    user.repository.create_branch(title)
  end
  
  protected
    def title_to_ref(str)
      str.tr(' ','_')
    end
end

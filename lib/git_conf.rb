# Tell a branch to have its own database with:
#   git config branch.#{branch_name}.database true
# Clone from master with rake git:db:clone
require 'rubygems'
require 'grit' # "mojombo-grit" gem from github

def Rails.repo
  @@repository ||= Grit::Repo.new(Rails.root)
end

# Adjust your environment.rb to use this subclass:
#   Rails::Initializer.run(:process, GitConf.new) do |config|
#     ...
#   end
class GitConf < Rails::Configuration
  def initialize
    super
    @branched_database = false
  end
  
  def branched_database?() @branched_database end
  
  # agument the original method in order to append
  # the branch name suffix in certain conditions
  def database_configuration
    @database_configuration ||= begin
      config = super
      if Rails.env == "development"
        head = Rails.repo.head
        branch = head && head.name
        # check if this branch has a special database
        if branch and branch != "master" and branch !~ /\W/ and branch_has_database?(branch)
          development = config["development"]
          # save original configuration
          development["master-database"] = development["database"]
          # append branch name suffix
          base_name, extension = development["database"].split(".", 2)
          development["database"] = "#{base_name}_#{branch}"
          development["database"] += ".#{extension}" if extension
          # finally, indicate that this database has branched
          @branched_database = true
        end
      end
      config
    end
  end
  
  protected
  
  def branch_has_database?(branch)
    Rails.repo.config["branch.#{branch}.database"] == "true"
  end
end
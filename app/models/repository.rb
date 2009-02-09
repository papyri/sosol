require 'fileutils'

class Repository
  attr_reader :master, :path, :repo
  
  def initialize(master)
    @master = master
    @path = File.join(USER_REPOSITORY_ROOT, "#{master.name}.git")
    @canonical = Grit::Repo.new(CANONICAL_REPOSITORY)
    if exists?
      @repo = Grit::Repo.new(path)
    else
      @repo = nil
    end
  end
  
  def exists?
    master.has_repository?
  end
  
  def create
    master.update_attribute :has_repository, true
    # create a git repository
    @repo ||= @canonical.fork_bare(path)
  end
  
  def destroy
    master.update_attribute :has_repository, false
    # destroy a git repository
    FileUtils::rm_r path, :verbose => true, :secure => true
  end
  
  def create_branch(name)
    # We have to abuse git here because Grit::Head doesn't appear to have
    # a facility for writing out a sha1 to refs/heads/name yet
    # Also, we always assume we want to branch from master
    # TODO: Update master branch tip from canonical
    @repo.git.branch({}, name, 'master')
  end
end
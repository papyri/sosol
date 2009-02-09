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
end
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
    
    # create some placeholder branches
    ["p.genova/p.genova.2/p.genova.2.67.xml",
    "sb/sb.24/sb.24.16003.xml",
    "p.lond/p.lond.7/p.lond.7.2067.xml",
    "p.ifao/p.ifao.2/p.ifao.2.31.xml",
    "p.gen.2/p.gen.2.1/p.gen.2.1.4.xml",
    "p.harr/p.harr.1/p.harr.1.109.xml",
    "p.petr.2/p.petr.2.30.xml",
    "sb/sb.16/sb.16.12255.xml",
    "p.harr/p.harr.2/p.harr.2.193.xml",
    "p.oxy/p.oxy.43/p.oxy.43.3118.xml",
    "chr.mitt/chr.mitt.12.xml",
    "sb/sb.12/sb.12.11001.xml",
    "p.stras/p.stras.9/p.stras.9.816.xml",
    "sb/sb.6/sb.6.9108.xml",
    "p.yale/p.yale.1/p.yale.1.43.xml",
    "p.yale/p.yale.1/p.yale.1.44.xml"].each do |fixture|
      create_branch("DDB_EpiDoc_XML/" + fixture)
    end
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
  
  def branches
    @repo.branches.map{|b| b.name}.delete("master")
  end
end
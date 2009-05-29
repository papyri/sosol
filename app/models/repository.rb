require 'fileutils'

class Grit::Commit
  def to_hash
    return {
      :id => @id,
      # Default for this is just first 7 chars
      # :id_abbrev => id_abbrev,
      :author_name => @author.name,
      :author_email => @author.email,
      :authored_date => @authored_date,
      :committer_name => @committer.name,
      :committer_email => @committer.email,
      :committed_date => @committed_date,
      :message => @message
    }
  end
end

class Repository
  attr_reader :master, :path, :repo
  
  # Allow Repository instances to be created outside User context.
  # These instances will only work with the canonical repo.
  def initialize(master = nil)
    @master = master
    if master.nil?
      @path = CANONICAL_REPOSITORY
    else
      @path = File.join(USER_REPOSITORY_ROOT, "#{master.name}.git")
    end
    
    @canonical = Grit::Repo.new(CANONICAL_REPOSITORY)
    if master.nil? || exists?
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
  
  def get_file_from_branch(file, branch)
    tree = @repo.tree(branch, [File.dirname(file)])
    subtree = tree.contents.first
    blob = subtree / File.basename(file)
    return blob.data
  end
  
  def get_log_for_file_from_branch(file, branch)
    @repo.log(branch, file).map{|commit| commit.to_hash}
  end
  
  def create_branch(name)
    # We have to abuse git here because Grit::Head doesn't appear to have
    # a facility for writing out a sha1 to refs/heads/name yet
    # Also, we always assume we want to branch from master
    # TODO: Update master branch tip from canonical
    
    @repo.git.branch({}, name, 'master')
  end
  
  def branches
    @repo.branches.map{|b| b.name}
  end
  
  def commit_content(file, branch, data, comment)
    index = @repo.index
    index.read_tree(branch)
    index.add(file, data)
    index.commit(comment,
                 @repo.commits(branch,1).first.to_s, # commit parent
                 nil,
                 nil,
                 branch)
  end
end
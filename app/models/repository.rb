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
      master_class_path = @master.class.to_s.underscore.pluralize
      FileUtils.mkdir_p(File.join(REPOSITORY_ROOT, master_class_path))
      @path = File.join(REPOSITORY_ROOT,
                        master_class_path, "#{master.name}.git")
    end
    
    @canonical = Grit::Repo.new(CANONICAL_REPOSITORY)
    if master.nil? || exists?(path)
      @repo = Grit::Repo.new(path)
    else
      @repo = nil
    end
  end
  
  def exists?(path)
    # master.has_repository?
    File.exists?(path)
  end

  def create
    # master.update_attribute :has_repository, true
    # create a git repository
    @repo ||= @canonical.fork_bare(path)
  end
  
  def destroy
    # master.update_attribute :has_repository, false
    # destroy a git repository
    FileUtils::rm_r path, :verbose => false, :secure => true
  end
  
  def get_file_from_branch(file, branch = 'master')  
    tree = @repo.tree(branch, [File.dirname(file)])
    subtree = tree.contents.first
    return nil if subtree.nil?
    blob = subtree / File.basename(file)
    return blob.nil? ? nil : blob.data
  end
  
  def get_all_files_from_path_on_branch(path = '', branch = 'master')
    root_tree = @repo.tree(branch, [path]).contents.first
    return recurse_git_tree(root_tree, [path])
  end
  
  def recurse_git_tree(tree, path)
    files = []
    tree.blobs.each do |blob|
      files << File.join(path, blob.name)
    end
    tree.trees.each do |this_tree|
      path.push(this_tree.name)
      files += recurse_git_tree(this_tree, path)
      path.pop
    end
    return files
  end
  
  def get_log_for_file_from_branch(file, branch = 'master')
    @repo.log(branch, file).map{|commit| commit.to_hash}
  end
  
  def create_branch(name, source_name = 'master')
    # We have to abuse git here because Grit::Head doesn't appear to have
    # a facility for writing out a sha1 to refs/heads/name yet
    # Also, we always assume we want to branch from master by default
    # TODO: Update master branch tip from canonical?
    
    @repo.git.branch({}, name, source_name)
  end
  
  def copy_branch_from_repo(branch, new_branch, other_repo)
    self.add_alternates(other_repo)
    head_ref = other_repo.repo.get_head(branch).commit.sha
    self.create_branch(new_branch, head_ref)
  end
  
  def add_alternates(other_repo)
    @repo.alternates = @repo.alternates() | [ File.join(other_repo.repo.path, "objects") ]
  end
  
  def branches
    @repo.branches.map{|b| b.name}
  end
  
  def commit_content(file, branch, data, comment)
    if @path == CANONICAL_REPOSITORY
      raise "Cannot commit directly to canonical repository"
    end
    
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

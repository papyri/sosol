# encoding: utf-8

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

class JGitTree
  attr_accessor :parent
  attr_accessor :nodes
  attr_accessor :name, :sha, :mode
  attr_accessor :repo, :branch

  def initialize()
    @parent = nil
    @nodes = {}
    @mode = org.eclipse.jgit.lib.FileMode::TREE
    return self
  end

  def load_from_repo(repo, branch, path = nil)
    @repo ||= repo
    @branch ||= branch

    # read the root node into nodes
    last_commit_id = repo.resolve(branch)
    jgit_tree = org.eclipse.jgit.revwalk.RevWalk.new(repo).parseCommit(last_commit_id).getTree()

    tree_walk = org.eclipse.jgit.treewalk.TreeWalk.new(repo)
    tree_walk.addTree(jgit_tree)
    unless path.nil?
      # puts "Tree walk for path: #{path}"
      tree_walk = org.eclipse.jgit.treewalk.TreeWalk.forPath(repo,path,jgit_tree)
      # path_filter = org.eclipse.jgit.treewalk.filter.PathFilter.create(path)
      # tree_walk.setFilter(path_filter)
      # tree_walk.next()
      tree_walk.enterSubtree()
    end
    tree_walk.setRecursive(false)
    tree_walk.setPostOrderTraversal(true)
    
    while tree_walk.next()
      current_name = tree_walk.getNameString()
      if !path.nil? && path.split('/').length != tree_walk.getDepth()
        # puts "Skipping #{current_name}"
        next
      end
      # puts "Walking #{current_name}"
      nodes[current_name] = JGitTree.new()
      nodes[current_name].set_sha(tree_walk.getObjectId(0).name(), tree_walk.getFileMode(0), self)
    end
  end

  def set_sha(sha, mode, parent)
    # puts "Set SHA: #{sha} #{mode}"
    @nodes = {}
    @sha = sha
    @mode = mode
    @parent = parent
    # if we're a tree, read the current tree
  end

  def add(path, sha, mode)
    # puts "Add for #{path}"
    # takes a path relative to this tree and adds it
    components = path.split('/')
    if components.length > 1 # need to recurse
      if nodes[components.first].nodes.length == 0 # need to load this subtree first
        nodes[components.first].load_from_repo(self.root.repo, self.root.branch, nodes[components.first].path)
      end
      nodes[components.first].add(components[1..-1].join('/'), sha, mode)
      nodes[components.first].update_sha
    else # base case
      nodes[path] = JGitTree.new()
      nodes[path].set_sha(sha, mode, self)
      # puts "Added #{path} in #{self.path}: #{sha} #{mode}"
    end
  end

  def del(path)
    # takes a path relative to this tree and removes it
    components = path.split('/')
    if components.length > 1 # need to recurse
      if nodes[components.first].nodes.length == 0 # need to load this subtree first
        nodes[components.first].load_from_repo(self.root.repo, self.root.branch, nodes[components.first].path)
      end
      nodes[components.first].del(components[1..-1].join('/'))
      nodes[components.first].update_sha
    else
      nodes.delete(path)
    end
  end

  def path
    if parent.nil?
      return ""
    else
      return (parent.path + '/' + parent.nodes.key(self)).sub(/^\//,'')
    end
  end

  def update_sha
    inserter = root.repo.newObjectInserter()
    formatter = org.eclipse.jgit.lib.TreeFormatter.new()

    nodes.keys.sort.each do |node|
      # puts "About to append #{node} #{nodes[node].mode} #{nodes[node].sha} in #{self.path}"
      formatter.append(node, nodes[node].mode, org.eclipse.jgit.lib.ObjectId.fromString(nodes[node].sha))
    end

    tree_id = inserter.insert(formatter)
    inserter.flush()
    @sha = tree_id.name()
  end

  def depth(n = 0)
    if parent.nil?
      return n
    else
      return parent.depth(n + 1)
    end
  end

  def to_s
    pretty = ""
    nodes.each do |key, value|
      depth.times { pretty += "  " }
      pretty += "#{value.sha} #{key}\n"
      pretty += value.to_s
      # pretty += "\n"
    end
    return pretty
  end

  def root
    if parent.nil?
      return self
    else
      return parent.root
    end
  end

  def add_blob(path, sha)
    add(path, sha, org.eclipse.jgit.lib.FileMode::REGULAR_FILE)
  end

  def add_tree(path, sha)
    add(path, sha, org.eclipse.jgit.lib.FileMode::TREE)
  end

  def write!
  end
end

class Repository
  attr_reader :master, :path, :repo, :jgit_repo
  
  # Allow Repository instances to be created outside User context.
  # These instances will only work with the canonical repo.
  def initialize(master = nil)
    @master = master
    if master.nil?
      @path = Sosol::Application.config.canonical_repository
    else
      @master_class_path = @master.class.to_s.underscore.pluralize
      if @master.class == Board
        unless @master.community.nil?
          @master_class_path = File.join('communities', @master.community.name)
        end
      end
      FileUtils.mkdir_p(File.join(Sosol::Application.config.repository_root, @master_class_path))
      
      @path = File.join(Sosol::Application.config.repository_root,
                        @master_class_path, "#{master.name}.git")
    end
    
    @canonical = Grit::Repo.new(Sosol::Application.config.canonical_repository)
    if master.nil? || exists?(path)
      @repo = Grit::Repo.new(path)

      begin
        @jgit_repo = org.eclipse.jgit.storage.file.FileRepositoryBuilder.new.setGitDir(java.io.File.new(path)).readEnvironment().findGitDir().build()
      rescue Exception => e
        Rails.logger.info("JGIT CorruptObjectException: #{e.inspect}")
      end
    else
      @repo = nil
      @jgit_repo = nil
    end
  end
  
  def owner
    return @master
  end
  
  def exists?(path)
    # master.has_repository?
    File.exists?(path)
  end

  def create
    # master.update_attribute :has_repository, true
    # create a git repository
    @repo ||= @canonical.fork_bare(path)
    begin
      @jgit_repo ||= org.eclipse.jgit.storage.file.FileRepositoryBuilder.new.setGitDir(java.io.File.new(path)).readEnvironment().findGitDir().build()
    rescue Exception => e
      Rails.logger.info("JGIT CorruptObjectException: #{e.inspect}")
    end
  end
  
  def destroy
    # master.update_attribute :has_repository, false
    # destroy a git repository
    
    # BEFORE DELETION: REPACK CANONICAL
    # This will pull in all objects regardless of alternates/shared status.
    # If you delete an alternates-referenced repository without repacking,
    # referenced objects will disappear, possibly making the repo unusable.
    @canonical.git.repack({})
    
    canon = Repository.new
    canon.del_alternates(self)
    `rm -r "#{path}"`
  end
  
  #returns the blob that represents the given file
  #the given file is the filename + path to the file
  def get_blob_from_branch(file, branch = 'master')
    begin
      if @jgit_repo.nil?
        # Rails.logger.info("JGIT NIL")
        return nil
      end
      last_commit_id = @jgit_repo.resolve(branch)
      jgit_tree = org.eclipse.jgit.revwalk.RevWalk.new(@jgit_repo).parseCommit(last_commit_id).getTree()
      path_filter = org.eclipse.jgit.treewalk.filter.PathFilter.create(file)
      tree_walk = org.eclipse.jgit.treewalk.TreeWalk.new(@jgit_repo)
      tree_walk.addTree(jgit_tree)
      tree_walk.setRecursive(true)
      tree_walk.setFilter(path_filter)
      if !tree_walk.next()
        Rails.logger.info("JGIT TREEWALK for #{file} on #{branch}: #{tree_walk}")
        return nil
      end
      # jgit_blob = ""
      # @jgit_repo.open(tree_walk.getObjectId(0)).copyTo(jgit_blob)
      # Rails.logger.info("JGIT BLOB: #{jgit_blob}")
      jgit_blob = ""
      begin
        Rails.logger.info("JGIT Blob ID for #{file} on #{branch} = #{tree_walk.getObjectId(0).name()}")
        jgit_blob = org.apache.commons.io.IOUtils.toString(@jgit_repo.open(tree_walk.getObjectId(0)).openStream(), "UTF-8")
      rescue Exception => e
        Rails.logger.info("JGIT Blob Exception for #{file} on #{branch} in #{path}: #{e.inspect}")
        return nil
      end
      Rails.logger.info("JGIT BLOB for #{file} on #{branch} in #{path}: #{jgit_blob.force_encoding("UTF-8").length}")
      return jgit_blob
    rescue Exception => e
      Rails.logger.info("JGIT Exception: #{e.inspect}\n#{caller.join("\n")}")
      return nil
    end
  end
  
  def get_file_from_branch(file, branch = 'master')  
    blob = get_blob_from_branch(file, branch)
    return get_blob_data(blob)
  end
  
  def get_blob_data(blob)
    begin
      # blob.data gets INSANELY slow for large files in a large repo,
      # this uses @repo.git.show to call a git command instead:
      #   slower than I would like but still an order of magnitude
      #   faster (for an example see e.g.
      #   DDB_EpiDoc_XML/p.mich/p.mich.4.1/p.mich.4.1.224.xml)
      # data = blob.nil? ? nil : @repo.git.show({}, blob.id.to_s)
      # BALMAS -> above problem was addressed via a patch to the GRIT modules
      # should should be okay now to cal blob.data
      data = blob.nil? ? nil : blob # .data
      return data
    rescue Grit::Git::GitTimeout
      self.class.increase_timeout
      get_blob_data(blob)
    end
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
    @repo.log(branch, file, :follow => true).map{|commit| commit.to_hash}
  end
  
  def update_master_from_canonical
    @repo.update_ref('master',@canonical.get_head('master').commit.id)
  end
  
  def create_branch(name, source_name = 'master')
    # We always assume we want to branch from master by default
    if source_name == 'master'
      self.update_master_from_canonical
      source_name = @repo.get_head(source_name).commit.id
    end
    
    org.eclipse.jgit.api.Git.new(@jgit_repo).branchCreate().setName(name).setStartPoint(source_name).call()
  end
  
  def delete_branch(name)
    org.eclipse.jgit.api.Git.new(@jgit_repo).branchDelete().setBranchNames("refs/heads/#{name}").setForce(true).call()
  end
  
  #(from_branch, to_branch, from_repo)
  def copy_branch_from_repo(branch, new_branch, other_repo)
    # Lightweight (but have to watch out for side-effects of repo deletion):
    # self.add_alternates(other_repo)
    # Heavyweight (missing objects are actually copied):
    self.fetch_objects(other_repo)
    
    head_ref = other_repo.repo.get_head(branch).commit.sha
    self.create_branch(new_branch, head_ref)
  end
  
  def add_remote(other_repo)
    unless @repo.remote_list.include?(other_repo.name)
      @repo.remote_add(other_repo.name, other_repo.path)
    end
  end
  
  def fetch_objects(other_repo)
    self.add_remote(other_repo)
    begin
      @repo.remote_fetch(other_repo.name)
    rescue Grit::Git::GitTimeout
      self.class.increase_timeout
      fetch_objects(other_repo)
    end
  end
  
  def name
    return [@master_class_path, @master.name].join('/').tr(' ', '_')
  end
  
  def add_alternates(other_repo)
    @repo.alternates = @repo.alternates() | [ File.join(other_repo.repo.path, "objects") ]
  end
  
  def del_alternates(other_repo)
    @repo.alternates = @repo.alternates() - [ File.join(other_repo.repo.path, "objects") ]
  end
  
  def branches
    org.eclipse.jgit.api.Git.new(@jgit_repo).branchList().call().map{|e| e.getName().sub(/^refs\/heads\//,'')}
  end
  
  def rename_file(original_path, new_path, branch, comment, actor)
    content = get_file_from_branch(original_path, branch)
    new_blob = get_blob_from_branch(new_path, branch)
    Rails.logger.info("JGIT RENAME #{original_path} -> #{new_path} = #{new_blob.inspect}")

    if !content
      raise "Rename error: Original file '#{original_path}' does not exist on branch '#{branch}'"
    elsif !new_blob.nil?
      raise "Rename error: Destination file '#{new_path}' already exists on branch '#{branch}'"
    end
    
    index = @repo.index
    index.read_tree(branch)
    # do the rename here, against index.tree
    # rename is just a simultaneous add/delete
    # add the new data
    index.add(new_path, content)
    # remove the old path from the tree
    index.delete(original_path)

    index.commit(comment,
                 @repo.commits(branch,1), # commit parent,
                 actor,
                 nil,
                 branch)
  end
  
  # Returns a String of the SHA1 of the commit
  def commit_content(file, branch, data, comment, actor = nil)
    if @path == Sosol::Application.config.canonical_repository
      raise "Cannot commit directly to canonical repository" unless (file == CollectionIdentifier.new.to_path)
    end

    begin
      inserter = @jgit_repo.newObjectInserter()
      file_id = inserter.insert(org.eclipse.jgit.lib.Constants::OBJ_BLOB, data.to_java_bytes)

      last_commit_id = @jgit_repo.resolve(branch)
      
      jgit_tree = org.eclipse.jgit.revwalk.RevWalk.new(@jgit_repo).parseCommit(last_commit_id).getTree()
      path_filter = org.eclipse.jgit.treewalk.filter.PathFilter.create(File.dirname(file))
      tree_walk = org.eclipse.jgit.treewalk.TreeWalk.new(@jgit_repo)
      tree_walk.addTree(jgit_tree)
      tree_walk.setRecursive(true)
      tree_walk.setFilter(path_filter)

      # insert the leaf tree object with the new blob in it
      formatter = org.eclipse.jgit.lib.TreeFormatter.new()
      blob_inserted = false
      while tree_walk.next()
        current_file = File.basename(tree_walk.getPathString())
        Rails.logger.info("JGIT Commit walked: #{current_file}")
        if (!blob_inserted) && (current_file > File.basename(file))
          Rails.logger.info("JGIT Commit inserted: #{File.basename(file)}")
          formatter.append(File.basename(file), org.eclipse.jgit.lib.FileMode::REGULAR_FILE, file_id)
          blob_inserted = true
        end
        if current_file != File.basename(file)
          formatter.append(current_file, tree_walk.getFileMode(0), tree_walk.getObjectId(0))
        end
      end
      if !blob_inserted
        Rails.logger.info("JGIT Commit inserted: #{File.basename(file)}")
        formatter.append(File.basename(file), org.eclipse.jgit.lib.FileMode::REGULAR_FILE, file_id)
      end

      tree_id = inserter.insert(formatter)

      components = File.dirname(file).split("/")
      # components.pop
      components.each_index do |i|
        # for each dir, we need to write a new tree which points to
        # - all trees
        # - all blobs
        current_full_dir = components[0..-(i+1)].join("/")
        current_parent_dir = components[0..-(i+2)].join("/")
        current_dir = components[-(i+1)]
        
        tree_walk = org.eclipse.jgit.treewalk.TreeWalk.new(@jgit_repo)
        tree_walk.addTree(jgit_tree)
        tree_walk.setRecursive(true)
        tree_walk.setPostOrderTraversal(true)
        if current_parent_dir != ""
          path_filter = org.eclipse.jgit.treewalk.filter.PathFilter.create(current_parent_dir)
          tree_walk.setFilter(path_filter)
        end

        Rails.logger.info("JGIT Commit walking: #{current_full_dir} = #{tree_walk.getTreeCount()}")

        formatter = org.eclipse.jgit.lib.TreeFormatter.new()
        tree_inserted = false
        while tree_walk.next()
          current_file = tree_walk.getPathString()
          # if tree_walk.isSubtree()
            # Rails.logger.info("JGIT Subtree: #{current_file}")
          # end
          if (current_file.split("/").length == current_full_dir.split("/").length)
            # Rails.logger.info("JGIT Commit walked @ depth #{tree_walk.getDepth()}: #{current_file}")
            current_file = current_file.split("/")[-1]
            if (!tree_inserted) && (current_file > current_dir)
              Rails.logger.info("JGIT Commit inserted: #{current_dir}")
              formatter.append(current_dir, org.eclipse.jgit.lib.FileMode::TREE, tree_id)
              tree_inserted = true
            end

            if (!tree_inserted) && (current_file == current_dir)
              Rails.logger.info("JGIT Commit inserted: #{current_dir}")
              formatter.append(current_dir, org.eclipse.jgit.lib.FileMode::TREE, tree_id)
              tree_inserted = true
            else
              formatter.append(current_file, tree_walk.getFileMode(0), tree_walk.getObjectId(0))
            end
          else
            # Rails.logger.info("JGIT Commit skipped: #{current_file} for #{current_full_dir}")
          end
        end
        if !tree_inserted
          Rails.logger.info("JGIT Commit inserted: #{current_dir}")
          formatter.append(current_dir, org.eclipse.jgit.lib.FileMode::TREE, tree_id)
        end

        tree_id = inserter.insert(formatter)
      end

      person_ident = org.eclipse.jgit.lib.PersonIdent.new("name", "email")

      commit = org.eclipse.jgit.lib.CommitBuilder.new()
      commit.setTreeId(tree_id)
      commit.setParentId(@jgit_repo.resolve(branch))
      commit.setAuthor(person_ident)
      commit.setCommitter(person_ident)
      commit.setMessage(comment)

      commit_id = inserter.insert(commit)
      inserter.flush()

      Rails.logger.info("JGIT COMMIT before: #{@jgit_repo.resolve(branch).name()}")
      ref_update = @jgit_repo.updateRef(branch)
      # ref_update.setForceUpdate(true)
      ref_update.setRefLogIdent(person_ident)
      ref_update.setNewObjectId(commit_id)
      ref_update.setExpectedOldObjectId(@jgit_repo.resolve(branch))
      # ref_update.setExpectedOldObjectId(org.eclipse.jgit.lib.ObjectId.zeroId())
      ref_update.setRefLogMessage("commit: #{comment}", false)

      result = ref_update.update()
      Rails.logger.info("JGIT COMMIT #{file} = #{file_id.name()} on #{branch} = #{tree_id.name()} comment '#{comment}' = #{commit_id.name()}: #{result.toString()}")

      Rails.logger.info("JGIT COMMIT after: #{@jgit_repo.resolve(branch).name()}")
      self.get_blob_from_branch(file, branch)
      return commit_id.name()
    rescue Exception => e
      Rails.logger.info("JGIT COMMIT exception #{file} on #{branch} comment #{comment}: #{e.inspect}")
      return nil
    end
  end
  
  def self.increase_timeout
    Grit::Git.git_timeout *= 2
    RAILS_DEFAULT_LOGGER.warn "Git timed out, increasing timeout to #{Grit::Git.git_timeout}"
  end
  
  def safe_repo_name(name)
    java.text.Normalizer.normalize(name.tr(' ','_'),java.text.Normalizer::Form::NFD).gsub(/\p{M}/,'')
  end
end

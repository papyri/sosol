# encoding: utf-8

require 'fileutils'
require 'jgit_tree'
require 'shellwords'

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
  @@jgit_repo_cache = java.util.WeakHashMap.new

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
    else
      @repo = nil
    end
  end

  def jgit_repo
    result = @@jgit_repo_cache.get(@path)
    if result.nil? && exists?(@path)
      begin
        result = org.eclipse.jgit.storage.file.FileRepositoryBuilder.new.setGitDir(java.io.File.new(path)).readEnvironment().findGitDir().build()
        @@jgit_repo_cache.put(@path, result)
      rescue Exception => e
        Rails.logger.error("JGIT CorruptObjectException: #{e.inspect}\n#{e.backtrace.join("\n")}")
      end
    end
    return result
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
      @@jgit_repo_cache.put(path, org.eclipse.jgit.storage.file.FileRepositoryBuilder.new.setGitDir(java.io.File.new(path)).readEnvironment().findGitDir().build())
    rescue Exception => e
      Rails.logger.error("JGIT CorruptObjectException: #{e.inspect}\n#{e.backtrace.join("\n")}")
    end
  end

  def destroy
    # master.update_attribute :has_repository, false
    # destroy a git repository

    # BEFORE DELETION: REPACK CANONICAL
    # This will pull in all objects regardless of alternates/shared status.
    # If you delete an alternates-referenced repository without repacking,
    # referenced objects will disappear, possibly making the repo unusable.
    begin
      @canonical.git.repack({})

      canon = Repository.new
      canon.del_alternates(self)
      `rm -r "#{path}"`
    rescue Grit::Git::GitTimeout
      self.class.increase_timeout
      self.destroy
    end
  end

  #returns the blob that represents the given file
  #the given file is the filename + path to the file
  def get_blob_from_branch(file, branch = 'master')
    begin
      if self.jgit_repo.nil?
        # Rails.logger.info("JGIT NIL")
        return nil
      end
      last_commit_id = self.jgit_repo.resolve(branch)
      jgit_tree = org.eclipse.jgit.revwalk.RevWalk.new(self.jgit_repo).parseCommit(last_commit_id).getTree()
      path_filter = org.eclipse.jgit.treewalk.filter.PathFilter.create(file)
      tree_walk = org.eclipse.jgit.treewalk.TreeWalk.new(self.jgit_repo)
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
        Rails.logger.debug("JGIT Blob ID for #{file} on #{branch} = #{tree_walk.getObjectId(0).name()}")
        jgit_blob = org.apache.commons.io.IOUtils.toString(self.jgit_repo.open(tree_walk.getObjectId(0)).openStream(), "UTF-8")
      rescue Exception => e
        Rails.logger.error("JGIT Blob Exception for #{file} on #{branch} in #{path}: #{e.inspect}\n#{e.backtrace.join("\n")}")
        return nil
      end
      Rails.logger.debug("JGIT BLOB for #{file} on #{branch} in #{path}: #{jgit_blob.force_encoding("UTF-8").length}")
      return jgit_blob
    rescue Exception => e
      Rails.logger.error("JGIT Exception: #{e.inspect}\n#{caller.join("\n")}\n#{e.backtrace.join("\n")}")
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

  def get_log_for_file_from_branch(file, branch = 'master', limit = 1)
    @repo.log(branch, file, {:follow => true, :max_count => limit}).map{|commit| commit.to_hash}
  end

  def update_master_from_canonical
    @repo.update_ref('master',@canonical.get_head('master').commit.id)
  end

  def create_branch(name, source_name = 'master', force = false)
    # We always assume we want to branch from master by default
    if source_name == 'master'
      self.update_master_from_canonical
    end

    begin
      ref = org.eclipse.jgit.api.Git.new(self.jgit_repo).branchCreate().setName(name).setStartPoint(source_name).setForce(force).call()
      # Rails.logger.debug("Branched #{ref.getName()} from #{source_name} = #{ref.getObjectId().name()}")
    rescue Exception => e
      Rails.logger.error("create_branch exception: #{e.inspect}\n#{e.backtrace.join("\n")}")
    end
  end

  def delete_branch(name)
    org.eclipse.jgit.api.Git.new(self.jgit_repo).branchDelete().setBranchNames("refs/heads/#{name}").setForce(true).call()
  end

  #(from_branch, to_branch, from_repo)
  def copy_branch_from_repo(branch, new_branch, other_repo)
    # Lightweight (but have to watch out for side-effects of repo deletion):
    # self.add_alternates(other_repo)
    # Heavyweight (missing objects are actually copied):
    #head_ref = other_repo.jgit_repo.resolve(branch).name()
    Rails.logger.info("copy_branch_from_repo(#{branch}, #{new_branch}, #{other_repo.path}, #{@path})")
    begin
      Java::gitwrapper.utils::fetchLite(branch, new_branch, other_repo.path, @path)
    rescue Java::JavaUtilConcurrent::ExecutionException => e
      Rails.logger.error(e.inspect)
      fallback_git_command = "git --git-dir=#{Shellwords.escape(@path)} fetch #{other_repo.name} #{branch}:#{new_branch}"
      Rails.logger.info("Trying fallback git command: #{fallback_git_command}")
      Rails.logger.info(`#{fallback_git_command}`)
      unless $?.to_i == 0
        raise "Error with fallback git command in copy_branch_from_repo"
      end
    end
    #self.fetch_objects(other_repo, branch)
    #Rails.logger.info("copy_branch_from_repo #{branch} = #{head_ref} locally: #{jgit_repo.resolve("refs/remotes/" + other_repo.name + "/" + branch).name()}")
    #self.create_branch(new_branch, other_repo.name + "/" + branch)
  end

  def add_remote(other_repo)
    remote_configs = org.eclipse.jgit.transport.RemoteConfig.getAllRemoteConfigs(self.jgit_repo.getConfig()).to_a
    unless remote_configs.map{|c| c.getName()}.include?(other_repo.name)
      remote_config = org.eclipse.jgit.transport.RemoteConfig.new(self.jgit_repo.getConfig(), other_repo.name)
      remote_config.addURI(org.eclipse.jgit.transport.URIish.new("file://" + other_repo.path))
      remote_config.update(self.jgit_repo.getConfig())
    end
  end

  def fetch_objects(other_repo, branch = nil)
    Rails.logger.debug("fetch_objects: #{other_repo.name}, #{branch}")
    Rails.logger.debug("Adding remote #{other_repo.name}")
    self.add_remote(other_repo)
    Rails.logger.debug("Remote added")
    begin
      fetch_command = org.eclipse.jgit.api.Git.new(self.jgit_repo).fetch()
      fetch_command.setRemote(other_repo.name)
      fetch_command.setThin(false)
      unless branch.nil?
        fetch_command.setRefSpecs(org.eclipse.jgit.transport.RefSpec.new("+refs/heads/" + branch + ":" + "refs/remotes/" + other_repo.name + "/" + branch))
      end
      Rails.logger.debug("Running fetch")
      result = fetch_command.call()
      Rails.logger.debug("Fetch complete")
      unless branch.nil?
        update = result.getTrackingRefUpdate("refs/remotes/" + other_repo.name + "/" + branch)
        if update.nil?
          Rails.logger.debug("fetch: ref not updated")
        else
          Rails.logger.debug("fetch: updated #{update.getRemoteName()} #{update.getOldObjectId()} -> #{update.getNewObjectId()} with result #{update.getResult().toString()}")
        end
      end
    rescue Grit::Git::GitTimeout
      self.class.increase_timeout
      fetch_objects(other_repo)
    rescue Java::OrgEclipseJgitApiErrors::TransportException => e
      Rails.logger.error("fetch transport exception: #{e.inspect}\n#{e.backtrace.join("\n")}")
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
    org.eclipse.jgit.api.Git.new(self.jgit_repo).branchList().call().map{|e| e.getName().sub(/^refs\/heads\//,'')}
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

    # TODO: just get the object id instead of reinserting
    inserter = self.jgit_repo.newObjectInserter()
    file_id = inserter.insert(org.eclipse.jgit.lib.Constants::OBJ_BLOB, content.to_java_string.getBytes(java.nio.charset.Charset.forName("UTF-8")))
    inserter.flush()
    inserter.release()

    jgit_tree = JGit::JGitTree.new()
    jgit_tree.load_from_repo(self.jgit_repo, branch)
    jgit_tree.add_blob(new_path, file_id.name())
    jgit_tree.del(original_path)
    jgit_tree.commit(comment, actor)

    # index = @repo.index
    # index.read_tree(branch)
    # do the rename here, against index.tree
    # rename is just a simultaneous add/delete
    # add the new data
    # index.add(new_path, content)
    # remove the old path from the tree
    # index.delete(original_path)

    # index.commit(comment,
                 # @repo.commits(branch,1), # commit parent,
                 # actor,
                 # nil,
                 # branch)
  end

  # Returns a String of the SHA1 of the commit
  def commit_content(file, branch, data, comment, actor)
    if @path == Sosol::Application.config.canonical_repository
      raise "Cannot commit directly to canonical repository" unless (file == CollectionIdentifier.new.to_path)
    end

    begin
      inserter = self.jgit_repo.newObjectInserter()
      file_id = inserter.insert(org.eclipse.jgit.lib.Constants::OBJ_BLOB, data.to_java_string.getBytes(java.nio.charset.Charset.forName("UTF-8")))

      last_commit_id = self.jgit_repo.resolve(branch)

      jgit_tree = JGit::JGitTree.new()
      jgit_tree.load_from_repo(self.jgit_repo, branch)
      jgit_tree.add_blob(file, file_id.name())

      jgit_tree.commit(comment, actor)
      inserter.flush()
      inserter.release()
    rescue Exception => e
      Rails.logger.error("JGIT COMMIT exception #{file} on #{branch} comment #{comment}: #{e.inspect}\n#{e.backtrace.join("\n")}")
      raise Exceptions::CommitError.new("Commit failed. #{e.message}")
    end
  end

  def self.increase_timeout
    Grit::Git.git_timeout *= 2
    Rails.logger.warn "Git timed out, increasing timeout to #{Grit::Git.git_timeout}"
  end

  def safe_repo_name(name)
    java.text.Normalizer.normalize(name.tr(' ','_'),java.text.Normalizer::Form::NFD).gsub(/\p{M}/,'')
  end
end

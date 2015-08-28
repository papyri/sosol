# encoding: utf-8

require 'fileutils'
require 'jgit_tree'
require 'shellwords'

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

    if master.nil? || exists?(path)
      begin
        @jgit_repo = org.eclipse.jgit.storage.file.FileRepositoryBuilder.new.setGitDir(java.io.File.new(path)).readEnvironment().findGitDir().build()
      rescue Exception => e
        Rails.logger.error("JGIT CorruptObjectException: #{e.inspect}\n#{e.backtrace.join("\n")}")
      end
    else
      @jgit_repo = nil
    end
  end

  def owner
    return @master
  end

  # Returns the appropriate git command prefix for this Repository and its path
  def git_command_prefix
    return "git --git-dir=#{Shellwords.escape(self.path)}"
  end

  def exists?(path)
    # master.has_repository?
    File.exists?(path)
  end

  def fork_bare(destination_path)
    `git clone --bare -q -s #{Shellwords.escape(self.path)} #{Shellwords.escape(destination_path)}`
  end

  def create
    # master.update_attribute :has_repository, true
    # create a git repository
    Repository.new.fork_bare(path)
    begin
      @jgit_repo ||= org.eclipse.jgit.storage.file.FileRepositoryBuilder.new.setGitDir(java.io.File.new(path)).readEnvironment().findGitDir().build()
    rescue Exception => e
      Rails.logger.error("JGIT CorruptObjectException: #{e.inspect}\n#{e.backtrace.join("\n")}")
    end
  end

  def repack
    `#{self.git_command_prefix} repack`
    unless $?.success?
      Rails.logger.warn("Canonical repack failed")
    end
  end

  def destroy
    # master.update_attribute :has_repository, false
    # destroy a git repository

    # BEFORE DELETION: REPACK CANONICAL
    # This will pull in all objects regardless of alternates/shared status.
    # If you delete an alternates-referenced repository without repacking,
    # referenced objects will disappear, possibly making the repo unusable.
    canon = Repository.new
    canon.repack()
    canon.del_alternates(self)
    FileUtils.rm_rf(path, :secure => true)
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
        Rails.logger.debug("JGIT Blob ID for #{file} on #{branch} = #{tree_walk.getObjectId(0).name()}")
        jgit_blob = org.apache.commons.io.IOUtils.toString(@jgit_repo.open(tree_walk.getObjectId(0)).openStream(), "UTF-8")
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
    return get_blob_from_branch(file, branch)
  end

  def get_log_for_file_from_branch(file, branch = 'master', limit = 1)
    `#{git_command_prefix} log -n #{limit} --follow --pretty=format:%H #{Shellwords.escape(branch)} -- #{Shellwords.escape(file)}`.split("\n")
  end

  def get_head(branch)
    return `#{self.git_command_prefix} rev-list -n 1 refs/heads/#{Shellwords.escape(branch)}`.chomp
  end

  def update_ref(branch, sha1)
    return `#{self.git_command_prefix} update-ref refs/heads/#{Shellwords.escape(branch)} #{sha1}`
  end

  def update_master_from_canonical
    self.update_ref('master',Repository.new.get_head('master'))
  end

  def create_branch(name, source_name = 'master', force = false)
    # We always assume we want to branch from master by default
    if source_name == 'master'
      self.update_master_from_canonical
    end

    begin
      ref = org.eclipse.jgit.api.Git.new(@jgit_repo).branchCreate().setName(name).setStartPoint(source_name).setForce(force).call()
      # Rails.logger.debug("Branched #{ref.getName()} from #{source_name} = #{ref.getObjectId().name()}")
    rescue Exception => e
      Rails.logger.error("create_branch exception: #{e.inspect}\n#{e.backtrace.join("\n")}")
    end
  end

  def delete_branch(name)
    org.eclipse.jgit.api.Git.new(@jgit_repo).branchDelete().setBranchNames("refs/heads/#{name}").setForce(true).call()
  end

  #(from_branch, to_branch, from_repo)
  def copy_branch_from_repo(branch, new_branch, other_repo)
    # Lightweight (but have to watch out for side-effects of repo deletion):
    # self.add_alternates(other_repo)
    # Heavyweight (missing objects are actually copied):
    #head_ref = other_repo.jgit_repo.resolve(branch).name()
    Rails.logger.info("copy_branch_from_repo(#{branch}, #{new_branch}, #{other_repo.path}, #{@path})")
    Java::gitwrapper.utils::fetchLite(branch, new_branch, other_repo.path, @path)
    #self.fetch_objects(other_repo, branch)
    #Rails.logger.info("copy_branch_from_repo #{branch} = #{head_ref} locally: #{jgit_repo.resolve("refs/remotes/" + other_repo.name + "/" + branch).name()}")
    #self.create_branch(new_branch, other_repo.name + "/" + branch)
  end

  def add_remote(other_repo)
    remote_configs = org.eclipse.jgit.transport.RemoteConfig.getAllRemoteConfigs(@jgit_repo.getConfig()).to_a
    unless remote_configs.map{|c| c.getName()}.include?(other_repo.name)
      remote_config = org.eclipse.jgit.transport.RemoteConfig.new(@jgit_repo.getConfig(), other_repo.name)
      remote_config.addURI(org.eclipse.jgit.transport.URIish.new("file://" + other_repo.path))
      remote_config.update(@jgit_repo.getConfig())
    end
  end

  def name
    return [@master_class_path, @master.name].join('/').tr(' ', '_')
  end

  def alternates_path
    File.join(self.path,%w{objects info alternates})
  end

  def alternates
    if File.exists?(self.alternates_path())
      return File.readlines(self.alternates_path())
    else
      return []
    end
  end

  def alternates=(repository_paths)
    File.write(self.alternates_path, repository_paths.join("\n"))
  end

  def add_alternates(other_repo)
    self.alternates = self.alternates() | [ File.join(other_repo.path, "objects") ]
  end

  def del_alternates(other_repo)
    self.alternates = self.alternates() - [ File.join(other_repo.path, "objects") ]
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

    # TODO: just get the object id instead of reinserting
    inserter = @jgit_repo.newObjectInserter()
    file_id = inserter.insert(org.eclipse.jgit.lib.Constants::OBJ_BLOB, content.to_java_string.getBytes(java.nio.charset.Charset.forName("UTF-8")))
    inserter.flush()
    inserter.release()

    jgit_tree = JGit::JGitTree.new()
    jgit_tree.load_from_repo(@jgit_repo, branch)
    jgit_tree.add_blob(new_path, file_id.name())
    jgit_tree.del(original_path)
    jgit_tree.commit(comment, actor)
  end

  # Returns a String of the SHA1 of the commit
  def commit_content(file, branch, data, comment, actor)
    if @path == Sosol::Application.config.canonical_repository
      raise "Cannot commit directly to canonical repository" unless (file == CollectionIdentifier.new.to_path)
    end

    begin
      inserter = @jgit_repo.newObjectInserter()
      file_id = inserter.insert(org.eclipse.jgit.lib.Constants::OBJ_BLOB, data.to_java_string.getBytes(java.nio.charset.Charset.forName("UTF-8")))

      last_commit_id = @jgit_repo.resolve(branch)

      jgit_tree = JGit::JGitTree.new()
      jgit_tree.load_from_repo(@jgit_repo, branch)
      jgit_tree.add_blob(file, file_id.name())

      jgit_tree.commit(comment, actor)
      inserter.flush()
      inserter.release()
    rescue Exception => e
      Rails.logger.error("JGIT COMMIT exception #{file} on #{branch} comment #{comment}: #{e.inspect}\n#{e.backtrace.join("\n")}")
      return nil
    end
  end

  def safe_repo_name(name)
    java.text.Normalizer.normalize(name.tr(' ','_'),java.text.Normalizer::Form::NFD).gsub(/\p{M}/,'')
  end
end

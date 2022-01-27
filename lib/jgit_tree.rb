module JGit
  class JGitTree
    attr_accessor :parent, :nodes, :name, :sha, :mode, :repo, :branch

    def initialize
      @parent = nil
      @nodes = {}
      @mode = org.eclipse.jgit.lib.FileMode::TREE
      self
    end

    def load_from_repo(repo, branch, path = nil)
      @repo ||= repo
      @branch ||= branch

      # read the root node into nodes
      last_commit_id = repo.resolve(branch)
      jgit_tree = org.eclipse.jgit.revwalk.RevWalk.new(repo).parseCommit(last_commit_id).getTree

      tree_walk = org.eclipse.jgit.treewalk.TreeWalk.new(repo)
      tree_walk.addTree(jgit_tree)
      unless path.nil?
        # puts "Tree walk for path: #{path}"
        tree_walk = org.eclipse.jgit.treewalk.TreeWalk.forPath(repo, path, jgit_tree)
        # path_filter = org.eclipse.jgit.treewalk.filter.PathFilter.create(path)
        # tree_walk.setFilter(path_filter)
        # tree_walk.next()
        tree_walk.enterSubtree
      end
      tree_walk.setRecursive(false)
      tree_walk.setPostOrderTraversal(true)

      while tree_walk.next
        current_name = tree_walk.getNameString
        if !path.nil? && path.split('/').length != tree_walk.getDepth
          # puts "Skipping #{current_name}"
          next
        end

        # puts "Walking #{current_name}"
        nodes[current_name] = JGitTree.new
        nodes[current_name].set_sha(tree_walk.getObjectId(0).name, tree_walk.getFileMode(0), self)
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

    def commit(comment, person_ident)
      if parent.nil?
        inserter = repo.newObjectInserter

        commit = org.eclipse.jgit.lib.CommitBuilder.new
        commit.setTreeId(org.eclipse.jgit.lib.ObjectId.fromString(update_sha))
        commit.setParentId(repo.resolve(branch))
        commit.setAuthor(person_ident)
        commit.setCommitter(person_ident)
        # TODO: Check if this solves character encoding problem
        commit.setEncoding('UTF-8')
        commit.setMessage(comment)

        commit_id = inserter.insert(commit)
        inserter.flush
        inserter.release

        Rails.logger.info("JGIT COMMIT before: #{repo.resolve(branch).name}")
        ref_update = repo.updateRef("refs/heads/#{branch}")
        ref_update.setRefLogIdent(person_ident)
        ref_update.setNewObjectId(commit_id)
        ref_update.setExpectedOldObjectId(repo.resolve(branch))
        ref_update.setRefLogMessage("commit: #{comment}", false)

        result = ref_update.update
        Rails.logger.info("JGIT COMMIT on #{branch} = #{sha} comment '#{comment}' = #{commit_id.name}: #{result.toString}")

        Rails.logger.info("JGIT COMMIT after: #{repo.resolve(branch).name}")
        commit_id.name
      else
        root.commit(comment, person_ident)
      end
    end

    def add(path, sha, mode)
      Rails.logger.debug("JGITTREE: Add for #{path}")
      # takes a path relative to this tree and adds it
      components = path.split('/')
      if components.length > 1 # need to recurse
        if !nodes.key?(components.first) # creating a new tree
          nodes[components.first] = JGitTree.new
          nodes[components.first].parent = self
        elsif nodes[components.first].nodes.length.zero? # need to load this subtree first
          nodes[components.first].load_from_repo(root.repo, root.branch, nodes[components.first].path)
        end
        nodes[components.first].add(components[1..-1].join('/'), sha, mode)
        nodes[components.first].update_sha
      else # base case
        nodes[path] = JGitTree.new
        nodes[path].set_sha(sha, mode, self)
        # puts "Added #{path} in #{self.path}: #{sha} #{mode}"
      end
    end

    def del(path)
      Rails.logger.info("JGIT del for #{path}")
      # takes a path relative to this tree and removes it
      components = path.split('/')
      if components.length > 1 # need to recurse
        if nodes[components.first].nodes.length.zero? # need to load this subtree first
          nodes[components.first].load_from_repo(root.repo, root.branch, nodes[components.first].path)
        end
        nodes[components.first].del(components[1..-1].join('/'))
        nodes[components.first].update_sha
      else
        nodes.delete(path)
      end
    end

    def path
      if parent.nil?
        ''
      else
        "#{parent.path}/#{parent.nodes.key(self)}".sub(%r{^/}, '')
      end
    end

    def update_sha
      inserter = root.repo.newObjectInserter
      formatter = org.eclipse.jgit.lib.TreeFormatter.new

      # Git expects Tree entries sorted as if they have a trailing slash
      # TODO: could still potentially have tree/file collision here, e.g. file 'test' and directory 'test' will still collide in the hash
      # But I don't think this occurs in idp.data
      sorted_nodes = nodes.keys.map do |n|
                       nodes[n].mode == org.eclipse.jgit.lib.FileMode::TREE ? "#{n}/" : n
                     end.sort.map { |n| n.chomp('/') }
      sorted_nodes.each do |node|
        # puts "About to append #{node} #{nodes[node].mode} #{nodes[node].sha} in #{self.path}"
        formatter.append(node, nodes[node].mode, org.eclipse.jgit.lib.ObjectId.fromString(nodes[node].sha))
      end

      tree_id = inserter.insert(formatter)
      inserter.flush
      inserter.release
      @sha = tree_id.name
    end

    def depth(n = 0)
      if parent.nil?
        n
      else
        parent.depth(n + 1)
      end
    end

    def to_s
      pretty = ''
      nodes.each do |key, value|
        depth.times { pretty += '  ' }
        pretty += "#{value.sha} #{key}\n"
        pretty += value.to_s
        # pretty += "\n"
      end
      pretty
    end

    def root
      if parent.nil?
        self
      else
        parent.root
      end
    end

    def add_blob(path, sha)
      add(path, sha, org.eclipse.jgit.lib.FileMode::REGULAR_FILE)
    end

    def add_tree(path, sha)
      add(path, sha, org.eclipse.jgit.lib.FileMode::TREE)
    end
  end
end

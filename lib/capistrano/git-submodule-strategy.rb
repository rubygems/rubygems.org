module Capistrano::SubmoduleStrategy
  def test
    test! " [ -f #{repo_path}/HEAD ] "
  end

  def check
    git :'ls-remote --heads', repo_url
  end

  def clone
    if depth = fetch(:git_shallow_clone)
      git :clone, '--mirror', '--depth', depth, '--no-single-branch', repo_url, repo_path
    else
      git :clone, '--mirror', repo_url, repo_path
    end
  end

  def update
    # Note: Requires git version 1.9 or greater
    if depth = fetch(:git_shallow_clone)
      git :fetch, '--depth', depth, 'origin', fetch(:branch)
    else
      git :remote, :update
    end
  end

  def release
    context.within_only release_path do
      git :init
      git :remote, 'add', 'origin', "file://#{repo_path}"
      git :fetch
      git :fetch, 'origin', fetch(:branch)
      git :reset, '--hard', 'FETCH_HEAD'
      git :submodule, 'update', '--init'
    end
  end

  def fetch_revision
    context.capture(:git, "rev-list --max-count=1 --abbrev-commit --abbrev=12 #{fetch(:branch)}")
  end
end

# shit hack to execute command only in specified directory
module SSHKit
  module Backend
    class Abstract
      def within_only(directory, &block)
        pwd = @pwd
        @pwd = []
        within directory, &block
      ensure
        @pwd = pwd
      end
    end
  end
end

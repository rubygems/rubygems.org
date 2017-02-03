require "capistrano/scm/git"

class Capistrano::SubmoduleStrategy < Capistrano::SCM::Git
  def archive_to_release_path
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

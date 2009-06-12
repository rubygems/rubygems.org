# Pulled together from various mailing lists.

namespace :svn do
  desc "Adds all files with an svn status flag of '?'"
  task(:add) { system %q(svn status | awk '/\\?/ {print $2}' | xargs svn add) }
  
  desc "Deletes all files with an svn status flag of '!'"
  task(:delete) { system %q(svn status | awk '/\\!/ {print $2}' | xargs svn delete) }
  
  desc "Writes the log file to doc/svn_log.txt"
  task(:log) do
    File.delete("#{RAILS_ROOT}/doc/svn_log.txt") if File::exists?("#{RAILS_ROOT}/doc/svn_log.txt")
    File.new("#{RAILS_ROOT}/doc/svn_log.txt", "w+")
    system("svn log >> doc/svn_log.txt")
  end
  
  desc 'Updates svn:ignore from .svnignore'
  task(:update_svn_ignore) do
    system %q(svn propset svn:ignore -F .svnignore .)
  end
end

require File.expand_path('../config/application', __FILE__)
Gemcutter::Application.load_tasks

desc "Run all tests and features"
task :default => [:test, :cucumber]

desc "Run weekly at 00:00 UTC"
task :weekly_cron => %w[gemcutter:rubygems:update_download_counts]

namespace :chef do
  task :setup do
    if File.directory? "chef"
      sh "cd chef; git pull --rebase"
    else
      sh "git clone git@github.com:rubygems/rubygems-aws chef"
    end
  end

  desc "Provision the application instances in AWS"
  task :app => :setup do
    unless ENV['DEPLOY_USER']
      puts "Please set DEPLOY_USER to your AWS username"
      exit 1
    end

    unless ENV['DEPLOY_SSH_KEY']
      puts "Please set DEPLOY_SSH_KEY to be the path to your SSH to use"
      exit 1
    end

    files = ["chef/chef/data_bags/secrets/rubygems.json",
             "chef/chef/site-cookbooks/rubygems/files/default/rubygems.org.crt",
             "chef/chef/site-cookbooks/rubygems/files/default/rubygems.org.key"]

    files.each do |f|
      unless File.file? f
        puts "Missing '#{f}': get it from another committer"
        exit 1
      end
    end

    Bundler.with_clean_env do
      sh "cd chef; bundle install && librarian-chef install && RUBYGEMS_EC2_APP=ec2-54-245-134-70.us-west-2.compute.amazonaws.com cap rubygems.org chef:app"
    end
  end
end

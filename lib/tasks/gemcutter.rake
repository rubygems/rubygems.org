namespace :gemcutter do
  desc "Clean out files that aren't needed."
  task :clean => :environment do
    system("git clean -dfx server/; git checkout server/")
    [Rubygem, Version, Dependency, Requirement, Linkset].each { |c| c.delete_all }
    Rake::Task["gemcutter:index:create"].execute
  end


  desc "Get the gem server up and running"
  task :bootstrap => :environment do
    Rake::Task["clean"].execute
    Rake::Task["gemcutter:index:create"].execute
    ARGV[1] = "bench/old"
    Rake::Task["gemcutter:import:process"].execute
    ARGV[1] = "bench/new"
    Rake::Task["gemcutter:import:process"].execute
  end

  namespace :index do
    desc "Create the index"
    task :create => :environment do
      Gemcutter.indexer.generate_index
    end

    desc "Update the index"
    task :update => :environment do
      Gemcutter.indexer.update_index
    end
  end

  desc "Look for migrations and try to match the key"
  task :migrate => :environment do
    require 'webrat'
    require 'webrat/mechanize'
    Ownership.find_all_by_approved(false).each do |ownership|
      rubygem = ownership.rubygem
      session.visit("http://rubyforge.org/projects/")
    end
  end

  namespace :import do
    desc 'Download all of the gems in server/rubygems.txt'
    task :download do
      require 'curb'
      require 'active_support'
      url_queue = File.readlines("server/rubygems.txt").map { |g| g.strip }
      puts "Downloading #{url_queue.size} gems..."
      FileUtils.mkdir("cache") unless File.exist?("cache")

      responses = {}
      url_queue.in_groups_of(25).each do |group|
        multi = Curl::Multi.new
        group.each do |url|
          next unless url
          path = File.join("cache", File.basename(url))
          if File.exists?(path)
            puts "Skipping #{File.basename(url)}"
            next
          end

          easy = Curl::Easy.new(url) do |curl|
            curl.follow_location = true
            curl.on_success do |c|
              puts "Success for #{File.basename(url)} in #{c.total_time} seconds"
              begin
                File.open(path, "wb") do |file|
                  file.write c.body_str
                end
              rescue Exception => e
                puts "Problem saving: #{e}"
              end
            end
            curl.on_failure do |c|
              puts "Failure for #{File.basename(url)}: #{c.response_code}"
            end
          end
          multi.add(easy)
        end
        multi.perform
      end
    end

    desc 'Parse out rubygems'
    task :parse do
      require 'hpricot'
      doc = Hpricot(open("server/rubygems.html"))
      File.open("server/rubygems.txt", "w") do |file|
        (doc / "a")[1..-1].each do |gem|
          puts gem['href']
          file.write "http://gems.rubyforge.org/gems/#{gem['href']}\n"
        end
      end
    end

    desc 'Bring the gems through the gemcutter process'
    task :process => :environment do
      gems = Dir[File.join(ARGV[1], "*.gem")].sort.reverse
      puts "Processing #{gems.size} gems..."
      gems.each do |path|
        puts "Processing #{path}"
        cutter = Gemcutter.new(nil, File.open(path))

        cutter.pull_spec
        cutter.find
        cutter.save
      end
    end
  end
end

namespace :advisory do
  desc 'Mark versions as vulnerable'
  task update: :environment do
    if Advisory.update?
      puts Advisory.mark_versions
    else
      puts "Advisories are already up to date"
    end
  end
end

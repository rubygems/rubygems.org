namespace :advisory do
  desc 'Mark versions as vulnerable'
  task update: :environment do
    if AdvisoryDb.update?
      puts AdvisoryDb.mark_versions
    else
      puts "Advisories are already up to date"
    end
  end
end

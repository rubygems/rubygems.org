namespace :db do
  # From http://blog.hasmanythrough.com/2006/8/27/validate-all-your-records
  desc "Run model validations on all model records in database"
  task :validate_models => :environment do
    # because rails loads stuff on demand...
    Dir.glob(RAILS_ROOT + '/app/models/**/*.rb').each do |file| 
      silence_warnings do
        require file
      end
    end
  
    Object.subclasses_of(ActiveRecord::Base).select { |c| c.base_class == c}.sort_by(&:name).each do |klass|
      next if klass.name == "CGI::Session::ActiveRecordStore::Session"
      invalid_count = 0
      total = klass.count
      chunk_size = 1000
      (total / chunk_size + 1).times do |i|
        chunk = klass.find(:all, :offset => (i * chunk_size), :limit => chunk_size)
        chunk.reject(&:valid?).each do |record|
          invalid_count += 1
          puts "#{klass} #{record.id}: #{record.errors.full_messages.to_sentence}"
        end rescue nil
      end
      puts "#{invalid_count} of #{total} #{klass.name.pluralize} are invalid." if invalid_count > 0
    end
  end
end

class DelayedJobGenerator < Rails::Generator::Base
  
  def manifest
    record do |m|
      m.template 'script', 'script/delayed_job', :chmod => 0755
      m.migration_template "migration.rb", 'db/migrate',
                           :migration_file_name => "create_delayed_jobs"
    end
  end
  
end

namespace :multifactor_auth do
  desc "Migrate user mfa level from ui_only to ui_and_gem_signin"
  task migrate_ui_only: :environment do
    users = User.where(mfa_level: :ui_only)

    total = users.count
    puts "Total: #{total}"

    completed_migrations = 0
    users.find_each do |user|
      begin
        user.update!(mfa_level: :ui_and_gem_signin)
      rescue StandardError => e
        puts "Cannot update mfa level for: #{user.handle}"
        puts "Caught exception: #{e}"
      end

      completed_migrations += 1
      print format("\r%.2f%% (%d/%d) complete", completed_migrations.to_f / total * 100.0, completed_migrations, total)
    end
  end
end

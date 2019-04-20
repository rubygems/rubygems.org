namespace :api_keys do
  desc "Migrate user api keys to ApiKey model"
  task migrate: :environment do
    users = User.where.not(api_key: nil).all

    total = users.count
    i = 0
    puts "Total: #{total}"
    users.find_each do |user|
      begin
        hashed_key = Digest::SHA256.hexdigest(user.api_key)
        scopes_hash = ApiKey::API_SCOPES.index_with { true }

        api_key = user.api_keys.new(scopes_hash.merge(hashed_key: hashed_key, name: "legacy-key"))
        api_key.save(validate: false)
        puts "Count not create new API key: #{api_key.inspect}, user: #{user.handle}" unless api_key.persisted?
      rescue StandardError => e
        puts "Count not create new API key for user: #{user.handle}"
        puts "caught exception #{e}! ohnoes!"
      end

      i += 1
      print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
    end
    puts
    puts "Done."
  end
end

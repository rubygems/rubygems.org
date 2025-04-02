namespace :policies do
  task policy_update_announcement: :environment do
    User.find_in_batches(batch_size: 1000) do |user_batch|
      user_batch.each do |user|
        Mailer.policy_update_announcement(user).delivery_later
      end
    end
  end

  task policy_update_review_closed: :environment do
    User.find_in_batches(batch_size: 1000) do |user_batch|
      user_batch.each do |user|
        Mailer.policy_update_review_closed(user).delivery_later
      end
    end
  end
end

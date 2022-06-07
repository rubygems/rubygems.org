require "resolv"

def mx_exists?(email)
  domain = email.split("@").last
  mx_resolver = Resolv::DNS.new
  mx_resolver.timeouts = 10

  return false if mx_resolver.getresources(domain, Resolv::DNS::Resource::IN::MX).empty?
  true
rescue StandardError => e
  puts "Error during processing: #{$ERROR_INFO}"
  puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
  false
end

namespace :mfa_policy do
  # To be sent on launch day (June 13, 2022)
  # rake mfa_policy:announce_recommendation
  desc "Send email notification to all users about MFA Phase 2 rollout (MFA Recommendation for popular gems)"
  task announce_recommendation: :environment do
    users = User.all
    total_users = users.count
    puts "Sending #{total_users} MFA announcement email"

    i = 0
    users.find_each do |user|
      Mailer.delay.mfa_recommendation_announcement(user.id) if mx_exists?(user.email)
      i += 1
      print format("\r%.2f%% (%d/%d) complete", i.to_f / total_users * 100.0, i, total_users)
    end
  end
end

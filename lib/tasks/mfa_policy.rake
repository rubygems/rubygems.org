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
  # This task is meant to be run on MFA Phase 2 launch day - June 13, 2022
  # For more information on the MFA Phase 2 rollout, refer to this RFC:
  # https://github.com/rubygems/rfcs/pull/36/files#diff-3d5cc3acc06fe7e9150fdbfc43399c5ad42572c122187774bfc3a4857df524f1R46-R67
  # rake mfa_policy:announce_recommendation
  desc "Send email notification to all users about MFA Phase 2 rollout (MFA Recommendation for popular gems)"
  task announce_recommendation: :environment do
    # users who own at least one gem with a minimum of 165,000,000 downloads or more
    users = User.joins(rubygems: :gem_download).where("gem_downloads.count >= 165000000").uniq
    total_users = users.count
    puts "Sending #{total_users} MFA announcement email"

    i = 0
    users.each do |user|
      Mailer.delay.mfa_recommendation_announcement(user.id) if mx_exists?(user.email)
      i += 1
      print format("\r%.2f%% (%d/%d) complete", i.to_f / total_users * 100.0, i, total_users)
    end
  end
end

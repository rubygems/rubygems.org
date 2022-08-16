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

  # This task is meant to be run one week prior to MFA Phase 3 launch day - send out on Aug 8, 2022
  # For more information on the MFA Phase 3 rollout, refer to this RFC:
  # https://github.com/rubygems/rfcs/pull/36/files#diff-3d5cc3acc06fe7e9150fdbfc43399c5ad42572c122187774bfc3a4857df524f1R69-R85
  # rake mfa_policy:reminder_enable_mfa
  desc "Send email reminder to users who will have MFA enforced about impending MFA Phase 3 rollout"
  task reminder_enable_mfa: :environment do
    # users who own at least one gem with 180,000,000 downloads or more with weak or no MFA
    users = User.joins(rubygems: :gem_download).where("gem_downloads.count >= 180000000").where(mfa_level: %w[disabled ui_only])
    total_users = users.count
    puts "Sending #{total_users} MFA reminder email"

    i = 0
    users.each do |user|
      Mailer.delay.mfa_required_soon_announcement(user.id) if mx_exists?(user.email)
      i += 1
      print format("\r%.2f%% (%d/%d) complete", i.to_f / total_users * 100.0, i, total_users)
    end
  end

  # This task is meant to be run once MFA Phase 3 has launched - send out on Aug 15, 2022
  # For more information on the MFA Phase 3 rollout, refer to this RFC:
  # https://github.com/rubygems/rfcs/pull/36/files#diff-3d5cc3acc06fe7e9150fdbfc43399c5ad42572c122187774bfc3a4857df524f1R69-R85
  # rake mfa_policy:announce_enforcement_for_popular_gems
  desc "Send email to notify users that MFA is now being enforced due to MFA Phase 3 rollout"
  task announce_enforcement_for_popular_gems: :environment do
    # users who own at least one gem with 180,000,000 downloads or more, with weak MFA or no MFA enabled
    users = User.joins(rubygems: :gem_download).where("gem_downloads.count >= 180000000").where(mfa_level: %w[disabled ui_only]).uniq
    total_users = users.count
    puts "Sending #{total_users} MFA required for popular gems email"

    mailers_sent = 0
    mailers_not_sent = 0
    unsent_mailer_emails = []
    users.each do |user|
      if mx_exists?(user.email)
        Mailer.delay.mfa_required_popular_gems_announcement(user.id)
        mailers_sent += 1
        print format("\r%.2f%% (%d/%d) complete", mailers_sent.to_f / total_users * 100.0, mailers_sent, total_users)
      else
        mailers_not_sent += 1
        unsent_mailer_emails << user.email
      end
    end

    puts "Mailer was not sent to #{mailers_not_sent} account(s):\n#{unsent_mailer_emails.join(", \n")}" if unsent_mailer_emails.any?
  end
end

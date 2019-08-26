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

# login in 2019: rake mfa_notification:send
# rest users: rake mfa_notification:send[2009-01-01,2018-12-31]
namespace :mfa_notification do
  desc "Send email notification to all users about MFA"
  task :send, %i[login_start login_end] => [:environment] do |_task, args|
    args.with_defaults(login_start: "2019-01-01", login_end: Time.now.utc.strftime("%Y-%m-%d"))

    mfa_disabled_users = User.where.not(mfa_level: :ui_and_api)
    notify_users = mfa_disabled_users.where("updated_at BETWEEN ? AND ?", args[:login_start], args[:login_end])
    total = notify_users.count
    puts "Sending #{total} mfa notifications for login between #{args[:login_start]}..#{args[:login_end]}"

    i = 0
    notify_users.find_each do |user|
      Mailer.delay.mfa_notification(user.id) if mx_exists?(user.email)
      i += 1
      print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
    end
  end
end

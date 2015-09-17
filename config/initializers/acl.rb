module ACL
  extend self
  ADMIN_USERS = {}

  # Given ENV['ADMIN_USERS'] #=> "qrush=nick@example.com:bf4=bf@example.com"
  # Will build the ADMIN_USERS hash as:
  # { "qrush" => "nick@example.com", "bf4" => "bf@example.com" }
  # which is a reasonable way to identify a user without relying on User#id
  def load_admin_users!
    admin_users = ENV['ADMIN_USERS'.freeze].to_s.
      split(':'.freeze).reduce({}) { |result, handle_email|
      admin_user = Hash[ *handle_email.split('='.freeze) ]
      result.update(admin_user)
    }
    ADMIN_USERS.clear
    ADMIN_USERS.update(admin_users)
  end

  def admin?(user)
    admin_email = ADMIN_USERS[user.handle]
    admin_email && user.email == admin_email || false
  end

  load_admin_users!
end

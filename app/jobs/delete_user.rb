class DeleteUser
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def perform
    profile = User.find(user['id'])
    email = profile.email
    profile.destroy
    Mailer.deletion_confirmation(email)
  end
end

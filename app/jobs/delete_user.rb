class DeleteUser
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def perform
    profile = User.find(user['id'])
    email = profile.email
    if profile.destroy
      Mailer.deletion_complete(email)
    else
      Mailer.deletion_failed(email)
    end
  end
end

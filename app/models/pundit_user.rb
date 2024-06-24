class PunditUser
  attr_reader :api_key, :user, :owner

  def initialize(user)
    @api_key = nil
    @user = user
    @owner = user
  end

  def user?
    @user.present?
  end

  def api_key?
    false
  end

  def id
    user.id
  end

  def owns_gem?(rubygem)
    owner.owns_gem?(rubygem)
  end

  def same_user?(other_user)
    user == other_user
  end

  def can_show_dashboard? = true
  def can_index_rubygems? = true
  def can_push_rubygem? = false
  def can_yank_rubygem? = false
  def can_add_owner? = true
  def can_remove_owner? = true
  def can_access_webhooks? = true
  def can_configure_trusted_publishers? = true
end

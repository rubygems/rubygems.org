class PunditApiKey
  attr_reader :api_key, :user, :owner

  def initialize(api_key)
    @api_key = api_key
    @user = api_key.user
    @owner = api_key.owner
  end

  def user?
    @user.present?
  end

  def api_key?
    true
  end

  def owns_gem?(rubygem)
    owner.owns_gem?(rubygem)
  end

  def same_user?(other_user)
    user == other_user
  end

  def can_show_dashboard? = api_key.can_show_dashboard?
  def can_index_rubygems? = api_key.can_index_rubygems?
  def can_push_rubygem? = api_key.can_push_rubygem?
  def can_yank_rubygem? = api_key.can_yank_rubygem?
  def can_add_owner? = api.can_add_owner?
  def can_remove_owner? = api.can_remove_owner?
  def can_access_webhooks? = api_key.can_access_webhooks?
  def can_configure_trusted_publishers? = api_key.can_push_rubygem?
end

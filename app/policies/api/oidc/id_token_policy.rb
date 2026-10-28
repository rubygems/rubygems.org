# frozen_string_literal: true

class Api::OIDC::IdTokenPolicy < Api::ApplicationPolicy
  class Scope < Api::ApplicationPolicy::Scope
  end

  def index?
    user_api_key? &&
      account_wide_api_key_scope?(:access_oidc_api_key_roles)
  end

  def show? = index?
end

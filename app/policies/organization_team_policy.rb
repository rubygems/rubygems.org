# frozen_string_literal: true

class OrganizationTeamPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  alias organization_team record
  delegate :organization, to: :organization_team

  def show?
    organization_member_with_role?(user, :maintainer) || deny(t(:forbidden))
  end
end

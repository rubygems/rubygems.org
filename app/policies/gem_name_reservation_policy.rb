# frozen_string_literal: true

class GemNameReservationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  alias gem_name_reservation record
  delegate :organization, to: :gem_name_reservation

  def create?
    organization_member_with_role?(user, :admin) || deny(t(:forbidden))
  end

  alias new? create?

  def destroy?
    organization_member_with_role?(user, :admin) || deny(t(:forbidden))
  end
end

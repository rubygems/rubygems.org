class Admin::GitHubUserPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      # if user.belongs_to_team?("rubygems-org")
      #   scope.all
      # else
        scope.where(id: user.id)
      # end
    end
  end

  def avo_index?
    belongs_to_team?("rubygems-org")
  end

  def avo_show?
    belongs_to_team?("rubygems-org")
  end
end

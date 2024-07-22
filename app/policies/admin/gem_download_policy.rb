class Admin::GemDownloadPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end

  def avo_index?
    true
  end

  def avo_show?
    true
  end
end

class Admin::LinksetPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def avo_index?
    policy!(user, Rubygem).avo_index?
  end

  def avo_show?
    policy!(user, record.rubygem).avo_show?
  end
end

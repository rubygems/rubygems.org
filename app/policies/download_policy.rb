class DownloadPolicy < ApplicationPolicy
  class Scope < Scope
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

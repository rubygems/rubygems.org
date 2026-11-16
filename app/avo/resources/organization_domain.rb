# frozen_string_literal: true

class Avo::Resources::OrganizationDomain < Avo::BaseResource
  self.title = :domain
  self.includes = [:organization]
  self.search = {
    query: lambda {
             needle = ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)
             query.where("domain LIKE ?", "%#{needle}%")
           }
  }

  def actions
    action Avo::Actions::RemoveOrganizationDomain
  end

  def fields
    field :id, as: :id
    field :domain, as: :text, readonly: true
    field :organization, as: :belongs_to, readonly: true
    field :token, as: :text, readonly: true
    field :verified_at, as: :date_time, readonly: true
    field :last_checked_at, as: :date_time, readonly: true
    field :last_check_result, as: :text, readonly: true
    field :created_at, as: :date_time, readonly: true, only_on: :show

    field :checks, as: :has_many
    field :audits, as: :has_many
  end
end

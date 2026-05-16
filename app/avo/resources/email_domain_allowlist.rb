# frozen_string_literal: true

class Avo::Resources::EmailDomainAllowlist < Avo::BaseResource
  self.title = :domain
  self.includes = []
  self.search = {
    query: lambda {
             needle = ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)
             query.where("domain ILIKE ?", "%#{needle}%")
           }
  }

  def actions
    action Avo::Actions::AllowlistEmailDomain
    action Avo::Actions::UnallowlistEmailDomain
  end

  def fields
    field :id, as: :id, hide_on: :index

    field :domain, as: :text, link_to_resource: true, only_on: %i[index show]
    field :notes, as: :textarea, only_on: %i[show]

    field :created_at, as: :date_time, sortable: true, readonly: true, only_on: %i[index show]
    field :updated_at, as: :date_time, sortable: true, readonly: true, only_on: %i[index show]
  end
end

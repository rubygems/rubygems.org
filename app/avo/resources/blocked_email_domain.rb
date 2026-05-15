# frozen_string_literal: true

class Avo::Resources::BlockedEmailDomain < Avo::BaseResource
  self.title = :domain
  self.includes = []
  self.search = {
    query: lambda {
             query.where("domain ILIKE ?", "%#{params[:q]}%")
           }
  }

  def actions
    action Avo::Actions::BlockEmailDomain
    action Avo::Actions::UnblockEmailDomain
  end

  def fields
    field :id, as: :id, hide_on: :index

    field :domain, as: :text, link_to_resource: true, only_on: %i[index show]
    field :source, as: :select,
      enum: ::BlockedEmailDomain.sources,
      only_on: %i[index show],
      readonly: true
    field :notes, as: :textarea, only_on: %i[show]

    field :created_at, as: :date_time, sortable: true, readonly: true, only_on: %i[index show]
    field :updated_at, as: :date_time, sortable: true, readonly: true, only_on: %i[index show]
  end
end

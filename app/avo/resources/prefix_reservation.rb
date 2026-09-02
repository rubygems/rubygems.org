# frozen_string_literal: true

class Avo::Resources::PrefixReservation < Avo::BaseResource
  self.title = :prefix
  self.includes = [:organization]
  self.search = {
    query: lambda {
             needle = ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)
             query.where("prefix ILIKE ?", "%#{needle}%")
           }
  }

  def fields
    field :id, as: :id, hide_on: :index

    field :prefix, as: :text,
      help: "Lowercase gem name prefix reserved for the organization, e.g. <code>acme</code> reserves <code>acme-widgets</code>."
    field :organization, as: :belongs_to

    field :created_at, as: :date_time, sortable: true, readonly: true, only_on: %i[index show]
    field :updated_at, as: :date_time, sortable: true, readonly: true, only_on: %i[index show]
  end
end

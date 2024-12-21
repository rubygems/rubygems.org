class Avo::Resources::Ownership < Avo::BaseResource
  self.title = :cache_key
  self.includes = []

  class ConfirmedFilter < Avo::Filters::ScopeBooleanFilter; end

  def filters
    filter ConfirmedFilter, arguments: { default: { confirmed: true, unconfirmed: true } }
  end

  def fields
    field :id, as: :id, link_to_resource: true

    field :user, as: :belongs_to
    field :rubygem, as: :belongs_to

    field :role, as: :select, enum: Ownership.roles

    field :token, as: :heading

    field :token, as: :text, visible: -> { false }
    field :token_expires_at, as: :date_time
    field :api_key_rubygem_scopes, as: :has_many

    field :notifications, as: :heading

    field :push_notifier, as: :boolean
    field :owner_notifier, as: :boolean

    field :authorization, as: :heading

    field :authorizer, as: :belongs_to
    field :confirmed_at, as: :date_time
  end
end

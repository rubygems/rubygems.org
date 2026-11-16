# frozen_string_literal: true

class Avo::Resources::OrganizationDomainCheck < Avo::BaseResource
  self.includes = [:organization_domain]

  def fields
    field :id, as: :id
    field :organization_domain, as: :belongs_to, readonly: true
    field :checked_at, as: :date_time, readonly: true
    field :result, as: :text, readonly: true
    field :error_code, as: :text, readonly: true
    field :error_message, as: :text, readonly: true
  end
end

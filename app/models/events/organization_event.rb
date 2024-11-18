class Events::OrganizationEvent < ApplicationRecord
  belongs_to :organization

  include Events::Tags

  CREATED = define_event "organization:created" do
    attribute :name, :string
    attribute :actor_gid, :global_id
  end
end

class Events::OrgEvent < ApplicationRecord
  belongs_to :org

  include Events::Tags

  CREATED = define_event "org:created" do
    attribute :name, :string
    attribute :actor_gid, :global_id
  end
end

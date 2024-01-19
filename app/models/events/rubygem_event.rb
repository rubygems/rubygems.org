class Events::RubygemEvent < ApplicationRecord
  belongs_to :rubygem

  include Events::Tags

  VERSION_PUSHED = define_event "rubygem:version:pushed" do
    attribute :number, :string
    attribute :platform, :string
    attribute :sha256, :string

    attribute :pushed_by, :string

    attribute :version_gid, :global_id
    attribute :actor_gid, :global_id
  end

  VERSION_YANKED = define_event "rubygem:version:yanked" do
    attribute :number, :string
    attribute :platform, :string

    attribute :yanked_by, :string

    attribute :version_gid, :global_id
    attribute :actor_gid, :global_id
  end

  VERSION_UNYANKED = define_event "rubygem:version:unyanked" do
    attribute :number, :string
    attribute :platform, :string

    attribute :version_gid, :global_id
  end

  OWNER_ADDED = define_event "rubygem:owner:added" do
    attribute :owner, :string
    attribute :authorizer, :string

    attribute :actor_gid, :global_id
    attribute :owner_gid, :global_id
  end

  OWNER_CONFIRMED = define_event "rubygem:owner:confirmed" do
    attribute :owner, :string
    attribute :authorizer, :string

    attribute :actor_gid, :global_id
    attribute :owner_gid, :global_id
  end

  OWNER_REMOVED = define_event "rubygem:owner:removed" do
    attribute :owner, :string
    attribute :removed_by, :string

    attribute :actor_gid, :global_id
    attribute :owner_gid, :global_id
  end
end

class Events::RubygemEvent < ApplicationRecord
  belongs_to :rubygem
  belongs_to :ip_address, optional: true
  belongs_to :geoip_info, optional: true
end

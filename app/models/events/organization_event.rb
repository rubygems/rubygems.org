# frozen_string_literal: true

class Events::OrganizationEvent < ApplicationRecord
  belongs_to :organization

  include Events::Tags

  CREATED = define_event "organization:created" do
    attribute :name, :string
    attribute :actor_gid, :global_id
  end

  RUBYGEM_ADDED = define_event "organization:rubygem:added" do
    attribute :rubygem, :string
    attribute :added_by, :string

    attribute :rubygem_gid, :global_id
    attribute :actor_gid, :global_id
  end

  TEAM_CREATED = define_event "organization:team:created" do
    attribute :team, :string
    attribute :created_by, :string

    attribute :team_gid, :global_id
    attribute :actor_gid, :global_id
  end

  TEAM_MEMBER_ADDED = define_event "organization:team:member_added" do
    attribute :team, :string
    attribute :member, :string
    attribute :actor, :string

    attribute :team_gid, :global_id
    attribute :member_gid, :global_id
    attribute :actor_gid, :global_id
  end

  TEAM_MEMBER_REMOVED = define_event "organization:team:member_removed" do
    attribute :team, :string
    attribute :member, :string
    attribute :actor, :string

    attribute :team_gid, :global_id
    attribute :member_gid, :global_id
    attribute :actor_gid, :global_id
  end
end

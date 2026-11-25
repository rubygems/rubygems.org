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

  DOMAIN_ADDED = define_event "organization:domain:added" do
    attribute :domain, :string
    attribute :txt_record_value, :string
    attribute :actor_gid, :global_id
  end

  DOMAIN_DELETED = define_event "organization:domain:deleted" do
    attribute :domain, :string
    attribute :txt_record_value, :string
    attribute :actor_gid, :global_id
  end
end

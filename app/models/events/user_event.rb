class Events::UserEvent < ApplicationRecord
  belongs_to :user, class_name: "::User"

  include Events::Tags

  LOGIN_SUCCESS = define_event "user:login:success" do
    attribute :two_factor_method, :string
    attribute :two_factor_label, :string
    attribute :authentication_method, :string
  end
  EMAIL_SENT = define_event "user:email:sent" do
    attribute :to, :string
    attribute :from, :string
    attribute :subject, :string
    attribute :redact_ip, :boolean
    attribute :message_id, :string

    attribute :mailer, :string
    attribute :action, :string
  end
  EMAIL_ADDED = define_event "user:email:added" do
    attribute :email, :string
  end
  EMAIL_VERIFIED = define_event "user:email:verified" do
    attribute :email, :string
  end
  CREATED = define_event "user:created" do
    attribute :email, :string
  end

  API_KEY_CREATED = define_event "user:api_key:created" do
    attribute :name, :string
    attribute :scopes, Types::ArrayOf.new(ActiveRecord::Type::String.new)
    attribute :gem, :string
    attribute :mfa, :boolean

    attribute :api_key_gid, :global_id
  end

  API_KEY_DELETED = define_event "user:api_key:deleted" do
    attribute :name, :string

    attribute :api_key_gid, :global_id
  end

  PASSWORD_CHANGED = define_event "user:password:changed"
end

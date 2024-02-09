class UserResource < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.search_query = lambda {
    scope.where("email LIKE ? OR handle LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
  }
  self.unscoped_queries_on_index = true

  class DeletedFilter < ScopeBooleanFilter; end
  filter DeletedFilter, arguments: { default: { not_deleted: true, deleted: false } }

  action BlockUser
  action CreateUser
  action ChangeUserEmail
  action ResetApiKey
  action ResetUser2fa
  action YankRubygemsForUser
  action YankUser

  field :id, as: :id
  # Fields generated from the model
  field :email, as: :text
  field :gravatar,
    as: :gravatar,
    rounded: true,
    size: 48 do |_, _, _|
      model.email
    end

  field :email_confirmed, as: :boolean

  field :email_reset, as: :boolean
  field :handle, as: :text
  field :public_email, as: :boolean
  field :twitter_username, as: :text, as_html: true, format_using: -> { link_to value, "https://twitter.com/#{value}", target: :_blank, rel: :noopener if value.present? }
  field :unconfirmed_email, as: :text

  field :mail_fails, as: :number
  field :blocked_email, as: :text

  field :deleted_at, as: :date_time

  tabs style: :pills do
    tab "Auth" do
      field :encrypted_password, as: :password, visible: ->(_) { false }
      field :totp_seed, as: :text, visible: ->(_) { false }
      field :mfa_seed, as: :text, visible: ->(_) { false } # legacy field
      field :mfa_level, as: :select, enum: ::User.mfa_levels
      field :mfa_recovery_codes, as: :text, visible: ->(_) { false }
      field :mfa_hashed_recovery_codes, as: :text, visible: ->(_) { false }
      field :webauthn_id, as: :text
      field :remember_token_expires_at, as: :date_time
      field :api_key, as: :text, visible: ->(_) { false }
      field :confirmation_token, as: :text, visible: ->(_) { false }
      field :remember_token, as: :text, visible: ->(_) { false }
      field :salt, as: :text, visible: ->(_) { false }
      field :token, as: :text, visible: ->(_) { false }
      field :token_expires_at, as: :date_time
    end
    field :ownerships, as: :has_many
    field :rubygems, as: :has_many, through: :ownerships
    field :subscriptions, as: :has_many
    field :subscribed_gems, as: :has_many, through: :subscriptions
    field :deletions, as: :has_many
    field :web_hooks, as: :has_many
    field :unconfirmed_ownerships, as: :has_many
    field :api_keys, as: :has_many, name: "API Keys"
    field :ownership_calls, as: :has_many
    field :ownership_requests, as: :has_many
    field :pushed_versions, as: :has_many
    field :oidc_api_key_roles, as: :has_many
    field :webauthn_credentials, as: :has_many
    field :webauthn_verification, as: :has_one

    field :audits, as: :has_many
    field :events, as: :has_many
  end
end

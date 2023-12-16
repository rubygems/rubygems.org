class WebauthnVerificationResource < Avo::BaseResource
  self.title = :id
  self.includes = []

  field :id, as: :id
  # Fields generated from the model
  field :path_token, as: :text
  field :path_token_expires_at, as: :date_time
  field :otp, as: :text
  field :otp_expires_at, as: :date_time
  field :user, as: :belongs_to
  # add fields here
end

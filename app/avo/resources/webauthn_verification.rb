class Avo::Resources::WebauthnVerification < Avo::BaseResource
  self.includes = []

  def fields
    field :id, as: :id

    field :path_token, as: :text
    field :path_token_expires_at, as: :date_time
    field :otp, as: :text
    field :otp_expires_at, as: :date_time
    field :user, as: :belongs_to
  end
end

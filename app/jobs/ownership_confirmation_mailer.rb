OwnershipConfirmationMailer = Struct.new(:ownership_id) do
  def perform
    ownership = Ownership.find_by(id: ownership_id)
    if ownership
      OwnersMailer.ownership_confirmation(ownership).deliver
    else
      Rails.logger.info("[jobs:ownership_confirmation_mailer] ownership not found. skipping sending mail for #{ownership_id}")
    end
  end
end

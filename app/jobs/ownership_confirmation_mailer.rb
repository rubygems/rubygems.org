OwnershipConfirmationMailer = Struct.new(:ownership_id) do
  include SemanticLogger::Loggable

  def perform
    ownership = Ownership.find_by(id: ownership_id)
    if ownership
      OwnersMailer.ownership_confirmation(ownership).deliver
    else
      logger.info("ownership not found. skipping sending mail for #{ownership_id}")
    end
  end
end

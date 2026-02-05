# frozen_string_literal: true

class Maintenance::BackfillAttestationRepairsTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  attribute :max_attestation_id, :integer
  validates :max_attestation_id, presence: true, numericality: { greater_than: 0 }

  def collection
    Attestation.where(id: ..max_attestation_id)
  end

  def process(attestation)
    logger.tagged(attestation_id: attestation.id, version_id: attestation.version_id) do
      unless attestation.repairable?
        logger.info "Attestation #{attestation.id} is not repairable, skipping"
        return
      end

      changes = attestation.repair!

      if changes
        logger.info "Attestation #{attestation.id} repaired: #{changes.join(', ')}"
      else
        logger.warn "Attestation #{attestation.id} was repairable but repair! returned false"
      end
    end
  rescue StandardError => e
    logger.error "Failed to repair attestation #{attestation.id}: #{e.class}: #{e.message}"
    raise
  end
end

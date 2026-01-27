class Avo::Actions::RepairAttestation < Avo::Actions::ApplicationAction
  self.name = "Repair attestation"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    attestation = resource.record
    if attestation.repairable?
      issues = attestation.repair_issues
      "This attestation has the following issues:\n\n#{issues.map { |i| "• #{i}" }.join("\n")}\n\nProceed with repair?"
    else
      "This attestation appears valid. No repairs are expected."
    end
  }
  self.confirm_button_label = "Repair attestation"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(attestation)
      changes = attestation.repair!

      if changes
        succeed "Attestation repaired: #{changes.join(', ')}"
      else
        succeed "No repair was needed"
      end
    rescue ActiveRecord::RecordInvalid => e
      error "Failed to save repaired attestation: #{e.message}"
    rescue StandardError => e
      Rails.logger.error("Attestation repair error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      error "Repair failed: #{e.class}: #{e.message}"
    end
  end
end

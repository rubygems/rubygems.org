class Avo::Actions::RepairAttestation < Avo::Actions::ApplicationAction
  self.name = "Repair attestation"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    if resource.record.repairable?
      "This attestation has invalid data that needs repair. Proceed with repair?"
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
    end
  end
end

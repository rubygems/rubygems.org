class ResetUser2fa < Avo::BaseAction
  self.name = "Reset user 2fa"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to disable MFA and reset the password for #{record.handle} #{record.email}?\n" \
      "This action will be logged."
  }

  field :comment, as: :textarea, required: true

  self.confirm_button_label = "Reset MFA"

  def validate(fields:, **_args)
    unless fields[:comment].presence&.then { _1.length >= 25 }
      error "Must supply a sufficiently detailed comment"
      return
    end

    true
  end

  def handle(**args)
    return keep_modal_open unless validate(**args)
    models, fields, current_user = args.values_at(:models, :fields, :current_user)

    models.each do |user|
      user.transaction do
        user.password = SecureRandom.hex(20).encode("UTF-8")
        user.disable_mfa!
        Audit.create!(
          admin_github_user: current_user,
          auditable: user,
          action: self.class.name,
          comment: fields[:comment],
          audited_changes: {
            records: user.class.connection.transaction_manager.current_transaction.records.to_h do |record|
              [record.to_global_id.uri,
               { changes: record.previous_changes,
                 unchanged: record.attributes.except(*record.previous_changes.keys) }]
            end,
            fields: fields.except(:comment),
            arguments: arguments,
            model: user.to_global_id.uri
          }
        )
      end
    end
  end
end

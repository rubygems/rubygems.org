# app/controllers/concerns/recorder.rb

module Recorder
  extend ActiveSupport::Concern

  private

  def record_transparency_log_event(event_type, record)
    attributes = {
      event_type: event_type,
      authentication_method: "api_key",
      **resource_attributes(record),
      **subject_attributes(record),
      **actor_attributes(record)
    }

    TransparencyLog::Recorder.new.record(attributes)
  rescue StandardError => e
    Rails.error.report(e, handled: true)
  end

  def resource_attributes(record)
    rubygem =
      case record
      when Pusher
        record.rubygem
      when Deletion
        record.version.rubygem
      when User
        @rubygem
      end

    {
      resource_type: "rubygem",
      resource_name: rubygem.name,
      resource_id: rubygem.id.to_s
    }
  end

  def subject_attributes(record)
    case record
    when Pusher, Deletion
      version = record.version

      {
        subject_type: "gem_version",
        subject_name: version.full_name,
        subject_id: version.id.to_s
      }
    when User
      {
        subject_type: "user",
        subject_name: record.handle,
        subject_id: record.id.to_s
      }
    end
  end

  def actor_attributes(record)
    case record
    when Pusher, Deletion
      {
        actor_type: @api_key.user? ? "user" : "unknown",
        actor_id: @api_key.owner_id.to_s,
        actor_handle: @api_key.owner&.name
      }
    when User
      {
        actor_type: "user",
        actor_id: @api_key.user.id.to_s,
        actor_handle: @api_key.user.handle
      }
    end
  end
end

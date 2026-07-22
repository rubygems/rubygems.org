# frozen_string_literal: true

class Maintenance::RevokeCacheExposedApiKeysTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  attribute :min_api_key_id, :integer
  attribute :max_api_key_id, :integer
  validate :max_api_key_id_not_before_min

  def collection
    scope = ApiKey.legacy.unexpired
    scope = scope.where(id: min_api_key_id..) if min_api_key_id.present?
    scope = scope.where(id: ..max_api_key_id) if max_api_key_id.present?
    scope
  end

  def process(api_key)
    return if api_key.expired?

    logger.tagged(api_key_id: api_key.id, owner_id: api_key.owner_id) do
      ApiKey.transaction do
        api_key.expire!
        api_key.user.record_event!(Events::UserEvent::CACHE_EXPOSURE_KEY_REVOKED,
          name: api_key.name, api_key_gid: api_key.to_gid)
      end
      logger.info "Revoked cache-exposed api key"
    end
  end

  private

  def max_api_key_id_not_before_min
    return if min_api_key_id.blank? || max_api_key_id.blank?
    return if max_api_key_id >= min_api_key_id

    errors.add(:max_api_key_id, "must be greater than or equal to min_api_key_id")
  end
end

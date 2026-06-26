# frozen_string_literal: true

# Maps a Rekor log entry into the transparency log event columns that persist inclusion evidence.
TransparencyLogEvent::RekorEntry = Data.define(
  :origin,
  :kind,
  :version,
  :index,
  :checkpoint,
  :inclusion_proof
) do
  def event_attributes
    {
      rekor_log_origin: origin,
      rekor_entry_kind: kind,
      rekor_entry_version: version,
      rekor_log_index: index,
      rekor_checkpoint: checkpoint,
      rekor_inclusion_proof: inclusion_proof
    }
  end
end

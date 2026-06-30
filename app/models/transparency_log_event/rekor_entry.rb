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
  def self.from_json(json_entry)
    new(
      origin: '',
      kind: json_entry["kindVersion"]["kind"],
      version: json_entry["kindVersion"]["version"],
      index: json_entry["logIndex"],
      checkpoint: json_entry["inclusionProof"]["checkpoint"],
      inclusion_proof: json_entry["inclusionProof"]
    )
  end

  def event_attributes
    {
      rekor_log_origin: '',
      rekor_entry_kind: kind,
      rekor_entry_version: version,
      rekor_log_index: index,
      rekor_checkpoint: checkpoint,
      rekor_inclusion_proof: inclusion_proof
    }
  end
end

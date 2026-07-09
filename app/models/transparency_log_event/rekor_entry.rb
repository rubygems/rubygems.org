# frozen_string_literal: true

# Bundles the raw Rekor response body together with the normalized log entry
# it maps into the transparency log event columns that persist inclusion evidence.
TransparencyLogEvent::RekorEntry = Data.define(
  :response_body,
  :origin,
  :kind,
  :version,
  :index,
  :checkpoint,
  :inclusion_proof
) do
  def self.from_json(response_body)
    new(
      response_body: response_body,
      origin: '',
      kind: response_body["kindVersion"]["kind"],
      version: response_body["kindVersion"]["version"],
      index: response_body["logIndex"],
      checkpoint: response_body["inclusionProof"]["checkpoint"],
      inclusion_proof: response_body["inclusionProof"]
    )
  end

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

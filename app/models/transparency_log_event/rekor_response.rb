# frozen_string_literal: true

# Bundles the raw Rekor response body together with the normalized log entry
# it maps into the transparency log event columns that persist inclusion evidence.
TransparencyLogEvent::RekorResponse = Data.define(
  :response_body,
  :origin,
  :kind,
  :version,
  :index,
  :checkpoint,
  :inclusion_proof
) do
  def self.from_json(response_body)
    inclusion_proof = response_body["inclusionProof"]
    checkpoint = inclusion_proof.dig("checkpoint", "envelope")

    new(
      response_body:,
      origin: checkpoint.lines.first.chomp,
      kind: response_body.dig("kindVersion", "kind"),
      version: response_body.dig("kindVersion", "version"),
      index: response_body["logIndex"],
      checkpoint:,
      inclusion_proof:
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

# frozen_string_literal: true

class Avo::Resources::TemporaryPushGrantArtifact < Avo::BaseResource
  self.includes = %i[temporary_push_grant version]

  def fields
    field :id, as: :id
    field :temporary_push_grant, as: :belongs_to
    field :platform, as: :text, help: "The gem platform exactly as built, e.g. <code>ruby</code> or <code>x86_64-linux</code>."
    field :sha256, as: :text, help: "Hex SHA-256 of the exact reviewed .gem file."
    field :version, as: :belongs_to, readonly: true, only_on: %i[index show]
  end
end

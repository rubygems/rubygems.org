module Tuf
  class Serialize
    def self.canonical(document)
      # TODO: Use CanonicalJSON
      JSON.pretty_generate(document)
    end

    def self.roundtrip(document)
      JSON.parse(canonical(document))
    end
  end
end

# frozen_string_literal: true

class OIDC::IdToken::KeyValuePairsComponent < ApplicationComponent
  attr_reader :pairs

  def initialize(pairs:)
    @pairs = pairs
    super()
  end

  def template
    dl(class: "t-body provider_attributes full-width overflow-wrap") do
      pairs.each do |key, val|
        dt(class: "adoption__heading text-right") { code { key } }
        dd { code { val } }
      end
    end
  end
end

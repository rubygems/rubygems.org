# frozen_string_literal: true

class OIDC::IdToken::KeyValuePairsComponent < ApplicationComponent
  prop :pairs, reader: :public

  def view_template
    dl(class: "t-body provider_attributes full-width overflow-wrap") do
      pairs.each do |key, val|
        dt(class: "description__heading text-right") { code { key } }
        dd { code { val } }
      end
    end
  end
end

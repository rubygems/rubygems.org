# frozen_string_literal: true

class OIDC::IdToken::KeyValuePairsComponent < ApplicationComponent
  prop :pairs, reader: :public

  def view_template
    dl(class: "grid grid-cols-[auto_1fr] gap-x-4 gap-y-2 text-sm overflow-x-auto") do
      pairs.each do |key, val|
        dt(class: "text-right font-semibold text-neutral-600 dark:text-neutral-400") { code { key } }
        dd(class: "break-all") { code { val } }
      end
    end
  end
end

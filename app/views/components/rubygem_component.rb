# frozen_string_literal: true

class RubygemComponent < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo

  extend Phlex::Rails::HelperMacros

  register_output_helper :download_count_component
  register_value_helper :short_info
  register_value_helper :latest_version_number

  prop :rubygem

  def view_template(&)
    link_to rubygem_path(id: @rubygem.name), class: LINK_CLASSES do
      div(class: "flex flex-row w-full items-center justify-between") do
        h2(class: "text-b1 font-semibold text-neutral-900 dark:text-white group-hover:text-orange-500 transition-colors",
           data: { testid: "rubygem-name" }) do
          plain @rubygem.name
        end
        version = latest_version_number(@rubygem)
        if version
          code(class: "ml-2 shrink-0 px-2 text-c3 bg-green-200 dark:bg-green-800 rounded-sm text-neutral-900 dark:text-white") { plain version }
        end
      end

      div(class: "flex flex-row w-full items-center justify-between mt-1") do
        p(class: "text-b3 text-neutral-600 dark:text-neutral-400 truncate flex-1 mr-4") do
          plain short_info(@rubygem)
        end
        download_count_component(@rubygem)
      end
    end
  end

  LINK_CLASSES = "flex flex-col w-full px-4 py-4 rounded-md " \
                 "hover:bg-orange-50 dark:hover:bg-orange-950 " \
                 "border-b border-neutral-200 dark:border-neutral-800 " \
                 "group no-underline"
end

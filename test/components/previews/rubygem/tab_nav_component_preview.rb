# frozen_string_literal: true

class Rubygem::TabNavComponentPreview < Lookbook::Preview
  layout "hammy_component_preview"

  def default
    render Rubygem::TabNavComponent.new(current: :gem_info) do |nav|
      nav.disabled_tab("Readme", icon: "description")
      nav.tab("Gem info", "#", icon: "info-i", name: :gem_info)
      nav.disabled_tab("Contents", icon: "folder-open")
      nav.tab("Dependencies", "#", icon: "account-tree", name: :dependencies)
    end
  end
end

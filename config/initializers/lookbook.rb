Rails.application.config.lookbook.preview_layout = "component_preview" if Rails.env.local?

if Rails.env.development?
  module Lookbook::PreviewOverrides
    # see https://github.com/ViewComponent/lookbook/issues/584
    def render(component = nil, **args, &block)
      if block
        super { component.instance_exec component, &block }
      else
        super
      end
    end
  end

  Rails.application.configure { Lookbook::Preview.prepend Lookbook::PreviewOverrides }
end

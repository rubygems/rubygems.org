module LayoutHelper
  # <%= layout_section "Footer Nav", class: "py-8 bg-orange-100 dark:bg-orange-950 text-neutral-800 dark:text-neutral-200 flex-col items-center">
  def layout_section(_name, **options, &)
    options[:class] = "w-full px-8 #{options[:class]}"

    tag.div(**options) do
      tag.div(class: "max-w-screen-xl mx-auto flex flex-col", &)
    end
  end
end

module IconHelper
  # size is in tailwind units (6 = 24px)
  def icon_tag(name, size: 6, **options)
    options[:class] = "h-#{size} w-#{size} flex-shrink-0 stroke-current stroke-0 fill-current #{options[:class]}"
    options[:height] = size * 4
    options[:width] = size * 4
    options[:aria] ||= { hidden: true }
    options[:role] ||= "graphics-symbol"

    tag.svg(**options) do
      concat tag.use(href: "/images/icons.svg##{name}")
    end
  end
end

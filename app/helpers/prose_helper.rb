module ProseHelper
  def prose(**options, &)
    base = "prose prose-neutral dark:prose-invert prose-lg md:prose-xl max-w-prose mx-auto"
    styles = "prose-headings:font-semibold"
    options[:class] = "#{options[:class]} #{base} #{styles}"
    tag.div(**options, &)
  end
end

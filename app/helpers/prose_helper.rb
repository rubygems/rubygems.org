module ProseHelper
  def prose(&)
    base = "prose prose-neutral dark:prose-invert prose-lg lg:prose-xl max-w-prose mx-auto"
    styles = "prose-headings:font-semibold"
    tag.div class: "#{base} #{styles}", &
  end
end

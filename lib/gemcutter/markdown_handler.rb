module Gemcutter::MarkdownHandler
  def self.erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def self.call(_template, source)
    "@title = t('.title'); prose { Kramdown::Document.new(#{source.dump}).to_html.html_safe }"
  end
end

# frozen_string_literal: true

require "gemcutter/markdown"

module Gemcutter::MarkdownHandler
  def self.call(_template, source)
    "@title = t('.title'); prose { Gemcutter::Markdown.render(#{source.dump}) }"
  end
end

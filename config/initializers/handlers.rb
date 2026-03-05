# frozen_string_literal: true

require "gemcutter/markdown_handler"

ActionView::Template.register_template_handler :md, Gemcutter::MarkdownHandler

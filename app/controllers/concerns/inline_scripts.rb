# frozen_string_literal: true

# This concern allows us to define inline scripts in the controller.
# This means that scripts can be generated and then their sha256 hash can be
# calculated for use in the content security policy.
#
# This is useful for importmap and other inline scripts that are generated
# and need to be included in the content security policy.
#
# We rely on the sha256 hash because a nonce doesn't work as well with caching.
# The nonce would otherwise get cached and served to everyone. Not very nonce-y.
module InlineScripts
  extend ActiveSupport::Concern

  module Helper
    def javascript_inline_importmap_tag(importmap)
      importmap = inline_script_content(importmap) if importmap.is_a?(Symbol)
      tag.script importmap.html_safe, type: "importmap", "data-turbo-track": "reload"
    end

    def javascript_module_tag(content)
      content = inline_script_content(content) if content.is_a?(Symbol)
      tag.script content.html_safe, type: "module"
    end
  end

  class_methods do
    def inline_script(name, content = nil, &block)
      content = block if block
      inline_scripts[name] = content
    end
  end

  included do
    class_attribute :inline_scripts
    self.inline_scripts = {}

    helper InlineScripts::Helper
    helper_method :inline_script_content

    private :inline_scripts
    private :inline_script_content
    private :inline_script_content_security_hashes

    content_security_policy do |policy|
      script_srcs = policy.script_src + inline_script_content_security_hashes
      policy.script_src(*script_srcs)
    end
  end

  def inline_script_content(name)
    content = inline_scripts[name]
    case content
    when Proc then instance_exec(&content)
    when Symbol then send(content)
    else content
    end
  end

  def inline_script_content_security_hashes
    inline_scripts.map do |name, _|
      content = inline_script_content(name)
      "'sha256-#{Digest::SHA256.base64digest(content)}'"
    end
  end

  def inline_scripts
    self.class.inline_scripts
  end
end

class WebHookSerializer < ApplicationSerializer
  attributes :failure_count, :url

  def to_xml(options = {})
    super(options.merge(root: 'web_hook'))
  end
end

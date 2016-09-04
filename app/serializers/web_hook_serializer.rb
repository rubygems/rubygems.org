class WebHookSerializer < ApplicationSerializer
  def attributes(*args)
    data = super

    object.specific.each do |o|
      data[o.rubygem.name] ||= []
      data[o.rubygem.name] << { "failure_count" => o.failure_count, "url" => o.url }
    end

    globals = object.global.to_a
    return data unless globals.present?

    data['all gems'] = []
    globals.each do |g|
      data['all gems'] << { "failure_count" => g.failure_count, "url" => g.url }
    end

    data
  end

  def to_xml(options = {})
    super(options.merge(root: 'web_hook'))
  end
end

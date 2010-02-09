class NewRelic::MetricParser::MemCache < NewRelic::MetricParser
  def is_memcache?; true; end
  
  # for MemCache metrics, the short name is actually
  # the full name
  def short_name
    name
  end
  def developer_name
    "MemCache #{segments[1..-1].join '/'}"
  end
end
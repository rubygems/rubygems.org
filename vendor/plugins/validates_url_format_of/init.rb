module ValidatesUrlFormatOf
  IPv4_PART = /\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]/  # 0-255
  REGEXP = %r{
    \A
    https?://                                        # http:// or https://
    ([^\s:@]+:[^\s:@]*@)?                            # optional username:pw@
    ( (xn--)?[^\W_]+([-.][^\W_]+)*\.[a-z]{2,6}\.? |  # domain (including Punycode/IDN)...
        #{IPv4_PART}(\.#{IPv4_PART}){3} )            # or IPv4
    (:\d{1,5})?                                      # optional port
    ([/?]\S*)?                                       # optional /whatever or ?whatever
    \Z
  }iux

  DEFAULT_MESSAGE     = 'does not appear to be a valid URL'
  DEFAULT_MESSAGE_URL = 'does not appear to be valid'
  
  def validates_url_format_of(*attr_names)
    options = { :allow_nil => false,
                :allow_blank => false,
                :with => REGEXP }                
    options = options.merge(attr_names.pop) if attr_names.last.is_a?(Hash)

    attr_names.each do |attr_name|
      message = attr_name.to_s.match(/(_|\b)URL(_|\b)/i) ? DEFAULT_MESSAGE_URL : DEFAULT_MESSAGE
      validates_format_of(attr_name, { :message => message }.merge(options))
    end
  end
  
end

ActiveRecord::Base.extend(ValidatesUrlFormatOf)

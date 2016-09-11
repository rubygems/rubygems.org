module WillPaginate::ViewHelpers
  class LinkRenderer
    BLACK_LISTED_PARAMS = [:host, :protocol, :port, :subdomain, :domain, :tld_length,
                           :trailing_slash, :anchor, :params, :only_path, :script_name,
                           :original_script_name, :relative_url_root].freeze

    private

    def symbolized_update(target, other)
      other.each do |key, value|
        key = key.to_sym
        next if BLACK_LISTED_PARAMS.include? key
        existing = target[key]

        if value.is_a?(Hash) && (existing.is_a?(Hash) || existing.nil?)
          symbolized_update(existing || (target[key] = {}), value)
        else
          target[key] = value
        end
      end
    end
  end
end

# frozen_string_literal: true

class OrganizationDomain::Name
  ALLOWED_CHARACTERS = /\A[a-z0-9.-]+\z/
  MAX_LABEL_LENGTH = 63
  # 253 minus "_rubygems-challenge.".length
  MAX_LENGTH = 233

  class << self
    def valid?(input)
      errors_for(input).empty?
    end

    def errors_for(input)
      check_errors(input.to_s)
    end

    private

    def check_errors(domain)
      return [:blank] if domain.blank?

      errors = invalid_label_errors(domain)
      errors << :public_suffix if errors.empty? && !PublicSuffix.valid?(domain, default_rule: nil)
      errors << :too_long if domain.length > MAX_LENGTH
      errors
    end

    def invalid_label_errors(domain)
      # include subdomains in the label check
      labels = domain.split(".", -1)
      [
        (:invalid_characters unless ALLOWED_CHARACTERS.match?(domain)),
        (:invalid_label unless labels.all? { |label| valid_label?(label) }),
        (:single_label if labels.size < 2),
        (:ip_address if labels.last.match?(/\A\d+\z/))
      ].compact
    end

    def valid_label?(label)
      label.length.between?(1, MAX_LABEL_LENGTH) && !label.start_with?("-") && !label.end_with?("-")
    end
  end
end

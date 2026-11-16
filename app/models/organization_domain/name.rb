# frozen_string_literal: true

class OrganizationDomain::Name
  ALLOWED_CHARACTERS = /\A[a-z0-9.-]+\z/
  # Labels are the text segments between "." in a domain
  MAX_LABEL_LENGTH = 63
  # 253 minus "_rubygems-challenge.".length
  MAX_LENGTH = 233

  class << self
    def valid?(input)
      errors_for(input).empty?
    end

    # Returns every rule the domain breaks, as symbols, in a stable order.
    def errors_for(input)
      check_errors(input.to_s)
    end

    private

    def check_errors(domain)
      return [:blank] if domain.blank?

      errors = structural_errors(domain)
      # Only meaningful for an otherwise well-formed name; anything else would
      # also fail here and just repeat the structural problem.
      errors << :public_suffix if errors.empty? && !PublicSuffix.valid?(domain, default_rule: nil)
      errors << :too_long if domain.length > MAX_LENGTH
      errors
    end

    def structural_errors(domain)
      labels = domain.split(".", -1)
      [
        (:invalid_characters unless ALLOWED_CHARACTERS.match?(domain)),
        (:invalid_label unless labels.all? { |label| valid_label?(label) }),
        (:single_label if labels.size < 2),
        (:ip_address if labels.last.match?(/\A\d+\z/))
      ].compact
    end

    # Label shape only; characters are checked across the whole domain.
    def valid_label?(label)
      label.length.between?(1, MAX_LABEL_LENGTH) && !label.start_with?("-") && !label.end_with?("-")
    end
  end
end

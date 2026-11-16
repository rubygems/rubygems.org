# frozen_string_literal: true

# Validates a domain name entered by an organization owner. Input is never
# corrected here; callers only strip and downcase before validating.
class OrganizationDomain::Name
  Error = Data.define(:key, :characters, :hint)

  ALLOWED_CHARACTERS = /\A[a-z0-9.-]+\z/
  LABEL = /\A[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/
  # 253 minus "_rubygems-challenge.".length
  MAX_LENGTH = 233

  class << self
    def valid?(input)
      errors_for(input).empty?
    end

    # Returns an array with at most one Error: the first failing rule.
    def errors_for(input)
      domain = input.to_s
      key = first_failing_rule(domain)
      return [] unless key

      if key == :invalid_characters
        [Error.new(key:, characters: domain.scan(/[^a-z0-9.-]/).uniq, hint: hint_for(domain))]
      else
        [Error.new(key:, characters: [], hint: nil)]
      end
    end

    private

    def first_failing_rule(domain)
      return :blank if domain.blank?
      return :invalid_characters unless ALLOWED_CHARACTERS.match?(domain)

      labels = domain.split(".", -1)
      return :invalid_label unless labels.all? { |label| LABEL.match?(label) }
      return :single_label if labels.size < 2
      return :ip_address if labels.last.match?(/\A\d+\z/)
      return :public_suffix unless PublicSuffix.valid?(domain, default_rule: nil)

      :too_long if domain.length > MAX_LENGTH
    end

    def hint_for(domain)
      if domain.include?("/") then :url
      elsif domain.include?("@") then :email
      elsif domain.start_with?("*.") then :wildcard
      elsif domain.match?(/:\d/) then :port
      elsif !domain.ascii_only? then :unicode
      end
    end
  end
end

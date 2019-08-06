# frozen_string_literal: true

# Adapted from Phil Nash's pwned gem to use the HIBP V3 API with zero additional
# dependencies for rubygems.org
#
# MIT License (MIT), Copyright (c) 2018 Phil Nash
#
# Original source code: https://git.io/fjHb3

##
# An +ActiveModel+ validator to check passwords against the Pwned Passwords API.
#
# @example Validate a password on a +User+ model with the default options.
#     class User < ApplicationRecord
#       validates :password, not_pwned: true
#     end
#
# @example Validate a password on a +User+ model with a custom error message.
#     class User < ApplicationRecord
#       validates :password, not_pwned: { message: "has been pwned %{count} times" }
#     end
#
# @example Validate a password on a +User+ model that allows the password to have been breached once.
#     class User < ApplicationRecord
#       validates :password, not_pwned: { threshold: 1 }
#     end
class NotPwnedValidator < ActiveModel::EachValidator
  ##
  # The default threshold for whether a breach is considered pwned. The default
  # is 0, so any password that appears in a breach will mark the record as
  # invalid.
  DEFAULT_THRESHOLD = 0

  ##
  # Validates the +value+ against the Pwned Passwords API. If the +pwned_count+
  # is higher than the optional +threshold+ then the record is marked as
  # invalid.
  #
  # In the case of an API error the validator will either mark the
  # record as valid or invalid. Alternatively it will run an associated proc or
  # re-raise the original error.
  #
  # The validation will short circuit and return with no errors added if the
  # password is blank. Technically the empty string is not a password that is
  # reported to be found in data breaches, so returns +false+, short circuiting
  # that using +value.blank?+ saves us a trip to the API.
  #
  # @param record [ActiveModel::Validations] The object being validated
  # @param attribute [Symbol] The attribute on the record that is currently
  #   being validated.
  # @param value [String] The value of the attribute on the record that is the
  #   subject of the validation
  def validate_each(record, attribute, value)
    # Short circuit the validation for tests, unless explicitly enabled
    return if Rails.env.test? && !options[:enable_in_testing]
    return if value.blank?
    begin
      pwned_count = pwned_check(value)
      record.errors.add(attribute, :not_pwned, options.merge(count: pwned_count)) if pwned_count > threshold
    rescue RestClient::ExceptionWithResponse # rubocop:disable Lint/HandleExceptions
      # Do nothing if the HTTP call fails, consider the record valid
    end
  end

  private

  ##
  # Check for pwned passwords from the HIBP V3 API.
  #
  # @param password [String] The password being validated
  # @return [Integer] The number of times that the password has been compromised
  def pwned_check(password)
    hash = Digest::SHA1.hexdigest(password).upcase
    prefix = hash.first(5)

    response = RestClient::Request.execute(
      method: :get,
      url: "https://api.pwnedpasswords.com/range/#{prefix}",
      timeout: 3,
      headers: {
        user_agent: "RubyGems.org"
      }
    )

    hits = response.body.split("\r\n").map { |line| line.split(":") }
    found = hits.find { |hit| hash = "#{prefix}#{hit.first}" }

    if found
      found.last.to_i
    else
      0
    end
  end

  def threshold
    threshold = options[:threshold] || DEFAULT_THRESHOLD
    raise TypeError, "#{self.class} option 'threshold' must be of type Integer" unless threshold.is_a? Integer
    threshold
  end
end

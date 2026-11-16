# frozen_string_literal: true

# Stands in for Resolv::DNS: answers from a hash of [absolute name, type] => records.
# An Exception instance or class as the answer is raised instead.
class FakeDnsResolver
  TXT = Resolv::DNS::Resource::IN::TXT
  SOA = Resolv::DNS::Resource::IN::SOA

  attr_reader :queries

  def initialize(answers = {})
    @answers = answers
    @queries = []
  end

  def getresources(name, type)
    @queries << [name, type]
    answer = @answers.fetch([name, type], [])
    raise answer if answer.is_a?(Exception) || (answer.is_a?(Class) && answer <= Exception)

    answer
  end

  def timeouts=(_value)
  end

  def close
  end

  # Answers for a domain whose challenge record is published with `value` (absent when nil).
  def self.for_domain(domain, value: nil)
    soa = SOA.new(Resolv::DNS::Name.create("ns.#{domain}."), Resolv::DNS::Name.create("h.#{domain}."), 1, 1, 1, 1, 1)
    answers = { ["#{domain}.", SOA] => [soa] }
    answers[["_rubygems-challenge.#{domain}.", TXT]] = [TXT.new(value)] if value
    new(answers)
  end
end

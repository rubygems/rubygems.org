# frozen_string_literal: true

class Advisory::OSV < Advisory
  enum :severity, { low: "low", moderate: "moderate", high: "high", critical: "critical" }, validate: { allow_nil: true }
end

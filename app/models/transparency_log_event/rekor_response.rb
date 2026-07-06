# frozen_string_literal: true

# Bundles the raw Rekor response body together with its parsed log entry.
TransparencyLogEvent::RekorResponse = Data.define(:response_body, :rekor_entry)

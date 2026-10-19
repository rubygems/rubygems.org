# frozen_string_literal: true

require "test_helper"

class SponsorTest < ActiveSupport::TestCase
  test "categories, anonymity and independent footer visibility" do
    sponsor = Sponsor.new(name: "Private donor", tier: :supporter_plus, anonymous: true, show_in_footer: true)

    assert_predicate sponsor, :valid?
    sponsor.save!

    assert_empty Sponsor.in_footer

    sponsor.anonymous = false

    refute_predicate sponsor, :valid?
    assert_includes sponsor.errors.attribute_names, :logo
    assert_includes sponsor.errors.attribute_names, :website_url

    sponsor.website_url = "javascript:alert(1)"
    sponsor.tier = "future"
    sponsor.position = -1

    refute_predicate sponsor, :valid?
    %i[website_url tier position].each { |attribute| assert_includes sponsor.errors.attribute_names, attribute }
  end

  test "optimized raster logos only and no reuse of private blobs" do
    sponsor = Sponsor.new(name: "Sponsor", tier: :open_source, website_url: "https://example.org")
    sponsor.logo.attach(io: StringIO.new("<svg/>"), filename: "logo.svg", content_type: "image/svg+xml")

    refute_predicate sponsor, :valid?
    assert_includes sponsor.errors[:logo], "must be PNG or WebP"

    sponsor.logo.attach(io: StringIO.new("x" * (256.kilobytes + 1)), filename: "large.png", content_type: "image/png", identify: false)

    refute_predicate sponsor, :valid?
    assert_includes sponsor.errors[:logo], "must be no larger than 256 KB; optimize it before uploading"

    Rails.root.join("app/assets/images/sponsors/aws.png").open do |io|
      sponsor.logo.attach(io:, filename: "aws.png", content_type: "image/png")
      sponsor.save!
    end
    other = Sponsor.new(name: "Other", tier: :infrastructure, website_url: "https://other.example.org")
    other.logo.attach(sponsor.logo.blob.signed_id)

    refute_predicate other, :valid?
    assert_includes other.errors[:logo], "must be a new upload"
    sponsor.reload.update!(position: 9)

    assert_equal 9, sponsor.reload.position
  end
end

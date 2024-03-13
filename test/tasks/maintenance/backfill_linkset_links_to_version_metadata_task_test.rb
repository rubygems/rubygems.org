# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillLinksetLinksToVersionMetadataTaskTest < ActiveSupport::TestCase
  context "#collection" do
    should "return all versions" do
      assert_equal Version.count, Maintenance::BackfillLinksetLinksToVersionMetadataTask.collection.count
    end
  end

  context "#process" do
    context "without a linkset" do
      setup do
        @version = create(:version)
        @rubygem = @version.rubygem
        @rubygem.update!(linkset: nil)
      end

      should "not change version metadata" do
        assert_no_changes "@version.reload.metadata" do
          Maintenance::BackfillLinksetLinksToVersionMetadataTask.process(@version)
        end
      end
    end

    context "with a linkset and version metadata uris" do
      setup do
        @version = create(
          :version,
          metadata: {
            "source_code_uri" => "https://example.com/source",
            "documentation_uri" => "https://example.com/docs",
            "foo" => "bar"
          }
        )
        @rubygem = @version.rubygem
        @rubygem.linkset.update!("home" => "https://example.com/home",
                                 "wiki" => "https://example.com/wiki")
      end

      should "only update the home uri" do
        Maintenance::BackfillLinksetLinksToVersionMetadataTask.process(@version)

        assert_equal({
                       "source_code_uri" => "https://example.com/source",
                       "documentation_uri" => "https://example.com/docs",
                       "foo" => "bar",
                       "homepage_uri" => "https://example.com/home"
                     }, @version.reload.metadata)
      end

      should "not update the home uri when present in metadata" do
        @version.metadata["homepage_uri"] = "https://example.com/home/custom"
        @version.save!

        Maintenance::BackfillLinksetLinksToVersionMetadataTask.process(@version)

        assert_equal({
                       "source_code_uri" => "https://example.com/source",
                       "documentation_uri" => "https://example.com/docs",
                       "foo" => "bar",
                       "homepage_uri" => "https://example.com/home/custom"
                     }, @version.reload.metadata)
      end
    end

    context "with a linkset and no version metadata uris" do
      setup do
        @version = create(:version, metadata: { "foo" => "bar" })
        @rubygem = @version.rubygem
        @rubygem.linkset.update!("home" => "https://example.com/home",
                                 "wiki" => "https://example.com/wiki")
      end

      should "update the version metadata" do
        Maintenance::BackfillLinksetLinksToVersionMetadataTask.process(@version)

        assert_equal({
                       "wiki_uri" => "https://example.com/wiki",
                       "foo" => "bar",
                       "homepage_uri" => "https://example.com/home",
                       "bug_tracker_uri" => "http://example.com",
                       "source_code_uri" => "http://example.com",
                       "mailing_list_uri" => "http://example.com",
                       "documentation_uri" => "http://example.com"
                     }, @version.reload.metadata)
      end
    end
  end
end

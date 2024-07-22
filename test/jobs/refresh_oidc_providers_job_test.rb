require "test_helper"

class RefreshOIDCProvidersJobTest < ActiveJob::TestCase
  test "enqueues refresh jobs" do
    provider1 = create(:oidc_provider)
    provider2 = create(:oidc_provider)

    assert_enqueued_jobs 2, only: RefreshOIDCProviderJob do
      assert_enqueued_with(job: RefreshOIDCProviderJob, args: [{ provider: provider1 }]) do
        assert_enqueued_with(job: RefreshOIDCProviderJob, args: [{ provider: provider2 }]) do
          RefreshOIDCProvidersJob.perform_now
        end
      end
    end
  end
end

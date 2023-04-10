require "test_helper"

class Api::V1::OIDC::ApiKeyRolesTest < ActionDispatch::IntegrationTest
  make_my_diffs_pretty!

  context "on POST to assume_role" do
    setup do
      @role = create(:oidc_api_key_role)
      @user = @role.user

      travel_to Time.zone.at(1_680_020_830) # after the JWT iat, before the exp
    end

    context "with an unknown id" do
      should "response not found" do
        post assume_role_api_v1_oidc_api_key_role_path(@role.id + 1),
            params: {},
            headers: {}

        assert_response :not_found
      end
    end

    context "with a known id" do
      context "with an invalid jwt" do
        should "respond not found" do
          post assume_role_api_v1_oidc_api_key_role_path(@role),
              params: {
                jwt: "1eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImVCWl9jbjNzWFlBZDBjaDRUSEJLSElnT3dPRSIsImtpZCI6Ijc4MTY3RjcyN0RFQzVEODAxREQxQzg3ODRDNzA0QTFDODgwRUMwRTEifQ.eyJqdGkiOiI3OTY4NWI2NS05NDVkLTQ1MGEtYTNkOC1hMzZiY2Y3MmMyM2QiLCJzdWIiOiJyZXBvOnNlZ2lkZGlucy9vaWRjLXRlc3Q6cmVmOnJlZnMvaGVhZHMvbWFpbiIsImF1ZCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9zZWdpZGRpbnMiLCJyZWYiOiJyZWZzL2hlYWRzL21haW4iLCJzaGEiOiIwNGRlMzU1OGJjNTg2MTg3NGE4NmY4ZmNkNjdlNTE2NTU0MTAxZTcxIiwicmVwb3NpdG9yeSI6InNlZ2lkZGlucy9vaWRjLXRlc3QiLCJyZXBvc2l0b3J5X293bmVyIjoic2VnaWRkaW5zIiwicmVwb3NpdG9yeV9vd25lcl9pZCI6IjE5NDY2MTAiLCJydW5faWQiOiI0NTQ1MjMxMDg0IiwicnVuX251bWJlciI6IjQiLCJydW5fYXR0ZW1wdCI6IjEiLCJyZXBvc2l0b3J5X3Zpc2liaWxpdHkiOiJwdWJsaWMiLCJyZXBvc2l0b3J5X2lkIjoiNjIwMzkzODM4IiwiYWN0b3JfaWQiOiIxOTQ2NjEwIiwiYWN0b3IiOiJzZWdpZGRpbnMiLCJ3b3JrZmxvdyI6Ii5naXRodWIvd29ya2Zsb3dzL3Rva2VuLnltbCIsImhlYWRfcmVmIjoiIiwiYmFzZV9yZWYiOiIiLCJldmVudF9uYW1lIjoicHVzaCIsInJlZl90eXBlIjoiYnJhbmNoIiwid29ya2Zsb3dfcmVmIjoic2VnaWRkaW5zL29pZGMtdGVzdC8uZ2l0aHViL3dvcmtmbG93cy90b2tlbi55bWxAcmVmcy9oZWFkcy9tYWluIiwid29ya2Zsb3dfc2hhIjoiMDRkZTM1NThiYzU4NjE4NzRhODZmOGZjZDY3ZTUxNjU1NDEwMWU3MSIsImpvYl93b3JrZmxvd19yZWYiOiJzZWdpZGRpbnMvb2lkYy10ZXN0Ly5naXRodWIvd29ya2Zsb3dzL3Rva2VuLnltbEByZWZzL2hlYWRzL21haW4iLCJqb2Jfd29ya2Zsb3dfc2hhIjoiMDRkZTM1NThiYzU4NjE4NzRhODZmOGZjZDY3ZTUxNjU1NDEwMWU3MSIsInJ1bm5lcl9lbnZpcm9ubWVudCI6ImdpdGh1Yi1ob3N0ZWQiLCJpc3MiOiJodHRwczovL3Rva2VuLmFjdGlvbnMuZ2l0aHVidXNlcmNvbnRlbnQuY29tIiwibmJmIjoxNjgwMDE5OTM3LCJleHAiOjE2ODAwMjA4MzcsImlhdCI6MTY4MDAyMDUzN30.yVYbck_X2O8ehc7iOGLR1cNzRal85Oc25OxiCIohIjvY04S3neMasb5GAKMyKSM4gDA9g8w5hRAOyngc5O-EDapI4Ug6CHdXUQ2H73xzsNO-s73pHqs5jStzDWm24SdM8JFSG4ycCtoShimyRbc5nphbVdB74we_z2eLn5LwLE1fTxQ2e5pu2ReouRgnyKHlwrGcsMUN2S_JMCPGKhV8wQ6xbnHq1FEAgS3SS1JTOT_fOgmcJIxZ_NL-437TiU77g770kFFwmK7Ac_-E9AuDojAnTqAkLZq_-m-zULmtVHswNbaVqZmmbp9xm1XcWJFB50_Mg58Hxkx3CB4N9kvFbg"
              },
              headers: {}

          assert_response :not_found
          assert_empty @user.api_keys
        end
      end

      context "with a jwt that does not match the jwks" do
        should "respond not found" do
          @role.provider.jwks.each { _1["n"] += "NO" }
          @role.provider.save!

          post assume_role_api_v1_oidc_api_key_role_path(@role),
              params: {
                jwt: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImVCWl9jbjNzWFlBZDBjaDRUSEJLSElnT3dPRSIsImtpZCI6Ijc4MTY3RjcyN0RFQzVEODAxREQxQzg3ODRDNzA0QTFDODgwRUMwRTEifQ.eyJqdGkiOiI3OTY4NWI2NS05NDVkLTQ1MGEtYTNkOC1hMzZiY2Y3MmMyM2QiLCJzdWIiOiJyZXBvOnNlZ2lkZGlucy9vaWRjLXRlc3Q6cmVmOnJlZnMvaGVhZHMvbWFpbiIsImF1ZCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9zZWdpZGRpbnMiLCJyZWYiOiJyZWZzL2hlYWRzL21haW4iLCJzaGEiOiIwNGRlMzU1OGJjNTg2MTg3NGE4NmY4ZmNkNjdlNTE2NTU0MTAxZTcxIiwicmVwb3NpdG9yeSI6InNlZ2lkZGlucy9vaWRjLXRlc3QiLCJyZXBvc2l0b3J5X293bmVyIjoic2VnaWRkaW5zIiwicmVwb3NpdG9yeV9vd25lcl9pZCI6IjE5NDY2MTAiLCJydW5faWQiOiI0NTQ1MjMxMDg0IiwicnVuX251bWJlciI6IjQiLCJydW5fYXR0ZW1wdCI6IjEiLCJyZXBvc2l0b3J5X3Zpc2liaWxpdHkiOiJwdWJsaWMiLCJyZXBvc2l0b3J5X2lkIjoiNjIwMzkzODM4IiwiYWN0b3JfaWQiOiIxOTQ2NjEwIiwiYWN0b3IiOiJzZWdpZGRpbnMiLCJ3b3JrZmxvdyI6Ii5naXRodWIvd29ya2Zsb3dzL3Rva2VuLnltbCIsImhlYWRfcmVmIjoiIiwiYmFzZV9yZWYiOiIiLCJldmVudF9uYW1lIjoicHVzaCIsInJlZl90eXBlIjoiYnJhbmNoIiwid29ya2Zsb3dfcmVmIjoic2VnaWRkaW5zL29pZGMtdGVzdC8uZ2l0aHViL3dvcmtmbG93cy90b2tlbi55bWxAcmVmcy9oZWFkcy9tYWluIiwid29ya2Zsb3dfc2hhIjoiMDRkZTM1NThiYzU4NjE4NzRhODZmOGZjZDY3ZTUxNjU1NDEwMWU3MSIsImpvYl93b3JrZmxvd19yZWYiOiJzZWdpZGRpbnMvb2lkYy10ZXN0Ly5naXRodWIvd29ya2Zsb3dzL3Rva2VuLnltbEByZWZzL2hlYWRzL21haW4iLCJqb2Jfd29ya2Zsb3dfc2hhIjoiMDRkZTM1NThiYzU4NjE4NzRhODZmOGZjZDY3ZTUxNjU1NDEwMWU3MSIsInJ1bm5lcl9lbnZpcm9ubWVudCI6ImdpdGh1Yi1ob3N0ZWQiLCJpc3MiOiJodHRwczovL3Rva2VuLmFjdGlvbnMuZ2l0aHVidXNlcmNvbnRlbnQuY29tIiwibmJmIjoxNjgwMDE5OTM3LCJleHAiOjE2ODAwMjA4MzcsImlhdCI6MTY4MDAyMDUzN30.yVYbck_X2O8ehc7iOGLR1cNzRal85Oc25OxiCIohIjvY04S3neMasb5GAKMyKSM4gDA9g8w5hRAOyngc5O-EDapI4Ug6CHdXUQ2H73xzsNO-s73pHqs5jStzDWm24SdM8JFSG4ycCtoShimyRbc5nphbVdB74we_z2eLn5LwLE1fTxQ2e5pu2ReouRgnyKHlwrGcsMUN2S_JMCPGKhV8wQ6xbnHq1FEAgS3SS1JTOT_fOgmcJIxZ_NL-437TiU77g770kFFwmK7Ac_-E9AuDojAnTqAkLZq_-m-zULmtVHswNbaVqZmmbp9xm1XcWJFB50_Mg58Hxkx3CB4N9kvFbg"
              },
              headers: {}

          assert_response :not_found
          assert_empty @user.api_keys
        end
      end

      context "with a jwt with the wrong issuer" do
        should "respond not found" do
          @role.provider.configuration.issuer = "https://example.com"
          @role.provider.update!(issuer: "https://example.com")

          post assume_role_api_v1_oidc_api_key_role_path(@role),
              params: {
                jwt: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImVCWl9jbjNzWFlBZDBjaDRUSEJLSElnT3dPRSIsImtpZCI6Ijc4MTY3RjcyN0RFQzVEODAxREQxQzg3ODRDNzA0QTFDODgwRUMwRTEifQ.eyJqdGkiOiI3OTY4NWI2NS05NDVkLTQ1MGEtYTNkOC1hMzZiY2Y3MmMyM2QiLCJzdWIiOiJyZXBvOnNlZ2lkZGlucy9vaWRjLXRlc3Q6cmVmOnJlZnMvaGVhZHMvbWFpbiIsImF1ZCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9zZWdpZGRpbnMiLCJyZWYiOiJyZWZzL2hlYWRzL21haW4iLCJzaGEiOiIwNGRlMzU1OGJjNTg2MTg3NGE4NmY4ZmNkNjdlNTE2NTU0MTAxZTcxIiwicmVwb3NpdG9yeSI6InNlZ2lkZGlucy9vaWRjLXRlc3QiLCJyZXBvc2l0b3J5X293bmVyIjoic2VnaWRkaW5zIiwicmVwb3NpdG9yeV9vd25lcl9pZCI6IjE5NDY2MTAiLCJydW5faWQiOiI0NTQ1MjMxMDg0IiwicnVuX251bWJlciI6IjQiLCJydW5fYXR0ZW1wdCI6IjEiLCJyZXBvc2l0b3J5X3Zpc2liaWxpdHkiOiJwdWJsaWMiLCJyZXBvc2l0b3J5X2lkIjoiNjIwMzkzODM4IiwiYWN0b3JfaWQiOiIxOTQ2NjEwIiwiYWN0b3IiOiJzZWdpZGRpbnMiLCJ3b3JrZmxvdyI6Ii5naXRodWIvd29ya2Zsb3dzL3Rva2VuLnltbCIsImhlYWRfcmVmIjoiIiwiYmFzZV9yZWYiOiIiLCJldmVudF9uYW1lIjoicHVzaCIsInJlZl90eXBlIjoiYnJhbmNoIiwid29ya2Zsb3dfcmVmIjoic2VnaWRkaW5zL29pZGMtdGVzdC8uZ2l0aHViL3dvcmtmbG93cy90b2tlbi55bWxAcmVmcy9oZWFkcy9tYWluIiwid29ya2Zsb3dfc2hhIjoiMDRkZTM1NThiYzU4NjE4NzRhODZmOGZjZDY3ZTUxNjU1NDEwMWU3MSIsImpvYl93b3JrZmxvd19yZWYiOiJzZWdpZGRpbnMvb2lkYy10ZXN0Ly5naXRodWIvd29ya2Zsb3dzL3Rva2VuLnltbEByZWZzL2hlYWRzL21haW4iLCJqb2Jfd29ya2Zsb3dfc2hhIjoiMDRkZTM1NThiYzU4NjE4NzRhODZmOGZjZDY3ZTUxNjU1NDEwMWU3MSIsInJ1bm5lcl9lbnZpcm9ubWVudCI6ImdpdGh1Yi1ob3N0ZWQiLCJpc3MiOiJodHRwczovL3Rva2VuLmFjdGlvbnMuZ2l0aHVidXNlcmNvbnRlbnQuY29tIiwibmJmIjoxNjgwMDE5OTM3LCJleHAiOjE2ODAwMjA4MzcsImlhdCI6MTY4MDAyMDUzN30.yVYbck_X2O8ehc7iOGLR1cNzRal85Oc25OxiCIohIjvY04S3neMasb5GAKMyKSM4gDA9g8w5hRAOyngc5O-EDapI4Ug6CHdXUQ2H73xzsNO-s73pHqs5jStzDWm24SdM8JFSG4ycCtoShimyRbc5nphbVdB74we_z2eLn5LwLE1fTxQ2e5pu2ReouRgnyKHlwrGcsMUN2S_JMCPGKhV8wQ6xbnHq1FEAgS3SS1JTOT_fOgmcJIxZ_NL-437TiU77g770kFFwmK7Ac_-E9AuDojAnTqAkLZq_-m-zULmtVHswNbaVqZmmbp9xm1XcWJFB50_Mg58Hxkx3CB4N9kvFbg"
              },
              headers: {}

          assert_response :not_found
          assert_empty @user.api_keys
        end
      end

      context "with matching conditions" do
        should "return API key" do
          @role.access_policy.statements.first.conditions << {
            operator: "string_equals",
            claim: "sub",
            value: "repo:segiddins/oidc-test:ref:refs/heads/main"
          }
          @role.save!

          post assume_role_api_v1_oidc_api_key_role_path(@role),
              params: {
                jwt: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImVCWl9jbjNzWFlBZDBjaDRUSEJLSElnT3dPRSIsImtpZCI6Ijc4MTY3RjcyN0RFQzVEODAxREQxQzg3ODRDNzA0QTFDODgwRUMwRTEifQ.eyJqdGkiOiI3OTY4NWI2NS05NDVkLTQ1MGEtYTNkOC1hMzZiY2Y3MmMyM2QiLCJzdWIiOiJyZXBvOnNlZ2lkZGlucy9vaWRjLXRlc3Q6cmVmOnJlZnMvaGVhZHMvbWFpbiIsImF1ZCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9zZWdpZGRpbnMiLCJyZWYiOiJyZWZzL2hlYWRzL21haW4iLCJzaGEiOiIwNGRlMzU1OGJjNTg2MTg3NGE4NmY4ZmNkNjdlNTE2NTU0MTAxZTcxIiwicmVwb3NpdG9yeSI6InNlZ2lkZGlucy9vaWRjLXRlc3QiLCJyZXBvc2l0b3J5X293bmVyIjoic2VnaWRkaW5zIiwicmVwb3NpdG9yeV9vd25lcl9pZCI6IjE5NDY2MTAiLCJydW5faWQiOiI0NTQ1MjMxMDg0IiwicnVuX251bWJlciI6IjQiLCJydW5fYXR0ZW1wdCI6IjEiLCJyZXBvc2l0b3J5X3Zpc2liaWxpdHkiOiJwdWJsaWMiLCJyZXBvc2l0b3J5X2lkIjoiNjIwMzkzODM4IiwiYWN0b3JfaWQiOiIxOTQ2NjEwIiwiYWN0b3IiOiJzZWdpZGRpbnMiLCJ3b3JrZmxvdyI6Ii5naXRodWIvd29ya2Zsb3dzL3Rva2VuLnltbCIsImhlYWRfcmVmIjoiIiwiYmFzZV9yZWYiOiIiLCJldmVudF9uYW1lIjoicHVzaCIsInJlZl90eXBlIjoiYnJhbmNoIiwid29ya2Zsb3dfcmVmIjoic2VnaWRkaW5zL29pZGMtdGVzdC8uZ2l0aHViL3dvcmtmbG93cy90b2tlbi55bWxAcmVmcy9oZWFkcy9tYWluIiwid29ya2Zsb3dfc2hhIjoiMDRkZTM1NThiYzU4NjE4NzRhODZmOGZjZDY3ZTUxNjU1NDEwMWU3MSIsImpvYl93b3JrZmxvd19yZWYiOiJzZWdpZGRpbnMvb2lkYy10ZXN0Ly5naXRodWIvd29ya2Zsb3dzL3Rva2VuLnltbEByZWZzL2hlYWRzL21haW4iLCJqb2Jfd29ya2Zsb3dfc2hhIjoiMDRkZTM1NThiYzU4NjE4NzRhODZmOGZjZDY3ZTUxNjU1NDEwMWU3MSIsInJ1bm5lcl9lbnZpcm9ubWVudCI6ImdpdGh1Yi1ob3N0ZWQiLCJpc3MiOiJodHRwczovL3Rva2VuLmFjdGlvbnMuZ2l0aHVidXNlcmNvbnRlbnQuY29tIiwibmJmIjoxNjgwMDE5OTM3LCJleHAiOjE2ODAwMjA4MzcsImlhdCI6MTY4MDAyMDUzN30.yVYbck_X2O8ehc7iOGLR1cNzRal85Oc25OxiCIohIjvY04S3neMasb5GAKMyKSM4gDA9g8w5hRAOyngc5O-EDapI4Ug6CHdXUQ2H73xzsNO-s73pHqs5jStzDWm24SdM8JFSG4ycCtoShimyRbc5nphbVdB74we_z2eLn5LwLE1fTxQ2e5pu2ReouRgnyKHlwrGcsMUN2S_JMCPGKhV8wQ6xbnHq1FEAgS3SS1JTOT_fOgmcJIxZ_NL-437TiU77g770kFFwmK7Ac_-E9AuDojAnTqAkLZq_-m-zULmtVHswNbaVqZmmbp9xm1XcWJFB50_Mg58Hxkx3CB4N9kvFbg"
              },
              headers: {}

          assert_response :created

          resp = response.parsed_body

          assert_match(/^rubygems_/, resp["rubygems_api_key"])
          assert_equal({
                         "rubygems_api_key" => resp["rubygems_api_key"],
              "name" => "GitHub Pusher-79685b65-945d-450a-a3d8-a36bcf72c23d",
              "scopes" => ["push_rubygem"],
              "gem" => nil
                       }, resp)
          hashed_key = @user.api_keys.sole.hashed_key

          assert_equal hashed_key, Digest::SHA256.hexdigest(resp["rubygems_api_key"])
        end
      end

      context "with mismatched conditions" do
        should "return not found" do
          @role.access_policy.statements.first.conditions << {
            operator: "string_equals",
            claim: "sub",
            value: "repo:other/oidc-test:ref:refs/heads/main"
          }
          @role.save!

          post assume_role_api_v1_oidc_api_key_role_path(@role),
              params: {
                jwt: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImVCWl9jbjNzWFlBZDBjaDRUSEJLSElnT3dPRSIsImtpZCI6Ijc4MTY3RjcyN0RFQzVEODAxREQxQzg3ODRDNzA0QTFDODgwRUMwRTEifQ.eyJqdGkiOiI3OTY4NWI2NS05NDVkLTQ1MGEtYTNkOC1hMzZiY2Y3MmMyM2QiLCJzdWIiOiJyZXBvOnNlZ2lkZGlucy9vaWRjLXRlc3Q6cmVmOnJlZnMvaGVhZHMvbWFpbiIsImF1ZCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9zZWdpZGRpbnMiLCJyZWYiOiJyZWZzL2hlYWRzL21haW4iLCJzaGEiOiIwNGRlMzU1OGJjNTg2MTg3NGE4NmY4ZmNkNjdlNTE2NTU0MTAxZTcxIiwicmVwb3NpdG9yeSI6InNlZ2lkZGlucy9vaWRjLXRlc3QiLCJyZXBvc2l0b3J5X293bmVyIjoic2VnaWRkaW5zIiwicmVwb3NpdG9yeV9vd25lcl9pZCI6IjE5NDY2MTAiLCJydW5faWQiOiI0NTQ1MjMxMDg0IiwicnVuX251bWJlciI6IjQiLCJydW5fYXR0ZW1wdCI6IjEiLCJyZXBvc2l0b3J5X3Zpc2liaWxpdHkiOiJwdWJsaWMiLCJyZXBvc2l0b3J5X2lkIjoiNjIwMzkzODM4IiwiYWN0b3JfaWQiOiIxOTQ2NjEwIiwiYWN0b3IiOiJzZWdpZGRpbnMiLCJ3b3JrZmxvdyI6Ii5naXRodWIvd29ya2Zsb3dzL3Rva2VuLnltbCIsImhlYWRfcmVmIjoiIiwiYmFzZV9yZWYiOiIiLCJldmVudF9uYW1lIjoicHVzaCIsInJlZl90eXBlIjoiYnJhbmNoIiwid29ya2Zsb3dfcmVmIjoic2VnaWRkaW5zL29pZGMtdGVzdC8uZ2l0aHViL3dvcmtmbG93cy90b2tlbi55bWxAcmVmcy9oZWFkcy9tYWluIiwid29ya2Zsb3dfc2hhIjoiMDRkZTM1NThiYzU4NjE4NzRhODZmOGZjZDY3ZTUxNjU1NDEwMWU3MSIsImpvYl93b3JrZmxvd19yZWYiOiJzZWdpZGRpbnMvb2lkYy10ZXN0Ly5naXRodWIvd29ya2Zsb3dzL3Rva2VuLnltbEByZWZzL2hlYWRzL21haW4iLCJqb2Jfd29ya2Zsb3dfc2hhIjoiMDRkZTM1NThiYzU4NjE4NzRhODZmOGZjZDY3ZTUxNjU1NDEwMWU3MSIsInJ1bm5lcl9lbnZpcm9ubWVudCI6ImdpdGh1Yi1ob3N0ZWQiLCJpc3MiOiJodHRwczovL3Rva2VuLmFjdGlvbnMuZ2l0aHVidXNlcmNvbnRlbnQuY29tIiwibmJmIjoxNjgwMDE5OTM3LCJleHAiOjE2ODAwMjA4MzcsImlhdCI6MTY4MDAyMDUzN30.yVYbck_X2O8ehc7iOGLR1cNzRal85Oc25OxiCIohIjvY04S3neMasb5GAKMyKSM4gDA9g8w5hRAOyngc5O-EDapI4Ug6CHdXUQ2H73xzsNO-s73pHqs5jStzDWm24SdM8JFSG4ycCtoShimyRbc5nphbVdB74we_z2eLn5LwLE1fTxQ2e5pu2ReouRgnyKHlwrGcsMUN2S_JMCPGKhV8wQ6xbnHq1FEAgS3SS1JTOT_fOgmcJIxZ_NL-437TiU77g770kFFwmK7Ac_-E9AuDojAnTqAkLZq_-m-zULmtVHswNbaVqZmmbp9xm1XcWJFB50_Mg58Hxkx3CB4N9kvFbg"
              },
              headers: {}

          assert_response :not_found
          assert_empty @user.api_keys
        end
      end

      should "return an API token" do
        post assume_role_api_v1_oidc_api_key_role_path(@role),
            params: {
              jwt: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImVCWl9jbjNzWFlBZDBjaDRUSEJLSElnT3dPRSIsImtpZCI6Ijc4MTY3RjcyN0RFQzVEODAxREQxQzg3ODRDNzA0QTFDODgwRUMwRTEifQ.eyJqdGkiOiI3OTY4NWI2NS05NDVkLTQ1MGEtYTNkOC1hMzZiY2Y3MmMyM2QiLCJzdWIiOiJyZXBvOnNlZ2lkZGlucy9vaWRjLXRlc3Q6cmVmOnJlZnMvaGVhZHMvbWFpbiIsImF1ZCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9zZWdpZGRpbnMiLCJyZWYiOiJyZWZzL2hlYWRzL21haW4iLCJzaGEiOiIwNGRlMzU1OGJjNTg2MTg3NGE4NmY4ZmNkNjdlNTE2NTU0MTAxZTcxIiwicmVwb3NpdG9yeSI6InNlZ2lkZGlucy9vaWRjLXRlc3QiLCJyZXBvc2l0b3J5X293bmVyIjoic2VnaWRkaW5zIiwicmVwb3NpdG9yeV9vd25lcl9pZCI6IjE5NDY2MTAiLCJydW5faWQiOiI0NTQ1MjMxMDg0IiwicnVuX251bWJlciI6IjQiLCJydW5fYXR0ZW1wdCI6IjEiLCJyZXBvc2l0b3J5X3Zpc2liaWxpdHkiOiJwdWJsaWMiLCJyZXBvc2l0b3J5X2lkIjoiNjIwMzkzODM4IiwiYWN0b3JfaWQiOiIxOTQ2NjEwIiwiYWN0b3IiOiJzZWdpZGRpbnMiLCJ3b3JrZmxvdyI6Ii5naXRodWIvd29ya2Zsb3dzL3Rva2VuLnltbCIsImhlYWRfcmVmIjoiIiwiYmFzZV9yZWYiOiIiLCJldmVudF9uYW1lIjoicHVzaCIsInJlZl90eXBlIjoiYnJhbmNoIiwid29ya2Zsb3dfcmVmIjoic2VnaWRkaW5zL29pZGMtdGVzdC8uZ2l0aHViL3dvcmtmbG93cy90b2tlbi55bWxAcmVmcy9oZWFkcy9tYWluIiwid29ya2Zsb3dfc2hhIjoiMDRkZTM1NThiYzU4NjE4NzRhODZmOGZjZDY3ZTUxNjU1NDEwMWU3MSIsImpvYl93b3JrZmxvd19yZWYiOiJzZWdpZGRpbnMvb2lkYy10ZXN0Ly5naXRodWIvd29ya2Zsb3dzL3Rva2VuLnltbEByZWZzL2hlYWRzL21haW4iLCJqb2Jfd29ya2Zsb3dfc2hhIjoiMDRkZTM1NThiYzU4NjE4NzRhODZmOGZjZDY3ZTUxNjU1NDEwMWU3MSIsInJ1bm5lcl9lbnZpcm9ubWVudCI6ImdpdGh1Yi1ob3N0ZWQiLCJpc3MiOiJodHRwczovL3Rva2VuLmFjdGlvbnMuZ2l0aHVidXNlcmNvbnRlbnQuY29tIiwibmJmIjoxNjgwMDE5OTM3LCJleHAiOjE2ODAwMjA4MzcsImlhdCI6MTY4MDAyMDUzN30.yVYbck_X2O8ehc7iOGLR1cNzRal85Oc25OxiCIohIjvY04S3neMasb5GAKMyKSM4gDA9g8w5hRAOyngc5O-EDapI4Ug6CHdXUQ2H73xzsNO-s73pHqs5jStzDWm24SdM8JFSG4ycCtoShimyRbc5nphbVdB74we_z2eLn5LwLE1fTxQ2e5pu2ReouRgnyKHlwrGcsMUN2S_JMCPGKhV8wQ6xbnHq1FEAgS3SS1JTOT_fOgmcJIxZ_NL-437TiU77g770kFFwmK7Ac_-E9AuDojAnTqAkLZq_-m-zULmtVHswNbaVqZmmbp9xm1XcWJFB50_Mg58Hxkx3CB4N9kvFbg"
            },
            headers: {}

        assert_response :created

        resp = response.parsed_body

        assert_match(/^rubygems_/, resp["rubygems_api_key"])
        assert_equal({
                       "rubygems_api_key" => resp["rubygems_api_key"],
            "name" => "GitHub Pusher-79685b65-945d-450a-a3d8-a36bcf72c23d",
            "scopes" => ["push_rubygem"],
            "gem" => nil
                     }, resp)
        hashed_key = @user.api_keys.sole.hashed_key

        assert_equal hashed_key, Digest::SHA256.hexdigest(resp["rubygems_api_key"])
      end
    end
  end

  private

  def sign_body(body)
    private_key = OpenSSL::PKey::EC.new(@private_key_pem)
    private_key.sign(OpenSSL::Digest.new("SHA256"), body)
  end
end

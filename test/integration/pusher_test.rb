require "test_helper"

class PusherIntegrationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include GemspecYamlTemplateHelpers

  setup do
    @user = create(:user, email: "user@example.com")
    @api_key = create(:api_key, owner: @user)
    @gem = gem_file
    @cutter = Pusher.new(@api_key, @gem)

    # Ensure we test #log_pushing
    @cutter.logger.level = :info
  end

  teardown do
    @gem&.close
  end

  context "creating a new gemcutter" do
    should "not be able to pull spec with metadata containing bad ruby objects" do
      yaml = "#{gemspec_yaml_template}exploit: !ruby/hash:ActionController::Routing::RouteSet::NamedRouteCollection {}\n"
      @gem = build_gem(yaml)
      @cutter = Pusher.new(@api_key, @gem)
      out, err = capture_io do
        @cutter.pull_spec
      end

      assert_empty out
      assert_empty err
      assert_nil @cutter.spec
      assert_match(/RubyGems\.org cannot process this gem/, @cutter.message)
      assert_equal 422, @cutter.code
    end

    should "not be able to save a gem if it is not valid" do
      legit_gem = create(:rubygem, name: "legit-gem")
      create(:version, rubygem: legit_gem, number: "0.0.1")
      @gem = build_gem(gemspec_yaml_template(name: "legit-gem", version: "not-a-version"))
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.process

      assert_match(/RubyGems.org cannot process this gem/, @cutter.message)
      assert_equal 422, @cutter.code
    end

    should "not be able to save a gem if the date is not valid" do
      gem = build_gem(gemspec_yaml_template(date: "not-a-date"))

      @cutter = Pusher.new(@api_key, gem)
      out, err = capture_io do
        @cutter.process
      end

      assert_empty out
      assert_empty err
      assert_match(/path: root -> date/, @cutter.message)

      assert_equal 422, @cutter.code
    end

    should "not be able to save a gem if the required_ruby_version is not valid" do
      yaml = gemspec_yaml_template.sub(
        "      version: '0'\nrequired_rubygems_version",
        "      version: test\nrequired_rubygems_version"
      )
      @gem = build_gem(yaml)
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.process

      assert_match(/path: root -> required_ruby_version -> requirements -> 0 -> 1 -> version/, @cutter.message)
      assert_equal 422, @cutter.code
    end

    should "not be able to save a gem if the required_rubygems_version is not valid" do
      yaml = gemspec_yaml_template.sub(
        "      version: '0'\nrequirements:",
        "      version: test\nrequirements:"
      )
      @gem = build_gem(yaml)
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.process

      assert_match(/path: root -> required_rubygems_version -> requirements -> 0 -> 1 -> version/, @cutter.message)
      assert_equal 422, @cutter.code
    end

    should "not be able to save a gem if the dependency requirement is not valid" do
      dep = <<~DEP.chomp
        - !ruby/object:Gem::Dependency
          name: foo
          requirement: !ruby/object:Gem::Requirement
            requirements:
            - - "!!!"
              - !ruby/object:Gem::Version
                version: '0'
          type: :runtime
          prerelease: false
          version_requirements: !ruby/object:Gem::Requirement
            requirements:
            - - "!!!"
              - !ruby/object:Gem::Version
                version: '0'
      DEP
      @gem = build_gem(gemspec_yaml_template(dependencies: [dep]))
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.process

      assert_match(/requirements must be list of valid requirements/, @cutter.message)
      assert_equal 403, @cutter.code
    end

    should "not be able to save a gem if the dependency name is not valid" do
      dep = <<~DEP.chomp
        - !ruby/object:Gem::Dependency
          name: "\\nother"
          requirement: !ruby/object:Gem::Requirement
            requirements:
            - - ">="
              - !ruby/object:Gem::Version
                version: '0'
          type: :runtime
          prerelease: false
          version_requirements: !ruby/object:Gem::Requirement
            requirements:
            - - ">="
              - !ruby/object:Gem::Version
                version: '0'
      DEP
      @gem = build_gem(gemspec_yaml_template(dependencies: [dep]))
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.process

      assert_match(/Dependency unresolved name can only include letters, numbers, dashes, and underscores/, @cutter.message)
      assert_equal 403, @cutter.code
    end

    should "not be able to save a gem if the metadata has incorrect values" do
      yaml = gemspec_yaml_template.sub("metadata: {}", "metadata:\n  foo: []")
      @gem = build_gem(yaml)
      @cutter = Pusher.new(@api_key, @gem)

      refute @cutter.process

      assert_match(/path: root -> metadata -> foo/, @cutter.message)
      assert_equal 422, @cutter.code
    end

    should "not be able to save a gem if it is signed and has been tampered with" do
      signing_key = OpenSSL::PKey::RSA.new(2048)
      @gem = build_gem(gemspec_yaml_template, key: signing_key)
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.process

      assert_includes @cutter.message, %(missing signing certificate)
      assert_equal 422, @cutter.code
    end

    should "not be able to save a gem if it is signed with an expired signing certificate" do
      signing_key = OpenSSL::PKey::RSA.new(2048)
      expired_cert = OpenSSL::X509::Certificate.new
      expired_cert.subject = expired_cert.issuer = OpenSSL::X509::Name.parse("/CN=expired/DC=example/DC=com")
      expired_cert.not_before = 2.years.ago
      expired_cert.not_after = 1.year.ago
      expired_cert.public_key = signing_key.public_key
      expired_cert.serial = 0x0
      expired_cert.version = 2
      expired_cert.sign(signing_key, OpenSSL::Digest.new("SHA256"))

      pem = expired_cert.to_pem.lines.map { |l| "    #{l}" }.join
      yaml = gemspec_yaml_template.sub("cert_chain: []", "cert_chain:\n  - |\n#{pem}")
      @gem = build_gem(yaml, key: signing_key)
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.process

      assert_includes @cutter.message, %(/CN=expired/DC=example/DC=com not valid after)
      assert_equal 422, @cutter.code
    end

    context "for a signed gem having two certificates in the chain" do
      setup do
        Dir.chdir(Dir.mktmpdir)
      end

      should "be able to save the gem if the chain is valid" do
        signing_key = OpenSSL::PKey::RSA.new(1024)
        spec = new_gemspec("valid_cert_chain", "0.0.0", "Summary", "ruby") do |s|
          s.signing_key = signing_key
          s.cert_chain = two_cert_chain(signing_key: signing_key)
        end
        gem_path = build_gemspec(spec)

        @cutter = Pusher.new(@api_key, File.open(gem_path))
        @cutter.process

        assert_equal 200, @cutter.code
      end

      should "not be able to save the gem if the root certificate has expired" do
        begin
          old_verify_root_policy = Gem::Security::SigningPolicy.verify_root
          Gem::Security::SigningPolicy.verify_root = false
          signing_key = OpenSSL::PKey::RSA.new(1024)

          spec = new_gemspec("expired_root_cert", "0.0.0", "Summary", "ruby") do |s|
            s.signing_key = signing_key
            s.cert_chain = two_cert_chain(signing_key: signing_key, root_not_before: 2.years.ago)
          end
          gem_path = build_gemspec(spec)
        ensure
          Gem::Security::SigningPolicy.verify_root = old_verify_root_policy
        end

        @cutter = Pusher.new(@api_key, File.open(gem_path))
        @cutter.process

        assert_includes @cutter.message, %(CN=Root not valid after)
        assert_equal(422, @cutter.code)
      end

      teardown do
        Dir.chdir(Rails.root)
      end
    end

    should "not be able to pull spec with metadata containing bad ruby symbols" do
      symbol_payloads = [
        "exploit: :badsymbol",
        'exploit: :"badsymbol"',
        "exploit: !ruby/sym badsymbol",
        "exploit: !ruby/symbol badsymbol"
      ]

      symbol_payloads.each do |payload|
        @gem = build_gem("#{gemspec_yaml_template}#{payload}\n")
        @cutter = Pusher.new(@api_key, @gem)
        out, err = capture_io do
          @cutter.pull_spec
        end

        assert_empty out
        assert_empty err
        assert_nil @cutter.spec
        assert_includes @cutter.message, %(RubyGems.org cannot process this gem)
        assert_equal 422, @cutter.code
      end
    end

    should "not be able to pull spec with metadata containing aliases" do
      @gem = build_gem(gemspec_yaml_template(use_yaml_alias: true))
      @cutter = Pusher.new(@api_key, @gem)

      refute @cutter.pull_spec
      assert_nil @cutter.spec
      assert_equal <<~MSG, @cutter.message
        RubyGems.org cannot process this gem.
        Pushing gems where there are aliases in the YAML gemspec is no longer supported.
        Ensure you are using a recent version of RubyGems to build the gem by running
        `gem update --system` and then try pushing again.
      MSG
      assert_equal 422, @cutter.code
    end

    should "not be able to pull spec when no data available" do
      yaml = gemspec_yaml_template(use_yaml_alias: true)
      tar = StringIO.new("".b)
      Gem::Package::TarWriter.new(tar) do |gem_tar|
        gem_tar.add_file "metadata.gz", 0o444 do |io|
          gz_io = Zlib::GzipWriter.new io, Zlib::BEST_COMPRESSION
          gz_io.write yaml
          gz_io.close
        end
      end
      @gem = StringIO.new(tar.string)
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.pull_spec

      assert_includes @cutter.message, "Pushing gems where there are aliases in the YAML gemspec is no longer supported"
    end
  end

  def two_cert_chain(signing_key:, root_not_before: Time.current, cert_not_before: Time.current)
    root_key = OpenSSL::PKey::RSA.new(1024)
    root_subject = "/C=FI/O=Test/OU=Test/CN=Root"

    root_cert = OpenSSL::X509::Certificate.new
    root_cert.subject = root_cert.issuer = OpenSSL::X509::Name.parse(root_subject)
    root_cert.not_before = root_not_before
    root_cert.not_after = root_not_before + 1.year
    root_cert.public_key = root_key.public_key
    root_cert.serial = 0x0
    root_cert.version = 2
    root_cert.sign(root_key, OpenSSL::Digest.new("SHA256"))

    subject = "/C=FI/O=Test/OU=Test/CN=Test"

    cert = OpenSSL::X509::Certificate.new
    cert.issuer = OpenSSL::X509::Name.parse(root_subject)
    cert.subject = OpenSSL::X509::Name.parse(subject)
    cert.not_before = cert_not_before
    cert.not_after = cert_not_before + 1.year
    cert.public_key = signing_key.public_key
    cert.serial = 0x0
    cert.version = 2
    cert.sign(root_key, OpenSSL::Digest.new("SHA256"))

    [root_cert, cert]
  end

  context "successfully saving a gemcutter" do
    setup do
      @rubygem = create(:rubygem, name: "gemsgemsgems")
      @cutter.stubs(:rubygem).returns @rubygem
      create(:version, rubygem: @rubygem, number: "0.1.1", summary: "old summary", pusher_api_key: @cutter.api_key)
      @spec = mock
      @cutter.stubs(:version).returns @rubygem.versions[0]
      @cutter.stubs(:spec).returns(@spec)
      @rubygem.stubs(:update_attributes_from_gem_specification!)
      @cutter.stubs(:write_gem)
    end

    context "when cutter is saved" do
      setup do
        assert @cutter.save
      end

      should "set gem file size" do
        assert_equal @gem.size, @cutter.size
      end

      should "set success code" do
        assert_equal 200, @cutter.code
      end

      should "set info_checksum" do
        assert_not_nil @rubygem.versions.last.info_checksum
      end

      should "indexe rubygem and version" do
        assert_predicate @rubygem, :indexed?
        assert_predicate @rubygem.versions.last, :indexed?
      end

      should "create rubygem index" do
        @rubygem.update_column("updated_at", Date.new(2016, 0o7, 0o4))
        perform_enqueued_jobs only: ReindexRubygemJob
        response = Searchkick.client.get index: Rubygem.searchkick_index.name, id: @rubygem.id
        expected_response = {
          "name"              => "gemsgemsgems",
          "downloads"         => 0,
          "version"           => "0.1.1",
          "version_downloads" => 0,
          "platform"          => "ruby",
          "authors"           => "Joe User",
          "info"              => "Some awesome gem",
          "licenses"          => "MIT",
          "metadata"          => { "foo" => "bar" },
          "sha"               => "b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78",
          "project_uri"       => "http://localhost/gems/gemsgemsgems",
          "gem_uri"           => "http://localhost/gems/gemsgemsgems-0.1.1.gem",
          "homepage_uri"      => "http://example.com",
          "wiki_uri"          => "http://example.com",
          "documentation_uri" => "http://example.com",
          "mailing_list_uri"  => "http://example.com",
          "source_code_uri"   => "http://example.com",
          "bug_tracker_uri"   => "http://example.com",
          "changelog_uri"     => nil,
          "funding_uri"       => nil,
          "yanked"            => false,
          "summary"           => "old summary",
          "description"       => "Some awesome gem",
          "updated"           => "2016-07-04T00:00:00.000Z",
          "dependencies"      => { "development" => [], "runtime" => [] },
          "suggest"           => { "input" => "gemsgemsgems", "weight" => 0, "contexts" => { "yanked" => false } }
        }

        assert_equal expected_response, response["_source"]
      end

      should "record the push event" do
        assert_event Events::RubygemEvent::VERSION_PUSHED, {
          number: "0.1.1",
          platform: "ruby",
          sha256: @rubygem.versions.last.sha256_hex,
          version_gid: @rubygem.versions.last.to_gid.to_s
        }, @rubygem.events.where(tag: Events::RubygemEvent::VERSION_PUSHED).sole
      end
    end

    should "purge gem cache" do
      GemCachePurger.expects(:call).with(@rubygem.name).at_least_once
      @cutter.save
    end

    context "with rstuf enabled" do
      setup do
        setup_rstuf
      end

      should "enqueue rstuf addition" do
        assert_enqueued_with(job: Rstuf::AddJob, args: [version: @cutter.version]) do
          @cutter.save
        end
      end

      teardown do
        teardown_rstuf
      end
    end

    should "update rubygem attributes when saved" do
      @rubygem.expects(:update_attributes_from_gem_specification!).with(@cutter.version, @spec)
      @cutter.save
    end

    should "enqueue job for email, updating ES index, spec index and purging cdn" do
      assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
        assert_enqueued_jobs 6, only: FastlyPurgeJob do
          assert_enqueued_jobs 1, only: Indexer do
            assert_enqueued_jobs 1, only: ReindexRubygemJob do
              @cutter.save
            end
          end
        end
      end
    end
  end

  context "pushing a new version" do
    setup do
      @rubygem = create(:rubygem)
      @cutter.stubs(:rubygem).returns @rubygem
      create(:version, rubygem: @rubygem, summary: "old summary")
      @version = create(:version, rubygem: @rubygem, summary: "new summary", pusher_api_key: @cutter.api_key)
      @cutter.stubs(:version).returns @version
      @rubygem.stubs(:update_attributes_from_gem_specification!)
      @cutter.stubs(:version).returns @version
      GemCachePurger.stubs(:call)
      @cutter.stubs(:write_gem)
      @cutter.save
    end

    should "update rubygem index" do
      perform_enqueued_jobs only: ReindexRubygemJob
      response = Searchkick.client.get index: Rubygem.searchkick_index.name, id: @rubygem.id

      assert_equal "new summary", response["_source"]["summary"]
    end

    should "send gem pushed email" do
      perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

      email = ActionMailer::Base.deliveries.last

      assert_equal "Gem #{@version.to_title} pushed to RubyGems.org", email.subject
      assert_equal [@user.email], email.to

      assert_event Events::UserEvent::EMAIL_SENT, {
        to: @user.email, from: "no-reply@mailer.rubygems.org", subject: email.subject,
        message_id: email.message_id, mailer: "mailer", action: "gem_pushed"
      }, @user.events.where(tag: Events::UserEvent::EMAIL_SENT).sole
    end
  end

  context "pushing to s3 fails" do
    setup do
      @gem = build_gem(gemspec_yaml_template)
      @cutter = Pusher.new(@api_key, @gem)
      @fs = RubygemFs.s3!("https://some.host")
      s3_exception = Aws::S3::Errors::ServiceError.new("stub raises", "something went wrong")
      Aws::S3::Client.any_instance.stubs(:put_object).with(any_parameters).raises(s3_exception)
      @cutter.process
    end

    should "not create version" do
      rubygem = Rubygem.find_by(name: "test")
      expected_message = "There was a problem saving your gem. Please try again."

      assert_equal expected_message, @cutter.message
      assert_equal 0, rubygem.versions.count
    end

    teardown do
      RubygemFs.mock!
    end
  end

  context "saving fails with ArgumentError" do
    setup do
      @gem = build_gem(gemspec_yaml_template)
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.stubs(:update).raises(ArgumentError.new("some message"))
      @cutter.process
    end

    should "not create rubygem or version" do
      rubygem = Rubygem.find_by(name: "test")
      expected_message = "There was a problem saving your gem. some message"

      assert_equal expected_message, @cutter.message
      assert_nil rubygem
    end
  end

  context "with attestations and trusted publisher" do
    setup do
      attestations = build_list(:sigstore_bundle, 2)
      @rubygem = create(:rubygem, name: "test", owners: [@user])
      create(:version, rubygem: @rubygem, number: "0.1.1", indexed: true)
      rubygem_trusted_publisher = create(:oidc_rubygem_trusted_publisher, rubygem: @rubygem)
      rubygem_trusted_publisher.trusted_publisher.update!(
        repository_owner: "sigstore-conformance",
        repository_name: "extremely-dangerous-public-oidc-beacon",
        workflow_filename: "extremely-dangerous-oidc-beacon.yml"
      )

      @api_key = create(:api_key, owner: rubygem_trusted_publisher.trusted_publisher, key: "54321", scopes: %i[push_rubygem])
      create(:oidc_id_token, api_key: @api_key, jwt: { claims: { "ref" => "refs/heads/main" } })
      @cutter = Pusher.new(@api_key, build_gem(gemspec_yaml_template), attestations: attestations.map(&:as_json))
    end

    should "add valid attestations to version" do
      @cutter.send(:sigstore_verifier).expects(:verify).twice
        .returns Sigstore::VerificationSuccess.new

      assert @cutter.process, @cutter.message # rubocop:disable Minitest/AssertWithExpectedArgument
      assert_equal 2, @cutter.version.attestations.size
    end

    should "report metrics around successful attestation verification" do
      StatsD.stubs(:increment)
      StatsD.expects(:increment).with("attestation.verified", tags: { rubygem: @rubygem.name }).once

      @cutter.send(:sigstore_verifier).expects(:verify).twice
        .returns Sigstore::VerificationSuccess.new
      @cutter.process
    end

    should "fail when first attestation fails to validate" do
      @cutter.send(:sigstore_verifier).expects(:verify).once
        .returns Sigstore::VerificationFailure.new("abc")

      refute @cutter.process
      assert_equal "Attestation verification failed:\nabc", @cutter.message
      assert_equal 422, @cutter.code
    end

    should "fail when second attestation fails to validate" do
      @cutter.send(:sigstore_verifier).expects(:verify).once
        .returns Sigstore::VerificationFailure.new("abc")
      @cutter.send(:sigstore_verifier).expects(:verify).once
        .returns Sigstore::VerificationSuccess.new

      refute @cutter.process
      assert_equal "Attestation verification failed:\nabc", @cutter.message
      assert_equal 422, @cutter.code
    end
  end

  context "the gem has been signed and not tampered with" do
    setup do
      Dir.chdir(Dir.mktmpdir)
      signing_key = OpenSSL::PKey::RSA.new(2048)

      cert = OpenSSL::X509::Certificate.new
      cert.subject = cert.issuer = OpenSSL::X509::Name.parse("/CN=snakeoil/DC=example/DC=invalid")
      cert.not_before = Time.current
      cert.not_after = 1.year.from_now
      cert.public_key = signing_key.public_key
      cert.serial = 0x0
      cert.version = 2
      cert.sign(signing_key, OpenSSL::Digest.new("SHA256"))

      spec = new_gemspec("valid_signature", "0.0.0", "Summary", "ruby") do |s|
        s.signing_key = signing_key
        s.cert_chain = [cert]
      end
      gem_path = build_gemspec(spec)

      @gem = File.open(gem_path)
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.process
    end

    should "extracts the certificate chain to the version" do
      assert_equal 200, @cutter.code
      assert_not_nil @cutter.version
      assert_not_nil @cutter.version.cert_chain
      assert_equal 1, @cutter.version.cert_chain.size
      assert_equal "DC=invalid,DC=example,CN=snakeoil", @cutter.version.cert_chain.first.subject.to_utf8
    end

    teardown do
      Dir.chdir(Rails.root)
      RubygemFs.mock!
    end
  end
end

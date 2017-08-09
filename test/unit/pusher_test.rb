# rubocop:disable Metrics/BlockLength
require 'test_helper'

class PusherTest < ActiveSupport::TestCase
  context "creating a new gemcutter" do
    setup do
      @user = create(:user, email: "user@example.com")
      @gem = gem_file
      @cutter = Pusher.new(@user, @gem)
    end

    should "have some state" do
      assert @cutter.respond_to?(:user)
      assert @cutter.respond_to?(:version)
      assert @cutter.respond_to?(:version_id)
      assert @cutter.respond_to?(:spec)
      assert @cutter.respond_to?(:message)
      assert @cutter.respond_to?(:code)
      assert @cutter.respond_to?(:rubygem)
      assert @cutter.respond_to?(:body)

      assert_equal @user, @cutter.user
    end

    should "initialize size from the gem" do
      assert_equal @gem.size, @cutter.size
    end

    context "processing incoming gems" do
      should "work normally when things go well" do
        @cutter.stubs(:lock_key).returns 'lock_key'
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find).returns true
        @cutter.stubs(:authorize).returns true
        @cutter.stubs(:validate).returns true
        @cutter.stubs(:save)

        @cutter.process
      end

      should "not attempt to find rubygem if spec can't be pulled" do
        @cutter.stubs(:pull_spec).returns false
        @cutter.stubs(:find).never
        @cutter.stubs(:authorize).never
        @cutter.stubs(:save).never
        @cutter.process
      end

      should "not attempt to authorize if not found" do
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find)
        @cutter.stubs(:authorize).never
        @cutter.stubs(:save).never

        @cutter.process
      end

      should "not attempt to validate if not authorized" do
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find).returns true
        @cutter.stubs(:authorize).returns false
        @cutter.stubs(:validate).never
        @cutter.stubs(:save).never

        @cutter.process
      end

      should "not attempt to save if not validated" do
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find).returns true
        @cutter.stubs(:authorize).returns true
        @cutter.stubs(:validate).returns false
        @cutter.stubs(:save).never

        @cutter.process
      end
    end

    should "not be able to pull spec from a bad path" do
      @cutter.stubs(:body).stubs(:stub!).stubs(:read)
      @cutter.pull_spec
      assert_nil @cutter.spec
      assert_match(/RubyGems\.org cannot process this gem/, @cutter.message)
      assert_equal @cutter.code, 422
    end

    should "not be able to pull spec with metadata containing bad ruby objects" do
      @gem = gem_file("exploit.gem")
      @cutter = Pusher.new(@user, @gem)
      @cutter.pull_spec
      assert_nil @cutter.spec
      assert_match(/RubyGems\.org cannot process this gem/, @cutter.message)
      assert_match(/ActionController::Routing::RouteSet::NamedRouteCollection/, @cutter.message)
      assert_equal @cutter.code, 422
    end

    should "not be able to save a gem if it is not valid" do
      legit_gem = create(:rubygem, name: 'legit-gem')
      create(:version, rubygem: legit_gem, number: '0.0.1')
      @gem = gem_file("legit-gem-0.0.1.gem.fake")
      @cutter = Pusher.new(@user, @gem)
      @cutter.stubs(:save).never
      @cutter.process
      assert_equal @cutter.rubygem.name, 'legit'
      assert_equal @cutter.version.number, 'gem-0.0.1'
      assert_match(/There was a problem saving your gem: Number is invalid/, @cutter.message)
      assert_equal @cutter.code, 403
    end

    should "not be able to pull spec with metadata containing bad ruby symbols" do
      ["1.0.0", "2.0.0", "3.0.0", "4.0.0"].each do |version|
        @gem = gem_file("dos-#{version}.gem")
        @cutter = Pusher.new(@user, @gem)
        @cutter.pull_spec
        assert_nil @cutter.spec
        assert_includes @cutter.message, %(RubyGems.org cannot process this gem)
        assert_includes @cutter.message, %(Tried to load unspecified class: Symbol)
        assert_equal @cutter.code, 422
      end
    end

    should "be able to pull spec with metadata containing aliases" do
      @gem = gem_file("aliases-0.0.0.gem")
      @cutter = Pusher.new(@user, @gem)
      @cutter.pull_spec
      assert_not_nil @cutter.spec
      assert_not_nil @cutter.spec.dependencies.first.requirement
    end

    should "not be able to pull spec when no data available" do
      @gem = gem_file("aliases-nodata-0.0.1.gem")
      @cutter = Pusher.new(@user, @gem)
      @cutter.pull_spec
      assert_includes @cutter.message, %{package content (data.tar.gz) is missing}
    end

    context "initialize new gem with find if one does not exist" do
      setup do
        spec = mock
        spec.expects(:name).returns "some name"
        spec.expects(:version).returns "1.3.3.7"
        spec.expects(:original_platform).returns "ruby"
        @cutter.stubs(:spec).returns spec
        @cutter.stubs(:size).returns 5
        @cutter.stubs(:body).returns StringIO.new("dummy body")

        @cutter.find
      end

      should "set rubygem" do
        assert_equal 'some name', @cutter.rubygem.name
      end

      should "set version" do
        assert_equal '1.3.3.7', @cutter.version.number
      end

      should "set gem version size" do
        assert_equal 5, @cutter.version.size
      end

      should "set sha256" do
        expected_sha = Digest::SHA2.base64digest(@cutter.body.string)
        assert_equal expected_sha, @cutter.version.sha256
      end
    end

    context "finding an existing gem" do
      should "bring up existing gem with matching spec" do
        @rubygem = create(:rubygem)
        spec = mock
        spec.stubs(:name).returns @rubygem.name
        spec.stubs(:version).returns "1.3.3.7"
        spec.stubs(:original_platform).returns "ruby"
        @cutter.stubs(:spec).returns spec
        @cutter.find

        assert_equal @rubygem, @cutter.rubygem
        assert_not_nil @cutter.version
      end

      should "error out when changing case with usuable versions" do
        @rubygem = create(:rubygem)
        create(:version, rubygem: @rubygem)

        assert_not_equal @rubygem.name, @rubygem.name.upcase

        spec = mock
        spec.expects(:name).returns @rubygem.name.upcase
        spec.expects(:version).returns "1.3.3.7"
        spec.expects(:original_platform).returns "ruby"
        @cutter.stubs(:spec).returns spec
        refute @cutter.find

        assert_match(/Unable to change case/, @cutter.message)
      end

      should "update the DB to reflect the case in the spec" do
        @rubygem = create(:rubygem)
        assert_not_equal @rubygem.name, @rubygem.name.upcase

        spec = mock
        spec.stubs(:name).returns @rubygem.name.upcase
        spec.stubs(:version).returns "1.3.3.7"
        spec.stubs(:original_platform).returns "ruby"
        @cutter.stubs(:spec).returns spec
        @cutter.find

        @cutter.rubygem.save
        @rubygem.reload

        assert_equal @rubygem.name, @rubygem.name.upcase
      end
    end

    context "checking if the rubygem can be pushed to" do
      should "be true if rubygem is new" do
        @cutter.stubs(:rubygem).returns Rubygem.new
        assert @cutter.authorize
      end

      context "with a existing rubygem" do
        setup do
          @rubygem = create(:rubygem, name: "the_gem_name")
          @cutter.stubs(:rubygem).returns @rubygem
        end

        should "be true if owned by the user" do
          @rubygem.ownerships.create(user: @user)
          assert @cutter.authorize
        end

        should "be true if no versions exist since it's a dependency" do
          assert @cutter.authorize
        end

        should "be false if not owned by user and an indexed version exists" do
          create(:version, rubygem: @rubygem, number: '0.1.1')
          refute @cutter.authorize
          assert_equal "You do not have permission to push to this gem. Ask an owner to add you with: gem owner the_gem_name --add user@example.com",
            @cutter.message
          assert_equal 403, @cutter.code
        end

        should "be true if not owned by user but no indexed versions exist" do
          create(:version, rubygem: @rubygem, number: '0.1.1', indexed: false)
          assert @cutter.authorize
        end
      end
    end

    context "successfully saving a gemcutter" do
      setup do
        @rubygem = create(:rubygem, name: 'gemsgemsgems')
        @cutter.stubs(:lock_key).returns 'lock_key'
        @cutter.stubs(:rubygem).returns @rubygem
        create(:version, rubygem: @rubygem, number: '0.1.1', summary: 'old summary')
        @cutter.stubs(:version).returns @rubygem.versions[0]
        @rubygem.stubs(:update_attributes_from_gem_specification!)
        GemCachePurger.stubs(:call)
        Indexer.any_instance.stubs(:write_gem)
        @cutter.save
      end

      should "update rubygem attributes" do
        assert_received(@rubygem, :update_attributes_from_gem_specification!) do |rubygem|
          rubygem.with(@cutter.version, @cutter.spec)
        end
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

      should "call GemCachePurger" do
        assert_received(GemCachePurger, :call) { |obj| obj.with(@rubygem.name).once }
      end

      should "enque job for updating ES index, spec index and purging cdn" do
        assert_difference 'Delayed::Job.count', 2 do
          @cutter.save
        end
      end

      should "create rubygem index" do
        @rubygem.update_column('updated_at', Date.new(2016, 07, 04))
        Delayed::Worker.new.work_off
        response = Rubygem.__elasticsearch__.client.get index: "rubygems-#{Rails.env}",
                                                        type:  'rubygem',
                                                        id:    @rubygem.id
        expected_response = {
          'name'                  => 'gemsgemsgems',
          'yanked'                => false,
          'summary'               => 'old summary',
          'description'           => 'Some awesome gem',
          'downloads'             => 0,
          'latest_version_number' => '0.1.1',
          'updated'               => '2016-07-04T00:00:00.000Z'
        }

        assert_equal expected_response, response['_source']
      end
    end

    context "locking a cutter" do
      setup do
        @cutter1 = Pusher.new(@user, gem_file("test-1.0.0.gem"))
        @cutter2 = Pusher.new(@user, gem_file("test-1.0.0.gem"))
      end

      should "lock with a spec" do
        @cutter1.stubs(:spec).returns(OpenStruct.new(name: 'test', version: '1.0.0'))
        assert @cutter1.with_lock, 'Lock should be obtained'
      end

      should "not lock without a spec" do
        @cutter1.stubs(:spec).returns(nil)
        refute @cutter1.with_lock, 'Lock should not be obtained without a spec'
      end

      should "409 when lock cannot be obtained" do
        @cutter1.stubs(:lock_key).returns('lock_key')
        Rails.cache.write('lock_key', true)
        @cutter1.with_lock
        assert_match(/We are already processing this gem with the specified version/, @cutter1.message)
      end

      should "lock should cause conflict" do
        lock_key = 'lock_key'
        @cutter1.stubs(:lock_key).returns(lock_key)
        @cutter2.stubs(:lock_key).returns(lock_key)

        lock_1_run = false
        lock_2_run = false

        # Start running lock 1, immediately set lock 1 to run
        lock1_thread = Thread.new do
          lock1 = @cutter1.with_lock do
            lock_1_run = true
            sleep 0.01 until lock_2_run
          end
          assert lock1, 'lock should have succeeded'
        end

        # Wait until lock 1 has been run - this will mean that the lock
        # has been claimed
        sleep 0.01 until lock_1_run

        # Attempt to run lock 2, this should conflict with lock1
        lock2 = @cutter2.with_lock
        refute lock2, 'lock should have failed'

        # Allow lock1 to finish, then join the thread
        lock_2_run = true
        lock1_thread.join

        # Make sure lock1 released the lock and lock2 returned a proper message
        refute Rails.cache.exist?(lock_key), 'Lock should have been released'
        assert_nil @cutter1.message, 'cutter_1 should not have had a message'
        assert_match(/We are already processing this gem with the specified version/, @cutter2.message)
      end
    end

    context 'pushing a new version' do
      setup do
        @rubygem = create(:rubygem)
        @cutter.stubs(:rubygem).returns @rubygem
        create(:version, rubygem: @rubygem, summary: 'old summary')
        version = create(:version, rubygem: @rubygem, summary: 'new summary')
        @cutter.stubs(:version).returns version
        @rubygem.stubs(:update_attributes_from_gem_specification!)
        @cutter.stubs(:version).returns version
        @cutter.stubs(:lock_key).returns 'lock_key'
        GemCachePurger.stubs(:call)
        Indexer.any_instance.stubs(:write_gem)
        @cutter.save
      end

      should "update rubygem index" do
        Delayed::Worker.new.work_off
        response = Rubygem.__elasticsearch__.client.get index: "rubygems-#{Rails.env}",
                                                        type:  'rubygem',
                                                        id:    @rubygem.id
        assert_equal 'new summary', response['_source']['summary']
      end
    end
  end
end

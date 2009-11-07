# DO NOT MODIFY THIS FILE
module Bundler
 file = File.expand_path(__FILE__)
 dir = File.dirname(file)

  ENV["PATH"]     = "#{dir}/../../bin:#{ENV["PATH"]}"
  ENV["RUBYOPT"]  = "-r#{file} #{ENV["RUBYOPT"]}"

  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/xml-simple-1.0.12/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/xml-simple-1.0.12/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/nokogiri-1.4.0/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/nokogiri-1.4.0/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/nokogiri-1.4.0/ext")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/activesupport-2.3.4/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/activesupport-2.3.4/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/builder-2.1.2/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/builder-2.1.2/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/clearance-0.8.2/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/clearance-0.8.2/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/rack-test-0.5.0/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/rack-test-0.5.0/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/actionmailer-2.3.4/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/actionmailer-2.3.4/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/gchartrb-0.8/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/gchartrb-0.8/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/redgreen-1.2.2/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/redgreen-1.2.2/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/will_paginate-2.3.11/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/will_paginate-2.3.11/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/factory_girl-1.2.3/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/factory_girl-1.2.3/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/net-ssh-2.0.15/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/net-ssh-2.0.15/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/net-scp-1.0.2/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/net-scp-1.0.2/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/mime-types-1.16/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/mime-types-1.16/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/aws-s3-0.6.2/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/aws-s3-0.6.2/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/rack-cache-0.5.2/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/rack-cache-0.5.2/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/shoulda-2.10.2/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/shoulda-2.10.2/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/polyglot-0.2.9/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/polyglot-0.2.9/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/treetop-1.4.2/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/treetop-1.4.2/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/memcache-client-1.7.5/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/memcache-client-1.7.5/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/rack-1.0.1/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/rack-1.0.1/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/actionpack-2.3.4/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/actionpack-2.3.4/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/sinatra-0.9.4/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/sinatra-0.9.4/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/webrat-0.5.3/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/webrat-0.5.3/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/ambethia-smtp-tls-1.1.2/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/ambethia-smtp-tls-1.1.2/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/diff-lcs-1.1.2/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/diff-lcs-1.1.2/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/rake-0.8.7/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/rake-0.8.7/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/activerecord-2.3.4/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/activerecord-2.3.4/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/term-ansicolor-1.0.4/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/term-ansicolor-1.0.4/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/cucumber-0.3.101/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/cucumber-0.3.101/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/fakeweb-1.2.6/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/fakeweb-1.2.6/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/activeresource-2.3.4/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/activeresource-2.3.4/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/rails-2.3.4/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/rails-2.3.4/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/ddollar-pacecar-1.1.6/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/ddollar-pacecar-1.1.6/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/rr-0.10.4/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/rr-0.10.4/lib")

  @gemfile = "#{dir}/../../Gemfile"

  require "rubygems"

  @bundled_specs = {}
  @bundled_specs["xml-simple"] = eval(File.read("#{dir}/specifications/xml-simple-1.0.12.gemspec"))
  @bundled_specs["xml-simple"].loaded_from = "#{dir}/specifications/xml-simple-1.0.12.gemspec"
  @bundled_specs["nokogiri"] = eval(File.read("#{dir}/specifications/nokogiri-1.4.0.gemspec"))
  @bundled_specs["nokogiri"].loaded_from = "#{dir}/specifications/nokogiri-1.4.0.gemspec"
  @bundled_specs["activesupport"] = eval(File.read("#{dir}/specifications/activesupport-2.3.4.gemspec"))
  @bundled_specs["activesupport"].loaded_from = "#{dir}/specifications/activesupport-2.3.4.gemspec"
  @bundled_specs["builder"] = eval(File.read("#{dir}/specifications/builder-2.1.2.gemspec"))
  @bundled_specs["builder"].loaded_from = "#{dir}/specifications/builder-2.1.2.gemspec"
  @bundled_specs["clearance"] = eval(File.read("#{dir}/specifications/clearance-0.8.2.gemspec"))
  @bundled_specs["clearance"].loaded_from = "#{dir}/specifications/clearance-0.8.2.gemspec"
  @bundled_specs["rack-test"] = eval(File.read("#{dir}/specifications/rack-test-0.5.0.gemspec"))
  @bundled_specs["rack-test"].loaded_from = "#{dir}/specifications/rack-test-0.5.0.gemspec"
  @bundled_specs["actionmailer"] = eval(File.read("#{dir}/specifications/actionmailer-2.3.4.gemspec"))
  @bundled_specs["actionmailer"].loaded_from = "#{dir}/specifications/actionmailer-2.3.4.gemspec"
  @bundled_specs["gchartrb"] = eval(File.read("#{dir}/specifications/gchartrb-0.8.gemspec"))
  @bundled_specs["gchartrb"].loaded_from = "#{dir}/specifications/gchartrb-0.8.gemspec"
  @bundled_specs["redgreen"] = eval(File.read("#{dir}/specifications/redgreen-1.2.2.gemspec"))
  @bundled_specs["redgreen"].loaded_from = "#{dir}/specifications/redgreen-1.2.2.gemspec"
  @bundled_specs["will_paginate"] = eval(File.read("#{dir}/specifications/will_paginate-2.3.11.gemspec"))
  @bundled_specs["will_paginate"].loaded_from = "#{dir}/specifications/will_paginate-2.3.11.gemspec"
  @bundled_specs["factory_girl"] = eval(File.read("#{dir}/specifications/factory_girl-1.2.3.gemspec"))
  @bundled_specs["factory_girl"].loaded_from = "#{dir}/specifications/factory_girl-1.2.3.gemspec"
  @bundled_specs["net-ssh"] = eval(File.read("#{dir}/specifications/net-ssh-2.0.15.gemspec"))
  @bundled_specs["net-ssh"].loaded_from = "#{dir}/specifications/net-ssh-2.0.15.gemspec"
  @bundled_specs["net-scp"] = eval(File.read("#{dir}/specifications/net-scp-1.0.2.gemspec"))
  @bundled_specs["net-scp"].loaded_from = "#{dir}/specifications/net-scp-1.0.2.gemspec"
  @bundled_specs["mime-types"] = eval(File.read("#{dir}/specifications/mime-types-1.16.gemspec"))
  @bundled_specs["mime-types"].loaded_from = "#{dir}/specifications/mime-types-1.16.gemspec"
  @bundled_specs["aws-s3"] = eval(File.read("#{dir}/specifications/aws-s3-0.6.2.gemspec"))
  @bundled_specs["aws-s3"].loaded_from = "#{dir}/specifications/aws-s3-0.6.2.gemspec"
  @bundled_specs["rack-cache"] = eval(File.read("#{dir}/specifications/rack-cache-0.5.2.gemspec"))
  @bundled_specs["rack-cache"].loaded_from = "#{dir}/specifications/rack-cache-0.5.2.gemspec"
  @bundled_specs["shoulda"] = eval(File.read("#{dir}/specifications/shoulda-2.10.2.gemspec"))
  @bundled_specs["shoulda"].loaded_from = "#{dir}/specifications/shoulda-2.10.2.gemspec"
  @bundled_specs["polyglot"] = eval(File.read("#{dir}/specifications/polyglot-0.2.9.gemspec"))
  @bundled_specs["polyglot"].loaded_from = "#{dir}/specifications/polyglot-0.2.9.gemspec"
  @bundled_specs["treetop"] = eval(File.read("#{dir}/specifications/treetop-1.4.2.gemspec"))
  @bundled_specs["treetop"].loaded_from = "#{dir}/specifications/treetop-1.4.2.gemspec"
  @bundled_specs["memcache-client"] = eval(File.read("#{dir}/specifications/memcache-client-1.7.5.gemspec"))
  @bundled_specs["memcache-client"].loaded_from = "#{dir}/specifications/memcache-client-1.7.5.gemspec"
  @bundled_specs["rack"] = eval(File.read("#{dir}/specifications/rack-1.0.1.gemspec"))
  @bundled_specs["rack"].loaded_from = "#{dir}/specifications/rack-1.0.1.gemspec"
  @bundled_specs["actionpack"] = eval(File.read("#{dir}/specifications/actionpack-2.3.4.gemspec"))
  @bundled_specs["actionpack"].loaded_from = "#{dir}/specifications/actionpack-2.3.4.gemspec"
  @bundled_specs["sinatra"] = eval(File.read("#{dir}/specifications/sinatra-0.9.4.gemspec"))
  @bundled_specs["sinatra"].loaded_from = "#{dir}/specifications/sinatra-0.9.4.gemspec"
  @bundled_specs["webrat"] = eval(File.read("#{dir}/specifications/webrat-0.5.3.gemspec"))
  @bundled_specs["webrat"].loaded_from = "#{dir}/specifications/webrat-0.5.3.gemspec"
  @bundled_specs["ambethia-smtp-tls"] = eval(File.read("#{dir}/specifications/ambethia-smtp-tls-1.1.2.gemspec"))
  @bundled_specs["ambethia-smtp-tls"].loaded_from = "#{dir}/specifications/ambethia-smtp-tls-1.1.2.gemspec"
  @bundled_specs["diff-lcs"] = eval(File.read("#{dir}/specifications/diff-lcs-1.1.2.gemspec"))
  @bundled_specs["diff-lcs"].loaded_from = "#{dir}/specifications/diff-lcs-1.1.2.gemspec"
  @bundled_specs["rake"] = eval(File.read("#{dir}/specifications/rake-0.8.7.gemspec"))
  @bundled_specs["rake"].loaded_from = "#{dir}/specifications/rake-0.8.7.gemspec"
  @bundled_specs["activerecord"] = eval(File.read("#{dir}/specifications/activerecord-2.3.4.gemspec"))
  @bundled_specs["activerecord"].loaded_from = "#{dir}/specifications/activerecord-2.3.4.gemspec"
  @bundled_specs["term-ansicolor"] = eval(File.read("#{dir}/specifications/term-ansicolor-1.0.4.gemspec"))
  @bundled_specs["term-ansicolor"].loaded_from = "#{dir}/specifications/term-ansicolor-1.0.4.gemspec"
  @bundled_specs["cucumber"] = eval(File.read("#{dir}/specifications/cucumber-0.3.101.gemspec"))
  @bundled_specs["cucumber"].loaded_from = "#{dir}/specifications/cucumber-0.3.101.gemspec"
  @bundled_specs["fakeweb"] = eval(File.read("#{dir}/specifications/fakeweb-1.2.6.gemspec"))
  @bundled_specs["fakeweb"].loaded_from = "#{dir}/specifications/fakeweb-1.2.6.gemspec"
  @bundled_specs["activeresource"] = eval(File.read("#{dir}/specifications/activeresource-2.3.4.gemspec"))
  @bundled_specs["activeresource"].loaded_from = "#{dir}/specifications/activeresource-2.3.4.gemspec"
  @bundled_specs["rails"] = eval(File.read("#{dir}/specifications/rails-2.3.4.gemspec"))
  @bundled_specs["rails"].loaded_from = "#{dir}/specifications/rails-2.3.4.gemspec"
  @bundled_specs["ddollar-pacecar"] = eval(File.read("#{dir}/specifications/ddollar-pacecar-1.1.6.gemspec"))
  @bundled_specs["ddollar-pacecar"].loaded_from = "#{dir}/specifications/ddollar-pacecar-1.1.6.gemspec"
  @bundled_specs["rr"] = eval(File.read("#{dir}/specifications/rr-0.10.4.gemspec"))
  @bundled_specs["rr"].loaded_from = "#{dir}/specifications/rr-0.10.4.gemspec"

  def self.add_specs_to_loaded_specs
    Gem.loaded_specs.merge! @bundled_specs
  end

  def self.add_specs_to_index
    @bundled_specs.each do |name, spec|
      Gem.source_index.add_spec spec
    end
  end

  add_specs_to_loaded_specs
  add_specs_to_index

  def self.require_env(env = nil)
    context = Class.new do
      def initialize(env) @env = env && env.to_s ; end
      def method_missing(*) ; yield if block_given? ; end
      def only(*env)
        old, @only = @only, _combine_only(env.flatten)
        yield
        @only = old
      end
      def except(*env)
        old, @except = @except, _combine_except(env.flatten)
        yield
        @except = old
      end
      def gem(name, *args)
        opt = args.last.is_a?(Hash) ? args.pop : {}
        only = _combine_only(opt[:only] || opt["only"])
        except = _combine_except(opt[:except] || opt["except"])
        files = opt[:require_as] || opt["require_as"] || name
        files = [files] unless files.respond_to?(:each)

        return unless !only || only.any? {|e| e == @env }
        return if except && except.any? {|e| e == @env }

        if files = opt[:require_as] || opt["require_as"]
          files = Array(files)
          files.each { |f| require f }
        else
          begin
            require name
          rescue LoadError
            # Do nothing
          end
        end
        yield if block_given?
        true
      end
      private
      def _combine_only(only)
        return @only unless only
        only = [only].flatten.compact.uniq.map { |o| o.to_s }
        only &= @only if @only
        only
      end
      def _combine_except(except)
        return @except unless except
        except = [except].flatten.compact.uniq.map { |o| o.to_s }
        except |= @except if @except
        except
      end
    end
    context.new(env && env.to_s).instance_eval(File.read(@gemfile), @gemfile, 1)
  end
end

module Gem
  @loaded_stacks = Hash.new { |h,k| h[k] = [] }

  def source_index.refresh!
    super
    Bundler.add_specs_to_index
  end
end

require 'rack/cache/options'
require 'rack/cache/request'
require 'rack/cache/response'
require 'rack/cache/storage'

module Rack::Cache
  # Implements Rack's middleware interface and provides the context for all
  # cache logic, including the core logic engine.
  class Context
    include Rack::Cache::Options

    # Array of trace Symbols
    attr_reader :trace

    # The Rack application object immediately downstream.
    attr_reader :backend

    def initialize(backend, options={})
      @backend = backend
      @trace = []

      initialize_options options
      yield self if block_given?

      @private_header_keys =
        private_headers.map { |name| "HTTP_#{name.upcase.tr('-', '_')}" }
    end

    # The configured MetaStore instance. Changing the rack-cache.metastore
    # value effects the result of this method immediately.
    def metastore
      uri = options['rack-cache.metastore']
      storage.resolve_metastore_uri(uri)
    end

    # The configured EntityStore instance. Changing the rack-cache.entitystore
    # value effects the result of this method immediately.
    def entitystore
      uri = options['rack-cache.entitystore']
      storage.resolve_entitystore_uri(uri)
    end

    # The Rack call interface. The receiver acts as a prototype and runs
    # each request in a dup object unless the +rack.run_once+ variable is
    # set in the environment.
    def call(env)
      if env['rack.run_once']
        call! env
      else
        clone.call! env
      end
    end

    # The real Rack call interface. The caching logic is performed within
    # the context of the receiver.
    def call!(env)
      @trace = []
      @env = @default_options.merge(env)
      @request = Request.new(@env.dup.freeze)

      response =
        if @request.get? || @request.head?
          if !@env['HTTP_EXPECT']
            lookup
          else
            pass
          end
        else
          invalidate
        end

      # log trace and set X-Rack-Cache tracing header
      trace = @trace.join(', ')
      response.headers['X-Rack-Cache'] = trace

      # write log message to rack.errors
      if verbose?
        message = "cache: [%s %s] %s\n" %
          [@request.request_method, @request.fullpath, trace]
        @env['rack.errors'].write(message)
      end

      # tidy up response a bit
      response.not_modified! if not_modified?(response)
      response.body = [] if @request.head?
      response.to_a
    end

  private

    # Record that an event took place.
    def record(event)
      @trace << event
    end

    # Does the request include authorization or other sensitive information
    # that should cause the response to be considered private by default?
    # Private responses are not stored in the cache.
    def private_request?
      @private_header_keys.any? { |key| @env.key?(key) }
    end

    # Determine if the #response validators (ETag, Last-Modified) matches
    # a conditional value specified in #request.
    def not_modified?(response)
      response.etag_matches?(@request.env['HTTP_IF_NONE_MATCH']) ||
        response.last_modified_at?(@request.env['HTTP_IF_MODIFIED_SINCE'])
    end

    # Whether the cache entry is "fresh enough" to satisfy the request.
    def fresh_enough?(entry)
      if entry.fresh?
        if allow_revalidate? && max_age = @request.cache_control.max_age
          max_age > 0 && max_age >= entry.age
        else
          true
        end
      end
    end

    # Delegate the request to the backend and create the response.
    def forward
      Response.new(*backend.call(@env))
    end

    # The request is sent to the backend, and the backend's response is sent
    # to the client, but is not entered into the cache.
    def pass
      record :pass
      forward
    end

    # Invalidate POST, PUT, DELETE and all methods not understood by this cache
    # See RFC2616 13.10
    def invalidate
      record :invalidate
      metastore.invalidate(@request, entitystore)
      pass
    end

    # Try to serve the response from cache. When a matching cache entry is
    # found and is fresh, use it as the response without forwarding any
    # request to the backend. When a matching cache entry is found but is
    # stale, attempt to #validate the entry with the backend using conditional
    # GET. When no matching cache entry is found, trigger #miss processing.
    def lookup
      if @request.no_cache? && allow_reload?
        record :reload
        fetch
      elsif entry = metastore.lookup(@request, entitystore)
        if fresh_enough?(entry)
          record :fresh
          entry.headers['Age'] = entry.age.to_s
          entry
        else
          record :stale
          validate(entry)
        end
      else
        record :miss
        fetch
      end
    end

    # Validate that the cache entry is fresh. The original request is used
    # as a template for a conditional GET request with the backend.
    def validate(entry)
      # send no head requests because we want content
      @env['REQUEST_METHOD'] = 'GET'

      # add our cached validators to the environment
      @env['HTTP_IF_MODIFIED_SINCE'] = entry.last_modified
      @env['HTTP_IF_NONE_MATCH'] = entry.etag

      backend_response = forward

      response =
        if backend_response.status == 304
          record :valid
          entry = entry.dup
          entry.headers.delete('Date')
          %w[Date Expires Cache-Control ETag Last-Modified].each do |name|
            next unless value = backend_response.headers[name]
            entry.headers[name] = value
          end
          entry
        else
          record :invalid
          backend_response
        end

      store(response) if response.cacheable?

      response
    end

    # The cache missed or a reload is required. Forward the request to the
    # backend and determine whether the response should be stored.
    def fetch
      # send no head requests because we want content
      @env['REQUEST_METHOD'] = 'GET'

      # avoid that the backend sends no content
      @env.delete('HTTP_IF_MODIFIED_SINCE')
      @env.delete('HTTP_IF_NONE_MATCH')

      response = forward

      # Mark the response as explicitly private if any of the private
      # request headers are present and the response was not explicitly
      # declared public.
      if private_request? && !response.cache_control.public?
        response.private = true
      elsif default_ttl > 0 && response.ttl.nil? && !response.cache_control.must_revalidate?
        # assign a default TTL for the cache entry if none was specified in
        # the response; the must-revalidate cache control directive disables
        # default ttl assigment.
        response.ttl = default_ttl
      end

      store(response) if response.cacheable?

      response
    end

    # Write the response to the cache.
    def store(response)
      record :store
      metastore.store(@request, response, entitystore)
      response.headers['Age'] = response.age.to_s
    end
  end
end

require 'httparty'

module Cloudflare
  class BaseAPI
    include HTTParty

    class Error < StandardError; end

    class Parser::Cloudflare < HTTParty::Parser
      protected

      def json
        parsed = JSON.parse(body, :quirks_mode => true, :allow_nan => true)
        raise Error, "call failed: #{body}" if !parsed['success']
        parsed['result']
      end
    end

    parser Parser::Cloudflare
  end

  class API < BaseAPI
    base_uri 'api.cloudflare.com/client/v4'

    def initialize(api_token)
      @options = {
        headers: {
          'Authorization' => "Bearer #{api_token}",
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
        },
      }
    end

    def zone_api(name)
      zone_id = zone_id(name)
      Zone.new(@options, zone_id)
    end

    def zone_id(name)
      zones = self.class.get('/zones', @options.merge(query: { name: name })).parsed_response
      raise "#{name} not found" if zones.empty?
      zones.first['id']
    end

    class Zone < BaseAPI
      def initialize(options, zone_id)
        @options = options
        self.class.base_uri "https://api.cloudflare.com/client/v4/zones/#{zone_id}"
      end

      def records(query = {})
        options = @options.merge(query: query)
        self.class.get('/dns_records', options).parsed_response
      end

      def record(name)
        records = records(name: name)
        raise "#{name} not found" if records.empty?
        records.first
      end

      def patch_record(id, updates)
        self.class.patch("/dns_records/#{id}", @options.merge(body: updates.to_json))
      end
    end
  end
end

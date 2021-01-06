require 'cloudflare/ddns/version'
require 'httparty'
require_relative './api'

module Cloudflare
  module DDNS
    IP_RESOLVER = 'https://api.ipify.org'

    class Error < StandardError; end

    def self.update_record(api_token, zone_name, record_name)
      api = API.new(api_token)
      zone_api = api.zone_api(zone_name)
      record = zone_api.record(record_name)
      current_ip = fetch_ip
      return if record['content'] == current_ip

      zone_api.patch_record(record['id'], content: current_ip)
      current_ip
    end

    def self.fetch_ip
      HTTParty.get(IP_RESOLVER).body
    end
  end
end

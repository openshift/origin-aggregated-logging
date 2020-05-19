#! /usr/bin/env ruby

require 'net/https'
require 'json'

if ARGV.length != 2
  abort "Usage: wait_for_es_version.rb <min_es_version> <es_url>"
end

min_version = ARGV[0]
es_url = ARGV[1]

uri = URI(es_url)

cert_dir = "/etc/fluent/keys/"

fluentd_ca_file = File.join(cert_dir, "ca-bundle.crt")

client_file = File.join(cert_dir, "tls.crt")
client_cert = OpenSSL::X509::Certificate.new File.read client_file

key_file = File.join(cert_dir, "tls.key")
client_key = OpenSSL::PKey::RSA.new File.read key_file


Net::HTTP.start(uri.host, uri.port, :use_ssl => true, :ca_file => fluentd_ca_file, :cert => client_cert, :key => client_key) do |http|
  request = Net::HTTP::Get.new uri
  response = http.request request

  hash = JSON.parse(response.body)

  version = hash["version"]["number"]

  if version.to_f < min_version.to_f
    warn "Elasticsearch is currently version: #{version} - Expecting it to be at least: #{min_version}"
    exit 1
  end
end
require_relative './spec_helper'

require 'resolve/hostname'

describe Resolve::Hostname do
  context 'initialized as near default' do
    r = Resolve::Hostname.new(:ttl => 2, :resolver_ttl => 2)

    describe '#primary_ip_version' do
      it 'returns :ipv4' do
        expect(r.primary_ip_version).to be(:ipv4)
      end
    end

    describe '#secondary_ip_version' do
      it 'returns :ipv6' do
        expect(r.secondary_ip_version).to be(:ipv6)
      end
    end

    describe '#primary_version_address?' do
      context 'with valid IPv4 address' do
        it 'returns true' do
          expect(r.primary_version_address?('127.0.0.1')).to be_true
        end
      end

      context 'with invalid IPv4 address' do
        context 'in ruby 2.0.0 or later' do
          if IPAddr.const_defined?('InvalidAddressError')
            it 'raises IPAddr::InvalidAddressError' do
              expect{ r.primary_version_address?('256.256.256.256') }.to raise_error(IPAddr::InvalidAddressError)
              expect{ r.primary_version_address?('256.256.256.0')   }.to raise_error(IPAddr::InvalidAddressError)
              expect{ r.primary_version_address?('256.256.0.0')     }.to raise_error(IPAddr::InvalidAddressError)
              expect{ r.primary_version_address?('256.0.0.0')       }.to raise_error(IPAddr::InvalidAddressError)
              expect{ r.primary_version_address?('0.0.0.0') }.not_to raise_error()
            end
          end
        end
        context 'in ruby 1.9.3 or earlier' do
          unless IPAddr.const_defined?('InvalidAddressError')
            it 'raises ArgumentError' do
              expect{ r.primary_version_address?('256.256.256.256') }.to raise_error(ArgumentError)
              expect{ r.primary_version_address?('256.256.256.0')   }.to raise_error(ArgumentError)
              expect{ r.primary_version_address?('256.256.0.0')     }.to raise_error(ArgumentError)
              expect{ r.primary_version_address?('256.0.0.0')       }.to raise_error(ArgumentError)
              expect{ r.primary_version_address?('0.0.0.0') }.not_to raise_error()
            end
          end
        end
      end

      context 'with IPv6 address' do
        it 'returns false' do
          expect(r.primary_version_address?('::1')).to be_false
        end
      end
    end

    describe '#resolv_instance' do
      it 'returns instance newly instanciated instead of already expired' do
        first = r.resolv_instance

        r.resolver_expires = Time.now - 1

        expect(r.resolv_instance).not_to be(first)
      end
    end

    describe '#getaddress' do
      it 'returns ipv4 address string for www.google.com' do
        expect(r.getaddress('www.google.com')).to match(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)
      end

      it 'returns IPv4 address for example.com' do
        require 'ipaddr'
        expect(IPAddr.new(r.getaddress('example.com')).ipv4?).to be_true
      end

      it 'returns same ruby object for second query' do
        first = r.getaddress('google.com')
        expect(r.getaddress('google.com')).to be(first)
      end

      it 'raise error for records non-existing' do
        expect { r.getaddress('not-existing.example.com') }.to raise_error(Resolve::Hostname::NotFoundError)
      end

      it 'returns newly fetched object instead of expired cache' do
        first = r.getaddress('www.example.com')

        r.cache['www.example.com'].expires = Time.now - 1

        expect(r.getaddress('www.example.com')).not_to be(first)
      end

      it 'returns 127.0.0.1 for localhost' do
        expect(r.getaddress('localhost')).to eq('127.0.0.1')
      end

      it 'returns address string itself for address string' do
        expect(r.getaddress('127.0.0.1')).to eq('127.0.0.1')
        expect(r.getaddress('::1')).to eq('::1')
        expect(r.getaddress('192.168.0.1')).to eq('192.168.0.1')
      end
    end
  end

  context 'initialized as system resolver enabled' #TODO
  context 'initialized with ipv6 primary' #TODO
  context 'initialized as not permitted for secondary address version' #TODO

  context 'initialized as not to raise NotFoundError' #TODO
end

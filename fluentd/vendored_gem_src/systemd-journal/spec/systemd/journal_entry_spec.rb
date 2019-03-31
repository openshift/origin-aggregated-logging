require 'spec_helper'

RSpec.describe Systemd::JournalEntry do
  let(:msg)       { 'test message' }
  let(:pid)       { '123' }
  let(:hash)      { { '_PID' => pid, 'MESSAGE' => msg } }
  subject(:entry) { Systemd::JournalEntry.new(hash) }

  describe 'initialize' do
    it 'takes a hash as an argument' do
      expect { Systemd::JournalEntry.new(hash) }.to_not raise_error
    end
  end

  describe '[]' do
    it 'accepts symbols as a field name' do
      expect(entry[:message]).to eq(msg)
    end

    it 'accepts strings as a field name' do
      expect(entry['message']).to eq(msg)
    end

    it 'doesnt care about case' do
      expect(entry['MeSSage']).to eq(msg)
    end

    it 'returns nil if not found' do
      expect(entry['missing']).to be nil
    end
  end

  describe 'each' do
    it 'is chainable as an enumerator' do
      expect(entry.each.class).to be(Enumerator)
    end

    it 'yields each key/value in turn' do
      items = entry.map { |k, v| [k, v] }
      expect(items).to eq([['_PID', pid], ['MESSAGE', msg]])
    end
  end

  describe 'to_h' do
    it 'returns a deep copy of the entry' do
      copy = subject.to_h
      expect(copy).to eq(hash)
      expect { copy['_PID'] << '3' }.to_not change { subject._pid }
    end
  end

  describe 'catalog' do
    context 'without a catalog' do
      it 'returns nil if the entry has no catalog' do
        expect(entry.catalog).to be nil
      end
    end

    context 'with a catalog' do
      let(:catalog) { 'Process @_PID@ said @MESSAGE@' }
      subject(:entry) do
        Systemd::JournalEntry.new(hash.merge(message_id: '123'))
      end

      before(:each) do
        allow(Systemd::Journal).to receive(:catalog_for).and_return(catalog)
      end

      it 'does field substitution by default' do
        expect(entry.catalog).to eq('Process 123 said test message')
      end

      it 'does field substitution when requested' do
        expect(entry.catalog(replace: true))
          .to eq('Process 123 said test message')
      end

      it 'skips field substition if requested' do
        expect(entry.catalog(replace: false)).to eq(catalog)
      end
    end
  end
end

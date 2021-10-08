require 'spec_helper'

RSpec.describe Systemd::Journal do
  subject(:j) do
    Systemd::Journal.new(file: journal_file).tap do |journal|
      journal.seek(:head)
      journal.move_next
    end
  end

  describe 'open' do
    it 'creates and closes' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_close)
        .and_call_original

      result = Systemd::Journal.open { 1 }
      expect(result).to eq 1
    end

    it 'raises original exception when creating journal fails' do
      expect(Systemd::Journal::Native).to_not receive(:sd_journal_close)

      expect do
        Systemd::Journal.open(file: 1, path: 2, files: 3) { 1 }
      end.to raise_error(ArgumentError)
    end
  end

  describe 'initialize' do
    subject(:j) { Systemd::Journal }

    it 'detects invalid argument combinations' do
      expect { j.new(path: '/',     files: []) }.to raise_error(ArgumentError)
      expect { j.new(container: '', files: []) }.to raise_error(ArgumentError)
      expect { j.new(container: '', path: '/') }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError on attempt to open a container without support' do
      allow(Systemd::Journal::Native).to receive(:open_container?)
        .and_return(false)

      expect { j.new(container: 'test') }.to raise_error(ArgumentError)
    end
  end

  describe 'close' do
    it 'closes the underlying file' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_close)
        .and_call_original

      j.close
    end

    it 'unregisters the finalizer' do
      expect(ObjectSpace).to receive(:undefine_finalizer)
        .with(j)
        .and_call_original

      j.close
    end

    it 'does not fail if called more than once' do
      j.close
      expect { j.close }.to_not raise_error
    end

    it 'marks the journal as closed' do
      expect(j).to_not be_closed
      j.close
      expect(j).to be_closed
    end
  end

  describe 'query_unique' do
    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_enumerate_unique)
        .and_return(-1)

      expect { j.query_unique(:_pid) }.to raise_error(Systemd::JournalError)
    end

    it 'lists all the unique values for the given field' do
      values     = j.query_unique(:_transport)
      transports = %w(syslog journal stdout kernel driver)

      expect(values.length).to eq(5)
      expect(values).to include(*transports)
    end
  end

  describe 'disk_usage' do
    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_usage)
        .and_return(-1)

      expect { j.disk_usage }.to raise_error(Systemd::JournalError)
    end

    it 'returns the disk usage of the example journal file' do
      pending 'blocks? bytes?'
      expect(j.disk_usage).to eq(4_005_888)
      # force failure to make travis-ci happy
      expect(true).to be false
    end
  end

  describe 'data_threshold' do
    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native)
        .to receive(:sd_journal_get_data_threshold)
        .and_return(-1)

      expect { j.data_threshold }.to raise_error(Systemd::JournalError)
    end

    it 'returns the default 64K' do
      expect(j.data_threshold).to eq(0x0010000)
    end
  end

  describe 'data_threshold=' do
    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native)
        .to receive(:sd_journal_set_data_threshold)
        .and_return(-1)

      expect { j.data_threshold = 10 }.to raise_error(Systemd::JournalError)
    end
  end

  describe 'read_field' do
    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_data)
        .and_return(-1)

      expect { j.read_field(:message) }.to raise_error(Systemd::JournalError)
    end

    it 'returns the correct value' do
      expect(j.read_field(:_hostname)).to eq('arch')
    end
  end

  describe 'current_entry' do
    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_enumerate_data)
        .and_return(-1)

      expect { j.current_entry }.to raise_error(Systemd::JournalError)
    end

    it 'returns a JournalEntry with the correct values' do
      entry = j.current_entry
      expect(entry._hostname).to eq('arch')
      expect(entry.message).to start_with('Allowing runtime journal')
    end
  end

  describe 'each' do
    it 'returns an enumerator' do
      expect(j.each.class).to be Enumerator
    end

    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_seek_head)
        .and_return(-1)

      expect { j.each }.to raise_error(Systemd::JournalError)
    end

    it 'properly enumerates all the entries' do
      entries = j.each.map(&:message)

      expect(entries.first).to start_with('Allowing runtime journal')
      expect(entries.last).to start_with('ROOT LOGIN ON tty1')
    end
  end

  context 'with catalog messages' do
    let(:msg_id)   { 'f77379a8490b408bbe5f6940505a777b' }
    let(:msg_text) { 'Subject: The Journal has been started' }

    describe 'catalog_for' do
      subject(:j) { Systemd::Journal }

      it 'throws a JournalError on invalid return code' do
        expect(Systemd::Journal::Native)
          .to receive(:sd_journal_get_catalog_for_message_id)
          .and_return(-1)

        expect { j.catalog_for(msg_id) }.to raise_error(Systemd::JournalError)
      end

      it 'returns the correct catalog entry' do
        cat = Systemd::Journal.catalog_for(msg_id)
        expect(cat.downcase).to start_with(msg_text.downcase)
      end
    end

    describe 'current_catalog' do
      it 'throws a JournalError on invalid return code' do
        expect(Systemd::Journal::Native)
          .to receive(:sd_journal_get_catalog)
          .and_return(-1)

        expect { j.current_catalog }.to raise_error(Systemd::JournalError)
      end

      it 'returns the correct catalog entry' do
        # find first entry with a catalog
        j.move_next until j.current_entry.catalog?

        expect(j.current_catalog.downcase).to start_with(msg_text.downcase)
      end
    end
  end

  describe 'filter' do
    it 'does basic filtering as expected' do
      j.filter(_transport: 'kernel')
      j.each do |entry|
        expect(entry._transport).to eq('kernel')
      end
      expect(j.count).to eq(435)
    end

    it 'does filtering with AND conditions' do
      j.filter(_transport: 'kernel', priority: 3)
      expect(j.count).to eq(2)
      j.each do |e|
        expect(e._transport).to eq('kernel')
        expect(e.priority).to eq('3')
      end
    end

    it 'does basic filtering with multiple options for the same key' do
      j.filter(_transport: %w(kernel driver))
      j.each do |entry|
        expect(%w(kernel driver)).to include(entry._transport)
      end
      expect(j.count).to eq(438)
    end

    it 'does basic filtering with multiple keys' do
      j.filter(
        { _transport: 'kernel' },
        { _systemd_unit: 'systemd-journald.service' }
      )

      c = j.each_with_object(Hash.new(0)) do |e, h|
        h[:transport] += 1 if e._transport == 'kernel'
        h[:unit]      += 1 if e._systemd_unit == 'systemd-journald.service'
      end

      expect(c[:transport]).to eq(435)
      expect(c[:unit]).to eq(3)
    end

    it 'does crazy stupid filtering' do
      filter = [
        { _transport: 'kernel', priority: 4   },
        { _systemd_unit: 'getty@tty1.service' },
        { _systemd_unit: 'systemd-logind.service', seat_id: 'seat0' },
        { priority: [3, 5] }
      ]

      j.filter(*filter)

      c = j.each_with_object(Hash.new(0)) do |e, h|
        h[:a] += 1 if e._transport == 'kernel' && e.priority == '4'
        h[:b] += 1 if e._systemd_unit == 'getty@tty1.service'
        if e._systemd_unit == 'systemd-logind.service' && e[:seat_id] == 'seat0'
          h[:c] += 1
        end
        h[:d] += 1 if %w(3 5).include?(e.priority)
      end

      # from journalctl --file <fixture> <filter> --output json | wc -l
      expect(c[:a]).to eq(26)
      expect(c[:b]).to eq(1)
      expect(c[:c]).to eq(1)
      expect(c[:d]).to eq(11)
    end
  end

  describe 'cursor' do
    it 'returns some opaque string' do
      expect(j.cursor).to be_kind_of(String)
    end

    it 'throws an error on failure' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_cursor)
        .and_return(-1)

      expect { j.cursor }.to raise_error(Systemd::JournalError)
    end
  end

  describe 'cursor?' do
    let!(:cursor) { j.cursor }
    it 'returns true if the cursor matches' do
      expect(j.cursor?(cursor)).to be true
    end

    it 'throws an error on failure' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_test_cursor)
        .and_return(-1)

      expect { j.cursor?(cursor) }.to raise_error(Systemd::JournalError)
    end
  end

  describe 'move' do
    it 'moves by the specified number of entries' do
      j.move(1)
      expect(j.read_field(:message)).to eq(journal_json[1]['MESSAGE'])
    end

    it 'does not move with 0' do
      j.move(1)
      j.move(0)
      expect(j.read_field(:message)).to eq(journal_json[1]['MESSAGE'])
    end

    it 'moves backwards' do
      j.move(3)
      j.move(-1)
      expect(j.read_field(:message)).to eq(journal_json[2]['MESSAGE'])
    end

    it 'returns the number of entries moved' do
      expect(j.move(3)).to eq(3)
    end

    it 'returns the number of entries moved even if if less' do
      j.move(2)
      expect(j.read_field(:message)).to eq(journal_json[2]['MESSAGE'])
      expect(j.move(-5)).to eq(2)
    end

    it 'returns 0 if it did not move' do
      expect(j.move(-1)).to eq(0)
    end
  end

  describe 'seek' do
    it 'treats a string parameter as the cursor' do
      cursor = j.cursor
      j.move(3)
      expect(j.cursor?(cursor)).to be false
      j.seek(cursor)
      j.move_next
      expect(j.cursor?(cursor)).to be true
    end

    it 'can seek to the end' do
      j.seek(:tail)
      j.move_previous
      expect(j.move_next).to be false
    end

    it 'can seek to the start' do
      j.seek(:start)
      j.move_next
      expect(j.move_previous).to be false
    end

    it 'can seek based on timestamp' do
      j.seek(Time.parse('2013-03-28T21:07:21-04:00'))
      j.move_next

      entry = j.current_entry
      ts    = entry.realtime_timestamp

      expect(entry.message).to start_with('input: ImExPS/2')
      expect(ts.utc.iso8601).to eq('2013-03-29T01:07:21Z')
    end

    it 'throws an ArgumentError for other types' do
      expect { j.seek(5) }.to raise_error(ArgumentError)
    end
  end

  describe 'wait' do
    it 'returns nil if nothing happens' do
      expect(Systemd::Journal::Native)
        .to receive(:sd_journal_wait)
        .and_return(:nop)

      expect(j.wait(1)).to be nil
    end

    it 'returns :append if new entries are found' do
      expect(Systemd::Journal::Native)
        .to receive(:sd_journal_wait)
        .and_return(:append)

      expect(j.wait(1)).to be :append
    end

    it 'raise a JournalError on error' do
      expect(Systemd::Journal::Native)
        .to receive(:sd_journal_wait)
        .and_return(-1)

      expect { j.wait(1) }.to raise_error(Systemd::JournalError)
    end

    it 'can use select' do
      pending 'not available on JRUBY' if Systemd::Journal::IS_JRUBY
      expect(Systemd::Journal::Native).to_not receive(:sd_journal_wait)
      j.wait(1, select: true)
    end

    it 'ignores request to use select on JRuby' do
      pending 'not necessary on MRI' unless Systemd::Journal::IS_JRUBY
      expect(Systemd::Journal::Native).to receive(:sd_journal_wait)
      j.wait(1, select: true)
    end
  end

  describe 'wait_select_reliable?' do
    it 'should not throw an error' do
      expect { j.wait_select_reliable? }.to_not raise_error
    end

    it 'should return a boolean' do
      expect([true, false]).to include(j.wait_select_reliable?)
    end
  end

  describe 'message' do
    it 'escapes percent signs in messages' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_send)
        .with(:string, 'MESSAGE=hello %% world %%', :string, nil)
        .and_return(0)

      Systemd::Journal.message(message: 'hello % world %')
    end
  end

  describe 'print' do
    it 'escapes percent signs' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_print)
        .with(Systemd::Journal::LOG_DEBUG, 'hello %% world %%')
        .and_return(0)

      Systemd::Journal.print(Systemd::Journal::LOG_DEBUG, 'hello % world %')
    end
  end
end

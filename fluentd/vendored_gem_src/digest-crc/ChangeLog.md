### 0.5.1 / 2020-03-03

* Fixed XOR logic in {Digest::CRC16Genibus}.
* Freeze all `TABLE` constants.
* Added missing documentation.

### 0.5.0 / 2020-03-01

* Added {Digest::CRC15}.
* Added {Digest::CRC16Genibus}.
* Added {Digest::CRC16Kermit}.
* Added {Digest::CRC16X25}.
* Added {Digest::CRC32BZip2}.
* Added {Digest::CRC32Jam}.
* Added {Digest::CRC32POSIX}.
* Added {Digest::CRC32XFER}.
* Added {Digest::CRC64Jones}.
* Added {Digest::CRC64XZ}.
* Renamed `Digest::CRC32Mpeg` to {Digest::CRC32MPEG}.
* Renamed `Digest::CRC81Wire` to {Digest::CRC8_1Wire}.

### 0.4.2 / 2020-03-01

* Corrected the logic in {Digest::CRC32#update}.
* Added missing {Digest::CRC5.pack} method.
* Fixed a require in `digest/crc8_1wire.rb`.

### 0.4.1 / 2014-04-16

* Allow Digest CRC classes to be extended and their constants overriden.
* Allow {Digest::CRC5::CRC_MASK} to be overriden by subclasses.
* {Digest::CRC81Wire} now inherites from {Digest::CRC8}.

### 0.4.0 / 2013-02-13

* Added {Digest::CRC16QT}.

### 0.3.0 / 2011-09-24

* Added {Digest::CRC81Wire} (Henry Garner).

### 0.2.0 / 2011-05-10

* Added {Digest::CRC32c}.
* Opted into [test.rubygems.org](http://test.rubygems.org/)
* Switched from using Jeweler and Bundler, to using
  [Ore::Tasks](http://github.com/ruby-ore/ore-tasks).

### 0.1.0 / 2010-06-01

* Initial release.
  * CRC1
  * CRC5
  * CRC8
  * CRC16
  * CRC16 CCITT
  * CRC16 DNP
  * CRC16 Modbus
  * CRC16 USB
  * CRC16 XModem
  * CRC16 ZModem
  * CRC24
  * CRC32
  * CRC32 Mpeg
  * CRC64


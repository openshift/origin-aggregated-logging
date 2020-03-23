#History
----

0.1.2 (2018/11/22)
------------------
* parse_line(String) is now public. (Thanks to Satoshi "Moris" Tagomori <https://github.com/tagomoris>)
* README improved. (thanks to sasaki takeru <https://github.com/takeru>)
* Unexpected ArgumentError of LTSV.dump with the argument that contains the instance of the specific type. (thanks to Ryo Nakamura <https://github.com/r7kamura>)

0.1.0 (2013/02/12)
------------------
* parse(String) method now accepts multi-line string and returns an Array of Hash. for single line String, use the new parse_line method.

(Thanks to Masato Ikeda)

0.0.3 (2013/02/11)
------------------
* Added the specs for load() method.
* Fixed the bug when handling empty keys or values.

(Thanks to Aki Ariga <https://github.com/chezou>)

0.0.2 (2013/02/08)
------------------
Fixed a bug with :parse method for handling an IO argument. (Thanks to Naoto SINGAKI <https://github.com/naoto/>)

----

0.0.1 (2013/02/07)
------------------
Initial Release.

How to configure
================

To use liblognorm, you need 3 things.

1. An installed and working copy of liblognorm. The installation process 
   has been discussed in the chapter :doc:`installation`.
2. Log files.
3. A rulebase, which is heart of liblognorm configuration.

Log files
---------

A log file is a text file, which typically holds many lines. Each line is 
a log message. These are usually a bit strange to read, thus to analyze. 
This mostly happens, if you have a lot of different devices, that are all 
creating log messages in a different format. 

Rulebase
--------

The rulebase holds all the schemes for your logs. It basically consists of 
many lines that reflect the structure of your log messages. When the 
normalization process is started, a parse-tree will be generated from
the rulebase and put into the memory. This will then be used to parse the 
log messages.

Each line in rulebase file is evaluated separately.

Rulebase Versions
-----------------
This documentation is for liblognorm version 2 and above. Version 2 is a
complete rewrite of liblognorm which offers many enhanced features but
is incompatible to some pre-v2 rulebase commands. For details, see
compatiblity document.

Note that liblognorm v2 contains a full copy of the v1 engine. As such
it is fully compatible to old rulebases. In order to use the new v2
engine, you need to explicitely opt in. To do so, you need to add
the line::

    version=2

to the top of your rulebase file. Currently, it is very important that

 * the line is given exactly as above
 * no whitespace within the sequence is permitted (e.g. "version = 2"
   is invalid)
 * no whitepace or comment after the "2" is permitted
   (e.g. "version=2 # comment") is invalid
 * this line **must** be the **very** first line of the file; this
   also means there **must** not be any comment or empty lines in
   front of it

Only if the version indicator is properly detected, the v2 engine is
used. Otherwise, the v1 engine is used. So if you use v2 features but
got the version line wrong, you'll end up with error messages from the
v1 engine.

The v2 engine understands almost all v1 parsers, and most importantly all
that are typically used. It does not understand these parsers:

 * tokenized
 * recursive
 * descent
 * regex
 * interpret
 * suffixed
 * named_suffixed

The recursive and descent parsers should be replaced by user-defined types
in. The tokenized parsers should be replaced by repeat. The interpret functionality
is provided via the parser's "format" parameters. For the others,
currently there exists no replacement, but will the exception of regex,
will be added based on demand. If you think regex support is urgently
needed, please read our
`related issue on github, <https://github.com/rsyslog/liblognorm/issues/143>`_
where you can also cast
you ballot in favor of it. If you need any of these parsers, you need
to use the v1 engine. That of course means you cannot use the v2 enhancements,
so converting as much as possible makes sense.

Commentaries
------------

To keep your rulebase tidy, you can use commentaries. Start a commentary 
with "#" like in many other configurations. It should look like this::

    # The following prefix and rules are for firewall logs
    
Note that the comment character MUST be in the first column of the line.

Empty lines are just skipped, they can be inserted for readability.

User-Defined Types
------------------

If the line starts with ``type=``, then it contains a user-defined type.
You can use a user-defined type wherever you use a built-in type; they
are equivalent. That also means you can use user-defined types in the
definition of other user-defined types (they can be used recursively).
The only restriction is that you must define a type **before** you can
use it.

This line has following format::

    type=<typename>:<match description>

Everything before the colon is treated as the type name. User-defined types
must always start with "@". So "@mytype" is a valid name, whereas "mytype"
is invalid and will lead to an error.

After the colon, a match description should be
given. It is exactly the same like the one given in rule lines (see below).

A generic IP address type could look as follows::

    type=@IPaddr:%ip:ipv4%
    type=@IPaddr:%ip:ipv6%

This creates a type "@IPaddr", which consists of either an IPv4 or IPv6
address. Note how we use two different lines to create an alternative
representation. This is how things generally work with types: you can use
as many "type" lines for a single type as you need to define your object.
Note that pure alternatives could also be defined via the "alternative"
parser - which option to choose is left to the user. They are equivalent.
The ability to use multiple type lines for definition, however, brings
more power than just to define alternatives.

Includes
--------
Especially with user-defined types includes come handy. With an include,
you can include definitions already made elsewhere into the current
rule set (just like the "include" directive works in many programming
languages). An include is done by a line starting with ``include=``
where the rest of the line is the actual file name, just like in this
example::

   include=/var/lib/liblognorm/stdtypes.rb

The definition is included right at the position where it occurs.
Processing of the original file is continued when the included file
has been fully processed. Includes can be nested.

To facilitate repositories of common rules, liblognorm honors the

::

   LIBLOGNORM_RULEBASES

environment variable. If it is set liblognorm tries to locate the file
inside the path pointed to by ``LIBLOGNORM_RULEBASES`` in the following
case: 

* the provided file cannot be found
* the provided file name is not an absolute path (does not start with "/")

So assuming we have::

   export LIBLOGNORM_RULEBASES=/var/lib/loblognorm

The above example can be re-written as follows::

   include=stdtypes.rb

Note, however, that if ``stdtypes.rb`` exist in the current working
directory, that file will be loaded insted of the one from 
``/var/lib/liblognorm``.

This use facilitates building a library of standard type definitions. Note
the the liblognorm project also ships type definitions for common
scenarios.

Rules
-----

If the line starts with ``rule=``, then it contains a rule. This line has
following format::

    rule=[<tag1>[,<tag2>...]]:<match description>

Everything before a colon is treated as comma-separated list of tags, which
will be attached to a match. After the colon, match description should be
given. It consists of string literals and field selectors. String literals
should match exactly, whereas field selectors may match variable parts
of a message.

A rule could look like this (in legacy format)::

    rule=:%date:date-rfc3164% %host:word% %tag:char-to:\x3a%: no longer listening on %ip:ipv4%#%port:number%'

This excerpt is a common rule. A rule always contains several different 
"parts"/properties and reflects the structure of the message you want to 
normalize (e.g. Host, IP, Source, Syslogtag...).


Literals
--------

Literal is just a sequence of characters, which must match exactly. 
Percent sign characters must be escaped to prevent them from starting a 
field accidentally. Replace each "%" with "\\x25" or "%%", when it occurs
in a string literal.

Fields
------

There are different formats for field specification:

 * legacy format
 * condensed format
 * full json format

Legacy Format
#############
Legay format is exactly identical to the v1 engine. This permits you to use
existing v1 rulebases without any modification with the v2 engine, except for
adding the ``version=2`` header line to the top of the file. Remember: some
v1 types are not supported - if you are among the few who use them, you need
to do some manual conversion. For almost all users, manual conversion should
not be necessary.

Legacy format is not documented here. If you want to use it, see the v1
documentation.

Condensed Format
################
The goal of this format is to be as brief as possible, permitting you an
as-clear-as-possible view of your rule. It is very similar to legacy format
and recommended to be used for simple types which do not need any parser
parameters.

Its structure is as follows::

    %<field name>:<field type>[{<parameters>}]%

**field name** -> that name can be selected freely. It should be a description 
of what kind of information the field is holding, e.g. SRC is the field 
contains the source IP address of the message. These names should also be 
chosen carefully, since the field name can be used in every rule and 
therefore should fit for the same kind of information in different rules.

Some special field names exist:

* **dash** ("-"): this field is matched but not saved
* **dot** ("."): this is useful if a parser returns a set of fields. Usually,
  it does so by creating a json subtree. If the field is named ".", then
  no subtree is created but instead the subfields are moved into the main
  hierarchy.
* **two dots** (".."): similiar to ".", but can be used at the lower level to denote
  that a field is to be included with the name given by the upper-level
  object. Note that ".." is only acted on if a subelement contains a single
  field. The reason is that if there were more, we could not assign all of
  them to the *single* name given by the upper-level-object. The prime
  use case for this special name is in user-defined types that parse only
  a single value. Without "..", they would always become a JSON subtree, which
  seems unnatural and is different from built-in types. So it is suggested to
  name such fields as "..", which means that the user can assign a name of his
  liking, just like in the case of built-in parsers.

**field type** -> selects the accordant parser, which are described below.

Special characters that need to be escaped when used inside a field 
description are "%" and ":". It is strongly recommended **not** to use them.

**parameters** -> This is an optional set of parameters, given in pure JSON
format. Parameters can be generic (e.g. "priority") or specific to a
parser (e.g. "extradata"). Generic parameters are described below in their
own section, parser-specific ones in the relevant type documentation.

As an example, the "char-to" parser accepts a parameter named "extradata"
which describes up to which character it shall match (the name "extradata"
stems back to the legacy v1 system)::

	%tag:char-to{"extradata":":"}%

Whitespace, including LF, is permitted inside a field definition after
the opening precent sign and before the closing one. This can be used to
make complex rules more readable. So the example rule from the overview
section above could be rewritten as::

    rule=:%
          date:date-rfc3164
          % %
	  host:word
	  % %
	  tag:char-to{"extradata":":"}
	  %: no longer listening on %
	  ip:ipv4
	  %#%
	  port:number
	  %'

When doing this, note well that whitespace IS important inside the
literal text. So e.g. in the second example line above "% %" we require
a single SP as literal text. Note that any combination of your liking is
valid, so it could also be written as::

    rule=:%date:date-rfc3164% %host:word% % tag:char-to{"extradata":":"}
          %: no longer listening on %  ip:ipv4  %#%  port:number  %'

To prevent a typical user error, continuation lines are **not** permitted
to start with ``rule=``. There are some obscure cases where this could
be a valid rule, and it can be re-formatted in that case. Moreoften, this
is the result of a missing percent sign, as in this sample::

     rule=:test%field:word ... missing percent sign ...
     rule=:%f:word%

If we would permit ``rule=`` at start of continuation line, these kinds
of problems would be very hard to detect.

Full JSON Format
################
This format is best for complex definitions or if there are many parser
parameters.

Its structure is as follows::

    %JSON%

Where JSON is the configuration expressed in JSON. To get you started, let's
rewrite above sample in pure JSON form::

    rule=:%[ {"type":"date-rfc3164", "name":"date"},
             {"type":"literal", "text:" "},
             {"type":"char-to", "name":"host", "extradata":":"},
             {"type":"literal", "text:": no longer listening on "},
             {"type":"ipv4", "name":"ip"},
             {"type":"literal", "text:"#"},
             {"type":"number", "name":"port"}
            ]%

A couple of things to note:

 * we express everything in this example in a *single* parser definition
 * this is done by using a **JSON array**; whenever an array is used,
   multiple parsers can be specified. They are exectued one after the
   other in given order.
 * literal text is matched here via explicit parser call; as specified
   below, this is recommended only for specific use cases with the
   current version of liblognorm
 * parser parameters (both generic and parser-specific ones) are given
   on the main JSON level
 * the literal text shall not be stored inside an output variable; for
   this reason no name attribute is given (we could also have used
   ``"name":"-"`` which achives the same effect but is more verbose).

With the literal parser calls replaced by actual literals, the sample
looks like this::

    rule=:%{"type":"date-rfc3164", "name":"date"}
          % %
           {"type":"char-to", "name":"host", "extradata":":"}
	  % no longer listening on %
            {"type":"ipv4", "name":"ip"}
	  %#%
            {"type":"number", "name":"port"}
          %

Which format you use and how you exactly use it is up to you.

Some guidelines:

 * using the "literal" parser in JSON should be avoided currently; the
   experimental version does have some rough edges where conflicts
   in literal processing will not be properly handled. This should not
   be an issue in "closed environments", like "repeat", where no such
   conflict can occur.
 * otherwise, JSON is perfect for very complex things (like nesting of
   parsers - it is **not** suggested to use any other format for these
   kinds of things.
 * if a field needs to be matched but the result of that match is not
   needed, omit the "name" attribute; specifically avoid using
   the more verbose ``"name":"-"``.
 * it is a good idea to start each defintion with ``"type":"..."``
   as this provides a good quick overview over what is being defined.
 
Mandatory Parameters
....................

type
~~~~
The field type, selects the parser to use. See "fields" below for description.

Optional Generic Parameters
...........................

name
~~~~
The field name to use. If "-" is used, the field is matched, but not stored.
In this case, you can simply **not** specify a field name, which is the
preferred way of doing this.

priority
~~~~~~~~
The priority to assign to this parser. Priorities are numerical values in the
range from 0 (highest) to 65535 (lowest). If multiple parsers could match at
a given character position of a log line, parsers are tried in priority order.
Different priorities can lead to different parsing. For example, if the
greedy "rest" type is assigned priority 0, and no other parser is assigned the
same priority, no other parser will ever match (because "rest" is very greedy
and always matches the rest of the message).

Note that liblognorm internally
has a parser-specific priority, which is selected by the program developer based
on the specificallity of a type. If the user assigns equal priorities, parsers are
executed based on the parser-specific priority.

The default priority value is 30,000.

Field types
-----------
We have legacy and regular field types. Pre-v2, we did not have user-defined types.
As such, there was a relatively large number of parsers that handled very similar
cases, for example for strings. These parsers still work and may even provide
best performance in extreme cases. In v2, we focus on fewer, but more
generic parsers, which are then tailored via parameters.

There is nothing bad about using legacy parsers and there is no
plan to outphase them at any time in the future. We just wanted to
let you know, especially if you wonder about some "wereid" parsers.
In v1, parsers could have only a single paramter, which was called
"extradata" at that time. This is why some of the legacy parsers
require or support a parameter named "extradata" and do not use a
better name for it (internally, the legacy format creates a
v2 parser defintion with "extradata" being populated from the
legacy "extradata" part of the configuration).

number
######

One or more decimal digits.

Parameters
..........

format
~~~~~~

Specifies the format of the json object. Possible values are "string" and
"number", with string being the default. If "number" is used, the json
object will be a native json integer.

maxval
~~~~~~

Maximum value permitted for this number. If the value is higher than this,
it will not be detected by this parser definition and an alternate detection
path will be pursued.

float
#####

A floating-pt number represented in non-scientific form.

Parameters
..........

format
~~~~~~

Specifies the format of the json object. Possible values are "string" and
"number", with string being the default. If "number" is used, the json
object will be a native json floating point number. Note that we try to
preserve the original string serialization format, but keep on your mind
that floating point numbers are inherently imprecise, so slight variance
may occur depending on processing them.


hexnumber
#########

A hexadecimal number as seen by this parser begins with the string
"0x", is followed by 1 or more hex digits and is terminated by white
space. Any interleaving non-hex digits will cause non-detection. The
rules are strict to avoid false positives.

Parameters
..........

format
~~~~~~

Specifies the format of the json object. Possible values are "string" and
"number", with string being the default. If "number" is used, the json
object will be a native json integer. Note that json numbers are always
decimal, so if "number" is selected, the hex number will be converted
to decimal. The original hex string is no longer available in this case.

maxval
~~~~~~

Maximum value permitted for this number. If the value is higher than this,
it will not be detected by this parser definition and an alternate detection
path will be pursued. This is most useful if fixed-size hex numbers need to
be processed. For example, for byte values the "maxval" could be set to 255,
which ensures that invalid values are not misdetected.


kernel-timestamp
################

Parses a linux kernel timestamp, which has the format::

    [ddddd.dddddd]

where "d" is a decimal digit. The part before the period has to
have at least 5 digits as per kernel code. There is no upper
limit per se inside the kernel, but liblognorm does not accept
more than 12 digits, which seems more than sufficient (we may reduce
the max count if misdetections occur). The part after the period
has to have exactly 6 digits.


whitespace
##########

This parses all whitespace until the first non-whitespace character
is found. This check is performed using the ``isspace()`` C library
function to check for space, horizontal tab, newline, vertical tab,
feed and carriage return characters.

This parser is primarily a tool to skip to the next "word" if
the exact number of whitspace characters (and type of whitespace)
is not known. The current parsing position MUST be on a whitspace,
else the parser does not match.

Remeber that to just parse but not preserve the field contents, the
dash ("-") is used as field name in compact format or the "name" 
parameter is simply omitted in JSON format. This is almost always
expected with the *whitespace* type.

string
######

This is a highly customizable parser that can be used to extract
many types of strings. It is meant to be used for most cases. It
is suggested that specific string types are created as user-defined
types using this parser.

This parser supports:

* various quoting modes for strings
* escape character processing

Parameters
..........

quoting.mode
~~~~~~~~~~~~
Specifies how the string is quoted. Possible modes:

* **none** - no quoting is permitted
* **required** - quotes must be present
* **auto** - quotes are permitted, but not required

Default is ``auto``.

quoting.escape.mode
~~~~~~~~~~~~~~~~~~~

Specifies how quote character escaping is handled. Possible modes:

* **none** - there are no escapes, quote characters are *not* permitted in value
* **double** - the ending quote character is duplicated to indicate
  a single quote without termination of the value (e.g. ``""``)
* **backslash** - a backslash is prepended to the quote character (e.g ``\"``)
* **both** - both double and backslash escaping can happen and are supported

Note that turning on ``backslash`` mode (or ``both``) has the side-effect that
backslash escaping is enabled in general. This usually is what you want
if this option is selected (e.g. otherwise you could no longer represent
backslash).

quoting.char.begin
~~~~~~~~~~~~~~~~~~

Sets the begin quote character.

Default is ".

quoting.char.end
~~~~~~~~~~~~~~~~

Sets the end quote character.

Default is ".

Note that setting the begin and end quote character permits you to
support more quoting modes. For example, brackets and braces are
used by some software for quoting. To handle such string, you can for
example use a configuration like this::

   rule=:a %f:string{"quoting.char.begin":"[", "quoting.char.end":"]"}% b

which matches strings like this::

   a [test test2] b

matching.permitted
~~~~~~~~~~~~~~~~~~

This allows to specify a set of characters permitted in the to-be-parsed
field. It is primarily a utility to extract things like programming-language
like names (e.g. consisting of letters, digits and a set of special characters
only), alphanumeric or alphabetic strings.

If this parameter is not specified, all characters are permitted. If it
is specified, only the configured characters are permitted.

Note that this option reliably only works on US-ASCII data. Multi-byte
character encodings may lead to strange results.

There are two ways to specify permitted characters. The simple one is to
specify them directly for the parameter::

  rule=:%f:string{"matching.permitted":"abc"}%

This only supports literal characters and all must be given as a single
parameter. For more advanced use cases, an array of permitted characters
can be provided::

  rule=:%f:string{"matching.permitted":[
		       {"class":"digit"},
		       {"chars":"xX"}
                          ]}%

Here, ``class`` is a specify for the usual character classes, with
support for:

* digit
* hexdigit
* alpha
* alnum

In contrast, ``chars`` permits to specify literal characters. Both
``class`` as well as ``chars`` may be specified multiple times inside
the array. For example, the ``alnum`` class could also be permitted as
follows::

  rule=:%f:string{"matching.permitted":[
		       {"class":"digit"},
		       {"class":"alpha"}
                          ]}%

word
####

One or more characters, up to the next space (\\x20), or
up to end of line.

string-to
######### 

One or more characters, up to the next string given in
"extradata".

alpha
#####   

One or more alphabetic characters, up to the next whitspace, punctuation,
decimal digit or control character.

char-to
####### 

One or more characters, up to the next character(s) given in
extradata.

Parameters
..........

extradata
~~~~~~~~~

This is a mandatory parameter. It contains one or more characters, each of
which terminates the match.


char-sep
########

Zero or more characters, up to the next character(s) given in extradata.

Parameters
..........

extradata
~~~~~~~~~~

This is a mandatory parameter. It contains one or more characters, each of
which terminates the match.

rest
####

Zero or more characters untill end of line. Must always be at end of the 
rule, even though this condition is currently **not** checked. In any case,
any definitions after *rest* are ignored.

Note that the *rest* syntax should be avoided because it generates
a very broad match. If it needs to be used, the user shall assign it
the lowest priority among his parser definitions. Note that the
parser-sepcific priority is also lowest, so by default it will only
match if nothing else matches.

quoted-string
#############   

Zero or more characters, surrounded by double quote marks.
Quote marks are stripped from the match.

op-quoted-string
################   

Zero or more characters, possibly surrounded by double quote marks.
If the first character is a quote mark, operates like quoted-string. Otherwise, operates like "word"
Quote marks are stripped from the match.

date-iso
########    
Date in ISO format ('YYYY-MM-DD').

time-24hr
#########   

Time of format 'HH:MM:SS', where HH is 00..23.

time-12hr
#########   

Time of format 'HH:MM:SS', where HH is 00..12.

duration
########   

A duration is similar to a timestamp, except that
it tells about time elapsed. As such, hours can be larger than 23
and hours may also be specified by a single digit (this, for example,
is commonly done in Cisco software).

Examples for durations are "12:05:01", "0:00:01" and "37:59:59" but not
"00:60:00" (HH and MM must still be within the usual range for
minutes and seconds).


date-rfc3164
############

Valid date/time in RFC3164 format, i.e.: 'Oct 29 09:47:08'.
This parser implements several quirks to match malformed
timestamps from some devices.

Parameters
..........

format
~~~~~~

Specifies the format of the json object. Possible values are

- **string** - string representation as given in input data
- **timestamp-unix** - string converted to an unix timestamp (seconds since epoch)
- **timestamp-unix-ms** - a kind of unix-timestamp, but with millisecond resolution.
  This format is understood for example by ElasticSearch. Note that RFC3164 does **not**
  contain subsecond resolution, so this option makes no sense for RFC3164-data only.
  It is usefull, howerver, if processing mixed sources, some of which contain higher
  precision.


date-rfc5424
############

Valid date/time in RFC5424 format, i.e.:
'1985-04-12T19:20:50.52-04:00'.
Slightly different formats are allowed.

Parameters
..........

format
~~~~~~

Specifies the format of the json object. Possible values are

- **string** - string representation as given in input data
- **timestamp-unix** - string converted to an unix timestamp (seconds since epoch).
  If subsecond resolution is given in the original timestamp, it is lost.
- **timestamp-unix-ms** - a kind of unix-timestamp, but with millisecond resolution.
  This format is understood for example by ElasticSearch. Note that a RFC5424
  timestamp can contain higher than ms resolution. If so, the timestamp is
  truncated to millisecond resolution.



ipv4
####

IPv4 address, in dot-decimal notation (AAA.BBB.CCC.DDD).

ipv6
####

IPv6 address, in textual notation as specified in RFC4291.
All formats specified in section 2.2 are supported, including
embedded IPv4 address (e.g. "::13.1.68.3"). Note that a 
**pure** IPv4 address ("13.1.68.3") is **not** valid and as
such not recognized.

To avoid false positives, there must be either a whitespace
character after the IPv6 address or the end of string must be
reached.

mac48
#####

The standard (IEEE 802) format for printing MAC-48 addresses in
human-friendly form is six groups of two hexadecimal digits,
separated by hyphens (-) or colons (:), in transmission order
(e.g. 01-23-45-67-89-ab or 01:23:45:67:89:ab ).
This form is also commonly used for EUI-64.
from: http://en.wikipedia.org/wiki/MAC_address

cef
###

This parses ArcSight Comment Event Format (CEF) as described in 
the "Implementing ArcSight CEF" manual revision 20 (2013-06-15).

It matches a format that closely follows the spec. The header fields
are extracted into the field name container, all extension are
extracted into a container called "Extensions" beneath it.

Example
.......

Rule (compact format)::

    rule=:%f:cef'

Data::

    CEF:0|Vendor|Product|Version|Signature ID|some name|Severity| aa=field1 bb=this is a value cc=field 3

Result::

    {
      "f": {
        "DeviceVendor": "Vendor",
        "DeviceProduct": "Product",
        "DeviceVersion": "Version",
        "SignatureID": "Signature ID",
        "Name": "some name",
        "Severity": "Severity",
        "Extensions": {
          "aa": "field1",
          "bb": "this is a value",
          "cc": "field 3"
        }
      }
    }

checkpoint-lea
##############

This supports the LEA on-disk format. Unfortunately, the format
is underdocumented, the Checkpoint docs we could get hold of just
describe the API and provide a field dictionary. In a nutshell, what
we do is extract field names up to the colon and values up to the
semicolon. No escaping rules are known to us, so we assume none
exists (and as such no semicolon can be part of a value).

If someone has a definitive reference or a sample set to contribute
to the project, please let us know and we will check if we need to
add additional transformations.


cisco-interface-spec
####################

A Cisco interface specifier, as for example seen in PIX or ASA.
The format contains a number of optional parts and is described
as follows (in ABNF-like manner where square brackets indicate
optional parts):

::

  [interface:]ip/port [SP (ip2/port2)] [[SP](username)]

Samples for such a spec are:

 * outside:192.168.52.102/50349
 * inside:192.168.1.15/56543 (192.168.1.112/54543)
 * outside:192.168.1.13/50179 (192.168.1.13/50179)(LOCAL\some.user)
 * outside:192.168.1.25/41850(LOCAL\RG-867G8-DEL88D879BBFFC8) 
 * inside:192.168.1.25/53 (192.168.1.25/53) (some.user)
 * 192.168.1.15/0(LOCAL\RG-867G8-DEL88D879BBFFC8)

Note that the current verision of liblognorm does not permit sole
IP addresses to be detected as a Cisco interface spec. However, we
are reviewing more Cisco message and need to decide if this is
to be supported. The problem here is that this would create a much
broader parser which would potentially match many things that are
**not** Cisco interface specs.

As this object extracts multiple subelements, it create a JSON
structure. 

Let's for example look at this definiton (compact format)::

    %ifaddr:cisco-interface-spec%

and assume the following message is to be parsed::

 outside:192.168.1.13/50179 (192.168.1.13/50179) (LOCAL\some.user)

Then the resulting JSON will be as follows::

{ "ifaddr": { "interface": "outside", "ip": "192.168.1.13", "port": "50179", "ip2": "192.168.1.13", "port2": "50179", "user": "LOCAL\\some.user" } }

Subcomponents that are not given in the to-be-normalized string are
also not present in the resulting JSON.

iptables
########    

Name=value pairs, separated by spaces, as in Netfilter log messages.
Name of the selector is not used; names from the line are 
used instead. This selector always matches everything till 
end of the line. Cannot match zero characters.

cisco-interface-spec
####################

This is an experimental parser. It is used to detect Cisco Interface
Specifications. A sample of them is:

::

   outside:176.97.252.102/50349

Note that this parser does not yet extract the individual parts
due to the restrictions in current liblognorm. This is planned for
after a general algorithm overhaul.

In order to match, this syntax must start on a non-whitespace char
other than colon.

json
####
This parses native JSON from the message. All data up to the first non-JSON
is parsed into the field. There may be any other field after the JSON,
including another JSON section.

Note that any white space after the actual JSON
is considered **to be part of the JSON**. So you cannot filter on whitespace
after the JSON.

Example
.......

Rule (compact format)::

    rule=:%field1:json%interim text %field2:json%'

Data::

   {"f1": "1"} interim text {"f2": 2}

Result::

   { "field2": { "f2": 2 }, "field1": { "f1": "1" } }

Note also that the space before "interim" must **not** be given in the
rule, as it is consumed by the JSON parser. However, the space after
"text" is required.

alternative
###########

This type permits to specify alternative ways of parsing within a single
definition. This can make writing rule bases easier. It also permits the
v2 engine to create a more efficient parsing data structure resulting in
better performance (to be noticed only in extreme cases, though).

An example explains this parser best::

    rule=:a %
            {"type":"alternative",
	     "parser": [
	                {"name":"num", "type":"number"},
			{"name":"hex", "type":"hexnumber"}
		       ]
	    }% b

This rule matches messages like these::

   a 1234 b
   a 0xff b

Note that the "parser" parameter here needs to be provided with an array
of *alternatives*. In this case, the JSON array is **not** interpreted as
a sequence. Note, though that you can nest defintions by using custom types.
 
repeat
######
This parser is used to extract a repeated sequence with the same pattern.

An example explains this parser best::

    rule=:a %
            {"name":"numbers", "type":"repeat",
                "parser":[
                           {"type":"number", "name":"n1"},
                           {"type":"literal", "text":":"},
	                   {"type":"number", "name":"n2"}
	                 ],
	        "while":[
	                   {"type":"literal", "text":", "}
	                ]
             }% b

This matches lines like this::
    
    a 1:2, 3:4, 5:6, 7:8 b

and will generate this JSON::

    { "numbers": [
                   { "n2": "2", "n1": "1" },
		   { "n2": "4", "n1": "3" },
		   { "n2": "6", "n1": "5" },
		   { "n2": "8", "n1": "7" }
		 ]
    }

As can be seen, there are two parameters to "alternative". The parser
parameter specifies which type should be repeatedly parsed out of
the input data. We could use a single parser for that, but in the example
above we parse a sequence. Note the nested array in the "parser" parameter.

If we just wanted to match a single list of numbers like::

    a 1, 2, 3, 4 b

we could use this definition::

    rule=:a %
            {"name":"numbers", "type":"repeat",
                "parser":
                         {"type":"number", "name":"n"},
	        "while":
	                 {"type":"literal", "text":", "}
             }% b

Note that in this example we also removed the redundant single-element
array in "while".

The "while" parameter tells "repeat" how long to do repeat processing. It
is specified by any parser, including a nested sequence of parser (array).
As long as the "while" part matches, the repetition is continued. If it no
longer matches, "repeat" processing is successfully completed. Note that
the "parser" parameter **must** match at least once, otherwise "repeat"
fails.

In the above sample, "while" mismatches after "4", because no ", " follows.
Then, the parser termiantes, and according to definition the literal " b"
is matched, which will result in a successful rule match (note: the "a ",
" b" literals are just here for explanatory purposes and could be any
other rule element).

Sometimes we need to deal with malformed messages. For example, we
could have a sequence like this::

    a 1:2, 3:4,5:6, 7:8 b

Note the missing space after "4,". To handle such cases, we can nest the
"alternative" parser inside "while"::

    rule=:a %
            {"name":"numbers", "type":"repeat",
                "parser":[
                           {"type":"number", "name":"n1"},
                           {"type":"literal", "text":":"},
	                   {"type":"number", "name":"n2"}
	                 ],
                "while": {
                            "type":"alternative", "parser": [
                                    {"type":"literal", "text":", "},
                                    {"type":"literal", "text":","}
                             ]
                         }
             }% b

This definition handles numbers being delemited by either ", " or ",".

For people with programming skills, the "repeat" parser is described
by this pseudocode::

    do
        parse via parsers given in "parser"
	if parsing fails
	    abort "repeat" unsuccessful
	parse via parsers given in "while"
    while the "while" parsers parsed successfully
    if not aborted, flag "repeat" as successful

Parameters
..........

option.permitMismatchInParser
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
If set to "True", permits repeat to accept as successful even when
the parser processing failed. This by default is false, and can be
set to true to cover some border cases, where the while part cannot
definitely detect the end of processing. An example of such a border
case is a listing of flags, being terminated by a double space where
each flag is delimited by single spaces. For example, Cisco products
generate such messages (note the flags part)::

    Aug 18 13:18:45 192.168.0.1 %ASA-6-106015: Deny TCP (no connection) from 10.252.88.66/443 to 10.79.249.222/52746 flags RST  on interface outside

cee-syslog
##########
This parses cee syslog from the message. This format has been defined
by Mitre CEE as well as Project Lumberjack.

This format essentially is JSON with additional restrictions:

 * The message must start with "@cee:"
 * an JSON **object** must immediately follow (whitespace before it permitted,
   but a JSON array is **not** permitted)
 * after the JSON, there must be no other non-whitespace characters.

In other words: the message must consist of a single JSON object only, 
prefixed by the "@cee:" cookie.

Note that the cee cookie is case sensitive, so "@CEE:" is **NOT** valid.

Prefixes
--------

Several rules can have a common prefix. You can set it once with this 
syntax::

    prefix=<prefix match description>
    
Prefix match description syntax is the same as rule match description. 
Every following rule will be treated as an addition to this prefix.

Prefix can be reset to default (empty value) by the line::

    prefix=

You can define a prefix for devices that produce the same header in each 
message. We assume, that you have your rules sorted by device. In such a 
case you can take the header of the rules and use it with the prefix 
variable. Here is a example of a rule for IPTables (legacy format, to be converted later)::

    prefix=%date:date-rfc3164% %host:word% %tag:char-to:-\x3a%:
    rule=:INBOUND%INBOUND:char-to:-\x3a%: IN=%IN:word% PHYSIN=%PHYSIN:word% OUT=%OUT:word% PHYSOUT=%PHYSOUT:word% SRC=%source:ipv4% DST=%destination:ipv4% LEN=%LEN:number% TOS=%TOS:char-to: % PREC=%PREC:word% TTL=%TTL:number% ID=%ID:number% DF PROTO=%PROTO:word% SPT=%SPT:number% DPT=%DPT:number% WINDOW=%WINDOW:number% RES=0x00 ACK SYN URGP=%URGP:number%

Usually, every rule would hold what is defined in the prefix at its 
beginning. But since we can define the prefix, we can save that work in 
every line and just make the rules for the log lines. This saves us a lot 
of work and even saves space.

In a rulebase you can use multiple prefixes obviously. The prefix will be 
used for the following rules. If then another prefix is set, the first one 
will be erased, and new one will be used for the following rules.

Rule tags
---------

Rule tagging capability permits very easy classification of syslog 
messages and log records in general. So you can not only extract data from 
your various log source, you can also classify events, for example, as 
being a "login", a "logout" or a firewall "denied access". This makes it 
very easy to look at specific subsets of messages and process them in ways 
specific to the information being conveyed. 

To see how it works, let’s first define what a tag is:

A tag is a simple alphanumeric string that identifies a specific type of 
object, action, status, etc. For example, we can have object tags for 
firewalls and servers. For simplicity, let’s call them "firewall" and 
"server". Then, we can have action tags like "login", "logout" and 
"connectionOpen". Status tags could include "success" or "fail", among 
others. Tags form a flat space, there is no inherent relationship between 
them (but this may be added later on top of the current implementation). 
Think of tags like the tag cloud in a blogging system. Tags can be defined 
for any reason and need. A single event can be associated with as many 
tags as required. 

Assigning tags to messages is simple. A rule contains both the sample of 
the message (including the extracted fields) as well as the tags. 
Have a look at this sample::

    rule=:sshd[%pid:number%]: Invalid user %user:word% from %src-ip:ipv4%

Here, we have a rule that shows an invalid ssh login request. The various 
fields are used to extract information into a well-defined structure. Have 
you ever wondered why every rule starts with a colon? Now, here is the 
answer: the colon separates the tag part from the actual sample part. 
Now, you can create a rule like this::

    rule=ssh,user,login,fail:sshd[%pid:number%]: Invalid user %user:word% from %src-ip:ipv4%

Note the "ssh,user,login,fail" part in front of the colon. These are the 
four tags the user has decided to assign to this event. What now happens 
is that the normalizer does not only extract the information from the 
message if it finds a match, but it also adds the tags as metadata. Once 
normalization is done, one can not only query the individual fields, but 
also query if a specific tag is associated with this event. For example, 
to find all ssh-related events (provided the rules are built that way), 
you can normalize a large log and select only that subset of the 
normalized log that contains the tag "ssh".

Log annotations
---------------

In short, annotations allow to add arbitrary attributes to a parsed
message, depending on rule tags. Values of these attributes are fixed,
they cannot be derived from variable fields. Syntax is as following::

    annotate=<tag>:+<field name>="<field value>"

Field value should always be enclosed in double quote marks.

There can be multiple annotations for the same tag.

Examples
--------

Look at :doc:`sample rulebase <sample_rulebase>` for configuration 
examples and matching log lines. Note that the examples are currently
in legacy format, only.

# Systemd::Journal [![Gem Version](https://badge.fury.io/rb/systemd-journal.png)](http://badge.fury.io/rb/systemd-journal) [![Code Climate](https://codeclimate.com/github/ledbettj/systemd-journal.png)](https://codeclimate.com/github/ledbettj/systemd-journal)

Ruby bindings for reading from the systemd journal.

* [gem documentation](http://rubydoc.info/gems/systemd-journal)
* [libsystemd-journal documentation](http://www.freedesktop.org/software/systemd/man/sd-journal.html)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'systemd-journal', '~> 1.4'
```

And then execute:

```sh
bundle install
```

If you have trust issues, fear not:

```sh
wget https://raw.githubusercontent.com/ledbettj/systemd-journal/master/certs/john@throttle.io.pem
gem cert --add john@throttle.io.pem
```

You can then verify the signature at install time with either `gem` or `bundler`:

```sh
gem install systemd-journal -P HighSecurity
bundle install --trust-policy HighSecurity
```

## Dependencies

Obviously you will need to have
[systemd](http://www.freedesktop.org/wiki/Software/systemd/) installed on your
system (specifically libsystemd or the older libsystemd-journal) in order to
use the gem.  Currently we support systemd 208 or higher.

## Usage

```ruby
require 'systemd/journal'
```

Print all messages as they occur:

```ruby
Systemd::Journal.open do |j|
  j.seek(:tail)
  j.move_previous
  
  # watch() does not return
  j.watch do |entry|
    puts entry.message
  end
end
```

Filter events and iterate:

```ruby
j = Systemd::Journal.new

# only display entries from SSHD with priority 6.
j.filter(priority: 6, _exe: '/usr/bin/sshd')
j.each do |entry|
  puts entry.message
end
j.close # close open files
```

Moving around the journal:

```ruby
j = Systemd::Journal.new

j.seek(:head)   # move to the start of journal
j.move(10)      # move forward by 10 entries
c = j.cursor    # get a reference to this entry
j.move(-5)      # move back 5 entries
j.seek(c)       # move to the saved cursor
j.cursor?(c)    # verify that we're at the correct entry
j.seek(:tail)   # move past the end of the journal
j.move_previous # move to last entry in journal
j.move_next     # move forward (fails since we're at the end)

j.current_entry # get the entry we're currently positioned at

# seek the entry that occured closest to this time
j.seek(Time.parse('2013-10-31T12:00:00+04:00:00'))
```

Waiting for things to happen:

```ruby
j = Systemd::Journal.new
j.seek(:tail)
j.move_previous
# wait up to one second for something to happen
puts 'something changed!' if j.wait(1_000_000)
  
# same as above, but can be interrupted with Control+C.
puts 'something changed!' if j.wait(1_000_000, select: true)
```

Accessing the catalog:

```ruby
j = Systemd::Journal.new
j.move_next
j.move_next until j.current_entry.catalog?

puts j.current_entry.catalog
# or if you have a message id:
puts Systemd::Journal.catalog_for(j.current_entry.message_id)
```

Writing to the journal:

```ruby
# write a simple message
Systemd::Journal.print(Systemd::Journal::LOG_INFO, 'Something happened')

# write custom fields
Systemd::Journal.message(
  message: 'Something bad happened',
  priority: Systemd::Journal::LOG_ERR,
  my_custom_field: 'foo was nil!'
)
```

See the documentation for more examples.

## Troubleshooting

### I get 'Cannot assign requested address' when trying to read an entry!

After calling one of the below, the Journal read pointer might not point at
a valid entry:

    Journal#filter
    Journal#clear_filters
    Journal#seek(:head)
    Journal#seek(:tail)

The solution is to always call one of `move`, `move_next`, `move_previous` and
friends before reading after issuing one of the above calls.  For most functions,
call `move_next`.  For `seek(:tail)`, call `move_previous`.

### I get a segfault pointing at Native.sd_journal_get_fd

This is caused by a bug in libsystemd v245 (and maybe earlier) which cannot be
solved in this gem, sadly.  It's fixed upstream in [this commit](https://github.com/systemd/systemd/commit/2b6df46d21abe8a8b7481e420588a9a129699cf9), which you can ask your distribution to backport if
necessary until v246 is released.

In ArchLinux, this patch is applied in systemd-libs 245.6-2.

## Issues?

This gem has been tested primarily on MRI and Arch Linux running systemd version
208 and up.  Please let me know if you have issues with other versions or
distributions.

The gem will run under JRuby, although some features which rely on native file
descriptor support will not work.

The gem will not run under truffleruby due to missing support for some FFI features.

If you run into problems or have questions, please open an
[Issue](https://github.com/ledbettj/systemd-journal/issues) or Pull Request.

## Pull Requests

1. Fork it
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create new Pull Request, targeting the __master__ branch.
6. Wipe hands on pants, you're done!

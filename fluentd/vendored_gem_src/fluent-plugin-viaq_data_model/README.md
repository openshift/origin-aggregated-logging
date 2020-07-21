# fluent-plugin-viaq_data_model - a ViaQ data model filter plugin for [Fluentd](http://fluentd.org)

[![Travis CI](https://secure.travis-ci.org/ViaQ/fluent-plugin-viaq_data_model.png)](http://travis-ci.org/#!/ViaQ/fluent-plugin-viaq_data_model)

## Introduction

This plugin formats Fluentd records in the proper [ViaQ data
model](https://github.com/ViaQ/elasticsearch-templates).  It does the
following:

* Removes empty fields
  * fields with a value of `nil`
  * string fields with a value of `''` or the empty string
  * hash valued fields with a value of `{}`
  * hash valued fields which contain only empty fields as described above
  * FixNum, Boolean and other field values are not removed - type must respond
    to `:empty?` to be considered empty

* Has multiple ways to handle "undefined" fields - that is - fields that
  are not listed in `default_keep_fields` or in `extra_keep_fields`
  * If `use_undefined true`, then undefined top level fields are moved
    to a top level field called `undefined`
  * If `undefined_to_string true`, then the values of undefined top level
    fields are converted to their JSON string representation
  * If `undefined_dot_replace_char` is set to a string value, then top
    level fields with a `'.'` in the field name will have the `'.'` changed
    to a `'_'` (by default - replace char is configurable)
  * If `undefined_max_num_fields` is a number greater than `-1`, and if the
    number of undefined fields is greater than this number, all of the
    undefined fields will be converted to their JSON string representation
    and stored in the `undefined_name` named field.

The ViaQ data model wants all top level fields defined and described.  These
can conflict with the fields defined by ViaQ.  You can "move" these fields to
be under a hash valued top level field called `undefined` so as not to conflict
with the "well known" ViaQ top level fields.  You can optionally keep some
fields as top level fields while moving others to the `undefined` container by
adding those fields to the `extra_keep_fields` list.

* Rename a time field to `@timestamp`

You cannot set the `@timestamp` field in a Fluentd `record_transformer` filter.
The plugin allows you to use some other field e.g. `time` and have that "moved"
to a top level field called `@timestamp`.

* Converts systemd and json-file logs to ViaQ data model format

Doing this conversion in a `record_transformer` with embedded ruby code is very
resource intensive.  The ViaQ plugin can convert common input formats such as
Kubernetes `json-file`, `/var/log/messages`, and systemd `journald` into their
corresponding ViaQ `_default_`, `systemd`, `kubernetes`, and
`pipeline_metadata` namespaced fields.  The `pipeline_metadata` will be added
to all records, regardless of tag.  Use the `pipeline_type` parameter to
specify which part of the pipeline this is, `collector` or `normalizer`.
The ViaQ data model conversion will only be applied to matching `tag`s
specified in a `formatter` section.

* Creates Elasticsearch index names or prefixes

You can create either a full Elasticsearch index name for the record (to be
used with the `fluent-plugin-elasticsearch` `target_index_key` parameter), or
create an index name prefix (missing the date/timestamp part of the index
name - to be used with `logstash_prefix_key`).  In order to use this, create an
`elasticsearch_index_name` section, and specify the `tag` to match, and the
`name_type` type of index name to create.  By default, a prefix name will be
stored in the `viaq_index_prefix` field in the record, and a full name will be
stored in the `viaq_index_name` field.  Configure
`elasticsearch_index_name_field` or `elasticsearch_index_prefix_field` to use a
different field name.

## Configuration

NOTE: All fields are Optional - no required fields.

See `filter-viaq_data_model.conf` for an example filter configuration.

* `default_keep_fields` - comma delimited string - default: `''`
  * This is the default list of fields to keep as top level fields in the record
  * `default_keep_fields message,@timestamp,ident` - do not move these fields into the `undefined` field
  * The default list of fields comes from the list of top level fields defined in the
    ViaQ [elasticsearch templates](https://github.com/ViaQ/elasticsearch-templates) - see below for an example of how to extract
    those fields to set the default value for `default_keep_fields`
* `extra_keep_fields` - comma delimited string - default: `''`
  * This is an extra list of fields to keep in addition to
  `default_keep_fields` - mostly useful as a way to hard code the
  `default_keep_fields` list for configuration management purposes, but at the
  same time allow customization in certain cases
  * `extra_keep_fields myspecialfield1,myspecialfield2`
* `keep_empty_fields` - comma delimited string - default `''`
  * Always keep these top level fields, even if they are empty
  * `keep_empty_fields message` - keep the `message` field, even if empty
* `process_kubernetes_events` - boolean - default `true`
  * If a record looks like a kubernetes event that has been added by the
  * eventrouter, add its fields under `kubernetes.event`
  * A record is considered to be a kubernetes eventrouter event if the
  * record has a top level field called `event` and it is a Hash.  If you
  * are not sure if this is always true, then define a specific tag or tags
  * and use a per-formatter `process_kubernetes_events` setting, below
* `use_undefined` - boolean - default `false`
  * If `true`, move fields not specified in `default_keep_fields` and
  `extra_keep_fields` to the `undefined` top level field.  If you use
  `use_undefined` you should specify the fields you want to keep out of
  `undefined` by using `default_keep_fields` and/or `extra_keep_fields`
* `undefined_name` - string - default `"undefined"`
  * Name of undefined top level field to use if `use_undefined true` is set
  * `undefined_name myfields` - keep undefined fields under field `myfields`
* `undefined_to_string` - boolean - default `false`
  * normalize undefined values to be string valued - see below
* `undefined_dot_replace_char` - string - default `UNUSED`
  * If an undefined field name has a `'.'` dot character in it, replace the dot
    with the replace char e.g. convert `"foo.bar"` to `"foo_bar"` - see below
  * Use the value `UNUSED` if you do not want to do any replacement - this is
    not recommended
* `undefined_max_num_fields` - integer - default `-1`
  * If the number of undefined fields exceeds the value of `undefined_max_num_fields`,
    then convert the hash of undefined fields to its JSON string representation,
    and store the values in the `undefined_name` field - see below
  * Use a value of `-1` if you want to have an unlimited number of undefined
    fields (not recommended)
  * Using `undefined_max_num_fields` implies that you want to use `undefined_name`
    as the name of the field to store the value, even if `use_undefined` is not
    set - if you want to use a different field name than `"undefined"` then set
    `undefined_name`
* `rename_time` - boolean - default `true`
  * Rename the time field e.g. when you need to set `@timestamp` in the record
  * NOTE: This will overwrite the `dest_time_name` if already set
* `rename_time_if_missing` - boolean - default `false`
  * Rename the time field only if it is not present.  For example, if some
  records already have the `@timestamp` field and you do not want to overwrite
  them, use `rename_time_if_missing true`
* `src_time_name` - string - default `time`
  * Use this field to get the value of the time field in the resulting record.
    This field will be removed from the record.
  * NOTE: This field must be present in the `default_keep_fields` or
  `extra_keep_fields` if `use_undefined true`
* `dest_time_name` - string - default `@timestamp`
  * This is the name of the top level field to hold the time value.  The value
  is taken from the value of the `src_time_name` field.
* `formatter` - a formatter for a well known common data model source
  * `enabled` - default `true` - is this formatter enabled?  **NOTE** if the
    formatter is disabled, it will still match, it just won't do anything, and
    it will skip the other formatters.
  * `type` - one of the well known sources
    * `sys_journal` - a record read from the systemd journal
    * `k8s_journal` - a Kubernetes container record read from the systemd
      journal - should have `CONTAINER_NAME`, `CONTAINER_ID_FULL`
    * `sys_var_log` - a record read from `/var/log/messages`
    * `k8s_json_file` - a record read from a `/var/log/containers/*.log` JSON
      formatted container log file
  * `tag` - the Fluentd tag pattern to match for these records
  * `remove_keys` - comma delimited list of keys to remove from the record
  * `process_kubernetes_events` - boolean - defaults to the global setting above
    * If a record looks like a kubernetes event that has been added by the
    * eventrouter, add its fields under `kubernetes.event`
    * A record is considered to be a kubernetes eventrouter event if the
    * record has a top level field called `event` and it is a Hash.
    * This per-formatter setting will override the global setting (see above)
    * This allows you to set the global setting to `false`, then only process
    * kubernetes events for this formatter matching this set of `tag` patterns.
* `pipeline_type` - which part of the pipeline is this? `collector` or
  `normalizer` - the default is `collector`
* `elasticsearch_index_name` - how to construct Elasticsearch index names or
  prefixes for given tags
  * `enabled` - default `true` - is this item enabled?  **NOTE** if the
    item is disabled, it will still match, it just won't do anything, and
    it will skip the other index name items.
  * `tag` - the Fluentd tag pattern to match for these records
  * `name_type` - the well known type of index name or prefix to create -
    `operations_full, project_full, operations_prefix, project_prefix` - The
    `operations_*` types will create a name like `.operations`, and the
    `project_*` types will create a name like
    `project.record['kubernetes']['namespace_name'].record['kubernetes']['namespace_id']`.
    When using the `full` types, a delimiter `.` followed by the date in
    `YYYY.MM.DD` format will be added to the string to make a full index name.
    When using the `prefix` types, it is assumed that the
    `fluent-plugin-elaticsearch` is used with the `logstash_prefix_key` to
    create the full index name.
* `elasticsearch_index_name_field` - name of the field in the record which stores
  the index name - you should remove this field in the elasticsearch output
  plugin using the `remove_keys` config parameter - default is `viaq_index_name`
* `elasticsearch_index_prefix_field` - name of the field in the record which stores
  the index prefix - you should remove this field in the elasticsearch output
  plugin using the `remove_keys` config parameter - default is `viaq_index_prefix`

**NOTE** The `formatter` blocks are matched in the given order in the file.
  This means, don't use `tag "**"` as the first formatter or none of your
  others will be matched or evaulated.

**NOTE** The `elasticsearch_index_name` processing is done *last*, *after* the
  formatting, removal of empty fields, `@timestamp` creation, etc., so use
  e.g. `record['systemd']['t']['GID']` instead of `record['_GID']`

**NOTE** The `elasticsearch_index_name` blocks are matched in the given order
  in the file.  This means, don't use `tag "**"` as the first formatter or none
  of your others will be matched or evaulated.

## How to get fields for `default_keep_fields`

If you have [elasticsearch templates](https://github.com/ViaQ/elasticsearch-templates) cloned locally in
`../elasticsearch-templates`:

    python -c 'import sys,yaml
    uniquefields = {}
    for ff in sys.argv[1:]:
      hsh = yaml.load(open(ff))
      print hsh
      if 0 < ff.find("_default_.yml"):
        # default is a special case
        for ent in hsh["_default_"]["fields"]:
          fieldname = ent["name"]
          uniquefields[fieldname] = fieldname
      else:
        fieldname = hsh.get("namespace")
        if fieldname:
          fieldname = hsh["namespace"]["name"]
          uniquefields[fieldname] = fieldname
        else:
          fieldname = hsh.keys()[0]
          uniquefields[fieldname] = fieldname
    print ",".join(sorted(uniquefields.keys()))
    ' $( find ../elasticsearch-templates/namespaces -name \*.yml )

## `undefined_to_string`

One of the problems with storing data in Elasticsearch is that it really
requires you to have strict control over the fields and the number of fields
being stored.  You typically have to define a strict input pipeline for
formatting the data, and define index templates to specify the type of data.
If you are dealing with unstructured data, you run into the risk that you have
a field named `fieldname` which in some records has a `string` value, but in
other documents may have an `int` value or a value of some other data type.
To mitigate this situation, the viaq plugin will convert unknown fields to their
JSON string representation.  For example, if you have the following configuration:

    undefined_to_string true

and you get a record that looks like this:

    {
      "message":"my message",
      "stringfield":"this is a string",
      "status":404,
      "compositefield":{"a":"b"},
      "anarray":[1, 2, 3]
    }

The end result would look like this:

    {
      "message":"my message",
      "stringfield":"this is a string",
      "status":"404",
      "compositefield":"{\"a\":\"b\"}",
      "anarray":"[1, 2, 3]"
    }

That is, the value of any unknown fields will be converted to their JSON string
representation.

## `undefined_dot_replace_char`

Another problem with storing data in Elasticsearch is that it will interpret
a field name like `"foo.bar"` to mean a Hash (Object type in Elasticsearch)
with a structure like this:

    {
      "foo":{
        "bar":"value"
      }
    }

This causes problems if the application emits logs with a string valued field `"foo"`,
_and_ a hash valued field `"foo.bar"`.  The only way to automatically solve this problem is by
converting `"foo.bar"` to be `"foo_bar"`, and using `undefined_to_string true` to convert both
values to string.

### OK, but I really want to store "foo.bar" as a Hash/Object

Since there is no automatic way to do this, it is the responsibility of _you_, the user, to

* create your own Elasticsearch index templates and index patterns for your fields
  * see [elasticsearch templates](https://github.com/ViaQ/elasticsearch-templates/)
  * see [custom index templates](https://github.com/richm/docs/releases/tag/20180904175002)
  * see also the Elasticsearch docs
* create your own custom Fluend `record_transformer` filter to restructure the record
  to conform to your schema
* add your custom fields to `extra_keep_fields` so that the ViaQ filter will not touch them

## `undefined_max_num_fields`

Another problem with storing data in Elasticsearch is that there is an upper limit to
the number of fields it can store without causing performance problems.  Viaq uses
`undefined_max_num_fields` to set an upper bound on the number of undefined fields in a single
record.  If the record contains more than `undefined_max_num_fields` undefined fields, no
further processing will take place on these fields.  Instead, the fields will be converted
to a single string JSON value, and will be stored in a top level field named with the value
of the `undefined_name` parameter (default `"undefined"`).  The default value is `1000` undefined
fields.  For example, if you have a record which looks like this:

    {
      "field1":"value1",
      ...
      "field10001":"value10001"
    }

where there are 10001 fields, the plugin by default will convert this to look something like this:

    {
      "undefined":"{\"field1\":\"value1\",...,\"field10001\":\"value10001\"}"
    }

You can still use Elasticsearch to search for the values, but you will need to use a complex query/filter
string.  The alternative is not being able to use Elasticsearch at all, or clobbering the performance
of Elasticsearch.

## Example - default values - undefined_to_string false

If the input record looks like this:

    {
      "a": "b",
      "c": "d",
      "e": '',
      "f": {
        "g": '',
        "h": {}
      },
      "i": {
        "j": 0,
        "k": False,
        "l": ''
      },
      "time": "2017-02-13 15:30:10.259106596-07:00"
    }

The resulting record, using the defaults, would look like this:

    {
      "a": "b",
      "c": "d",
      "i": {
        "j": 0,
        "k": False,
      },
      "@timestamp": "2017-02-13 15:30:10.259106596-07:00"
    }

## Formatter example

Given a record like the following with a tag of `journal.system`

    __REALTIME_TIMESTAMP=1502228121310282
    __MONOTONIC_TIMESTAMP=722903835100
    _BOOT_ID=d85e8a9d524c4a419bcfb6598db78524
    _TRANSPORT=syslog
    PRIORITY=6
    SYSLOG_FACILITY=3
    SYSLOG_IDENTIFIER=dnsmasq-dhcp
    SYSLOG_PID=2289
    _PID=2289
    _UID=99
    _GID=40
    _COMM=dnsmasq
    _EXE=/usr/sbin/dnsmasq
    _CMDLINE=/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper
    _CAP_EFFECTIVE=3400
    _SYSTEMD_CGROUP=/system.slice/libvirtd.service
    MESSASGE=my message

Using a configuration like this:

    <formatter>
      tag "journal.system**"
      type sys_journal
      remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
    </formatter>

The resulting record will look like this:

    {
    "systemd": {
      "t": {
        "BOOT_ID":"d85e8a9d524c4a419bcfb6598db78524",
        "GID":40,
        ...
      },
      "u": {
        "SYSLOG_FACILITY":3,
        "SYSLOG_IDENTIFIER":"dnsmasq-dhcp",
        ...
      },
    "message":"my message",
    ...
    }

## Elasticsearch index name example

Given a configuration like this:

    <elasticsearch_index_name>
      tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
      name_type operations_full
    </elasticsearch_index_name>
    <elasticsearch_index_name>
      tag "**"
      name_type project_full
    </elasticsearch_index_name>

A record with tag `journal.system` like this:

    {
      "@timestamp":"2017-07-27T17:27:46.216527+00:00"
    }

will end up looking like this:

    {
      "@timestamp":"2017-07-27T17:27:46.216527+00:00",
      "viaq_index_name":".operations.2017.07.07"
    }

A record with tag `kubernetes.journal.container` like this:

    {
      "@timestamp":"2017-07-27T17:27:46.216527+00:00",
      "kubernetes":{"namespace_name":"myproject","namespace_id":"000000"}
    }

will end up looking like this:

    {
      "@timestamp":"2017-07-27T17:27:46.216527+00:00",
      "kubernetes":{"namespace_name":"myproject","namespace_id":"000000"}
      "viaq_index_name":"project.myproject.000000.2017.07.07"
    }

### Note about using enabled false

Given a configuration like this:

    <elasticsearch_index_name>
      enabled false
      tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
      name_type operations_full
    </elasticsearch_index_name>
    <elasticsearch_index_name>
      tag "**"
      name_type project_full
    </elasticsearch_index_name>

A record with tag `journal.system` like this:

    {
      "@timestamp":"2017-07-27T17:27:46.216527+00:00"
    }

will end up looking like this:

    {
      "@timestamp":"2017-07-27T17:27:46.216527+00:00",
    }

That is, the tag will match the first `elasticsearch_index_name`, but since it
is disabled, no index name will be created, and it will _not_ fall through to
the `**` match below.  Using `enabled false` in this case allows you to not
generate index names for operations indices, but still continue to generate
index names for project indices.

A record with tag `kubernetes.journal.container` like this:

    {
      "@timestamp":"2017-07-27T17:27:46.216527+00:00",
      "kubernetes":{"namespace_name":"myproject","namespace_id":"000000"}
    }

will end up looking like this:

    {
      "@timestamp":"2017-07-27T17:27:46.216527+00:00",
      "kubernetes":{"namespace_name":"myproject","namespace_id":"000000"}
      "viaq_index_name":"project.myproject.000000.2017.07.07"
    }

## Installation

    gem install fluent-plugin-viaq_data_model

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Test it (`GEM_HOME=vendor bundle install; GEM_HOME=vendor bundle exec rake test`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

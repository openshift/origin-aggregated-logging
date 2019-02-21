# Fluent::Mixin::ConfigPlaceholders

Fluent::Mixin::ConfigPlaceHolders provide some placeholders to fluentd plugins that includes this mix-in. Placeholders below are expanded in 'super' of including plugin's #configure method.

Placeholder patterns are `${..}` and `__XXX__`. With optional setting in plugin code, `%{...}` is available.

Available placeholders are:

* hostname (${hostname}, %{hostname} or \_\_HOSTNAME\_\_)
  * you can specify hostname string explicitly on 'hostname' parameter
* random uuid (${uuid}, ${uuid:random}, %{uuid}, %{uuid:random}, \_\_UUID\_\_ or \_\_UUID\_RANDOM\_\_)
* hostname string based uuid (${uuid:hostname}, %{uuid:hostname} or \_\_UUID\_HOSTNAME\_\_)
* timestamp based uuid (${uuid:timestamp} %{uuid:timestamp} or \_\_UUID\_TIMESTAMP\_\_)

## Usage

In plugin (both of input and output), just include mixin.

    class FooInput < Fluent::Input
      Fluent::Plugin.register_input('foo', self)
    
      config_param :tag, :string
      
      include Fluent::Mixin::ConfigPlaceholders
    
      def configure(conf)
        super # MUST call 'super' at first!
        
        @tag #=> here, you can get string replaced '${hostname}' into actual hostname
      end
      
      # ...
    end

You can use this feature for tags for each fluentd node, paths for remote storage services like /root/${hostname}/access_log or non-race-condition paths like /files/${uuid:random}.

### Plugin setting

Plugin can determine which placeholders are enabled in their configurations, like this:

    class FooInput < Fluent::Input
      # ....
      
      # instance method #placeholders should return array of symbols
      
      def placeholders
        [:dollar, :percent, :underscore]
      end
      
      # default is [:dollar, :underscore]
      
      include Fluent::Mixin::ConfigPlaceholders
      
      # ....
    end

## AUTHORS

* TAGOMORI Satoshi <tagomoris@gmail.com>
* Contributors
  * [@ijin](https://twitter.com/ijin) (Michael H. Oshita)

## LICENSE

* Copyright: Copyright (c) 2012- tagomoris
* License: Apache License, Version 2.0

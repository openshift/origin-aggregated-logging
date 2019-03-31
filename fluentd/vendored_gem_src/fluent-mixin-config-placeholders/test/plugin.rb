class Fluent::ConfigPlaceholdersTestXInput < Fluent::Input
  Fluent::Plugin.register_input('config_placeholder_test_x', self)

  attr_accessor :conf
  def configure(conf)
    super

    @conf = conf
  end
end

class Fluent::ConfigPlaceholdersTestDefaultInput < Fluent::Input
  Fluent::Plugin.register_input('config_placeholder_test_1', self)

  config_param :tag, :string
  config_param :path, :string

  include Fluent::Mixin::ConfigPlaceholders
end

class Fluent::ConfigPlaceholdersTest0Input < Fluent::Input
  Fluent::Plugin.register_input('config_placeholder_test_0', self)

  config_param :tag, :string
  config_param :path, :string

  attr_accessor :conf

  def configure(conf)
    super

    @conf = conf
  end
end

class Fluent::ConfigPlaceholdersTest1Input < Fluent::Input
  Fluent::Plugin.register_input('config_placeholder_test_1', self)

  config_param :tag, :string
  config_param :path, :string

  def placeholders; [:dollar, :percent, :underscore]; end
  include Fluent::Mixin::ConfigPlaceholders
end

class Fluent::ConfigPlaceholdersTest2Input < Fluent::Input
  Fluent::Plugin.register_input('config_placeholder_test_2', self)

  config_param :tag, :string
  config_param :path, :string

  include Fluent::Mixin::ConfigPlaceholders

  attr_accessor :conf

  def placeholders; [:dollar, :percent, :underscore]; end
  def configure(conf)
    super

    @path.upcase!

    @conf = conf
  end
end

class Fluent::ConfigPlaceholdersTest3Input < Fluent::Input
  Fluent::Plugin.register_input('config_placeholder_test_2', self)

  config_param :hostname, :string
  config_param :attr1, :string

  include Fluent::Mixin::ConfigPlaceholders

  attr_accessor :conf

  def placeholders; [:dollar, :percent, :underscore]; end
  def configure(conf)
    super
    @conf = conf
  end
end

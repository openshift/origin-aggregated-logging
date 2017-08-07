module OpenshiftWorld

  def create_world
    @world = OpenshiftWorldImpl.new
  end

  def world
    @world
  end

end

class OpenshiftWorldImpl

  include ElasticsearchHelpers
  include KibanaHelpers
  include FileHelpers
  include ResourceHelpers

  attr_reader :token
  attr_reader :oc
  attr_accessor :namespace
  attr_accessor :master_url
  attr_reader :context

  def initialize
    @oc = OpenshiftCliWrapper::OC.new
    @context = {}
  end

  def browser
      if @browser.nil?
        caps = Selenium::WebDriver::Remote::Capabilities.firefox
        caps['acceptInsecureCerts'] = true
        driver = Selenium::WebDriver.for(:firefox, desired_capabilities: caps)
        @browser = Watir::Browser.new(driver)
        at_exit { @browser.quit() }
      end
      @browser
  end

  def browser?
    !@browser.nil?
  end

  def logger
    OpenshiftCliWrapper::LOGGER
  end

  def login(username: 'admin', password: 'password')
    @oc.login(master_url)
       .username(username)
       .password(password)
       .do()
    @token = @oc.whoami()
       .show_token()
       .do()
    key = username == 'admin' ? :admin_user : :user
    @context[key] = {username: username, token: @token}
  end

  def admin_user(key: :admin_user)
      @context[key]
  end

  def grant_cluster_admin_to(user)
      @oc.add_cluster_role_to_user('cluster-admin', user).do()
  end

  def grant_admin_to(user, namespace)
      @oc.add_role_to_user('admin', user).namespace(namespace).token(admin_user.token).do()
  end

  def operations_role?
      context.has_key?(:role) && 'operations' == context[:role]
  end

  def es_pod(selector: 'logging-infra=elasticsearch', token: nil)
      pod(selector: selector, token: token).items.find{|i|i.status.phase == 'Running'}
  end

  def kibana_pod(selector: 'logging-infra=kibana', token: nil)
      pod(selector: selector, token: token).items.find{|i|i.status.phase == 'Running'}
  end

end


World(OpenshiftWorld, LoopHelpers)

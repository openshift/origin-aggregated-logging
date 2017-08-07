
describe OpenshiftCliWrapper::OC do

  MASTER_URL='https://someplace:8443'

  module MockRunner
      def execute(cmd)
          @cmd = cmd
          @output
      end

      attr_reader :cmd
      attr_writer :success
      attr_writer :output

      def success?
          @success
      end
      
  end
  
  def init_oc
      @oc = OpenshiftCliWrapper::OC.new
      class << @oc
          include  MockRunner
      end
      @oc.success = true
  end

  before(:each) do
      init_oc
  end
    
  context 'when #get' do

    before(:each) do
        @oc.output = %{
apiVersion: v1
items: []
kind: List
metadata: {}
resourceVersion: ""
selfLink: ""
}
    end

    it 'should make get cmd with the proper args' do
        @oc.get(:pods, 'foo').output('yaml').do()
        expect(@oc.cmd()).to eql("oc get pods foo --output=yaml")
    end

    it 'should make the yaml output walkable' do
        expect(@oc.get(:pods).output('yaml').do().kind).to eq("List")
    end

    it 'should make the json output walkable' do
        @oc.output = %{
{ 
  "apiVersion" : "v1",
  "items" : [],
  "kind" : "List",
  "metadata" : {},
  "resourceVersion" : "",
  "selfLink" : ""
}
       }
        expect(@oc.get(:pods).output('json').do().kind).to eq("List")
    end

  end

  context 'when #login' do

    before(:each) do
        @oc.login(MASTER_URL)
    end

    it 'should make login cmd with the proper args' do
        @oc.login(MASTER_URL)
           .username('admin')
           .password('password')
           .do()
        expect(@oc.cmd()).to eql("oc login #{MASTER_URL} --insecure-skip-tls-verify --username=admin --password=password") 
    end

    it 'throws an error when username is not specified' do
        expect { @oc.password('foobar').do() }.to raise_error(OpenshiftCliWrapper::Errors::AuthorizationError)
    end

    it 'throws an error when password is not specified' do
        expect { @oc.username('foobar').do() }.to raise_error(OpenshiftCliWrapper::Errors::AuthorizationError)
    end

  end
end

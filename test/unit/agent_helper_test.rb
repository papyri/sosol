require 'test_helper'
require 'agent_helper'

class AgentHelperTest < ActiveSupport::TestCase
  
  context "agent tests" do
    setup do
    end
    
    teardown do
    end

    should 'send to srophe agent' do
      agent = AgentHelper::agent_of("http://syriaca.org/place/1000.xml")
      assert_not_nil agent
      agent_client = AgentHelper::get_client(agent)
      request_data  = File.read(File.join(File.dirname(__FILE__), 'data', 'srophe_request.xml'))
      response = agent_client.post_content(request_data)
      assert_match "<TEI", response
    end
  end
end

require_relative 'spec_helper'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  before do
    @nodes = mock('Oxidized::Nodes')
    app.set(:nodes, @nodes)
  end

  describe '/node/fetch/' do
    it 'gets the latest configuration of a node' do
      @nodes.expects(:fetch).with('sw42', nil).returns('Configuration of sw42')

      get '/node/fetch/sw42'
      _(last_response.ok?).must_equal true
      _(last_response.body).must_equal 'Configuration of sw42'
    end

    it 'gets the configuration of a node when a group is given' do
      @nodes.expects(:fetch).with('sw42', 'mygroup').returns('Configuration of sw42')

      get '/node/fetch/mygroup/sw42'
      _(last_response.ok?).must_equal true
      _(last_response.body).must_equal 'Configuration of sw42'
    end

    it 'gets the configuration of a node when a group contains /' do
      @nodes.expects(:fetch).with('sw42', 'my/group').returns('Configuration of sw42')

      get '/node/fetch/my/group/sw42'
      _(last_response.ok?).must_equal true
      _(last_response.body).must_equal 'Configuration of sw42'
    end

    it 'displays an error when the node is not found' do
      @nodes.expects(:fetch).raises(Oxidized::NodeNotFound, 'unable to find \'sw12\'')

      get '/node/fetch/sw12'
      _(last_response.ok?).must_equal true
      _(last_response.body).must_equal 'unable to find \'sw12\''
    end
  end

  describe '/node/next/' do
    it 'marks a node to be reloaded, then redirects to /nodes' do
      # Don't know why the method has been called Nodes#next...
      # This is for reloading the node configuration
      @nodes.expects(:next).with('sw42')
      get '/node/next/sw42'

      _(last_response.redirect?).must_equal true
      _(last_response.location).must_equal 'http://example.org/nodes'
    end

    it 'returns ok when requiring json' do
      @nodes.expects(:next).with('sw42')
      get '/node/next/sw42.json'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_equal '["ok"]'
    end

    # Don't know if this feature is used by anyone...
    it 'attaches user/email/message to the commit when using put and json' do
      data = {
        'user' => 'me',
        'email' => 'me@example.com',
        'message' => 'minitest, rack/test & mock simply rock',
        'from' => 'unused variable!'
      }
      @nodes.expects(:next).with('sw42', data)

      put '/node/next/sw42.json', data.to_json, "CONTENT_TYPE" => "application/json"

      _(last_response.ok?).must_equal true
      _(last_response.body).must_equal '["ok"]'
    end

    it 'attaches data to the commit when using a group and put, then redirects' do
      data = {
        'user' => 'me',
        'email' => 'me@example.com',
        'message' => 'minitest, rack/test & mock simply rock',
        'from' => 'unused variable!'
      }
      @nodes.expects(:next).with('sw42', data)

      put '/node/next/mygroup/sw42', data.to_json, "CONTENT_TYPE" => "application/json"

      _(last_response.redirect?).must_equal true
      _(last_response.location).must_equal 'http://example.org/nodes'
    end
  end
end

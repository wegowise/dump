RSpec.describe Dumpster do
  include Rack::Test::Methods

  let(:app) { Dumpster }

  describe 'GET /' do
    it 'renders successfully when nothing has been recorded yet' do
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).to eq <<-EOS.strip
        <p>What can I dump for you today?</p><div><a href='/stats'>Daily deadlock stats</a></div>
      EOS
    end

    it 'lists records in reverse chronological order' do
      create_dump(id: 0, key: 'foo', body: 'foo', created_at: Time.at(0))
      create_dump(id: 1, key: 'bar', body: 'bar', created_at: Time.at(60))
      create_dump(id: 2, key: 'baz', body: 'baz', created_at: Time.at(120))

      get '/'
      expect_last_response(
        "<p>What can I dump for you today?</p>",
        "<div><a href='/stats'>Daily deadlock stats</a></div>",
        "<a href='/dumps/2/body'>Fixture for baz</a> created on 1969-12-31 18:02:00 -0600<br/>",
        "<a href='/dumps/1/body'>Fixture for bar</a> created on 1969-12-31 18:01:00 -0600<br/>",
        "<a href='/dumps/0/body'>Fixture for foo</a> created on 1969-12-31 18:00:00 -0600"
      )
    end
  end

  describe 'GET /stats' do
    before do
      create_dump(id: 1, key: 'not counted', body: 'random html nonsense')
      1.upto(42) do |i|
        str = i.to_s
        create_dump(id: 661035 + i, key: str, body: str)
      end
    end

    it 'renders the stats as HTML for all dumps above key 661035' do
      get '/stats'
      expect_last_response(
        "<h1>Daily deadlock statistics</h1> ",
        "<table>",
        "<thead><th>Date</th><th>Count</th></thead>",
        "<tbody>",
        "<tr>",
        "<td>#{Date.today.strftime('%Y-%m-%d')}</td>",
        "<td>42</td>",
        "</tr>",
        "</tbody>",
        "</table>"
      )
    end

    it 'renders the stats as JSON for all dumps above key 661035' do
      get '/stats.json'
      expect_last_response(JSON.dump([[Date.today.strftime('%Y-%m-%d'), 42]]))
    end
  end

  describe 'GET /dumps/ID/body' do
    it 'returns the body of a specific record' do
      create_dump(id: 42, key: 'test key', body: 'test body')
      get '/dumps/42/body'
      expect(last_response).to be_ok
      expect(last_response.body).to eq 'test body'
    end

    it 'renders an error if the record does not exist' do
      get '/dumps/42/body'
      expect(last_response).to_not be_ok
      expect(last_response.body).to eq '<h1>Not Found</h1>'
    end
  end

  describe 'POST /dump' do
    it 'records a new dump with all params, responds with the new URL' do
      expect(Dump.count).to eq 0

      post '/dump', key: 'foo', body: 'bar'

      expect(Dump.count).to eq 1
      dump = Dump.first
      expect(dump.key).to eq 'foo'
      expect(dump.body).to eq 'bar'

      expect(last_response).to be_ok
      expect(last_response.body).to match %r{http://example.org/dumps/\d+/body}
    end

    it 'only records params that are allowed' do
      expect { post '/dump', key: 'foo', body: 'bar', id: 42 }
        .to raise_error Sequel::Error
    end
  end

  def create_dump(params = {})
    # Allow records to be created with specific primary keys in specs
    Dump.unrestrict_primary_key
    Dump.create(params)
    Dump.restrict_primary_key
  end

  def expect_last_response(*segments)
    expect(last_response.body).to eq(segments.join)
  end
end

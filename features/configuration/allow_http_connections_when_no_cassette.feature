Feature: allow_http_connections_when_no_cassette configuration option

  Usually, HTTP requests made when no cassette is inserted will result
  in an error (see cassettes/no_cassette.feature).  You can set the
  `allow_http_connections_when_no_cassette` configuration option to
  true to allow requests, if you do not want to use VCR for everything.

  Background:
    Given a file named "vcr_setup.rb" with:
      """
      require 'vcr_cucumber_helpers'

      if ARGV.include?('--with-server')
        start_sinatra_app(:port => 7777) do
          get('/') { "Hello" }
        end
      end

      require 'vcr'

      VCR.config do |c|
        c.allow_http_connections_when_no_cassette = true
        c.stub_with :fakeweb
        c.cassette_library_dir = 'cassettes'
      end
      """
    And the directory "vcr/cassettes" does not exist

  Scenario: Allow HTTP connections when no cassette
    Given a file named "no_cassette.rb" with:
      """
      require 'vcr_setup.rb'

      puts "Response: " + Net::HTTP.get_response('localhost', '/', 7777).body
      """
    When I run "ruby no_cassette.rb --with-server"
    Then the output should contain "Response: Hello"

  Scenario: Cassettes record and replay as normal
    Given a file named "record_replay_cassette.rb" with:
      """
      require 'vcr_setup.rb'

      VCR.use_cassette('localhost', :record => :new_episodes) do
        puts "Response: " + Net::HTTP.get_response('localhost', '/', 7777).body
      end
      """
    When I run "ruby record_replay_cassette.rb --with-server"
    Then the output should contain "Response: Hello"
    And the file "cassettes/localhost.yml" should contain "body: Hello"

    When I run "ruby record_replay_cassette.rb"
    Then the output should contain "Response: Hello"


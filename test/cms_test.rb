ENV["RACK_ENV"] = "test"
# assigning environment variable to "test" to let Sinatra and Rack
# know if the code is being tested and whether or not to start a web server.
# We dont want to start a web server while testing.

require "minitest/autorun"
require "rack/test"
# this is loading Minitest, and configuring it to
# automatically run any defined tests.
# "rack/test" loads `Rack::Test` helper methods

require_relative "../cms"
# we require access to our application file to be
# able to run tests on it.

class CMSTest < Minitest::Test
# our definded CMS class inherits behaviours from `Minitest::Test`

include Rack::Test::Methods
# we are mixing in helper methods for testing from Rack.

  def app
    Sinatra::Application
  end
  # Rack test methods expect an `app` method that returns
  # an instance of a Rack application.
  
  def test_index
    
    get "/"
    assert_equal 200, last_response.status
    # `last_response` gives us access to an instance of
    # `Rack::MockResponse`, which is more or less a simulation
    # of a response from a server. The simulation gives us
    # `status`, `body`, and `[]` methods for accessing the simulations
    # status code, body, and headers.
    
  end
  
  def test_filename
    
    get "/:filename"
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end
  
  def test_viewing_text_document
    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "Ruby 0.95 released"
  end
  

end
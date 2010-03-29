require 'test_helper'

class SessionControllerTest < ActionController::TestCase
  def setup
    @controller = SessionControllerTest.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
end

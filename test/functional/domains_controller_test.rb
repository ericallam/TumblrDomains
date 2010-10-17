require 'test_helper'

class DomainsControllerTest < ActionController::TestCase
  test "should get check_availability" do
    get :check_availability
    assert_response :success
  end

end

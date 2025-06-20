require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  def sign_in(user)
    visit sign_in_url
    fill_in "pin", with: user.pin
    click_on "Sign In"
  end
end

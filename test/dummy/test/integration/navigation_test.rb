# frozen_string_literal: true

require 'test_helper'

class NavigationTest < ActionDispatch::IntegrationTest
  test 'Do I see the import create page?' do
    Account.create(name: 'Test')
    get '/imports/accounts/new'
    assert_response :success
    assert_select 'button', 'Import'
  end
end

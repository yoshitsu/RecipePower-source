ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
# require "minitest/rails/capybara"
# require "mocha/mini_test"
# include Warden::Test::Helpers
# Warden.test_mode!
# gem 'minitest'
# require 'warden_test_helper.rb'
# require 'minitest/reporters'
# MiniTest::Reporters.use!

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  include FactoryGirl::Syntax::Methods
  fixtures :all

  # Add more helper methods to be used by all tests here...

end

=begin
class ApplicationController
  include Devise::TestHelpers
end
=end
class ActionDispatch::IntegrationTest
  # For devise authentication helpers
  include Warden::Test::Helpers
  Warden.test_mode!
end

=begin
class ActionController::TestCase
  include Devise::TestHelpers
  # For devise authentication helpers
  # include Warden::Test::Helpers
  # Warden.test_mode!
end
=end

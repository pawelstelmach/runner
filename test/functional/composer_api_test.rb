require File.dirname(__FILE__) + '/../test_helper'
require 'composer_controller'

class ComposerController; def rescue_action(e) raise e end; end

class ComposerControllerApiTest < Test::Unit::TestCase
  def setup
    @controller = ComposerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
end

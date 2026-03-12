module Api
  class BaseController < ApplicationController
    include ApiAuthentication
    skip_before_action :verify_authenticity_token
  end
end

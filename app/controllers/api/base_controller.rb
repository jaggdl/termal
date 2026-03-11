module Api
  class BaseController < ApplicationController
    include ApiAuthentication
  end
end

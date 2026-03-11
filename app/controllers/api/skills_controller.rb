module Api
  class SkillsController < ApplicationController
    allow_unauthenticated_access

    def show
      response.headers["Content-Type"] = "text/markdown"
      render formats: :md
    end
  end
end

module Api
  class SkillsController < ApplicationController
    allow_unauthenticated_access

    def show
      response.headers["Content-Type"] = "text/markdown"
      render formats: :md
    end

    def script
      response.headers["Content-Type"] = "text/plain"
      response.headers["Content-Disposition"] = 'inline; filename="termal-api"'
      render template: "api/skills/script", formats: [ :text ]
    end
  end
end

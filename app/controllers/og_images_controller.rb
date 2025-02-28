class OgImagesController < ApplicationController
  allow_unauthenticated_access
  include ActionView::Helpers::AssetUrlHelper

  def meal
    @meal = Meal.find(params[:id])

    respond_to do |format|
      format.html do
        # For HTML preview, just render the HTML template
        render layout: false
      end

      format.png do
        # First, render the HTML template to a string
        html = render_to_string(action: :meal, formats: [ :html ], layout: false)

        # Then convert the HTML to an image using IMGKit
        img_kit = IMGKit.new(html, width: 1200, height: 630, quality: 90)

        # Set content type and caching headers
        response.headers["Content-Type"] = "image/png"
        response.headers["Cache-Control"] = "public, max-age=86400"

        # Send the image data
        send_data img_kit.to_png, type: "image/png", disposition: "inline"
      end
    end
  end
end

module ApplicationHelper
  SIZE_CLASSES = {
    small: "w-16 h-16 object-cover bg-gray-200",
    medium: "absolute inset-0 w-full h-full object-cover bg-gray-200"
  }

  def meal_image_tag(meal, size: :medium)
    if meal.image.attached?
      image_tag meal.image.variant(resize_to_limit: [ 256, 256 ]), class: SIZE_CLASSES[size]
    else
      render partial: "shared/meal_placeholder", locals: { size: size }
    end
  end

  def main_nutrients
    [ "calories", "proteins", "fats", "carbs" ]
  end



  def markdown(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      filter_html: false,
      link_attributes: { target: "_blank" }
    )

    markdown = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      highlight: true
    )

    markdown.render(text).html_safe
  end
end

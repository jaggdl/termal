module ApplicationHelper
  SIZE_CLASSES = {
    small: "w-16 h-16 object-cover bg-gray-200 dark:bg-gray-700 aspect-square",
    medium: "absolute inset-0 w-full h-full object-cover bg-gray-200 dark:bg-gray-700"
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

  def nav_link_classes(is_active)
    base_classes = "transition-colors duration-200"
    active_classes = "font-bold text-xl text-black dark:text-dark-text"
    inactive_classes = "text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200"

    "#{base_classes} #{is_active ? active_classes : inactive_classes}"
  end

  def nav_icon_classes(is_active)
    base_classes = "h-6 w-6 transition-colors duration-200"
    active_classes = "text-sky-500 dark:text-dark-primary"
    inactive_classes = "text-gray-500 dark:text-gray-400"

    "#{base_classes} #{is_active ? active_classes : inactive_classes}"
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

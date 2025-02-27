module ApplicationHelper
  def meal_image_tag(meal, size: :medium)
    if meal.image.attached?
      case size
      when :small
        image_tag meal.image.variant(resize_to_limit: [ 256, 256 ]),
          class: "md:max-w-16 md:max-h-16 md:min-w-16 md:min-h-16 min-w-16 min-h-16 max-w-16 max-h-16 object-cover bg-gray-200"
      when :medium
        image_tag meal.image.variant(resize_to_limit: [ 256, 256 ]),
          class: "absolute inset-0 w-full h-full object-cover bg-gray-200"
      end
    else
      # Return placeholder based on size
      case size
      when :small
        render partial: "shared/meal_placeholder", locals: { size: :small }
      when :medium
        render partial: "shared/meal_placeholder", locals: { size: :medium }
      end
    end
  end
end

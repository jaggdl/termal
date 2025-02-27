module NutritionHelper
  def get_status_color(nutrient, percentage)
    if nutrient == "proteins"
      percentage < 90 ? "text-amber-500" : "text-green-500"
    else
      if percentage > 110
        "text-red-500"
      elsif percentage < 90
        "text-amber-500"
      else
        "text-green-500"
      end
    end
  end
end

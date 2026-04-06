module VectorSearchable
  extend ActiveSupport::Concern

  def vector_search_meal_ids(query:, start_date:, end_date:, distance_threshold: 0.7)
    return [] if query.blank?

    query_embedding = QueryEmbedding.find_or_create_embedding(query)
    embedding = query_embedding.embedding

    user_meal_ids = user_meals_in_date_range(start_date, end_date).pluck(:meal_id).uniq
    return [] if user_meal_ids.empty?

    vector_sql = <<~SQL
      SELECT meal_id, distance
      FROM meal_vectors
      WHERE embedding MATCH ? AND k = ?
    SQL

    vector_results = MealVector.find_by_sql([
      vector_sql,
      embedding.to_s,
      [ user_meal_ids.length, 100 ].max
    ])

    vector_results
      .select { |vr| user_meal_ids.include?(vr.meal_id) && vr.distance <= distance_threshold }
      .map(&:meal_id)
  end

  def matching_meals_by_query(query:, start_date:, end_date:)
    return [] if query.blank?

    meal_ids = vector_search_meal_ids(query: query, start_date: start_date, end_date: end_date)
    return [] if meal_ids.empty?

    Meal
      .joins(:user_meals)
      .where(user_meals: { user_id: id, consumed_at: start_date.beginning_of_day..end_date.end_of_day })
      .where(id: meal_ids)
      .select("meals.*, COUNT(user_meals.id) as consumption_count")
      .group("meals.id")
      .order("consumption_count DESC, meals.meal_name ASC")
  end
end

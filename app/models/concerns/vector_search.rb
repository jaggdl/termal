module VectorSearch
  extend ActiveSupport::Concern

  included do
    has_one :meal_vector, foreign_key: "meal_id"
    after_save :update_vector_embedding
    attr_accessor :combined_score
  end

  def content_for_embedding
    "#{meal_name} #{description}"
  end

  def update_vector_embedding
    find_or_create_meal_vector
  end

  def find_or_create_meal_vector
    return unless meal_name.present?

    MealVector.find_or_create_by!(meal_id: id) do |vector|
      vector.embedding = Embedding.create(content_for_embedding).embedding
    end
  end

  class_methods do
    def interaction_score_sql
      time_decay = "((CAST(strftime('%s', 'now') AS REAL) - CAST(strftime('%s', user_meals.consumed_at) AS REAL)) / 86400.0)"
      hour_diff = "MIN(ABS(CAST(strftime('%H', 'now') AS INTEGER) - CAST(strftime('%H', user_meals.consumed_at) AS INTEGER)), 24 - ABS(CAST(strftime('%H', 'now') AS INTEGER) - CAST(strftime('%H', user_meals.consumed_at) AS INTEGER)))"
      "SUM(exp(-? * #{time_decay} - ? * #{hour_diff}))"
    end

    def most_common_meals(user:, limit: 5, offset: 0, time_decay_rate: 0.1, hour_penalty: 0.05)
      sql = <<~SQL
        SELECT meals.*,
               COUNT(user_meals.id) AS consumption_count,
               COALESCE(#{interaction_score_sql}, 0) AS interaction_score
        FROM meals
        LEFT JOIN user_meals ON meals.id = user_meals.meal_id AND user_meals.user_id = ?
        WHERE meals.user_id = ? OR user_meals.id IS NOT NULL
        GROUP BY meals.id
        ORDER BY interaction_score DESC
        LIMIT ? OFFSET ?
      SQL

      find_by_sql([ sql, time_decay_rate, hour_penalty, user.id, user.id, limit, offset ])
    end

    def vector_search(query:, user:, limit: 5, offset: 0, time_decay_rate: 0.1, interaction_weight: 0.01, hour_penalty: 0.05, location_weight: 0.001)
      query_embedding = QueryEmbedding.find_or_create_embedding(query)
      embedding = query_embedding.embedding

      latitude = Current.latitude
      longitude = Current.longitude
      user_has_location = latitude.present? && longitude.present?

      # Build a set of all meal IDs visible to this user (owned + consumed)
      user_meal_ids = UserMeal.where(user_id: user.id).distinct.pluck(:meal_id)
      owned_meal_ids = Meal.where(user_id: user.id).pluck(:id)
      all_meal_ids = (user_meal_ids + owned_meal_ids).uniq

      return [] if all_meal_ids.empty?

      # Vector search (fast, uses index)
      vector_results = MealVector.find_by_sql([
        "SELECT meal_id, distance FROM meal_vectors WHERE embedding MATCH ? AND k = ?",
        embedding.to_s,
        [ all_meal_ids.length, limit * 10 ].max
      ])

      # Filter to user-visible meals and build distance hash
      vector_distances = {}
      user_vector_results = vector_results.select { |vr| all_meal_ids.include?(vr.meal_id) }
      user_vector_results.each { |vr| vector_distances[vr.meal_id] = vr.distance }

      return [] if user_vector_results.empty?

      # Fetch meals
      meal_ids = user_vector_results.map(&:meal_id)
      meals = where(id: meal_ids).to_a

      # Pre-group user_meals data by meal_id for O(1) lookup
      user_meals_data = UserMeal.where(user_id: user.id, meal_id: meal_ids)
                                 .pluck(:meal_id, :consumed_at, :latitude, :longitude)
      meals_by_id = {}
      user_meals_data.each do |um|
        (meals_by_id[um[0]] ||= []) << um
      end

      # Score meals
      now = Time.current
      now_seconds = now.to_i
      now_hour = now.hour

      meals.each do |meal|
        distance = vector_distances[meal.id] || 1.0
        meal_user_meals = meals_by_id[meal.id] || []

        interaction_score = meal_user_meals.sum do |um|
          consumed_at = um[1]
          time_decay = (now_seconds - consumed_at.to_i) / 86400.0
          consumed_hour = consumed_at.hour
          hour_diff = [ (now_hour - consumed_hour).abs, 24 - (now_hour - consumed_hour).abs ].min
          Math.exp(-time_decay_rate * time_decay - hour_penalty * hour_diff)
        end

        location_boost = 0.0
        if user_has_location
          user_lat = latitude.to_f
          user_lon = longitude.to_f
          max_radius_km = 10.0

          meal_user_meals.each do |um|
            meal_lat = um[2]
            meal_lon = um[3]
            next if meal_lat.nil? || meal_lon.nil?

            dist_km = haversine_distance(user_lat, user_lon, meal_lat.to_f, meal_lon.to_f)
            if dist_km <= max_radius_km
              location_boost += (max_radius_km - dist_km) / max_radius_km
            end
          end
        end

        meal.combined_score = (1.0 / (1.0 + distance)) + interaction_weight * interaction_score + location_weight * location_boost
      end

      meals.sort_by { |m| -m.combined_score }.drop(offset).first(limit)
    end

    def haversine_distance(lat1, lon1, lat2, lon2)
      # Convert to radians
      d_lat = to_radians(lat2 - lat1)
      d_lon = to_radians(lon2 - lon1)
      a = Math.sin(d_lat / 2) ** 2 +
          Math.cos(to_radians(lat1)) * Math.cos(to_radians(lat2)) * Math.sin(d_lon / 2) ** 2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      6371 * c # Earth radius in km
    end

    def to_radians(degrees)
      degrees * Math::PI / 180.0
    end
  end
end

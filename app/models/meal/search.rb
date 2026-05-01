class Meal::Search
  TIME_DECAY_RATE = 0.1
  HOUR_PENALTY = 0.05
  INTERACTION_WEIGHT = 0.01
  LOCATION_WEIGHT = 0.001
  MAX_RADIUS_KM = 10.0

  def self.vector_search(query:, user:, limit: 5, offset: 0)
    new(query:, user:, limit:, offset:).vector_search
  end

  def self.most_common_meals(user:, limit: 5, offset: 0)
    new(user:).most_common_meals(limit:, offset:)
  end

  def initialize(query: nil, user:, limit: nil, offset: nil)
    @query = query
    @user = user
    @limit = limit
    @offset = offset
  end

  def vector_search
    all_meal_ids = build_visible_meal_ids
    return [] if all_meal_ids.empty?

    vector_distances = vector_distances_for(all_meal_ids)
    return [] if vector_distances.empty?

    meals = fetch_meals(vector_distances.keys)
    user_meals_data = preload_user_meals_data(vector_distances.keys)

    score_meals(meals, vector_distances, user_meals_data)
      .sort_by { |m| -m.combined_score }
      .drop(@offset)
      .first(@limit)
  end

  def most_common_meals(limit:, offset:)
    Meal.find_by_sql([ most_common_sql, TIME_DECAY_RATE, HOUR_PENALTY, @user.id, @user.id, limit, offset || 0 ])
  end

  private

  def build_visible_meal_ids
    user_meal_ids = UserMeal.where(user_id: @user.id).distinct.pluck(:meal_id)
    owned_meal_ids = Meal.where(user_id: @user.id).pluck(:id)
    (user_meal_ids + owned_meal_ids).uniq
  end

  def vector_distances_for(all_meal_ids)
    embedding = QueryEmbedding.find_or_create_embedding(@query).embedding.to_s

    vector_results = MealVector.find_by_sql([
      "SELECT meal_id, distance FROM meal_vectors WHERE embedding MATCH ? AND k = ?",
      embedding,
      [ all_meal_ids.length, @limit * 10 ].max
    ])

    distances = {}
    vector_results
      .select { |vr| all_meal_ids.include?(vr.meal_id) }
      .each { |vr| distances[vr.meal_id] = vr.distance }
    distances
  end

  def fetch_meals(meal_ids)
    Meal.where(id: meal_ids).to_a
  end

  def preload_user_meals_data(meal_ids)
    raw = UserMeal.where(user_id: @user.id, meal_id: meal_ids)
                  .pluck(:meal_id, :consumed_at, :latitude, :longitude)
    grouped = {}
    raw.each { |um| (grouped[um[0]] ||= []) << um }
    grouped
  end

  def score_meals(meals, vector_distances, user_meals_data)
    now = Time.current
    now_seconds = now.to_i
    now_hour = now.hour
    user_has_location = Current.latitude.present? && Current.longitude.present?
    user_lat = Current.latitude.to_f
    user_lon = Current.longitude.to_f

    meals.each do |meal|
      distance = vector_distances[meal.id] || 1.0
      ums = user_meals_data[meal.id] || []

      interaction_score = compute_interaction_score(ums, now_seconds, now_hour)
      location_boost = user_has_location ? compute_location_boost(ums, user_lat, user_lon) : 0.0

      base_score = 1.0 / (1.0 + distance)
      consumption_boost = 1.0 + INTERACTION_WEIGHT * Math.log(1.0 + interaction_score)
      location_mult = 1.0 + LOCATION_WEIGHT * Math.log(1.0 + location_boost)
      meal.combined_score = base_score * consumption_boost * location_mult
    end
  end

  def compute_interaction_score(user_meals, now_seconds, now_hour)
    user_meals.sum do |um|
      consumed_at = um[1]
      time_decay = (now_seconds - consumed_at.to_i) / 86400.0
      consumed_hour = consumed_at.hour
      hour_diff = [ (now_hour - consumed_hour).abs, 24 - (now_hour - consumed_hour).abs ].min
      Math.exp(-TIME_DECAY_RATE * time_decay - HOUR_PENALTY * hour_diff)
    end
  end

  def compute_location_boost(user_meals, user_lat, user_lon)
    user_meals.sum(0.0) do |um|
      meal_lat = um[2]
      meal_lon = um[3]
      next 0.0 if meal_lat.nil? || meal_lon.nil?

      dist_km = haversine_distance(user_lat, user_lon, meal_lat.to_f, meal_lon.to_f)
      dist_km <= MAX_RADIUS_KM ? (MAX_RADIUS_KM - dist_km) / MAX_RADIUS_KM : 0.0
    end
  end

  def interaction_score_sql
    time_decay = "((CAST(strftime('%s', 'now') AS REAL) - CAST(strftime('%s', user_meals.consumed_at) AS REAL)) / 86400.0)"
    hour_diff = "MIN(ABS(CAST(strftime('%H', 'now') AS INTEGER) - CAST(strftime('%H', user_meals.consumed_at) AS INTEGER)), 24 - ABS(CAST(strftime('%H', 'now') AS INTEGER) - CAST(strftime('%H', user_meals.consumed_at) AS INTEGER)))"
    "SUM(exp(-? * #{time_decay} - ? * #{hour_diff}))"
  end

  def most_common_sql
    <<~SQL
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
  end

  def haversine_distance(lat1, lon1, lat2, lon2)
    d_lat = to_radians(lat2 - lat1)
    d_lon = to_radians(lon2 - lon1)
    a = Math.sin(d_lat / 2) ** 2 +
        Math.cos(to_radians(lat1)) * Math.cos(to_radians(lat2)) * Math.sin(d_lon / 2) ** 2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    6371 * c
  end

  def to_radians(degrees)
    degrees * Math::PI / 180.0
  end
end

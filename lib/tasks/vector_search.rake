namespace :vector_search do
  desc "Generate embeddings for all meals"
  task generate_embeddings: :environment do
    puts "Generating embeddings for all meals..."

    total = Meal.count
    count = 0

    Meal.find_each.with_index do |meal, i|
      count += 1

      if meal.meal_vector.nil?
        begin
          meal.find_or_create_meal_vector
          puts "Created embedding for meal #{meal.id}: #{meal.meal_name} (#{count}/#{total})"
        rescue => e
          puts "Error creating embedding for meal #{meal.id}: #{e.message}"
        end
      else
        puts "Embedding already exists for meal #{meal.id}: #{meal.meal_name} (#{count}/#{total})"
      end

      # Sleep briefly to avoid rate limits
      sleep(0.1) if i % 10 == 0
    end

    puts "Embedding generation complete!"
  end
end

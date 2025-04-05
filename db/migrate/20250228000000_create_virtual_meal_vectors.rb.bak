class CreateVirtualMealVectors < ActiveRecord::Migration[8.0]
  def up
    # First check if the chunks table already exists and drop it if it does
    execute "DROP TABLE IF EXISTS meal_vectors_chunks"
    
    # Then create the virtual table
    create_virtual_table :meal_vectors, :vec0, [
      "meal_id integer primary key",
      "embedding float[1536] distance_metric=cosine"
    ]
  end
  
  def down
    execute "DROP TABLE IF EXISTS meal_vectors"
    execute "DROP TABLE IF EXISTS meal_vectors_chunks"
    execute "DROP TABLE IF EXISTS meal_vectors_info"
    execute "DROP TABLE IF EXISTS meal_vectors_rowids"
    execute "DROP TABLE IF EXISTS meal_vectors_vector_chunks00"
  end
end

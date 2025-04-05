class CreateVirtualMealVectors < ActiveRecord::Migration[8.0]
  def up
    # Drop all related tables that might exist
    tables = [
      "meal_vectors",
      "meal_vectors_chunks",
      "meal_vectors_info",
      "meal_vectors_rowids", 
      "meal_vectors_vector_chunks00"
    ]
    
    tables.each do |table|
      execute "DROP TABLE IF EXISTS #{table}"
    end
    
    # Then create the virtual table
    create_virtual_table :meal_vectors, :vec0, [
      "meal_id integer primary key",
      "embedding float[1536] distance_metric=cosine"
    ]
  end
  
  def down
    # Drop all related tables
    tables = [
      "meal_vectors",
      "meal_vectors_chunks",
      "meal_vectors_info",
      "meal_vectors_rowids", 
      "meal_vectors_vector_chunks00"
    ]
    
    tables.each do |table|
      execute "DROP TABLE IF EXISTS #{table}"
    end
  end
end

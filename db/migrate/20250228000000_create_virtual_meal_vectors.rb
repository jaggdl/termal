class CreateVirtualMealVectors < ActiveRecord::Migration[8.0]
  def change
    create_virtual_table :meal_vectors, :vec0, [
      "meal_id integer primary key",
      "embedding float[1536] distance_metric=cosine"
    ]
  end
end

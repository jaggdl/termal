class CreateNutritionAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :nutrition_analyses do |t|
      t.text :text
      t.date :date_start
      t.date :date_end
      t.datetime :executed_at
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end

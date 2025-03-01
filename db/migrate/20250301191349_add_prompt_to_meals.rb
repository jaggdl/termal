class AddPromptToMeals < ActiveRecord::Migration[8.0]
  def change
    add_column :meals, :prompt, :string
  end
end

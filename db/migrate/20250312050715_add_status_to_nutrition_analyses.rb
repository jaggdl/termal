class AddStatusToNutritionAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_column :nutrition_analyses, :status, :string, default: "completed"

    # Update existing records to have completed status
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE nutrition_analyses SET status = 'completed';
        SQL
      end
    end
  end
end

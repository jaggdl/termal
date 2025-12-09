class CreateQueryEmbeddings < ActiveRecord::Migration[8.0]
  def change
    create_virtual_table :query_embeddings, :vec0, [
      "query_text text primary key",
      "embedding float[1536] distance_metric=cosine"
    ]
  end
end

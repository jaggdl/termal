class QueryEmbedding < ApplicationRecord
  self.primary_key = "query_text"

  has_neighbors :embedding, dimensions: 1536

  validates :query_text, presence: true

  def self.find_or_create_embedding(query)
    normalized_query = normalize_query(query)

    existing = find_by(query_text: normalized_query)
    return existing if existing

    embedding_result = Embedding.create(normalized_query)

    create!(
      query_text: normalized_query,
      embedding: embedding_result.embedding
    )
  end

  def self.normalize_query(query)
    query.to_s.strip.downcase
  end
end

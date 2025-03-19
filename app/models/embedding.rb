class Embedding
  attr_reader :embedding

  def initialize(embedding)
    @embedding = embedding
  end

  def self.create(input)
    llm_service = LlmService.new
    embedding = llm_service.embedding(input)
    new(embedding)
  end

  def to_s
    embedding.to_s
  end
end

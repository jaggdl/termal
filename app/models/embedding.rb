class Embedding
  attr_reader :embedding

  def initialize(embedding)
    @embedding = embedding
  end

  def self.create(input)
    open_ai_service = OpenAiService.new
    embedding = open_ai_service.embedding(input)
    new(embedding)
  end

  def to_s
    embedding.to_s
  end
end

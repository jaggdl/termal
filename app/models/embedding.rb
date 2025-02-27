class Embedding
  attr_reader :embedding

  def initialize(embedding)
    @embedding = embedding
  end

  def self.create(input)
    client = OpenAI::Client.new(
      access_token: GlobalSetting.get("openai_api_key"),
      log_errors: true
    )
    
    embedding = client.embeddings(
      parameters: {
        model: "text-embedding-3-small", 
        input: input
      }
    ).fetch("data")[0]["embedding"]
    
    new(embedding)
  end

  def to_s
    embedding.to_s
  end
end
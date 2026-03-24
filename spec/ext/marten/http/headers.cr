class Marten::HTTP::Headers
  def to_json
    JSON.build { |json| to_json(json) }
  end

  def to_json(json : JSON::Builder)
    json.object do
      headers.each do |name, value|
        json.field name, value.join(", ")
      end
    end
  end
end

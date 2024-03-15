class Marten::HTTP::Request
  def self.new(
    method : String,
    resource : String,
    headers : ::HTTP::Headers? = nil,
    body : String | Bytes | IO | Nil = nil,
    version = "HTTP/1.1"
  )
    new(::HTTP::Request.new(method: method, resource: resource, headers: headers, body: body, version: version))
  end
end

class HeadersRespondHandler < Marten::Handlers::Base
  def dispatch
    json(request.headers.to_stdlib)
  end
end

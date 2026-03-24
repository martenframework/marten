class HeadersRespondHandler < Marten::Handlers::Base
  def dispatch
    json(request.headers)
  end
end

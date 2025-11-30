class RequestDataRespondHandler < Marten::Handlers::Base
  def dispatch
    respond request.data.to_h.to_json
  end
end

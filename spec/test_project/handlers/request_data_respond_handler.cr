class RequestDataRespondHandler < Marten::Handlers::Base
  def dispatch
    data = request.data
    pp! data
    pp! data.to_h.to_json
    respond request.data.to_h.to_json
  end
end

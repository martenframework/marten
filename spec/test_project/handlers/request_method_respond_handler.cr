class RequestMethodRespondHandler < Marten::Handlers::Base
  def dispatch
    respond request.method
  end
end

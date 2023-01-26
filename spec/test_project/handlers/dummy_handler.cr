class DummyHandler < Marten::Handlers::Base
  def dispatch
    Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
  end
end

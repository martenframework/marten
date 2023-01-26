class QueryParamsRespondHandler < Marten::Handlers::Base
  def dispatch
    respond request.query_params.as_query
  end
end

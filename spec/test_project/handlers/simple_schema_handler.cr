class SimpleSchemaHandler < Marten::Handlers::Schema
  schema SimpleSchema
  success_url "/"
  template_name "base.html"

  def patch
    post
  end
end

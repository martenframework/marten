class SimpleFileSchemaHandler < Marten::Handlers::Schema
  schema SimpleFileSchema
  success_url "/"
  template_name "base.html"
end

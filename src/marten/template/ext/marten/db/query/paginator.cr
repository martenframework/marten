class Marten::DB::Query::Paginator(M)
  include Marten::Template::Object

  template_attributes :page_size, :pages_count
end

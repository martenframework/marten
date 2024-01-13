class Marten::DB::Query::Paginator(M)
  include Marten::Template::Object

  def resolve_template_attribute(key : String)
    case key
    when "page_size"
      page_size
    when "pages_count"
      pages_count
    end
  end
end

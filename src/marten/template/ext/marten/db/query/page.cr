class Marten::DB::Query::Page(M)
  include Marten::Template::Object

  template_attributes :all?, :any?, :count, :empty?, :first?, :next_page?, :next_page_number, :none?, :number, :one?,
    :pages_count, :previous_page?, :previous_page_number, :size, :total_count
end

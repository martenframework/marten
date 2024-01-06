class Marten::DB::Query::Set(M)
  include Marten::Template::Object

  def resolve_template_attribute(key : String)
    case key
    when "all"
      all
    when "all?"
      all?
    when "any?"
      any?
    when "count"
      count
    when "distinct"
      distinct
    when "empty?"
      empty?
    when "exists?"
      exists?
    when "first"
      first
    when "first!"
      first!
    when "first?"
      first?
    when "last"
      last
    when "last!"
      last!
    when "none"
      none
    when "none?"
      none?
    when "one?"
      one?
    when "reverse"
      reverse
    when "size"
      size
    end
  end
end

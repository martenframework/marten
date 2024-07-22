class Marten::DB::Query::Set(M)
  include Marten::Template::Object

  template_attributes :all, :all?, :any?, :count, :distinct, :empty?, :exists?, :first, :first!, :first?, :last, :last!,
    :none, :none?, :one?, :reverse, :size
end

class Array
  include Marten::Template::CanDefineTemplateAttributes

  template_attributes :any?, :compact, :empty?, :flatten, :first, :last, :none?, :one?, :present?, :reverse, :size
end

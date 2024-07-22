class Marten::DB::Field::File::File
  include Marten::Template::Object

  template_attributes :attached?, :name, :size, :url
end

require "./spec_helper"

describe Marten::DB::Field::File::File do
  describe "#resolve_template_attribute" do
    it "is able to return the result of #attached?" do
      field = Marten::DB::Field::File.new("my_field")

      file_1 = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file_1.resolve_template_attribute("attached?").should be_true

      file_2 = Marten::DB::Field::File::File.new(field)
      file_2.resolve_template_attribute("attached?").should be_false
    end

    it "is able to return the result of #name" do
      field = Marten::DB::Field::File.new("my_field")

      file_1 = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file_1.resolve_template_attribute("name").should eq "path/to/file.txt"

      file_2 = Marten::DB::Field::File::File.new(field)
      file_2.resolve_template_attribute("name").should be_nil
    end

    it "is able to return the result of #size" do
      Marten.media_files_storage.write("css/app.css", IO::Memory.new("html { background: white; }"))

      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field, "css/app.css")

      file.resolve_template_attribute("size").should eq field.storage.size("css/app.css")
    end

    it "is able to return the result of #url" do
      Marten.media_files_storage.write("css/app.css", IO::Memory.new("html { background: white; }"))

      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field, "css/app.css")

      file.resolve_template_attribute("url").should eq field.storage.url("css/app.css")
    end
  end
end

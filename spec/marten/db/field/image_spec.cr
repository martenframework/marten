require "./spec_helper"

describe Marten::DB::Field::Image do
  describe "#validate" do
    it "completes successfully if no value is provided" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Image.new("my_field", blank: true, null: true)
      field.validate(obj, nil)

      obj.errors.should be_empty
    end

    it "completes successfully if the value is a valid image" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Image.new("my_field", blank: true, null: true)

      file = Marten::DB::Field::File::File.new(field, "path/to/image.png")
      file.file = File.new(File.join(__DIR__, "image_spec/fixtures/image.png"))
      file.committed = false

      field.validate(obj, file)

      obj.errors.should be_empty
    end

    it "adds an error to the record if the value is not a valid image" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Image.new("my_field", blank: true, null: true)

      file = Marten::DB::Field::File::File.new(field, "path/to/helloworld.txt")
      file.file = File.new(File.join(__DIR__, "image_spec/fixtures/helloworld.txt"))
      file.committed = false
      field.validate(obj, file)

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "my_field"
      obj.errors.first.message.should eq I18n.t("marten.db.field.image.errors.not_an_image")
    end

    it "rewinds the file before validation" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Image.new("my_field", blank: true, null: true)

      raw_file = File.new(File.join(__DIR__, "image_spec/fixtures/image.png"))
      raw_file.seek(100)

      file = Marten::DB::Field::File::File.new(field, "path/to/image.png")
      file.file = raw_file
      file.committed = false

      field.validate(obj, file)

      obj.errors.should be_empty
    end

    it "rewinds the file after validation" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Image.new("my_field", blank: true, null: true)

      file = Marten::DB::Field::File::File.new(field, "path/to/image.png")
      file.file = File.new(File.join(__DIR__, "image_spec/fixtures/image.png"))
      file.committed = false

      field.validate(obj, file)

      file.open.pos.should eq 0
    end
  end
end

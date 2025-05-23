require "./spec_helper"

describe Marten::Schema::Field::Image do
  describe "#deserialize" do
    it "returns nil if the value is nil" do
      field = Marten::Schema::Field::Image.new("test_field")
      field.deserialize(nil).should be_nil
    end

    it "returns an HTTP uploaded file object if the value is one" do
      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.txt"}},
          IO::Memory.new("This is a test")
        )
      )
      field = Marten::Schema::Field::Image.new("test_field")
      field.deserialize(uploaded_file).should eq uploaded_file
    end

    it "returns nil if the value is an empty string" do
      field = Marten::Schema::Field::Image.new("test_field")
      field.deserialize("").should be_nil
    end

    it "raises if the passed value is a JSON object" do
      field = Marten::Schema::Field::Image.new("test_field")
      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.deserialize(JSON.parse(%{"foo"})) }
    end

    it "raises if the passed value is a non-empty string" do
      field = Marten::Schema::Field::Image.new("test_field")
      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.deserialize("foo") }
    end

    it "raises if the passed value has an unexpected type" do
      field = Marten::Schema::Field::Image.new("test_field")
      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.deserialize(true) }
    end
  end

  describe "#max_name_size" do
    it "returns nil by default" do
      field = Marten::Schema::Field::Image.new("test_field")
      field.max_name_size.should be_nil
    end

    it "returns the max name size if such value is configured" do
      field = Marten::Schema::Field::Image.new("test_field", max_name_size: 10)
      field.max_name_size.should eq 10
    end
  end

  describe "#serialize" do
    it "always returns nil" do
      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.txt"}},
          IO::Memory.new("This is a test")
        )
      )

      field = Marten::Schema::Field::Image.new("test_field")
      field.serialize(nil).should be_nil
      field.serialize(uploaded_file).should be_nil
    end
  end

  describe "#validate" do
    it "validates a regular image file" do
      raw_file = File.new(File.join(__DIR__, "image_spec/fixtures/image.png"))

      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.png"}},
          IO::Memory.new(raw_file.gets_to_end)
        )
      )
      schema = Marten::Schema::Field::ImageSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => [uploaded_file]}
      )

      field = Marten::Schema::Field::Image.new("test_field")
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "validates a regular image file when a filename limit is set" do
      raw_file = File.new(File.join(__DIR__, "image_spec/fixtures/image.png"))

      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.png"}},
          IO::Memory.new(raw_file.gets_to_end)
        )
      )
      schema = Marten::Schema::Field::ImageSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => [uploaded_file]}
      )

      field = Marten::Schema::Field::Image.new("test_field", max_name_size: 10)
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "does not validate a non-image file" do
      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.txt"}},
          IO::Memory.new("This is a test")
        )
      )

      schema = Marten::Schema::Field::ImageSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => [uploaded_file]}
      )

      field = Marten::Schema::Field::Image.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.image.errors.not_an_image")
    end

    it "does not validate a file whose name exceeds the configured limit" do
      raw_file = File.new(File.join(__DIR__, "image_spec/fixtures/image.png"))

      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="too_long.png"}},
          IO::Memory.new(raw_file.gets_to_end)
        )
      )
      schema = Marten::Schema::Field::ImageSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => [uploaded_file]}
      )

      field = Marten::Schema::Field::Image.new("test_field", max_name_size: 2)
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq(
        I18n.t("marten.schema.field.file.errors.file_name_too_long", max_name_size: 2)
      )
    end

    it "rewinds the file before validation" do
      raw_file = File.new(File.join(__DIR__, "image_spec/fixtures/image.png"))

      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.png"}},
          IO::Memory.new(raw_file.gets_to_end)
        )
      )
      uploaded_file.io.seek(100)

      schema = Marten::Schema::Field::ImageSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => [uploaded_file]}
      )

      field = Marten::Schema::Field::Image.new("test_field")
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "rewinds the file after validation" do
      raw_file = File.new(File.join(__DIR__, "image_spec/fixtures/image.png"))

      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.png"}},
          IO::Memory.new(raw_file.gets_to_end)
        )
      )

      schema = Marten::Schema::Field::ImageSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => [uploaded_file]}
      )

      field = Marten::Schema::Field::Image.new("test_field")
      field.perform_validation(schema)

      uploaded_file.io.pos.should eq 0
    end
  end
end

module Marten::Schema::Field::ImageSpec
  class TestSchema < Marten::Schema
    field :test_field, :file
  end
end

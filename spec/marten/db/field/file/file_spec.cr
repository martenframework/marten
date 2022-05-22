require "./spec_helper"
require "./file_spec/**"

describe Marten::DB::Field::File::File do
  with_installed_apps Marten::DB::Field::File::FileSpec::App

  describe "#attached?" do
    it "returns true if a file is attached" do
      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file.attached?.should be_true
    end

    it "returns true if no file is attached" do
      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field)
      file.attached?.should be_false
    end
  end

  describe "#committed?" do
    it "returns true if the file is committed" do
      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file.committed?.should be_true
    end

    it "returns true if the file is not committed" do
      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file.committed = false
      file.committed?.should be_false
    end
  end

  describe "#delete" do
    it "closes the associated file and deletes the file in the underlying storage" do
      Marten.media_files_storage.write("css/app.css", IO::Memory.new("html { background: white; }"))
      raw_file = File.new(File.join(__DIR__, "file_spec/fixtures/helloworld.txt"))

      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field, "css/app.css")
      file.file = raw_file

      file.delete

      file.file.should be_nil
      file.name.should be_nil
      file.committed?.should be_false

      Marten.media_files_storage.exists?("css/app.css").should be_false
    end

    it "saves the associated record if instructed to" do
      record = Marten::DB::Field::File::FileSpec::Attachment.create!

      record.file.save("path/to/file.txt", IO::Memory.new("Hello World!"), save: true)
      record.reload
      file_name = record.file.name.not_nil!

      record.file.delete(save: true)
      record.reload

      record.file.attached?.should be_false
      Marten.media_files_storage.exists?(file_name).should be_false
    end

    it "raises if no file is currently attached to the field file" do
      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field)
      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        file.delete
      end
    end
  end

  describe "#file" do
    it "returns the associated file object" do
      raw_file = File.new(File.join(__DIR__, "file_spec/fixtures/helloworld.txt"))
      field = Marten::DB::Field::File.new("my_field")

      file = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file.file = raw_file

      file.file.should eq raw_file
    end

    it "returns the associated uploaded file object" do
      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.txt"; size=123}},
          IO::Memory.new("Hello World!")
        )
      )
      field = Marten::DB::Field::File.new("my_field")

      file = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file.file = uploaded_file

      file.file.should eq uploaded_file
    end
  end

  describe "#file=" do
    it "allows to associate a file object to the field file" do
      raw_file = File.new(File.join(__DIR__, "file_spec/fixtures/helloworld.txt"))
      field = Marten::DB::Field::File.new("my_field")

      file = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file.file = raw_file

      file.file.should eq raw_file
    end

    it "allows to associate an upload file object to the field file" do
      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.txt"; size=123}},
          IO::Memory.new("Hello World!")
        )
      )
      field = Marten::DB::Field::File.new("my_field")

      file = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file.file = uploaded_file

      file.file.should eq uploaded_file
    end
  end

  describe "#name" do
    it "returns nil by default" do
      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field)
      file.name.should be_nil
    end

    it "returns the file name if set" do
      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file.name.should eq "path/to/file.txt"
    end
  end

  describe "#open" do
    it "it opens the file on the storage" do
      Marten.media_files_storage.write("css/app.css", IO::Memory.new("html { background: white; }"))

      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field, "css/app.css")

      file.open.gets.should eq "html { background: white; }"
    end

    it "returns the associated file object if applicable" do
      raw_file = File.new(File.join(__DIR__, "file_spec/fixtures/helloworld.txt"))
      field = Marten::DB::Field::File.new("my_field")

      file = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file.file = raw_file
      file.committed = false

      file.open.should eq raw_file
    end

    it "returns the associated upload file object io if applicable" do
      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.txt"; size=123}},
          IO::Memory.new("Hello World!")
        )
      )
      field = Marten::DB::Field::File.new("my_field")

      file = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file.file = uploaded_file
      file.committed = false

      file.open.should eq uploaded_file.io
    end

    it "raises if no file is currently attached to the field file" do
      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field)
      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        file.open
      end
    end
  end

  describe "#save" do
    it "saves a specific IO object in a specific location and updates the name" do
      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field)

      file.save("path/to/file.txt", IO::Memory.new("Hello World!"))

      file.name.not_nil!.starts_with?("path/to/file").should be_true
      field.storage.open(file.name.not_nil!).gets.should eq "Hello World!"
    end

    it "marks the field file as committed" do
      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field)
      file.committed = false

      file.save("path/to/file.txt", IO::Memory.new("Hello World!"))

      file.committed?.should be_true
    end

    it "saves the associated record if instructed to" do
      record = Marten::DB::Field::File::FileSpec::Attachment.create!
      record.file.save("path/to/file.txt", IO::Memory.new("Hello World!"), save: true)
      record.reload
      record.file.attached?.should be_true
      record.file.open.gets.should eq "Hello World!"
    end
  end

  describe "#size" do
    it "returns the size of the file from the storage" do
      Marten.media_files_storage.write("css/app.css", IO::Memory.new("html { background: white; }"))

      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field, "css/app.css")

      file.size.should eq field.storage.size("css/app.css")
    end

    it "returns the size of the associated file object if applicable" do
      raw_file = File.new(File.join(__DIR__, "file_spec/fixtures/helloworld.txt"))
      field = Marten::DB::Field::File.new("my_field")

      file = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file.file = raw_file
      file.committed = false

      file.size.should eq raw_file.size
    end

    it "returns the file of the associated upload file object io if applicable" do
      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.txt"; size=123}},
          IO::Memory.new("Hello World!")
        )
      )
      field = Marten::DB::Field::File.new("my_field")

      file = Marten::DB::Field::File::File.new(field, "path/to/file.txt")
      file.file = uploaded_file
      file.committed = false

      file.size.should eq uploaded_file.size
    end

    it "raises if no file is currently attached to the field file" do
      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field)
      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        file.size
      end
    end
  end

  describe "#url" do
    it "returns the url of the file from the storage" do
      Marten.media_files_storage.write("css/app.css", IO::Memory.new("html { background: white; }"))

      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field, "css/app.css")

      file.url.should eq field.storage.url("css/app.css")
    end

    it "raises if no file is currently attached to the field file" do
      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field)
      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        file.url
      end
    end
  end
end

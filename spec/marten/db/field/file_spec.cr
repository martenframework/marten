require "./spec_helper"
require "./file_spec/**"

describe Marten::DB::Field::File do
  with_installed_apps Marten::DB::Field::FileSpec::App

  describe "::new" do
    it "initializes a file field instance with the expected defaults" do
      field = Marten::DB::Field::File.new("my_field")
      field.id.should eq "my_field"
      field.primary_key?.should be_false
      field.blank?.should be_false
      field.null?.should be_false
      field.unique?.should be_false
      field.db_column.should eq field.id
      field.index?.should be_false
      field.storage.should eq Marten.media_files_storage
      field.upload_to.should eq ""
      field.max_size.should eq 100
    end
  end

  describe "#default" do
    it "returns nil by default" do
      field = Marten::DB::Field::File.new("my_field")
      field.default.should be_nil
    end

    it "returns the default value if specified" do
      field = Marten::DB::Field::File.new("my_field", default: "default_value")
      field.default.should eq "default_value"
    end
  end

  describe "#empty_value?" do
    it "returns true if the passed value is nil" do
      field = Marten::DB::Field::File.new("my_field")
      field.empty_value?(nil).should be_true
    end

    it "returns true for an empty string" do
      field = Marten::DB::Field::File.new("my_field")
      field.empty_value?("").should be_true
    end

    it "returns true for an empty symbol" do
      field = Marten::DB::Field::File.new("my_field")
      field.empty_value?(:"").should be_true
    end

    it "returns true for an empty file object" do
      field = Marten::DB::Field::File.new("my_field")
      field.empty_value?(Marten::DB::Field::File::File.new(field)).should be_true
    end

    it "returns false for a non-empty string" do
      field = Marten::DB::Field::File.new("my_field")
      field.empty_value?("path/to/file.txt").should be_false
    end

    it "returns false for a non-empty symbol" do
      field = Marten::DB::Field::File.new("my_field")
      field.empty_value?(:"path/to/file.txt").should be_false
    end

    it "returns false for a non-empty file object" do
      field = Marten::DB::Field::File.new("my_field")
      field.empty_value?(Marten::DB::Field::File::File.new(field, name: "path/to/file.txt")).should be_false
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::File.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.empty_value?(42)
      end
    end
  end

  describe "#from_db" do
    it "returns nil if the passed value is nil" do
      field = Marten::DB::Field::File.new("my_field")
      field.from_db(nil).should be_nil
    end

    it "returns the expected file object if the passed value is a string" do
      field = Marten::DB::Field::File.new("my_field")
      result = field.from_db("path/to/file.txt")
      result.should be_a Marten::DB::Field::File::File
      result.not_nil!.name.should eq "path/to/file.txt"
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::File.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.from_db(42)
      end
    end
  end

  describe "#from_db_result_set" do
    it "is able to read a string from a DB result set and returns a file object" do
      field = Marten::DB::Field::File.new("my_field")

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 'path/to/file.txt'") do |rs|
          rs.each do
            result = field.from_db_result_set(rs)
            result.should be_a Marten::DB::Field::File::File
            result.not_nil!.name.should eq "path/to/file.txt"
          end
        end
      end
    end
  end

  describe "#prepare_save" do
    it "saves a regular file object that wasn't saved previously" do
      record = Marten::DB::Field::FileSpec::Attachment.create!
      record.file = File.new(File.join(__DIR__, "file_spec/fixtures/helloworld.txt"))

      field = Marten::DB::Field::File.new("file")
      field.prepare_save(record)

      Marten.media_files_storage.open(record.file.name.not_nil!).gets.should eq "Hello World!"
    end

    it "saves an uploaded file object that wasn't saved previously" do
      record = Marten::DB::Field::FileSpec::Attachment.create!
      record.file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.txt"; size=123}},
          IO::Memory.new("Hello World!")
        )
      )

      field = Marten::DB::Field::File.new("file")
      field.prepare_save(record)

      Marten.media_files_storage.open(record.file.name.not_nil!).gets.should eq "Hello World!"
    end
  end

  describe "#sanitize_filename" do
    it "returns the expected filename for a field without specific upload_to attribute configured" do
      field = Marten::DB::Field::File.new("file")
      field.sanitize_filename("file.txt").should eq "file.txt"
      field.sanitize_filename("path/to/file.txt").should eq "path/to/file.txt"
    end

    it "returns the expected filename for a field with a static upload_to attribute configured" do
      field = Marten::DB::Field::File.new("file", upload_to: "files/uploads")
      field.sanitize_filename("file.txt").should eq "files/uploads/file.txt"
      field.sanitize_filename("path/to/file.txt").should eq "files/uploads/path/to/file.txt"
    end

    it "returns the expected filename for a field with a upload_to proc configured" do
      field = Marten::DB::Field::File.new("file", upload_to: ->(x : String) { File.join("files/uploads", x) })
      field.sanitize_filename("file.txt").should eq "files/uploads/file.txt"
      field.sanitize_filename("path/to/file.txt").should eq "files/uploads/path/to/file.txt"
    end

    it "raises for a blank filename" do
      field = Marten::DB::Field::File.new("file")
      expect_raises(Marten::DB::Errors::SuspiciousFileOperation) do
        field.sanitize_filename("")
      end
    end

    it "raises for a . filename" do
      field = Marten::DB::Field::File.new("file")
      expect_raises(Marten::DB::Errors::SuspiciousFileOperation) do
        field.sanitize_filename(".")
      end
    end

    it "raises for a .. filename" do
      field = Marten::DB::Field::File.new("file")
      expect_raises(Marten::DB::Errors::SuspiciousFileOperation) do
        field.sanitize_filename("..")
      end
    end

    it "raises for an absolute filename" do
      field = Marten::DB::Field::File.new("file")
      expect_raises(Marten::DB::Errors::SuspiciousFileOperation) do
        field.sanitize_filename("/root/file.txt")
      end
    end

    it "raises if the filename involves a path traversal" do
      field = Marten::DB::Field::File.new("file")
      expect_raises(Marten::DB::Errors::SuspiciousFileOperation) do
        field.sanitize_filename("path/to/../file.txt")
      end
    end
  end

  describe "#storage" do
    it "returns the default media files storage by default" do
      field = Marten::DB::Field::File.new("file")
      field.storage.should eq Marten.media_files_storage
    end

    it "returns the configured media files storage" do
      storage = Marten::Core::Storage::FileSystem.new(root: "files", base_url: "/files/")
      field = Marten::DB::Field::File.new("file", storage: storage)
      field.storage.should eq storage
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::File.new("my_field", db_column: "my_field_col")
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::String
      column.name.should eq "my_field_col"
      column.primary_key?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.max_size.should eq 100
      column.default.should be_nil
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::File.new("my_field")
      field.to_db(nil).should be_nil
    end

    it "returns a string value if the initial value is a string" do
      field = Marten::DB::Field::File.new("my_field")
      field.to_db("hello").should eq "hello"
    end

    it "returns a string value if the initial value is a symbol" do
      field = Marten::DB::Field::File.new("my_field")
      field.to_db(:hello).should eq "hello"
    end

    it "returns a string value containing the file name if the the initial value is a file object" do
      field = Marten::DB::Field::File.new("my_field")
      field.to_db(Marten::DB::Field::File::File.new(field, name: "path/to/file.txt")).should eq "path/to/file.txt"
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::File.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db(["foo", "bar"])
      end
    end
  end

  describe "::contribute_to_model" do
    it "defines a getter? method for the field as expected" do
      object_1 = Marten::DB::Field::FileSpec::Attachment.new
      object_1.file?.should be_false

      object_2 = Marten::DB::Field::FileSpec::Attachment.create!
      object_2.file = File.new(File.join(__DIR__, "file_spec/fixtures/helloworld.txt"))
      object_2.file?.should be_true
    end
  end
end

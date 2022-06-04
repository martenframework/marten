require "./spec_helper"

describe Marten::HTTP::UploadedFile do
  describe "::new" do
    it "allows to initialize an uploaded file from a form data part" do
      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.txt"}},
          IO::Memory.new("This is a test")
        )
      )
      uploaded_file.size.should eq 14
    end
  end

  describe "#filename" do
    it "returns the filename" do
      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.txt"}},
          IO::Memory.new
        )
      )
      uploaded_file.filename.should eq "a.txt"
    end
  end

  describe "#size" do
    it "returns the expected file size" do
      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.txt"}},
          IO::Memory.new("This is a test")
        )
      )
      uploaded_file.size.should eq 14
    end
  end

  describe "#io" do
    it "returns the IO object allowing to manipulate the file content" do
      uploaded_file = Marten::HTTP::UploadedFile.new(
        HTTP::FormData::Part.new(
          HTTP::Headers{"Content-Disposition" => %{form-data; name="file"; filename="a.txt"}},
          IO::Memory.new("This is a test")
        )
      )
      uploaded_file.io.should be_a File
      uploaded_file.io.gets_to_end.should eq "This is a test"
    end
  end
end

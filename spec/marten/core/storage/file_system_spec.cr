require "./spec_helper"

describe Marten::Core::Storage::FileSystem do
  describe "#exists" do
    it "returns true if a file associated with the passed file path exists" do
      storage = Marten::Core::Storage::FileSystem.new(root: File.join("/tmp/"), base_url: "/assets/")
      storage.save("css/app.css", IO::Memory.new("html { background: white; }"))
      storage.exists?("css/app.css").should be_true
    end

    it "returns false if no files associated with the passed file path exist" do
      storage = Marten::Core::Storage::FileSystem.new(root: File.join("/tmp/"), base_url: "/assets/")
      storage.exists?("css/unknown.css").should be_false
    end
  end

  describe "#open" do
    it "returns an IO corresponding to the passed file path" do
      storage = Marten::Core::Storage::FileSystem.new(root: File.join("/tmp/"), base_url: "/assets/")
      storage.save("css/app.css", IO::Memory.new("html { background: white; }"))
      io = storage.open("css/app.css")
      io.should be_a File
      io.gets.should eq "html { background: white; }"
    end

    it "raises if the file does not exist" do
      storage = Marten::Core::Storage::FileSystem.new(root: File.join("/tmp/"), base_url: "/assets/")
      expect_raises(Marten::Core::Storage::Errors::FileNotFound) do
        storage.open("css/unknown.css")
      end
    end
  end

  describe "#save" do
    it "copy the content of the passed IO object to the destination path" do
      storage = Marten::Core::Storage::FileSystem.new(root: File.join("/tmp/"), base_url: "/assets/")
      storage.save("css/app.css", IO::Memory.new("html { background: white; }"))
      File.read("/tmp/css/app.css").should eq "html { background: white; }"
    end
  end

  describe "#url" do
    it "returns a URL constructed from the base URL" do
      storage = Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "/assets/")
      storage.url("css/app.css").should eq "/assets/css/app.css"
    end

    it "only escape the filepath" do
      storage = Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "http://localhost:8080/assets/")
      storage.url("css/app:test.css").should eq "http://localhost:8080/assets/css/app%3Atest.css"
    end
  end
end

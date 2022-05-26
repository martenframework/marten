require "./spec_helper"

describe Marten::Core::Storage::FileSystem do
  describe "#delete" do
    it "deletes the file associated with the passed file path" do
      storage = Marten::Core::Storage::FileSystem.new(root: File.join("/tmp/"), base_url: "/assets/")
      storage.write("css/app.css", IO::Memory.new("html { background: white; }"))

      storage.delete("css/app.css")

      storage.exists?("css/app.css").should be_false
    end

    it "raises if the file does not exist" do
      storage = Marten::Core::Storage::FileSystem.new(root: File.join("/tmp/"), base_url: "/assets/")
      expect_raises(Marten::Core::Storage::Errors::FileNotFound) do
        storage.delete("css/unknown.css")
      end
    end
  end

  describe "#exists" do
    it "returns true if a file associated with the passed file path exists" do
      storage = Marten::Core::Storage::FileSystem.new(root: File.join("/tmp/"), base_url: "/assets/")
      storage.write("css/app.css", IO::Memory.new("html { background: white; }"))
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
      storage.write("css/app.css", IO::Memory.new("html { background: white; }"))
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
    it "copy the content of the passed IO object to the destination path if it does not already exist" do
      destination_path = "css/app_#{Time.local.to_unix}.css"
      storage = Marten::Core::Storage::FileSystem.new(root: File.join("/tmp/"), base_url: "/assets/")
      path = storage.save(destination_path, IO::Memory.new("html { background: white; }"))
      path.should eq destination_path
      File.read(File.join("/tmp", path)).should eq "html { background: white; }"
    end

    it "copy the content of the passed IO object to a modified destination path if it already exists" do
      destination_path = "css/app.css"

      storage = Marten::Core::Storage::FileSystem.new(root: File.join("/tmp/"), base_url: "/assets/")
      storage.save(destination_path, IO::Memory.new("html { background: white; }"))
      path = storage.save(destination_path, IO::Memory.new("html { background: white; }"))

      path.should_not eq destination_path
      path.starts_with?("css/app").should be_true
      File.read(File.join("/tmp", path)).should eq "html { background: white; }"
    end

    it "does not retain leading ./ characters in the generated path" do
      destination_path = "./app.css"

      storage = Marten::Core::Storage::FileSystem.new(root: File.join("/tmp/"), base_url: "/assets/")
      storage.save(destination_path, IO::Memory.new("html { background: white; }"))
      path = storage.save(destination_path, IO::Memory.new("html { background: white; }"))

      path.should_not eq destination_path
      path.starts_with?("app").should be_true
      File.read(File.join("/tmp", path)).should eq "html { background: white; }"
    end
  end

  describe "#size" do
    it "returns the size of the file associated with the passed file path" do
      storage = Marten::Core::Storage::FileSystem.new(root: File.join("/tmp/"), base_url: "/assets/")
      storage.write("css/app.css", IO::Memory.new("html { background: white; }"))
      storage.size("css/app.css").should eq File.size("/tmp/css/app.css")
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

  describe "#write" do
    it "copy the content of the passed IO object to the destination path" do
      storage = Marten::Core::Storage::FileSystem.new(root: File.join("/tmp/"), base_url: "/assets/")
      storage.write("css/app.css", IO::Memory.new("html { background: white; }"))
      File.read("/tmp/css/app.css").should eq "html { background: white; }"
    end
  end
end

require "./spec_helper"

describe Marten::Core::Storage::FileSystem do
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
  end
end

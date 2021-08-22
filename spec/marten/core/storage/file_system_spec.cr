require "./spec_helper"

describe Marten::Core::Storage::FileSystem do
  describe "#url" do
    it "returns a URL constructed from the base URL" do
      storage = Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "/assets/")
      storage.url("css/app.css").should eq "/assets/css/app.css"
    end
  end
end

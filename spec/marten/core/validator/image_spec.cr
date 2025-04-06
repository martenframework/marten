require "./spec_helper"

describe Marten::Core::Validator::Image do
  describe "::valid?" do
    it "returns true for valid images" do
      image_file = File.new(File.join(__DIR__, "image_spec/fixtures/image.png"))
      Marten::Core::Validator::Image.valid?(image_file).should be_true
    end

    it "returns false for non-image files" do
      non_image_file = File.new(File.join(__DIR__, "image_spec/fixtures/helloworld.txt"))
      Marten::Core::Validator::Image.valid?(non_image_file).should be_false
    end

    it "rewinds the IO before attempting to validate it and after" do
      image_file = File.new(File.join(__DIR__, "image_spec/fixtures/image.png"))
      image_file.seek(100)
      Marten::Core::Validator::Image.valid?(image_file).should be_true
      image_file.pos.should eq 0

      non_image_file = File.new(File.join(__DIR__, "image_spec/fixtures/helloworld.txt"))
      non_image_file.seek(100)
      Marten::Core::Validator::Image.valid?(non_image_file).should be_false
      non_image_file.pos.should eq 0
    end
  end
end

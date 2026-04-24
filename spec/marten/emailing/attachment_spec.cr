require "./spec_helper"

describe Marten::Emailing::Attachment do
  describe "#initialize" do
    it "assigns the filename, mime type, and content" do
      content = Bytes[104, 101, 108, 108, 111]
      attachment = Marten::Emailing::Attachment.new("test.txt", "text/plain", content)

      attachment.filename.should eq "test.txt"
      attachment.mime_type.should eq "text/plain"
      attachment.content.should eq Bytes[104, 101, 108, 108, 111]
    end

    it "duplicates the passed content bytes" do
      content = Bytes[104, 101, 108, 108, 111]
      attachment = Marten::Emailing::Attachment.new("test.txt", "text/plain", content)

      content[0] = 120

      attachment.content.should eq Bytes[104, 101, 108, 108, 111]
    end
  end

  describe "#size" do
    it "returns the attachment content bytes size" do
      attachment = Marten::Emailing::Attachment.new(
        "test.png",
        "image/png",
        Bytes[137, 80, 78, 71, 13, 10, 26, 10]
      )

      attachment.size.should eq 8
    end
  end
end

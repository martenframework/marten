require "./spec_helper"

describe Marten::HTTP::Status do
  describe ".status_code" do
    it "accepts integer status code" do
      status = Marten::HTTP::Status.status_code(400)
      status.should eq 400
    end

    it "accepts symbol status code" do
      status = Marten::HTTP::Status.status_code(:internal_server_error)
      status.should eq 500
    end

    it "raises error if symbol is unrecognized" do
      expect_raises(Marten::HTTP::Status::UnrecognizedStatusException) do
        status = Marten::HTTP::Status.status_code(:unrecognized_code)
        status.should eq 200
      end
    end
  end
end

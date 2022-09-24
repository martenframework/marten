require "./spec_helper"

describe Marten::Views::XFrameOptions do
  describe "::exempt_from_x_frame_options" do
    it "allows to mark a view class as exempted from using the X-Frame-Options header" do
      Marten::Views::XFrameOptionsSpec::ExemptedView.exempt_from_x_frame_options?.should be_true
    end

    it "allows to mark a view class as non-exempted from using the X-Frame-Options header" do
      Marten::Views::XFrameOptionsSpec::NonExemptedView.exempt_from_x_frame_options?.should be_false
    end
  end

  describe "::exempt_from_x_frame_options?" do
    it "returns true if the view class is exempted from using the X-Frame-Options header" do
      Marten::Views::XFrameOptionsSpec::ExemptedView.exempt_from_x_frame_options?.should be_true
    end

    it "returns false if the view class is not exempted from using the X-Frame-Options header" do
      Marten::Views::XFrameOptionsSpec::NonExemptedView.exempt_from_x_frame_options?.should be_false
    end
  end

  describe "#process_dispatch" do
    it "inserts a temporary header in the response if the view is exempted" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      view = Marten::Views::XFrameOptionsSpec::ExemptedView.new(request)
      response = view.process_dispatch

      response.headers[:"X-Frame-Options-Exempt"].should eq "true"
    end

    it "does not insert a temporary header in the response if the view is not exempted" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      view = Marten::Views::XFrameOptionsSpec::NonExemptedView.new(request)
      response = view.process_dispatch

      response.headers.has_key?(:"X-Frame-Options-Exempt").should be_false
    end
  end
end

module Marten::Views::XFrameOptionsSpec
  class ExemptedView < Marten::View
    include Marten::Views::XFrameOptions

    exempt_from_x_frame_options true
  end

  class NonExemptedView < Marten::View
    include Marten::Views::XFrameOptions

    exempt_from_x_frame_options false
  end
end

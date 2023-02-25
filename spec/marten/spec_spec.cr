require "./spec_helper"

describe Marten::Spec do
  describe "#client" do
    it "returns a client instance with CSRF checks disabled by default" do
      Marten::Spec.client.should be_a Marten::Spec::Client

      response = Marten::Spec.client.post(
        Marten.routes.reverse("simple_schema"),
        data: {"first_name" => "John", "last_name" => "Doe"}
      )

      response.status.should eq 302
    end
  end

  describe "#delivered_emails" do
    it "returns the emails that were collected by development emailing backend" do
      Marten::SpecSpec::TestEmail.new.deliver

      Marten::Emailing::Backend::Development.delivered_emails.size.should eq 1
      Marten::Spec.delivered_emails.should eq Marten::Emailing::Backend::Development.delivered_emails
    end
  end
end

module Marten::SpecSpec
  class TestEmail < Marten::Email
    subject "Hello World!"
    to "test@example.com"

    def html_body
      "HTML body"
    end

    def text_body
      "Text body"
    end
  end
end

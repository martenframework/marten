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
end

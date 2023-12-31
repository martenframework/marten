require "./spec_helper"

describe Marten::Emailing::Email do
  describe "::backend" do
    it "returns nil by default" do
      Marten::Emailing::EmailSpec::EmailWithoutConfiguration.backend.should be_nil
    end

    it "returns the custom backend if one is configured" do
      Marten::Emailing::EmailSpec::EmailWithCustomBackend.backend.should eq(
        Marten::Emailing::EmailSpec::TEST_BACKEND
      )
    end
  end

  describe "::bcc" do
    it "allows to override the #bcc method as expected" do
      email_1 = Marten::Emailing::EmailSpec::EmailWithOverriddenBcc.new(nil)
      email_1.bcc.should be_nil

      email_2 = Marten::Emailing::EmailSpec::EmailWithOverriddenBcc.new("test@example.com")
      email_2.bcc.should eq [Marten::Emailing::Address.new("test@example.com")]

      email_3 = Marten::Emailing::EmailSpec::EmailWithOverriddenBcc.new(
        Marten::Emailing::Address.new("test@example.com")
      )
      email_3.bcc.should eq [Marten::Emailing::Address.new("test@example.com")]

      email_4 = Marten::Emailing::EmailSpec::EmailWithOverriddenBcc.new(["test1@example.com", "test2@example.com"])
      email_4.bcc.should eq(
        [Marten::Emailing::Address.new("test1@example.com"), Marten::Emailing::Address.new("test2@example.com")]
      )

      email_4 = Marten::Emailing::EmailSpec::EmailWithOverriddenBcc.new(
        [Marten::Emailing::Address.new("test1@example.com"), Marten::Emailing::Address.new("test2@example.com")])
      email_4.bcc.should eq(
        [Marten::Emailing::Address.new("test1@example.com"), Marten::Emailing::Address.new("test2@example.com")]
      )
    end
  end

  describe "::cc" do
    it "allows to override the #bcc method as expected" do
      email_1 = Marten::Emailing::EmailSpec::EmailWithOverriddenCc.new(nil)
      email_1.cc.should be_nil

      email_2 = Marten::Emailing::EmailSpec::EmailWithOverriddenCc.new("test@example.com")
      email_2.cc.should eq [Marten::Emailing::Address.new("test@example.com")]

      email_3 = Marten::Emailing::EmailSpec::EmailWithOverriddenCc.new(
        Marten::Emailing::Address.new("test@example.com")
      )
      email_3.cc.should eq [Marten::Emailing::Address.new("test@example.com")]

      email_4 = Marten::Emailing::EmailSpec::EmailWithOverriddenCc.new(["test1@example.com", "test2@example.com"])
      email_4.cc.should eq(
        [Marten::Emailing::Address.new("test1@example.com"), Marten::Emailing::Address.new("test2@example.com")]
      )

      email_5 = Marten::Emailing::EmailSpec::EmailWithOverriddenCc.new(
        [Marten::Emailing::Address.new("test1@example.com"), Marten::Emailing::Address.new("test2@example.com")])
      email_5.cc.should eq(
        [Marten::Emailing::Address.new("test1@example.com"), Marten::Emailing::Address.new("test2@example.com")]
      )
    end
  end

  describe "::from" do
    it "allows to override the #from method as expected" do
      email_1 = Marten::Emailing::EmailSpec::EmailWithOverriddenFrom.new("test@example.com")
      email_1.from.should eq Marten::Emailing::Address.new("test@example.com")

      email_2 = Marten::Emailing::EmailSpec::EmailWithOverriddenFrom.new(
        Marten::Emailing::Address.new("test@example.com")
      )
      email_2.from.should eq Marten::Emailing::Address.new("test@example.com")
    end
  end

  describe "::html_template_name" do
    it "returns nil by default" do
      Marten::Emailing::EmailSpec::EmailWithoutConfiguration.html_template_name.should be_nil
    end

    it "returns the HTML template name if one is configured" do
      Marten::Emailing::EmailSpec::SimpleEmail.html_template_name.should eq "specs/emailing/email/simple_email.html"
    end
  end

  describe "::reply_to" do
    it "allows to override the #reply_to method as expected" do
      email_1 = Marten::Emailing::EmailSpec::EmailWithOverriddenReplyTo.new("test@example.com")
      email_1.reply_to.should eq Marten::Emailing::Address.new("test@example.com")

      email_2 = Marten::Emailing::EmailSpec::EmailWithOverriddenReplyTo.new(
        Marten::Emailing::Address.new("test@example.com")
      )
      email_2.reply_to.should eq Marten::Emailing::Address.new("test@example.com")
    end
  end

  describe "::subject" do
    it "allows to override the #subject method as expected" do
      email = Marten::Emailing::EmailSpec::EmailWithOverriddenSubject.new("Hello World!")
      email.subject.should eq "Hello World!"
    end
  end

  describe "::template_name" do
    it "allows to set the HTML template name by default if no content type is specified" do
      Marten::Emailing::EmailSpec::SimpleEmail.html_template_name.should eq "specs/emailing/email/simple_email.html"
    end

    it "allows to set template names for specific content types" do
      Marten::Emailing::EmailSpec::SimpleEmailWithHtmlAndTextBody.html_template_name.should eq(
        "specs/emailing/email/simple_email.html"
      )
      Marten::Emailing::EmailSpec::SimpleEmailWithHtmlAndTextBody.text_template_name.should eq(
        "specs/emailing/email/simple_email.txt"
      )
    end
  end

  describe "::text_template_name" do
    it "returns nil by default" do
      Marten::Emailing::EmailSpec::EmailWithoutConfiguration.text_template_name.should be_nil
    end

    it "returns the text template name if one is configured" do
      Marten::Emailing::EmailSpec::SimpleEmailWithHtmlAndTextBody.text_template_name.should eq(
        "specs/emailing/email/simple_email.txt"
      )
    end
  end

  describe "::to" do
    it "allows to override the #to method as expected" do
      email_1 = Marten::Emailing::EmailSpec::EmailWithOverriddenTo.new("test@example.com")
      email_1.to.should eq [Marten::Emailing::Address.new("test@example.com")]

      email_2 = Marten::Emailing::EmailSpec::EmailWithOverriddenTo.new(
        Marten::Emailing::Address.new("test@example.com")
      )
      email_2.to.should eq [Marten::Emailing::Address.new("test@example.com")]

      email_3 = Marten::Emailing::EmailSpec::EmailWithOverriddenTo.new(["test1@example.com", "test2@example.com"])
      email_3.to.should eq(
        [Marten::Emailing::Address.new("test1@example.com"), Marten::Emailing::Address.new("test2@example.com")]
      )

      email_3 = Marten::Emailing::EmailSpec::EmailWithOverriddenTo.new(
        [Marten::Emailing::Address.new("test1@example.com"), Marten::Emailing::Address.new("test2@example.com")]
      )
      email_3.to.should eq(
        [Marten::Emailing::Address.new("test1@example.com"), Marten::Emailing::Address.new("test2@example.com")]
      )
    end
  end

  describe "#backend" do
    it "returns the default emailing backend by default" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.backend.should eq Marten.settings.emailing.backend
    end

    it "returns the specific email backend configured if any" do
      email = Marten::Emailing::EmailSpec::EmailWithCustomBackend.new
      email.backend.should eq Marten::Emailing::EmailSpec::TEST_BACKEND
    end
  end

  describe "#bcc" do
    it "returns nil by default" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.bcc.should be_nil
    end
  end

  describe "#cc" do
    it "returns nil by default" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.cc.should be_nil
    end
  end

  describe "#context" do
    it "returns an empty global context object" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.context.should be_a Marten::Template::Context
      email.context.empty?.should be_true
    end

    it "is memoized" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.context.object_id.should eq email.context.object_id
    end
  end

  describe "#deliver" do
    it "delivers the email using the configured backend" do
      email = Marten::Emailing::EmailSpec::EmailWithCustomBackend.new
      email.deliver

      Marten::Emailing::EmailSpec::TEST_BACKEND.delivered.includes?(email).should be_true
    end

    it "runs before_deliver and after_deliver callbacks as expected" do
      email = Marten::Emailing::EmailSpec::EmailWithCallbacks.new

      email.foo.should be_nil
      email.bar.should be_nil

      email.deliver

      email.foo.should eq "set_foo"
      email.bar.should eq "set_bar"
    end
  end

  describe "#from" do
    it "returns the default emailing from address by default" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.from.should eq Marten.settings.emailing.from_address
    end
  end

  describe "#headers" do
    it "return an empty hash by default" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.headers.should be_empty
    end

    it "returns custom headers" do
      email = Marten::Emailing::EmailSpec::EmailWithOverriddenHeaders.new
      email.headers.should eq({"foo" => "bar"})
    end
  end

  describe "#html_body" do
    it "returns nil by default if no template is configured" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.html_body.should be_nil
    end

    it "renders the specified template name by including the email details and custom variables in the context" do
      email = Marten::Emailing::EmailSpec::SimpleEmail.new
      email.html_body.not_nil!.strip.should eq "Hello World! This email is sent from webmaster@localhost! Foo: bar!"
    end

    it "does not run before_render callbacks if no template is configured" do
      email = Marten::Emailing::EmailSpec::EmailWithCallbacksWithoutTemplate.new

      email.xyz.should be_nil
      email.html_body.should be_nil
      email.xyz.should be_nil
    end

    it "runs before_render callbacks as expected" do
      email = Marten::Emailing::EmailSpec::EmailWithCallbacks.new

      email.xyz.should be_nil
      email.html_body.should_not be_nil
      email.xyz.should eq "set_xyz"
    end
  end

  describe "#html_template_name" do
    it "returns nil by default if no template is configured" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.html_template_name.should be_nil
    end

    it "returns the configured template name" do
      email = Marten::Emailing::EmailSpec::SimpleEmailWithHtmlAndTextBody.new
      email.html_template_name.should eq "specs/emailing/email/simple_email.html"
    end
  end

  describe "#reply_to" do
    it "returns nil by default" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.reply_to.should be_nil
    end
  end

  describe "#subject" do
    it "returns nil by default" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.subject.should be_nil
    end
  end

  describe "#text_body" do
    it "returns nil by default if no template is configured" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.text_body.should be_nil
    end

    it "renders the specified template name by including the email details and custom variables in the context" do
      email = Marten::Emailing::EmailSpec::SimpleEmailWithHtmlAndTextBody.new
      email.text_body.not_nil!.strip.should eq "Hello World! This email is sent from webmaster@localhost! Foo: bar!"
    end

    it "does not run before_render callbacks if no template is configured" do
      email = Marten::Emailing::EmailSpec::EmailWithCallbacksWithoutTemplate.new

      email.xyz.should be_nil
      email.text_body.should be_nil
      email.xyz.should be_nil
    end

    it "runs before_render callbacks as expected" do
      email = Marten::Emailing::EmailSpec::EmailWithCallbacks.new

      email.xyz.should be_nil
      email.text_body.should_not be_nil
      email.xyz.should eq "set_xyz"
    end
  end

  describe "#text_template_name" do
    it "returns nil by default if no template is configured" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.text_template_name.should be_nil
    end

    it "returns the configured template name" do
      email = Marten::Emailing::EmailSpec::SimpleEmailWithHtmlAndTextBody.new
      email.text_template_name.should eq "specs/emailing/email/simple_email.txt"
    end
  end

  describe "#to" do
    it "returns an empty array by default" do
      email = Marten::Emailing::EmailSpec::EmailWithoutConfiguration.new
      email.to.should be_empty
    end
  end
end

module Marten::Emailing::EmailSpec
  class TestBackend < Marten::Emailing::Backend::Base
    @delivered = [] of Marten::Emailing::Email

    getter delivered

    def deliver(email : Marten::Emailing::Email) : Nil
      @delivered << email
    end
  end

  TEST_BACKEND = TestBackend.new

  class EmailWithoutConfiguration < Marten::Emailing::Email
  end

  class SimpleEmail < Marten::Emailing::Email
    template_name "specs/emailing/email/simple_email.html"

    before_render :prepare_context

    def prepare_context
      context["foo"] = "bar"
    end
  end

  class SimpleEmailWithHtmlAndTextBody < Marten::Emailing::Email
    template_name "specs/emailing/email/simple_email.html", content_type: :html
    template_name "specs/emailing/email/simple_email.txt", content_type: :text

    before_render :prepare_context

    def prepare_context
      context["foo"] = "bar"
    end
  end

  class EmailWithCustomBackend < Marten::Emailing::Email
    backend TEST_BACKEND
  end

  class EmailWithOverriddenBcc < Marten::Emailing::Email
    @bcc : Array(Marten::Emailing::Address) | Array(String) | Marten::Emailing::Address | Nil | String

    bcc @bcc

    def initialize(@bcc)
    end
  end

  class EmailWithOverriddenCc < Marten::Emailing::Email
    @cc : Array(Marten::Emailing::Address) | Array(String) | Marten::Emailing::Address | Nil | String

    cc @cc

    def initialize(@cc)
    end
  end

  class EmailWithOverriddenFrom < Marten::Emailing::Email
    @from : Marten::Emailing::Address | String

    from @from

    def initialize(@from)
    end
  end

  class EmailWithOverriddenReplyTo < Marten::Emailing::Email
    @reply_to : Marten::Emailing::Address | String

    reply_to @reply_to

    def initialize(@reply_to)
    end
  end

  class EmailWithOverriddenSubject < Marten::Emailing::Email
    @subject : String

    subject @subject

    def initialize(@subject)
    end
  end

  class EmailWithOverriddenTo < Marten::Emailing::Email
    @to : Array(Marten::Emailing::Address) | Array(String) | Marten::Emailing::Address | String

    to @to

    def initialize(@to)
    end
  end

  class EmailWithOverriddenHeaders < Marten::Emailing::Email
    def headers
      {"foo" => "bar"}
    end
  end

  class EmailWithCallbacks < Marten::Emailing::Email
    property foo : String? = nil
    property xyz : String? = nil
    property bar : String? = nil

    template_name "specs/emailing/email/simple_email.html", content_type: :html
    template_name "specs/emailing/email/simple_email.txt", content_type: :text

    before_deliver :set_foo
    before_render :set_xyz
    after_deliver :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_xyz
      self.xyz = "set_xyz"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class EmailWithCallbacksWithoutTemplate < Marten::Emailing::Email
    property foo : String? = nil
    property xyz : String? = nil
    property bar : String? = nil

    before_deliver :set_foo
    before_render :set_xyz
    after_deliver :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_xyz
      self.xyz = "set_xyz"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end
end

require "./spec_helper"

describe Marten::Middleware::I18n do
  around_each do |t|
    original_i18n_config = I18n.config
    original_default_locale = Marten.settings.i18n.default_locale
    original_available_locales = Marten.settings.i18n.available_locales

    I18n.config = I18n::Config.new

    t.run

    Marten.settings.i18n.default_locale = original_default_locale
    Marten.settings.i18n.available_locales = original_available_locales
    I18n.config = original_i18n_config
    Marten.setup_i18n
  end

  describe "#call" do
    it "is able to activate the right locale for a simple tag" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, :fr]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "fr"
    end

    it "is able to activate the right locale for an unsupported tag whose base locale tag is supported" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, :fr]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr-CA,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "fr"
    end

    it "is able to activate the right locale for an unsupported tag if a similar tag is supported for the base tag" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, "fr-CA"]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr-FR,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "fr-CA"
    end

    it "properly uses the locale tag assigned to the greatest priority" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, :es, :fr]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr;q=0.2,en;q=0.5,es;q=0.7"}
          )
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "es"
    end

    it "fallbacks to the default locale if the locale is not supported at all" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, :fr]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "it-IT,it;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "en"
    end

    it "is able to activate the right locale in a case insensitive way" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, :fr]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "fr"
    end

    it "is able to activate the right locale fallbacked to the base tag in a case insensitive way" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, "FR"]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "FR"
    end

    it "is able to activate the right similar locale in a case insensitive way" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, "FR-CA"]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr-FR,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "FR-CA"
    end

    it "activates the right locale for a simple tag from the locale cookie" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, :fr]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "",
        headers: HTTP::Headers{"Host" => "example.com"}
      )
      request.cookies[Marten.settings.i18n.locale_cookie_name] = "fr"

      middleware.call(
        request,
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "fr"
    end

    it "activates the right locale for an unsupported tag whose base locale tag is supported from the locale cookie" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, :fr]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "",
        headers: HTTP::Headers{"Host" => "example.com"}
      )
      request.cookies[Marten.settings.i18n.locale_cookie_name] = "fr-CA"

      middleware.call(
        request,
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "fr"
    end

    it "activates the right locale for an unknown tag if a similar tag is supported for the base tag of the cookie" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, "fr-CA"]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "",
        headers: HTTP::Headers{"Host" => "example.com"}
      )
      request.cookies[Marten.settings.i18n.locale_cookie_name] = "fr-FR"

      middleware.call(
        request,
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "fr-CA"
    end

    it "ensures that the locale cookie value has precedence over the Accept-Language header value" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, :fr, :es]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "",
        headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "es,en;q=0.5"}
      )
      request.cookies[Marten.settings.i18n.locale_cookie_name] = "fr"

      middleware.call(
        request,
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "fr"
    end

    it "patches the Vary header accordingly" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, :fr]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      response = middleware.call(
        Marten::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr,en;q=0.5"}
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "fr"
      response.headers[:VARY].should eq "Accept-Language"
    end

    it "sets the Content-Language header with the activated locale" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, :fr]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      response = middleware.call(
        Marten::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr,en;q=0.5"}
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      I18n.locale.should eq "fr"
      response.headers["Content-Language"].should eq "fr"
    end

    it "does not override the Content-Language header if it was already set in the response" do
      Marten.settings.i18n.default_locale = :en
      Marten.settings.i18n.available_locales = [:en, :fr]
      Marten.setup_i18n

      middleware = Marten::Middleware::I18n.new

      response = middleware.call(
        Marten::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr,en;q=0.5"}
        ),
        ->{
          r = Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          r.headers["Content-Language"] = "es"
          r
        }
      )

      I18n.locale.should eq "fr"
      response.headers["Content-Language"].should eq "es"
    end
  end
end

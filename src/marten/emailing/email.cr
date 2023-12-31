require "./email/callbacks"

module Marten
  module Emailing
    # Abstract base email class.
    #
    # This class holds the definition of a single email. It is supposed to be subclassed and each subclass is
    # responsible for defining how it should be initialized, the email properties, and how it should be rendered (for
    # example, using a specific HTML template).
    abstract class Email
      include Callbacks

      @context : Template::Context? = nil
      @headers = {} of String => String

      # Returns the specific backend to use for this email.
      #
      # A `nil` value indicate that the default backend will be used.
      class_getter backend : Backend::Base?

      # Returns the configured HTML body template name.
      class_getter html_template_name : String?

      # Returns the configured text body template name.
      class_getter text_template_name : String?

      # Allows to set the specific backend to use for this email.
      def self.backend(backend : Backend::Base) : Nil
        @@backend = backend
      end

      # Allows to configure the template that should be rendered when generating the body of the email.
      def self.template_name(
        template_name : String?,
        content_type : ContentType | String | Symbol = ContentType::HTML
      ) : Nil
        content_type = content_type.is_a?(ContentType) ? content_type : ContentType.parse(content_type.to_s)

        @@html_template_name = template_name if content_type.html?
        @@text_template_name = template_name if content_type.text?
      end

      # Returns the emailing backend to use in order to send this email.
      def backend
        self.class.backend || Marten.settings.emailing.backend
      end

      # Returns the email addresses the email should be BBC'ed to.
      def bcc : Array(Address)?
      end

      # Returns the email addresses the email should be CC'ed to.
      def cc : Array(Address)?
      end

      # Returns the global template context.
      #
      # This context object can be mutated for the lifetime of the email in order to define which variables will be
      # made available to the template runtime when rendering the email body.
      def context
        @context ||= Marten::Template::Context.new
      end

      # Delivers the email.
      def deliver
        run_before_deliver_callbacks
        result = backend.deliver(self)
        run_after_deliver_callbacks
        result
      end

      # Returns the sender email address.
      def from : Address
        Marten.settings.emailing.from_address
      end

      # Returns the headers to set on the email.
      def headers : Hash(String, String)
        @headers
      end

      # Returns the HTML body.
      def html_body : String?
        return if html_template_name.nil?

        render_template(html_template_name.not_nil!)
      end

      # Returns the template name that should be used to render the HTML body.
      def html_template_name : String?
        self.class.html_template_name
      end

      # Returns the reply-to email address.
      def reply_to : Address?
      end

      # Returns the subject of the email.
      def subject : String?
      end

      # Returns the text body.
      def text_body : String?
        return if text_template_name.nil?

        render_template(text_template_name.not_nil!)
      end

      # Returns the template name that should be used to render the text body.
      def text_template_name : String?
        self.class.text_template_name
      end

      # Returns an array of recipient email addresses.
      def to : Array(Address)
        [] of Address
      end

      # Allows to define the email addresses the email should be BBC'ed to.
      macro bcc(value)
        def bcc : Array(Marten::Emailing::Address)?
          if (v = {{ value }}).nil?
            return
          else
            normalize(v)
          end
        end
      end

      # Allows to define the email addresses the email should be BC'ed to.
      macro cc(value)
        def cc : Array(Marten::Emailing::Address)?
          if (v = {{ value }}).nil?
            return
          else
            normalize(v)
          end
        end
      end

      # Allows to define the sender email address.
      macro from(value)
        def from : Marten::Emailing::Address
          normalize({{ value }}).first
        end
      end

      # Allows to define the reply-to email address.
      macro reply_to(value)
        def reply_to : Marten::Emailing::Address
          normalize({{ value }}).first
        end
      end

      # Allows to define the subject of the email.
      macro subject(value)
        def subject : String
          {{ value }}
        end
      end

      # Allows to define the email addresses of the recipients of the email.
      macro to(value)
        def to : Array(Marten::Emailing::Address)
          normalize({{ value }})
        end
      end

      private def normalize(value : Array(Address) | Array(String) | Address | String) : Array(Address)
        case value
        when Array(Address)
          value
        when Array(String)
          value.map { |v| Address.new(v) }
        when Address
          [value]
        else
          [Address.new(value.as(String))]
        end
      end

      private def render_template(template_name)
        context[:email] = self
        run_before_render_callbacks

        Marten.templates.get_template(template_name).render(context)
      end
    end
  end
end

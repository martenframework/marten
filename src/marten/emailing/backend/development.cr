module Marten
  module Emailing
    module Backend
      # A development emailing backend that outputs details of delivered emails.
      class Development < Base
        class_getter delivered_emails = [] of Email

        getter? print_emails

        delegate delivered_emails, to: self.class

        def initialize(@print_emails = false, @collect_emails = true, @stdout : IO = STDOUT)
        end

        def deliver(email : Email) : Nil
          @@delivered_emails << email if collect_emails?

          return unless print_emails?

          parts = [] of String

          parts << "From: #{email.from}"
          parts << "To: #{email.to.join(", ")}"

          if !(cc = email.cc).nil?
            parts << "CC: #{cc.join(", ")}"
          end

          if !(bcc = email.bcc).nil?
            parts << "BCC: #{bcc.join(", ")}"
          end

          if !(reply_to = email.reply_to).nil?
            parts << "Reply-To: #{reply_to}"
          end

          parts << "Subject: #{email.subject}"
          parts << "Headers: #{email.headers}" unless email.headers.empty?

          if !(text = email.text_body).nil?
            parts << "---------- TEXT ----------"
            parts << text
          end

          if !(html = email.html_body).nil?
            parts << "---------- HTML ----------"
            parts << html
          end

          stdout.print(parts.join('\n'))
        end

        private getter stdout
        private getter? collect_emails
      end
    end
  end
end

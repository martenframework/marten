module Marten
  module HTTP
    class Status
      class UnrecognizedStatusException < Exception
      end

      def self.status_code(status = Int32 | Symbol) : Int32
        if status.is_a?(Int32)
          return status
        end

        # https://crystal-lang.org/api/1.9.2/HTTP/Status.html
        case status
        when :continue
          100
        when :switching_protocols
          101
        when :processing
          102
        when :early_hints
          103
        when :ok
          200
        when :created
          201
        when :accepted
          202
        when :non_authoritative_information
          203
        when :no_content
          204
        when :reset_content
          205
        when :partial_content
          206
        when :multi_status
          207
        when :already_reported
          208
        when :im_used
          226
        when :multiple_choices
          300
        when :move_permanently
          301
        when :found
          302
        when :see_other
          303
        when :not_modified
          304
        when :use_proxy
          305
        when :switch_proxy
          306
        when :temporary_redirect
          307
        when :permanent_redirect
          308
        when :bad_request
          400
        when :unauthorized
          401
        when :payment_required
          402
        when :forbidden
          403
        when :not_found
          404
        when :method_not_allowed
          405
        when :not_acceptable
          406
        when :proxy_authentication_required
          407
        when :requet_timeout
          408
        when :confict
          409
        when :gone
          410
        when :length_required
          411
        when :precondition_failed
          412
        when :payload_too_large
          413
        when :uri_too_long
          414
        when :unsupported_media_type
          415
        when :range_not_satisfiable
          416
        when :expectation_failed
          417
        when :im_a_teapot
          418
        when :misdirected_request
          421
        when :unprocessable_entry
          422
        when :locked
          423
        when :failed_dependency
          424
        when :upgrade_required
          426
        when :precondition_required
          428
        when :too_many_requests
          429
        when :request_header_fields_too_large
          431
        when :unavailable_for_legal_reasons
          451
        when :internal_server_error
          500
        when :not_implemented
          501
        when :bad_gateway
          502
        when :service_unavailable
          503
        when :gateway_timeout
          504
        when :http_version_not_supported
          505
        when :variant_also_negotiates
          506
        when :insufficient_storage
          507
        when :loop_detected
          508
        when :not_extended
          510
        when :network_authentication_required
          511
        else
          raise UnrecognizedStatusException.new
        end
      end
    end
  end
end

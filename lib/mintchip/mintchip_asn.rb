require 'mintchip/asn'

module Mintchip
  class MintchipASN < ASN

    # AssetStoreIdentifier ::= OCTET STRING (SIZE(8))
    # DateTime ::= OCTET STRING(SIZE(3))
    # Challenge ::= OCTET STRING(SIZE(4))
    # Value ::= OCTET STRING (SIZE(3))
    # CurrencyCode ::= OCTET STRING (SIZE(1))
    octet_string :asset_store_identifier, size: 8
    octet_string :date_time, size: 3
    octet_string :challenge, size: 4
    octet_string :value, size: 3
    octet_string :currency_code, size: 1

    # ValueMessage ::= SEQUENCE {
    #         secure-element-version      OCTET STRING(SIZE(1)),
    #         payer-id                 AssetStoreIdentifier ,
    #         payee-id                 AssetStoreIdentifier ,
    #         currency                 CurrencyCode ,
    #         value                    Value , 
    #         challenge                Challenge ,
    #         datetime                 DateTime,
    #         tac                      OCTET STRING(SIZE(24)) ,
    #         signature                OCTET STRING (SIZE(128))
    #          
    #     -- Pending Issue: Signature is currently on raw concatenated 
    #      
    #     -- value-message fields before DER encoding.
    # }
    sequence :value_message do
      octet_string :secure_element_version, size: 1
      asset_store_identifier :payer_id
      asset_store_identifier :payee_id
      currency_code :currency
      value :value
      challenge :challenge
      date_time :datetime
      octet_string :tac, size: 24
      octet_string :signature, size: 128
    end

    # ValueMessageRequest ::= SEQUENCE {
    #            payee-id                AssetStoreIdentifier,    
    #            currency                CurrencyCode,
    #               value                Value,
    #        include-cert                BOOLEAN,
    #        response-url                IA5String,
    #           Challenge                [0] IMPLICIT Challenge OPTIONAL  
    # }
    sequence :value_message_request do
      asset_store_identifier :payee_id
      currency_code :currency
      value :value
      boolean :include_cert
      ia5string :response_url
      challenge :challenge, tag: 0, tagging: :IMPLICIT
    end

    # ValueMessageResponse ::= SEQUENCE {
    #  
    #         value-message   ValueMessage
    #         payer-cert      [0] IMPLICIT Certificate OPTIONAL -- imported TYPE
    #          
    # }
    sequence :value_message_response do
      value_message :value_message
      #?????? Imported type
    end

    # AuthenticationRequest ::= SEQUENCE {
    #         requestor-id            AssetStoreIdentifier,
    #         challenge               Challenge,
    #         response-url            IA5String
    # }
    sequence :authentication_request do
      asset_store_identifier :requestor_id
      challenge :challenge
      ia5string :response_url
    end

    # AuthenticationResponse ::= SEQUENCE {
    #         zero-value-message      ValueMessage,
    #         cert                    [0] IMPLICIT Certificate OPTIONAL
    # }
    sequence :authentication_response do
      value_message :zero_value_message
      #?????? Imported type
    end

    # MessagePacket ::= [APPLICATION 0] SEQUENCE {
    #  
    #         version                 [0] ENUMERATED {v1(1),v2(2)} DEFAULT v1,          
    #         annotation              [1] IA5String OPTIONAL,
    #         packet                  [2] EXPLICIT CHOICE {   
    #          
    #                 auth-req        [0]         AuthenticationRequest,
    #                 vm-req          [1]         ValueMessageRequest,
    #                 auth-resp       [10]        AuthenticationResponse,
    #                 vm-resp         [11]        ValueMessageResponse
    #     }
    # }
    sequence :message_packet do
      enumerated :version, [1,2], tag: 0
      ia5string :annotation, tag: 1
      choice :packet, tag: 2, tagging: :EXPLICIT do
        authentication_request :auth_req, tag: 0
        value_message_request :vm_req, tag: 1
        authentication_response :auth_resp, tag: 10
        value_message_response :vm_resp, tag: 11
      end
    end

  end
end

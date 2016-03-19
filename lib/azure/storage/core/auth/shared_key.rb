#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# The MIT License(MIT)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files(the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions :

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#--------------------------------------------------------------------------
require 'cgi'
require 'azure/storage/core/auth/signer'

module Azure::Storage
  module Auth
    class SharedKey < Azure::Core::Auth::Signer
      # The Azure account's name.
      attr :account_name

      # Initialize the Signer.
      #
      # @param account_name [String] The account name. Defaults to the one in the
      #                global configuration.
      # @param access_key   [String] The access_key encoded in Base64. Defaults to the
      #                one in the global configuration.
      def initialize(account_name=Azure::Storage.config.storage_account_name, access_key=Azure::Storage.config.storage_access_key)
        @account_name = account_name
        super(access_key)
      end

      # The name of the strategy.
      #
      # @return [String]
      def name
        'SharedKey'
      end

      # Create the signature for the request parameters
      #
      # @param method     [Symbol] HTTP request method.
      # @param uri        [URI] URI of the request we're signing.
      # @param headers    [Hash] HTTP request headers.
      #
      # @return           [String] base64 encoded signature
      def sign(method, uri, headers)
        "#{account_name}:#{super(signable_string(method, uri, headers))}"
      end

      # Sign the request
      #
      # @param req    [Azure::Core::Http::HttpRequest] HTTP request to sign
      #
      # @return       [Azure::Core::Http::HttpRequest]
      def sign_request(req)
        req.headers['Authorization'] = "#{name} #{sign(req.method, req.uri, req.headers)}"
        req
      end

      # Generate the string to sign.
      #
      # @param method     [Symbol] HTTP request method.
      # @param uri        [URI] URI of the request we're signing.
      # @param headers    [Hash] HTTP request headers.
      #
      # @return [String]
      def signable_string(method, uri, headers)
        [
          method.to_s.upcase,
          headers.fetch('Content-Encoding', ''),
          headers.fetch('Content-Language', ''),
          headers.fetch('Content-Length', '').sub(/^0+/,''), # from 2015-02-21, if Content-Length == 0, it won't be signed
          headers.fetch('Content-MD5', ''),
          headers.fetch('Content-Type', ''),
          headers.fetch('Date', ''),
          headers.fetch('If-Modified-Since', ''),
          headers.fetch('If-Match', ''),
          headers.fetch('If-None-Match', ''),
          headers.fetch('If-Unmodified-Since', ''),
          headers.fetch('Range', ''),
          canonicalized_headers(headers),
          canonicalized_resource(uri)
        ].join("\n")
      end

      # Calculate the Canonicalized Headers string for a request.
      #
      # @param headers    [Hash] HTTP request headers.
      #
      # @return [String] a string with the canonicalized headers.
      def canonicalized_headers(headers)
        headers = headers.map { |k,v| [k.to_s.downcase, v] }
        headers.select! { |k,v| k =~ /^x-ms-/ }
        headers.sort_by! { |(k,v)| k }
        headers.map! { |k,v| '%s:%s' % [k, v] }
        headers.map! { |h| h.gsub(/\s+/, ' ') }.join("\n")
      end

      # Calculate the Canonicalized Resource string for a request.
      #
      # @param uri        [URI] URI of the request we're signing.
      #
      # @return           [String] a string with the canonicalized resource.
      def canonicalized_resource(uri)
        resource = '/' + account_name + (uri.path.empty? ? '/' : uri.path)
        params = CGI.parse(uri.query.to_s).map { |k,v| [k.downcase, v] }
        params.sort_by! { |k,v| k }
        params.map! { |k,v| '%s:%s' % [k, v.map(&:strip).sort.join(',')] }
        [resource, *params].join("\n")
      end
    end
  end
end

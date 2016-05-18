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

module Azure::Storage::Core
  module HttpClient
    # Returns the http agent based on uri
    # @param uri  [URI|String] the base uri (scheme, host, port) of the http endpoint
    # @return [Net::HTTP] http agent for a given uri
    def agents(uri)
      key = uri.to_s
      @agents ||= {}
      unless @agents.key?(key)
        @agents[key] = build_http(uri)
      end
      @agents[key]
    end

    # Empties all the http agents
    def reset_agents!
      @agents = nil
    end

    private

    def build_http(uri)
      ssl_options = {}
      if uri.is_a?(URI) && uri.scheme.downcase == 'https'
        ssl_options[:ca_file] = self.ca_file if self.ca_file
        ssl_options[:verify] = true
      end
      proxy_options = if ENV['HTTP_PROXY']
                        URI::parse(ENV['HTTP_PROXY'])
                      elsif ENV['HTTPS_PROXY']
                        URI::parse(ENV['HTTPS_PROXY'])
                      end || nil
      Faraday.new(uri, ssl: ssl_options, proxy: proxy_options) do |conn|
        conn.use FaradayMiddleware::FollowRedirects
        conn.adapter Faraday.default_adapter
      end
    end
  end
end
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
require 'azure/storage/service/serialization'

module Azure::Storage
  module File
    module Serialization
      include Service::Serialization

      def self.share_enumeration_results_from_xml(xml)
        xml = slopify(xml)
        expect_node("EnumerationResults", xml)

        results = enumeration_results_from_xml(xml, Azure::Service::EnumerationResults.new)
        
        return results unless (xml > "Shares").any? && ((xml > "Shares") > "Share").any?

        if xml.Shares.Share.count == 0
          results.push(share_from_xml(xml.Shares.Share))
        else
          xml.Shares.Share.each { |share_node|
            results.push(share_from_xml(share_node))
          }
        end

        results
      end

      def self.share_from_xml(xml)
        xml = slopify(xml)
        expect_node("Share", xml)

        Share::Share.new do |share|
          share.name = xml.Name.text if (xml > "Name").any?
          share.properties = share_properties_from_xml(xml.Properties) if (xml > "Properties").any?
          share.metadata = metadata_from_xml(xml.Metadata) if (xml > "Metadata").any?
        end
      end

      def self.share_properties_from_xml(xml)
        xml = slopify(xml)
        expect_node("Properties", xml)

        props = {}
        props[:last_modified] = (xml > "Last-Modified").text if (xml > "Last-Modified").any?
        props[:etag] = xml.ETag.text if (xml > "ETag").any?
        props[:quota] = xml.Quota.text if (xml > "Quota").any?
        props
      end

      def self.share_from_headers(headers)
        Share::Share.new do |share|
          share.properties = share_properties_from_headers(headers)
          share.quota = quota_from_headers(headers)
          share.metadata = metadata_from_headers(headers)
        end
      end

      def self.share_properties_from_headers(headers)
        props = {}
        props[:last_modified] = headers["Last-Modified"] 
        props[:etag] = headers["ETag"]
        props
      end

      def self.quota_from_headers(headers)
        headers["x-ms-share-quota"] ? headers["x-ms-share-quota"].to_i : nil
      end

      def self.share_stats_from_xml(xml)
        xml = slopify(xml)
        expect_node("ShareStats", xml)
        xml.ShareUsage.text.to_i
      end

      def self.directories_and_files_enumeration_results_from_xml(xml)
        xml = slopify(xml)
        expect_node("EnumerationResults", xml)

        results = enumeration_results_from_xml(xml, Azure::Service::EnumerationResults.new)

        return results unless (xml > "Entries").any?

        if ((xml > "Entries") > "File").any?
          if xml.Entries.File.count == 0
            results.push(file_from_xml(xml.Entries.File))
          else
            xml.Entries.File.each { |file_node|
              results.push(file_from_xml(file_node))
            }
          end
        end

        if ((xml > "Entries") > "Directory").any?
          if xml.Entries.Directory.count == 0
            results.push(directory_from_xml(xml.Entries.Directory))
          else
            xml.Entries.Directory.each { |directory_node|
              results.push(directory_from_xml(directory_node))
            }
          end
        end

        results
      end

      def self.file_from_xml(xml)
        xml = slopify(xml)
        expect_node("File", xml)

        File.new do |file|
          file.name = xml.Name.text if (xml > "Name").any?
          file.properties = file_properties_from_xml(xml.Properties) if (xml > "Properties").any?
        end
      end

      def self.file_properties_from_xml(xml)
        xml = slopify(xml)
        expect_node("Properties", xml)

        props = {}
        props[:content_length] = (xml > "Content-Length").text.to_i if (xml > "Content-Length").any?
        props
      end

      def self.directory_from_xml(xml)
        xml = slopify(xml)
        expect_node("Directory", xml)

        Directory::Directory.new do |directory|
          directory.name = xml.Name.text if (xml > "Name").any?
        end
      end

      def self.directory_from_headers(headers)
        Directory::Directory.new do |directory|
          directory.properties = directory_properties_from_headers(headers)
          directory.metadata = metadata_from_headers(headers)
        end
      end

      def self.directory_properties_from_headers(headers)
        props = {}
        props[:last_modified] = headers["Last-Modified"] 
        props[:etag] = headers["ETag"]
        props
      end

      def self.file_from_headers(headers)
        File.new do |file|
          file.properties = file_properties_from_headers(headers)
          file.metadata = metadata_from_headers(headers)
        end
      end

      def self.file_properties_from_headers(headers)
        props = {}

        props[:last_modified] = headers["Last-Modified"]
        props[:etag] = headers["ETag"]
        props[:type] = headers["x-ms-type"]

        props[:content_length] = headers["Content-Length"].to_i unless headers["Content-Length"].nil?
        props[:content_length] = headers["x-ms-content-length"].to_i unless headers["x-ms-content-length"].nil?
  
        props[:content_type] =  headers["Content-Type"]
        props[:content_encoding] = headers["Content-Encoding"]
        props[:content_language] = headers["Content-Language"]
        props[:content_disposition] = headers["Content-Disposition"]
        props[:content_md5] = headers["Content-MD5"]
        props[:cache_control] = headers["Cache-Control"]

        props[:copy_id] = headers["x-ms-copy-id"]
        props[:copy_status] = headers["x-ms-copy-status"]
        props[:copy_source] = headers["x-ms-copy-source"]
        props[:copy_progress] = headers["x-ms-copy-progress"]
        props[:copy_completion_time] = headers["x-ms-copy-completion-time"]
        props[:copy_status_description] = headers["x-ms-copy-status-description"]

        props[:accept_ranges] = headers["Accept-Ranges"].to_i if headers["Accept-Ranges"]

        props
      end

      def self.range_list_from_xml(xml)
        xml = slopify(xml)
        expect_node("Ranges", xml)

        range_list = []
        return range_list unless (xml > "Range").any?

        if xml.Range.count == 0
          range_list.push [xml.Range.Start.text.to_i, xml.Range.End.text.to_i]
        else
          xml.Range.each { |range|
            range_list.push [range.Start.text.to_i, range.End.text.to_i]
          }
        end

        range_list
      end
    end
  end
end

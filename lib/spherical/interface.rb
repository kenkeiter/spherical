# Copyright (C) 2011 Red Hat, Inc.
# Written by Ken Keiter <kenkeiter@redhat.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.
#
# Author:: Kenneth Keiter (mailto:ken@kenkeiter.com)
# Copyright:: Copyright (C) 2011 Red Hat, Inc.
# License:: Distributed under GPLv2

module Spherical
  
  class Interface
    
    # Create a new Interface instance which will attach to a vSphere or 
    # ESX/i endpoint on behalf of a Host instance. Accepts a +host_inst+ 
    # instance which will be passed as a root object to all instances 
    # instantiated as the result of requests, and an endpoint which to 
    # connect to.  
    #
    # <tt>my_interface = Interface.new(host, 'https://vsphere.example.com/sdk')</tt>
    def initialize(host_inst, endpoint)
      @host = host_inst
      @client = Savon::Client.new do
        wsdl.document = Spherical::WSDL_PATH
        wsdl.endpoint = endpoint
        wsdl.namespace = 'urn:vim25'
        http.auth.ssl.verify_mode = :none # no local issuer cert support
      end
    end
    
    # Determine if +sym+ can be invoked on the remote interface. Returns boolean.
    def supports_request?(sym)
      @client.wsdl.soap_actions.include?(sym)
    end
    
    # Coerce a structured hash to XML via a provided Builder instance, with 
    # native support for coercions of Managed Object References.
    #
    # The following rules apply when converting hashes to XML:
    # * If any hash value is a managed reference of any type, it will be 
    #   automatically converted to XML as a +ManagedObjectReference+. The key 
    #   that it is associated with will become the name of the tag.
    #   
    #   <tt>{:obj => my_folder}</tt> becomes 
    #   <tt><vim25:obj xsi:type="vim25:ManagedObjectReference">Folder-0</vim25:obj></tt>
    #
    # * Hashes can optionally contain two special keys: +content!+ and 
    #   +attributes!+. These allow finer grained control of the output by 
    #   allowing you to specify tag attributes, and when content should be 
    #   taken literally rather than being subject to coercion. If no 
    #   +:content!+ key is provided, keys will be represented as tags, and 
    #   coerced recursively.
    #   
    #   <tt>{:name => 'ken', :age => 10}</tt> becomes 
    #   <tt><vim25:name>ken</vim25:name><vim25:age>10</vim25:age></tt>
    #
    # * Hash values for which an array is provided will be converted to a 
    #   set of tags whose names match the key pointing to the array.
    #   
    #   <tt>{:name => ['ken', 'tigger']}</tt> becomes
    #   <tt><vim25:name>ken</vim25:name><vim25:name>tigger</vim25:name></tt>
    def coerce_to_xml(xml, params)
      return nil if params.empty?
      params.each do |key, val|

        case
        when val.kind_of?(ManagedReference)
          tag = [val.id, {'type' => val.type, 'xsi:type' => 'vim25:ManagedObjectReference'}]
          key.eql?(:this!) ? tag.insert(0, :_this) : tag.insert(0, key)
          xml.vim25(*tag)
        
        when val.kind_of?(Hash)
          content = val.pull(:content!, nil)
          attributes = val.pull(:attributes!, nil)
          if content.nil? # val *is* the content
            xml.vim25(key.to_sym, *attributes) do
              coerce_to_xml(xml, val)
            end
          else
            xml.vim25(key.to_sym, content, *attributes)
          end

        when val.kind_of?(Array)
          xml.vim25(key.to_sym) do
            val.each do |item|
              coerce_to_xml(xml, item)
            end
          end

        else # any normal type
          xml.vim25(key.to_sym, *val)
        end

      end
    end
    
    # Perform a request on the API endpoint using SOAP protocol. Accepts the 
    # following arguments:
    # 
    # +sym+:: Remote method name as a symbol converted to underscore format
    #         rather than camelCase.
    # +params+:: Request parameters which will be coerced to XML 
    #            using the coerce_to_xml method.
    # +&block+:: An optional block which allows you to build requests by 
    #            directly accessing the Builder instance and the remainder of 
    #            the Savon API.
    #
    # The first <tt><returnval></tt> tag typically contains the response from 
    # the server, so it is eliminated, and its contents are converted to 
    # native objects (by way of XmlSimple) and are further coerced and 
    # simplified by the response_to_native method. If a single result is 
    # returned, it is converted to an OpenStruct object with a special method 
    # called <tt>_hash</tt> that allows direct access to the original data 
    # structure. If multiple results are returned, they are converted to an 
    # array of OpenStructs, each with a <tt>_hash</tt> method. 
    #
    # SoapFault exceptions will be raised automatically when making requests.
    def request(sym, params = {}, &block)
      response = @client.request(:vim25, sym) do |soap, wsdl, http, wsse|
        soap.xml do |xml|
          xml.env(:Envelope, Spherical::SOAP_NS){
            xml.env(:Body){
              xml.vim25(sym){
                coerce_to_xml(xml, params)
                block.call(xml, soap, wsdl, http, wsse) if block_given?
              } # method call
            } # env :Body
          } # envelope
        end
      end
      raw_hash = XmlSimple.xml_in(response.to_xml, { 'KeyAttr' => ['key', 'id'], 'ForceArray' => false })
      result = raw_hash.value_at_first('returnval') # hack to find deeply nested response.
      native = response_to_native(result)
      case
      when native.kind_of?(Hash)
        return native.to_ostruct
      when native.kind_of?(Array)
        return native.map!{|o| o.to_ostruct }
      end
    end
    
    #######
    private
    #######
    
    # Coerce a response to a native data structure, recursively.
    def response_to_native(structure)
      case
      when structure.kind_of?(Hash)
        if structure.has_key?('type') or structure.has_key?('xsi:type') # it's an object
          type = structure['type'] || structure['xsi:type']
          if type =~ /^ArrayOf/
            type.sub!(/^ArrayOf/, '') # get class name.
            return structure.has_key?(type) ? response_to_native(structure[type]) : []
          else
            structure.delete('type'); structure.delete('xsi:type')
            return coerce_to_native(type, response_to_native(structure))
          end
        else # it's a hash, possibly containing objects.
          out = {}
          structure.each do |key, value|
            out[key] = response_to_native(value) # Value at key is not an object.
          end
          return out
        end
      when structure.kind_of?(Array)
        structure.map do |item|
          response_to_native(item)
        end
      else
        structure
      end
    end
    
    # Coerce a single value to a native object, or a ManagedReference.
    def coerce_to_native(type, options = {})
      xsd_coercion = Spherical::XSD_NATIVE_COERCIONS[type]
      return xsd_coercion.call(options['content']) unless xsd_coercion.nil?
      ManagedReference.build(@host, type.to_sym, options['content'], options)
    end
    
  end
  
end
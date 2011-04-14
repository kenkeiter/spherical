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
  
  # ManagedReference provides an abstraction layer for managing VMware 
  # ManagedObjectReferences. The VMware SOAP API provides client-side access 
  # to "object-oriented" server-side resources (within the context of the 
  # session) by returning references to those objects, upon which SOAP 
  # methods can be called, properties can be retrieved, etc.
  #
  # ManagedReferences are identified by an ID string that is unique per 
  # type and vSphere installation. ManagedReference tracks all 
  # ManagedObjectReferences, and provides common mechanisms for access to 
  # properties, structure traversal, and dynamic typing. In addition, 
  # ManagedReference can be subclassed to extend Ruby functionality for 
  # specific ManagedObjectReference types.
  #
  # Ruby classes are dynamically defined for each ManagedObjectReference type 
  # as they are instantiated and returned to the client. This means that, 
  # even if ManagedReference hasn't been subclassed for a specific type (i.e. 
  # that type has been defined), returned ManagedObjectReferences will still 
  # behave as objects in Ruby -- methods can be called on them, properties 
  # can be accessed, etc.
  
  class ManagedReference
    
    @@types = {} # type registry
    
    class << self
      
      # Clear all existing types (primarily for testing purposes)
      def clear_all!
        @@types = {}
      end
      
      # Instantiate a new instance of a given type with: 
      # +host+:: Host instance against which requests can be made 
      # +type_sym+:: a Symbol of the name of the type, such as +:VirtualMachine+
      # +id+:: the server-side ID of the object
      # +attrs+:: a hash of any attributes that the instance should provide 
      #           accessors for upon instantiation
      # 
      # Will return a new instance of the equivalent Ruby class for +type_sym+.
      def build(host, type, id, attrs = {})
        raise 'Type must be Symbol.' unless type.kind_of?(Symbol)
        klass = type_defined?(type) ? @@types[type] : Class.new(self).represent_managed(type)
        klass.new(host, id).apply_attributes(attrs) # instantiate instance
      end
      
      # When defining a subclass of ManagedReference, specifiy the type that
      # the new ManagedReference suclass should represent (DSL style). 
      # When called, this method will define a +type+ method in the type's 
      # Ruby class equivalent.
      def represent_managed(type)
        raise 'Type must be Symbol.' unless type.kind_of?(Symbol)
        meta = class << self; self; end
        meta.send(:define_method, :type){ type.to_sym }
        @@types[type] = self
        return self
      end
      
      # property_reader is a DSL-style method that can be called upon any 
      # type's class to define optionally-memoizing server-side property 
      # reader methods. This is the equivalent of +attr_reader+, with the 
      # exception that it provides optional memoization of the results.
      # 
      # If property_reader is called with an array of property names, those 
      # properties will be fetched (and optionally memoized) *simultaneously* 
      # in a single call when any of their accessor methods are called.
      # 
      #   class RandomManagedObject < ManagedReference
      #     represent_managed :RandomManagedObject
      #     property_reader ['someRandomProperty', 'summary'], :memoize => true
      #   end
      #
      # In the above example, two accessor methods ()+some_random_property+ 
      # and +summary+) are defined which provide access to the values of 
      # those properties. When either of those accessors are called for the 
      # first time, both properties are fetched from the server in the same 
      # request, and memoized (cached) for that object.
      #
      # Note that +property_names+ must be provided as strings. The accessor 
      # method names will be the underscore version of the +property_names+,
      # such that <tt>'somePropertyName' => obj.some_property_name</tt>.
      #
      # If memoization is not enabled, the property will be requested from 
      # the server each time the method is called!
      def property_reader(props, opts = {})
        opts = {:memoize => false}.merge!(opts)
        props = props.kind_of?(Array) ? props : [props] # coerce to array    
        props.each do |prop|
          accessor_name = prop.to_s.underscore.to_sym # camelcase to underscore
          define_method(accessor_name) do
            if !opts[:memoize] or !@attributes.has_key?(accessor_name)
              collect(*props).each{ |k, v| @attributes[k.to_s.underscore.to_sym] = v }
            end
            @attributes[accessor_name]
          end
        end
      end
      
      # Return bool indicating if a corresponding Ruby class has been created 
      # (either by subclassing, or anonymously/dynamically) for the given 
      # type name.
      def type_defined?(type)
        raise 'Type must be Symbol.' unless type.kind_of?(Symbol)
        @@types.include? type
      end
      
    end
    
    attr_accessor :id
    attr_reader :attributes
    
    # Initialize a new ManagedReference instance. This should only be called 
    # on ManagedReference subclasses. Note that if a ManagedReference subclass
    # overloads this method, it should still call <tt>super(*opts)</tt>,
    # otherwise it will not be properly initialized and fail miserably.
    def initialize(host, id, *opts)
      @host, @id, @opts = host, id, opts
      @attributes = {}
    end
    
    # Make a SOAP request to this instance's Host, against this 
    # ManagedReference's server-side object. Allows for request parameters to 
    # be provided as a complex hash, or the request may be fine-tuned with 
    # specific headers or security parameters, and custom-built XML using 
    # Builder. Accepts the following arguments:
    #
    # +sym+:: The underscore version of the camelCase method name to be called
    # +params+:: (optional when block is given) accepts a complex hash of 
    #            parameters encoded by Interface#coerce_to_xml. Note that 
    #            the managed object reference (<tt><_this></tt>) is always 
    #            automatically added to requests, regardless of whether 
    #            params or a block are given.
    # +&block+:: A block accepting the following parameters may be provided 
    #            so that the request may be built manually: 
    #            <tt>|xml, soap, wsdl, http, wsse|</tt> See Interface#request 
    #            for more detail.
    def request(sym, params = {}, &block)
      final_params = {:this! => self}.merge!(params) # this! must be first
      @host.api.request(sym.to_s.camelize.to_sym, final_params, &block)
    end
    
    # If the Host supports a SOAP method of the name called, that method will 
    # called accepting the second and third arguments to 
    # ManagedReference#request. This means that you can call remote methods 
    # on any object simply by calling the method on the object itself. Local
    # methods will override remote methods.
    def method_missing(sym, *opts, &block)
      return super(sym, *opts, &block) unless @host
      if @host.api.supports_request?(sym)
        request(sym, *opts, &block)
      else
        raise NoMethodError.new "undefined method '#{sym}' for #{to_s}"
      end
    end
    
    # Create attribute readers for a hash of attributes.
    def apply_attributes(attrs)
      attrs.each do |name, value|
        fixed_name = name.to_s.underscore.to_sym
        @attributes[fixed_name] = value
        self.class.send(:define_method, fixed_name) do
          value
        end
      end
      return self
    end
    
    # Poll the server for updates to the given property +paths+, feeding their 
    # current values to +&block+ each time until the block yields true.
    def wait_for_update(*paths, &block)
      begin
        filter = @host.service.property_collector.create_filter do |xml|
          xml.vim25(:spec, 'vim25:type' => 'PropertyFilterSpec'){
            xml.propSet{
              xml.type self.type
              paths.empty? ? xml.all(true) : paths.each{|p| xml.pathSet p }
            }
            xml.objectSet{ @host.api.coerce_to_xml(xml, :obj => self) } # target obj
          }
          xml.partialUpdates false
        end
      
        version = ''
        loop do
          result = @host.service.property_collector.wait_for_updates(:version => version)
          version = result.version
          if x = block.call
            return x
          end
        end
      rescue => e
        raise e
      ensure
        filter.destroy
      end
    end
    
    # Get the value of a single property from the server.
    def [](key)
      @host.service.property_collector.get_object_properties(self, [key])[key]
    end
    
    # Get the value of multiple properties from the server.
    def collect(*props)
      @host.service.property_collector.get_object_properties(self, props)
    end
    
    # Get the type of ManagedObjectReference this instance represents. Returns 
    # a Symbol.
    def type
      self.class.type
    end
    
    def to_s # :nodoc:
      "<(remote)#{type}:#{id}>"
    end
    
  end

end
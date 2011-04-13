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
  
  class ManagedReference
    
    @@types = {}
    
    class << self
      
      def clear_all!
        @@types = {}
      end
      
      def build(host, sym, id, attrs = {}, &block)
        klass = @@types.include?(sym) ? @@types[sym] : new_rep_subclass(sym)
        instance = klass.new(host, id).apply_attributes(attrs)
      end
      
      def new_rep_subclass(type)
        klass = Class.new(self)
        klass.represent_managed(type.to_sym)
      end
      
      # When defining a subclass of ManagedReference, specifiy the type that
      # the new ManagedReference suclass should represent. Defines type method 
      # in singleton class.
      def represent_managed(type)
        @@types[type] = self
        meta = class << self; self; end
        meta.send(:define_method, :type){ type.to_sym }
        return self
      end
      
      def property_reader(props, opts = {})
        opts = {:memoize => false}.merge!(opts)
        props = props.kind_of?(Array) ? props : [props]
        props.each do |prop|
          fixed_name = prop.to_s.underscore.to_sym # camelcase to underscore
          define_method(fixed_name) do
            if !opts[:memoize] or !@attributes.has_key?(fixed_name)
              collect(*props).each do |k, v|
                @attributes[k.to_s.underscore.to_sym] = v
              end
            end
            @attributes[fixed_name]
          end
        end
      end
      
      def type_defined?(sym)
        @@types.include? sym
      end
      
    end
    
    attr_accessor :id
    attr_reader :attributes
    
    def initialize(host, id, *opts)
      @host, @id, @opts = host, id, opts
      @attributes = {}
    end
    
    def request(sym, params = {}, &block)
      final_params = {:this! => self} # this! must be first
      final_params.merge!(params)
      @host.api.request(sym.to_s.camelize.to_sym, final_params, &block)
    end
    
    def method_missing(sym, *opts, &block)
      return super(sym, *opts, &block) unless @host
      if @host.api.supports_request?(sym)
        request(sym, *opts, &block)
      else
        raise NoMethodError.new "undefined method '#{sym}' for #{to_s}"
      end
    end
    
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
    
    def [](key)
      @host.service.property_collector.get_object_properties(self, [key])[key]
    end
    
    def collect(*props)
      @host.service.property_collector.get_object_properties(self, props)
    end
    
    def type
      self.class.type
    end
    
    def to_s
      "<(remote)#{type}:#{id}>"
    end
    
  end

end
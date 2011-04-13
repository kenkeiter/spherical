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
  
  module Searchable
    
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end
    
    module ClassMethods
      
    end
    
    module InstanceMethods
      
      def find_by_name(name, type = Object)
        @host.service.search_index.find_child(:entity => self, :name => name)
      end

      def find_by_hostname(hostname, filters = {}, type = Spherical::VirtualMachine)
        @host.service.search_index.find_by_dns_name({
          :entity => self, 
          :dnsName => hostname, 
          :vmSearch => type == Spherical::VirtualMachine
        }.merge(filters))
      end

      def find_by_ip(address, filters = {}, type = Spherical::VirtualMachine)
        @host.service.search_index.find_by_dns_name({
          :entity => self, 
          :ip => address, 
          :vmSearch => type == Spherical::VirtualMachine
        }.merge(filters))
      end

      def find_by_uuid(uuid, filters = {}, type = Spherical::VirtualMachine)
        @host.service.search_index.find_by_uuid({
          :entity => self, 
          :uuid => uuid, :instanceUuid => false, 
          :vmSearch => type == Spherical::VirtualMachine
        }.merge(filters))
      end
      
    end
    
  end
  
end
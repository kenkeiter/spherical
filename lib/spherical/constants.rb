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
  
  WSDL_PATH = File.join(File.dirname(__FILE__), '/vim.wsdl')
  
  XSD_NATIVE_COERCIONS = {'xsd:string' => lambda{|id| id.to_s },
                          'xsd:boolean' => lambda{|id| !!(id =~ /^true$/i) },
                          'xsd:datetime' => lambda{|id| Time.parse(id) },
                          'xsd:decimal' => lambda{|id| id.to_f }}
  
  SOAP_NS = {'xmlns:xsd' => "http://www.w3.org/2001/XMLSchema",
             'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance", 
             'xmlns:env' => "http://schemas.xmlsoap.org/soap/envelope/",
             'xmlns:vim25' => "urn:vim25"}
  
  FULL_PROP_TRAVERSAL = {
   'visitFolders' => {:type => 'Folder',
                      :path => 'childEntity',
                      :skip => false,
                      :select => ['visitFolders', 'dcToHf', 'dcToVmf', 
                                  'crToH', 'crToRp', 'HToVm', 'rpToVm']},
        'dcToVmf' => {:type => 'Datacenter',
                      :path => 'vmFolder',
                      :skip => false,
                      :select => ['visitFolders']},
         'dcToHf' => {:type => 'Datacenter',
                      :path => 'hostFolder',
                      :skip => false,
                      :select => ['visitFolders']},
          'crToH' => {:type => 'ComputeResource',
                      :path => 'host',
                      :skip => false},
         'crToRp' => {:type => 'ComputeResource',
                      :path => 'resourcePool',
                      :skip => false,
                      :select => ['rpToRp', 'rpToVm']},
         'rpToRp' => {:type => 'ResourcePool',
                      :path => 'resourcePool',
                      :skip => false,
                      :select => ['rpToRp', 'rpToVm']},
          'HToVm' => {:type => 'HostSystem',
                      :path => 'vm',
                      :skip => false,
                      :select => ['visitFolders']},
         'rpToVm' => {:type => 'ResourcePool',
                      :path => 'vm',
                      :skip => false}}
  
end
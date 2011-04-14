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
  
  class Host
    
    attr_reader :api, :service, :user
    
    DEFAULT_OPTS = {} # None, at the moment
    
    # Initialize a new host instance. Accepts a hash of options requiring:  
    # +:api+:: The URL of your vSphere or ESXi endpoint (i.e. 'http://your-vsphere-host-fqdn/sdk'). 
    # Optionally:
    # +:username+:: A username to log into the server with.
    # +:password+:: The password for +:username+'s account. If both a 
    #               +:username+ and +:password+ is provided, you do not need 
    #               to explicitly call login(), as it will be done for you 
    #               automatically.
    def initialize(opts = {})
      @options = DEFAULT_OPTS.merge(opts)
      @api = Spherical::Interface.new(self, @options[:api])
      @service = ManagedReference.build(self, :ServiceInstance, 'ServiceInstance')
      login if @options.include?(:username) and @options.include?(:password)
    end
    
    # Login to the vSphere server. Not required if you provided a +:username+ 
    # and +:password+ when initializing the host.
    def login(username = @options[:username], password = @options[:password])
      @user = @service.session_manager.login(:userName => username, :password => password)
    end
    
    # Get information about the vSphere server. This call typically provides 
    # a hash with the following keys (at a minimum):
    # +apiType+:: Indicates whether or not the service is a standalone host
    # +apiVersion+:: The version of the API as a dot-separated string
    # +build+:: The build string for the server
    # +fullName+:: The complete product name, including version information
    # +name+:: A short version of the product name
    # +osType+:: The server OS/architecture (for ex: 'win32-x86' or 'linux-x86')
    # +productLineId+:: Product ID of the product line (for ex: 'esx' or 'vpx')
    # +vendor+:: Name of the vendor of the product
    # +version+:: Dot-separated version string
    def about
      @service.about
    end
    
    # Retrieve an array of Datacenter instances that exist in the root folder 
    # of the vSphere endpoint.
    def datacenters
      @service.root_folder.children_of_type(:Datacenter)
    end
    
    def to_s # :nodoc:
      "<Host:#{@options[:api]}>"
    end
    
  end
  
end
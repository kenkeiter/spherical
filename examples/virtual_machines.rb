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

require 'spherical'

# Create a new host, providing a :username and :password so we don't have 
# to manually call login()
host = Spherical::Host.new :api => 'https://vsphere.example.com/sdk',
                           :username => 'username',
                           :password => 'password'

# Recurse over all of the datacenters in the root folder on host.
host.datacenters.each do |datacenter|
  
  # Recurse over VMs in the datacenter's inventory and print the MAC
  # addresses of each NIC interface in relation to the device name.
  datacenter.inventory.each do |vm|
    puts "Found VM #{vm.name} in #{datacenter.id}:"
    vm.mac_addresses.each do |if_name, address|
      puts "\t#{if_name} => #{address}"
    end
  end
  
end

# Now, find a VM within the first datacenter by MAC address
datacenter = host.datacenters.first
vm_instance = datacenter.find_by_uuid('564d5e5866f52d0403310abd6fa71988')

# Halt the instance abruptly, and wait for that task to complete. The 
# complete! call on the resulting Task object will poll the server (thus, 
# blocking further execution) until the request has been successfully completed.
vm_instance.halt!.complete!

# Now, mark the instance as a template
vm_instance.mark_as_template

# And deploy a clone of that instance into the root folder, powering it on 
# upon completion by default.
clone_task = vm_instance.clone('new_instance_name', datacenter.vm_folder, datacenter.datastore.first)
clone_task.complete!
new_vm = clone_task['info.result']

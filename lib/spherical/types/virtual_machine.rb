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
  
  class VirtualMachine < ManagedReference
    
    represent_managed :VirtualMachine   # represent MOR VirtualMachine
    property_reader ['config', 'summary'], :memoize => true # lazy-load these
    
    def stats
      summary.quick_stats
    end
    
    def guest_full_name; summary.config['guestFullName'] end
    def uuid; summary.config['instanceUuid'] end
    def name; summary.config['name'] end
    def num_cpus; summary.config['numCpu'] end
    def reserved_memory; summary.config['memoryReservation'] end
    
    def devices
      config.hardware['device']
    end
    
    def mac_addresses
      nics = []
      devices.each do |dev_id, dev|
        nics << dev if [:VirtualEthernetCard, :VirtualE1000].include? dev.type
      end
      Hash[nics.map{|nic| [nic.device_info['label'], nic.mac_address]}]
    end
    
    # Create a snapshot of the current virtual machine, and update the 
    # current snapshot. A name for the new snapshot is required, and you may 
    # optionally capture memory, or (if VMware Tools is installed) quiesce 
    # the guest file system (ensuring that the snapshot represents a constant 
    # system state).
    #
    # <tt>create_snapshot('my snapshot', :memory => true, :quiesce => true)</tt>
    #
    # Returns a Task instance which can be used to track the progress of 
    # snapshot creation.
    def create_snapshot(name, opts = {})
      opts = {:name => name, :description => name, 
              :memory => false, :quiesce => false}.merge!(opts)
      create_snapshot_task(opts)
    end
    
    # Clone this VM to the given folder and location, and optionally 
    # power it on. Accepts the following arguments:
    #
    # +name+:: Unique name for the new VM. Percent character (%) must be 
    #          escaped.
    # +dest+:: A Folder instance in which to place the new VM
    # +store+:: A hash accepting a +:datastore+ (and, optionally, +:host+) 
    #           key specifying the location to store the files associated 
    #           with the new VM. Both should be managed reference instances 
    #           of the types their names suggest.
    # +power_on+:: Boolean indicating if the cloned VM should be automatically 
    #              powered on upon completion.
    # +config+:: Optionally allows reconfiguration of VM parameters upon 
    #            completion. If you don't know what you're doing, don't use it.
    def clone(name, dest, store, power_on = true, config = {})
      clone_vm_task(:folder => dest,
                    :name => name,
                    :spec => {:location => store})
    end
    
    # Rename the virtual machine to the provided new_name. new_name should be 
    # escaped by the user.
    def rename(new_name)
      rename_task(:new_name => new_name)
    end
    
    # Power on the virtual machine. Returns a Task instance which can be 
    # polled or blocked upon for completion.
    def start
      power_on_vm_task
    end
    
    # Attempt to gracefully shutdown the guest operating system, and power 
    # off the virtual machine. Returns immediately. Success is unknown.
    def stop
      shutdown_guest
    end
    
    # Perform a hard restart on the virtual machine, regardless of the guest 
    # OS's status. Returns a new Task representing the restart request.
    def restart!
      reset_vm_task
    end
    
    # Attempt to perform a graceful reboot by signaling the guest operating 
    # system. Returns immediately. Success is unknown.
    def restart
      reboot_guest
    end
    
    # Attempt to suspend the guest OS. Returns immediately, success is unknwon.
    def suspend
      standby_guest
    end
    
    # Suspend a virtual machine to disk without waiting for the guest OS.
    def suspend!
      suspend_vm_task
    end
    
    # Perform a hard shutdown on the virtual machine, ignoring guest OS 
    # status. Returns a Task representing the shutdown request.
    def halt!
      power_off_vm_task
    end
    
    #############
    # existential
    #############
    
    # Destroy a virtual machine, removing its disks and configuration from 
    # its current datastore. Returns a Task instance representing the request.
    def destroy!
      destroy_task
    end
    
  end
  
end
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
  
  # The ServiceInstance class is a root/top-level class representitive of the 
  # details of a connection with a client.
  
  class Task < ManagedReference
    
    represent_managed :Task  # represent MOR ServiceInstance
    
    attr_reader :about
    
    # Block until task is complete. Note that this will function will 
    # poll the server continuously awaiting completion.
    def complete!
      wait_for_update('info.state'){ %w(success error).member? info.state }
    end
    
  end
  
end
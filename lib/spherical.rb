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

BASEPATH = File.dirname(__FILE__)
$: << File.join(BASEPATH, 'spherical')

require 'savon'
require 'xmlsimple'
require 'builder'
require 'ostruct'

require 'spherical/util'
require 'spherical/constants'
require 'spherical/interface'
require 'spherical/base'
require 'spherical/host'

Spherical.require_all File.join(BASEPATH, 'spherical/mixins/*.rb')
Spherical.require_all File.join(BASEPATH, 'spherical/types/*.rb')

Savon.configure do |config|
  config.log = false
end
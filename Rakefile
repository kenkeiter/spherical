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

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r spherical.rb -I spec -r spec_helper.rb"
end
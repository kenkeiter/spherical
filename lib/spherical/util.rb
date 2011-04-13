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
  
  def require_all(matcher)
    Dir.glob(matcher).each{|file| require file }
  end
  
  module_function :require_all
  
end

class String
  # Some methods imported from ActiveSupport gem, inflector.rb
  
  def underscore
    to_s.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end

  def camelize(first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    else
      to_s.first + camelize(to_s)[1..-1]
    end
  end

end

class OpenStruct

  attr_reader :table

end

class Hash
  # rmerge source: http://gist.github.com/gists/6391/

  # Recursively merge with other_hash in place.
  def rmerge!(other_hash)
    merge!(other_hash) do |key, oldval, newval| 
        oldval.class == self.class ? oldval.rmerge!(newval) : newval
    end
  end

  # Recursively merge with another hash, resulting in a new hash.
  def rmerge(other_hash)
    r = {}
    merge(other_hash) do |key, oldval, newval| 
      r[key] = oldval.class == self.class ? oldval.rmerge(newval) : newval
    end
  end

  # Peform breadth-first recursive map of hash.
  def rmap(&block)
    r = {}
    each do |k, v|
      test_val = v.class == self.class ? v.rmap(&block) : v
      item = block.call(k, test_val)
      item ? r[item.first] = item.last : r[k] = test_val # no changes made.
    end
    return r
  end

  def path_exists?(*path)
    path.inject(self) do |location, key|
      location.respond_to?(:keys) ? location[key] : nil
    end
  end

  def value_at_first(key)
    return fetch(key) if include? key
    each do |k, v|
      if v.class == self.class
        return v.has_key?(key) ? v[key] : v.value_at_first(key)
      end
    end
  end

  def pull(key, value = nil)
    if include? key
      value = fetch(key)
      delete(key)
    end
    return value
  end

  def to_ostruct(klass = OpenStruct, cch = {})
    cch[self] = (os = klass.new)
    os.__send__("_hash=", to_hash)
    each do |k, v|
      native_key = k.underscore
      raise "Invalid key: #{native_key}" unless native_key =~ /[a-z_][a-zA-Z0-9_]*/
      os.__send__("#{native_key}=", v.is_a?(Hash)? cch[v] || v.to_ostruct(klass, cch) : v)
    end
    os
  end

end
  
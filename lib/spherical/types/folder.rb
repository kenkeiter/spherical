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
  
  class Folder < ManagedReference
    
    represent_managed :Folder
    include Searchable # allow Folders to be searched
    include Traversable # this entity has children
    
    def create_subfolder(name)
      create_folder(:name => name)
    end
    
    def traverse(path, type = Object, create = false)
      elements = path.kind_of?(String) ? path.split('/').reject(&:empty?) : path
      return self if elements.empty?
      target = elements.pop
      path = elements.inject(self) do |folder, ele|
        folder.find(ele, Spherical::Folder) || (create && folder.create_subfolder(ele)) || return
      end
      if result = path.find(target, type)
        result
      elsif create and type == Spherical::Folder
        path.create_subfolder(target)
      else
        nil
      end
    end
    
    def inventory(criteria = {})
      property_spec = [{ :type => 'Folder', :pathSet => ['name', 'parent']}]
      criteria.each do |ptype, options|
        ptype = ptype.kind_of?(ManagedReference) ? ptype.type.to_s : ptype.to_s
        criteria_spec = {:type => ptype, :all => (options == :all)}
        (criteria_spec[:pathSet] = options << 'parent') unless options == :all
        property_spec << criteria_spec
      end
      
      results = @host.service.property_collector.retrieve_properties do |xml|
        xml.vim25(:specSet, 'xsi:type' => 'PropertyFilterSpec'){
          # specify properties to select for each object returned
          property_spec.each do |prop_set|
            xml.propSet{
              xml.type prop_set[:type]
              xml.all !!prop_set[:all]
              prop_set[:pathSet].each{|path| xml.pathSet(path) } if prop_set[:pathSet]
            }
          end
          # specify objects to filter
          xml.objectSet{
            @host.api.coerce_to_xml(xml, {:obj => self})
            xml.skip false
            xml.tag!(:selectSet, 'xsi:type' => 'TraversalSpec') {
              xml.vim25(:name, 'visitFolders')
              xml.vim25(:type, 'Folder')
              xml.vim25(:path, 'childEntity')
              xml.vim25(:skip, false)
              xml.vim25(:selectSet, 'xsi:type' => 'SelectionSpec') {
                xml.vim25(:name, 'visitFolders')
              }
            }
          }
        }
      end
      
      # Convert the result to a tree.
      structure = {}
      obj_results = results.kind_of?(Array) ? results : [results]
      obj_results.each do |obj_result|
        prop_set = obj_result.prop_set.kind_of?(Array) ? obj_result.prop_set : [obj_result.prop_set._hash]
        prop_set = Hash[prop_set.map{ |p| [p['name'], p['val']] }]
        puts obj_result, prop_set
        unless prop_set['parent']
          structure[obj_result.obj.apply_attributes(prop_set)] = {}
        else
          structure[prop_set['parent']][prop_set['name']] = [obj_result.obj, prop_set]
        end
      end
      
      return structure
      
    end
     
  end
  
end
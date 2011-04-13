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
  
  class PropertyCollector < ManagedReference
    
    represent_managed :PropertyCollector
    
    def children_for_object(obj, match_type, attrs = ['name', 'parent'], &block)      
      type = match_type.kind_of?(ManagedReference) ? match_type.type.to_s : match_type.to_s
      results = retrieve_properties do |xml|
        xml.vim25(:specSet, 'xsi:type' => 'PropertyFilterSpec'){
          # specify properties to select for each object returned
          xml.propSet{
            xml.type type
            if attrs == :all
              xml.all true
            else
              attrs.each{|attr| xml.pathSet attr }
            end
          }
          # specify objects to filter
          xml.objectSet{
            @host.api.coerce_to_xml(xml, {:obj => obj})
            xml.skip false
            Spherical::FULL_PROP_TRAVERSAL.each do |name, params|
              xml.vim25(:selectSet, 'xsi:type' => 'TraversalSpec') {
                xml.name name
                xml.type params[:type]
                xml.path params[:path]
                if params.key?(:select)
                  params[:select].each do |sel|
                    xml.vim25(:selectSet, 'xsi:type' => 'SelectionSpec') { xml.name sel }
                  end
                end
              }
            end
          }
        }
      end
      
      structure = []
      obj_results = results.kind_of?(Array) ? results : [results] # if multiple results
      obj_results.each do |obj_result|
        prop_set = obj_result.prop_set.kind_of?(Array) ? obj_result.prop_set : [obj_result.prop_set._hash]
        prop_set = Hash[prop_set.map{ |p| [p['name'], p['val']] }]
        final_obj = obj_result.obj.apply_attributes(prop_set)
        yield final_obj if block_given?
        structure << final_obj
      end
      
      return structure
      
    end
    
    def get_object_properties(obj, props)
      unless obj.kind_of?(ManagedReference)
        raise TypeError.new("Invalid object #{obj}. Must be a ManagedReference.")
      end
      results = retrieve_properties do |xml|
        xml.vim25(:specSet, 'vim25:type' => 'PropertyFilterSpec'){
          # specify properties to select for each object returned
          xml.propSet{
            xml.type obj.type.to_s
            (props == :all) ? xml.all(true) : props.each{|p| xml.pathSet p }
          }
          xml.objectSet{ @host.api.coerce_to_xml(xml, :obj => obj) } # target obj
        }
      end
      
      raise "Unable to retrieve #{props} for #{obj}." unless results._hash
      
      structure = {}
      obj_results = results._hash.kind_of?(Array) ? results : [results] # if multiple results
      obj_results.each do |obj_result|
        prop_set = obj_result.prop_set.kind_of?(Array) ? obj_result.prop_set : [obj_result.prop_set._hash]
        prop_set = Hash[prop_set.map{ |p| [p['name'], p['val']] }]
        structure.merge!(prop_set)
      end
      
      return structure
      
    end
    
  end
  
end
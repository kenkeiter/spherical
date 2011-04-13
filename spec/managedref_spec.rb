require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Spherical::ManagedReference do
  
  context 'when managing types' do
    
    before(:all) do
      Spherical::ManagedReference.clear_all!
    end
    
    it "should allow definition of new types" do
      klass = Class.new(Spherical::ManagedReference)
      klass.represent_managed(:Halibut)
      klass.type.should == :Halibut
      Spherical::ManagedReference.type_defined?(:Halibut).should == true
    end
    
    it "should allow the instantiation of new instances of defined types" do
      klass = Class.new(Spherical::ManagedReference)
      klass.represent_managed(:Halibut)
      
      inst = Spherical::ManagedReference.build(nil, :Halibut, 'thing-1')
      inst.class.type.should == :Halibut
      inst.id.should == 'thing-1'
    end
    
    # Managed reference classes that are undefined are still valid. This 
    # allows us to support server-side MORs generically without defining a 
    # wrapping class in the Spherical library.
    it "should allow the instantation of arbitrary types" do
      inst = Spherical::ManagedReference.build(nil, :Halibut, 'thing-1')
      inst.class.type.should == :Halibut
      inst.id.should == 'thing-1'
    end
    
    it "should associate unique Class instances with arbitrary types" do
      first_inst = Spherical::ManagedReference.build(nil, :Halibut, 'thing-1')
      second_inst = Spherical::ManagedReference.build(nil, :Halibut, 'thing-2')
      # Should be of the same class, different instances
      first_inst.class.should == second_inst.class
      first_inst.class.type.should == :Halibut
      # IDs should be set individually
      first_inst.id.should == 'thing-1'
      second_inst.id.should == 'thing-2'
    end
    
  end
  
end
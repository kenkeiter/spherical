require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Spherical::Host do
  
  context 'upon connecting' do
    
    before(:all) do
      @host = create_test_host
    end
    
    it "should provide service information" do
      @host.about.should be_instance_of(Hash)
    end
    
    it "should list datacenters" do
      @host.datacenters.should be_instance_of(Array)
    end
    
    it 'should list inventory' do
      @host.datacenters.each do |dc|
        dc.instances.each do |child|
          puts "-----> #{child.guest_full_name}"
          puts "       #{child.mac_addresses}"
        end
      end
    end
    
  end
  
end
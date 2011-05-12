$: << File.join(File.dirname(__FILE__), '../lib')

require 'spherical'

def create_test_host
  Spherical::Host.new :api => 'https://vsphere.example.com/sdk',
                      :username => 'username',
                      :password => 'password'
end
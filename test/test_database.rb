require "rubygems" 
require_gem "activerecord" 

class Files < ActiveRecord::Base
end

class TestDatabase < Test::Unit::TestCase
  def test_connection
    ActiveRecord::Base.establish_connection(
      :adapter  => "mysql",
      :host     => "localhost",
      :database => "earth_test",
      :username => "earth",
      :password => "earth"
    )
    
    file = Files.new
    file.path = 'an/arbitrary/path/to_a_file'
    file.save
  end
end
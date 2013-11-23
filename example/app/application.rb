require 'opal'
require 'foo'

puts "wow!"

module MyApp
  class Application
    def initialize
      @user = Adam.new
      @user.bar
    end
  end
end

MyApp::Application.new

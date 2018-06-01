require 'opal'
require 'user'
require 'native'

module MyApp
  class Application
    attr_reader :user

    def initialize
      @user = User.new('Bill')
      @user.authenticated?
    rescue
      @user = User.new('Bob')
      @user.authenticated?
      p @user
    end
  end
end

$app = MyApp::Application.new

p $app
puts "Done!"

$$.document.write("user is #{$app.user.name}")

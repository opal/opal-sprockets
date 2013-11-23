class Adam
  def bar
    if admin?
      puts "logged in"
    elsif special_persmission?
      puts "one time only"
    else
      raise "foo"
    end
  end

  def admin?
    @admin
  end

  def special_persmission?
    false
  end
end

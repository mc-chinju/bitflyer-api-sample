class Array
  # average
  def ave
    inject(0.0) { |r,i| r += i } / size
  end

  # variance
  def var
    reduce(0) { |a,b| a + (b - ave) ** 2 } / (size - 1)
  end

  # standard_deviation
  def sd
    Math.sqrt(var)
  end
end
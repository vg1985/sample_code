module RateSheetsHelper

  def rates_mass_edit_select
    [
      ['Set To', "set"],
      ['Add', "add"],
      ['Subtract', "subtract"],
      ['Multiply', "multiply"],
    ]
  end

  def paginate_select
    [
      ['10', 10],
      ['15', 15],
      ['20', 20],
      ['30', 30],
      ['40', 40],
      ['50', 50],
    ]
  end

end

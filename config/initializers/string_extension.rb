class String
  
  def to_name
    gsub("_id", "").titleize
  end
  
end
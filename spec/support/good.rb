class Good
  def self.find_by id:
    id == 0 ? nil : { id: id }
  end
end

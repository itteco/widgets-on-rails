class Token < ActiveRecord::Base
  validates_uniqueness_of :value

  def self.get_new(clientid=nil, data=nil)
    for i in 1..10 do # While True will hang up the server forever
      t = Token.new :clientid=>clientid, :data=>data, :value => rand(36**32).to_s(36) #16-symbol token
      return t if t.save
    end
  end
end

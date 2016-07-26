class OsDonation < ActiveRecord::Base
  has_paper_trail  :on => [:update, :destroy]  # don't track create events
  validates_uniqueness_of :fec_cycle_id

  has_one :os_match
  
  def create_fec_cycle_id
    unless self.cycle.nil? || self.fectransid.nil?
      self.fec_cycle_id = self.cycle + "_" + self.fectransid
    end
  end

end

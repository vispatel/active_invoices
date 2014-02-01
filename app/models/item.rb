class Item < ActiveRecord::Base
  belongs_to :invoice

  validates :quantity, :presence => true, :numericality => { :integer => true }
  validates :amount, :presence => true, :numericality => true
  validates :tax, :presence => true, :numericality => true
  validates :description, :presence => true

  attr_accessible :quantity, :description, :amount, :tax

  after_initialize :set_defaults

  def total
    self.quantity * self.amount
  end

  private

  def set_defaults
    self[:tax] = 20 if tax.blank?
  end
end

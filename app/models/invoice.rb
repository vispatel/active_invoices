class Invoice < ActiveRecord::Base
  STATUS_DRAFT = 'draft'
  STATUS_SENT  = 'sent'
  STATUS_PAID  = 'paid'

  belongs_to :client
  belongs_to :user

  has_many :items, :dependent => :destroy

  accepts_nested_attributes_for :items, :allow_destroy => true

  validates :code, :client_id, :presence => true
  validates :status, :inclusion => { :in => [STATUS_PAID, STATUS_SENT, STATUS_DRAFT], :message => "You need to pick one status." }
  validates :discount, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100 }

  attr_accessible :client_id, :items_attributes, :code, :status, :due_date, :discount, :terms, :notes

  class << self
    def suggest_code
      invoice = order('created_at desc').limit(1).first
      invoice.id + 1 rescue '1'
    end

    def status_collection
      {
        "Draft" => STATUS_DRAFT,
        "Sent" => STATUS_SENT,
        "Paid" => STATUS_PAID
      }
    end

    def this_month
      where('created_at >= ?', Date.new(Time.now.year, Time.now.month, 1).to_datetime)
    end
  end

  def items_total
    items.inject(0){ |sum, item| sum + item.total }
  end

  def taxes
    items.inject(0){ |sum, item| sum + item.total * (item.tax.to_f / 100) }
  end

  def total
    items_total * (1 - discount / 100) + taxes
  end

  def subtotal
    items_total * (1 - discount / 100)
  end

  def status_tag
    case self.status
      when STATUS_DRAFT then :error
      when STATUS_SENT then :warning
      when STATUS_PAID then :ok
    end
  end

  def invoice_location
    "#{Rails.root}/pdfs/invoice-#{self.code}.pdf"
  end
end

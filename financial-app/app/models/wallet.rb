class Wallet
  include Mongoid::Document
  include Mongoid::Timestamps

  # Fields
  field :balance, type: Float, default: 0.0
  field :currency, type: String, default: 'USD'
  field :is_active, type: Boolean, default: true

  # Relationships
  belongs_to :user
  has_many :transactions

  # Validations
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :user, presence: true

  # Instance methods
  def credit(amount)
    return false if amount <= 0

    with_lock do
      self.balance += amount
      save
    end
  end

  def debit(amount)
    return false if amount <= 0 || amount > balance

    with_lock do
      self.balance -= amount
      save
    end
  end

  private

  def with_lock
    # MongoDB doesn't have native row-level locking, so we implement optimistic locking
    retry_count = 0
    begin
      yield
    rescue Mongoid::Errors::StaleDocument
      retry_count += 1
      reload
      retry if retry_count < 3
      false
    end
  end
end

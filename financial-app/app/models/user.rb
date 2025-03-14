class User
  include Mongoid::Document
  include Mongoid::Timestamps

  # Fields
  field :email, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :stytch_user_id, type: String
  field :stripe_customer_id, type: String

  # Relationships
  has_many :transactions
  has_many :payment_methods
  has_one :wallet

  # Indexes
  index({ email: 1 }, { unique: true })
  index({ stytch_user_id: 1 }, { unique: true })
  index({ stripe_customer_id: 1 }, { sparse: true })

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :stytch_user_id, presence: true, uniqueness: true
  
  # Callbacks
  before_create :create_stripe_customer
  after_create :create_wallet

  private

  def create_stripe_customer
    return if stripe_customer_id.present?

    customer = Stripe::Customer.create(
      email: email,
      name: "#{first_name} #{last_name}".strip
    )
    self.stripe_customer_id = customer.id
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to create Stripe customer: #{e.message}"
    throw :abort
  end

  def create_wallet
    Wallet.create!(user: self, balance: 0)
  end
end

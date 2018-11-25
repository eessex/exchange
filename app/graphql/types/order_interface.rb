module Types::OrderInterface
  include Types::BaseInterface
  field_class Types::BaseField

  description 'Order'
  graphql_name 'Order'

  field :id, ID, null: false
  field :mode, Types::OrderModeEnum, null: true
  field :code, String, null: false
  field :buyer_phone_number, String, null: true
  field :buyer_total_cents, Integer, null: true
  field :buyer, Types::OrderPartyUnionType, null: false
  field :commission_fee_cents, Integer, null: true, seller_only: true
  field :commission_rate, Float, null: true
  field :created_at, Types::DateTimeType, null: false
  field :credit_card_id, String, null: true
  field :currency_code, String, null: false
  field :display_commission_rate, String, null: true
  field :items_total_cents, Integer, null: true, description: 'Item total in cents, for Offer Orders this field reflects current offer'
  field :last_approved_at, Types::DateTimeType, null: true
  field :last_submitted_at, Types::DateTimeType, null: true
  field :line_items, Types::LineItemType.connection_type, null: true
  field :requested_fulfillment, Types::RequestedFulfillmentUnionType, null: true
  field :seller_total_cents, Integer, null: true, seller_only: true
  field :seller, Types::OrderPartyUnionType, null: false
  field :shipping_total_cents, Integer, null: true
  field :state_expires_at, Types::DateTimeType, null: true
  field :state_reason, String, null: true
  field :state_updated_at, Types::DateTimeType, null: true
  field :state, Types::OrderStateEnum, null: false
  field :total_list_price_cents, Integer, null: false
  field :tax_total_cents, Integer, null: true
  field :transaction_fee_cents, Integer, null: true, seller_only: true
  field :updated_at, Types::DateTimeType, null: false

  # Deprecated
  field :offer_total_cents, Integer, null: false, deprecation_reason: 'itemsTotalCents reflects offer total for offer orders.'
  field :last_offer, Types::OfferType, null: true, deprecation_reason: 'Switch to OfferOrder lastOffer'
  field :offers, Types::OfferType.connection_type, deprecation_reason: 'Switch to OfferOrder offers', null: true do
    argument :from_id, String, required: false
    argument :from_type, String, required: false
  end

  orphan_types Types::BuyOrderType, Types::OfferOrderType

  def offers(**args)
    offers = object.offers.submitted
    offers = offers.where(args.slice(:from_id, :from_type)) if args.keys.any? { |ar| %i[from_id from_type].include? ar }
    offers
  end

  def offer_total_cents
    # This can be removed once reaction is updated to `itemsTotalCents`
    object.items_total_cents
  end

  def buyer
    OpenStruct.new(
      id: object.buyer_id,
      type: object.buyer_type
    )
  end

  def seller
    OpenStruct.new(
      id: object.seller_id,
      type: object.seller_type
    )
  end

  def requested_fulfillment
    # fulfillment is not a field on order so we have to resolve it here
    # it uses our union, for that to work we need to pass order (aka object)
    # to our Fulfillment
    return if object.fulfillment_type.blank?

    object
  end

  def display_commission_rate
    return if object.commission_rate.nil?

    ActiveSupport::NumberHelper.number_to_percentage(
      object.commission_rate * 100,
      precision: 2,
      strip_insignificant_zeros: true
    )
  end

  # Optional, see below
  definition_methods do
    # Optional: if this method is defined, it overrides `Schema.resolve_type`
    def resolve_type(object, _context)
      case object.mode
      when Order::BUY then Types::BuyOrderType
      when Order::OFFER then Types::OfferOrderType
      else
        raise 'Unknown order type'
      end
    end
  end
end
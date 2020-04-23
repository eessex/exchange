# Delete credit cards for Cypress test user
# Cards are automatically added by Integrity builds,
# but must be periodically cleaned.
# Prevents Stripe errors for "too many cards"
# https://github.com/artsy/integrity#too-many-credit-cards-for-a-customer

namespace :cypress do
  desc 'Delete credit cards for Cypress test user.'
  task clean_credit_cards: :environment do
    logger.info("[#{Time.zone.now}] Cleaning credit cards for Integrity test user...")
    first_order = Order.where(buyer_id: '5d97bb95d845aa001137da26').first
    payment_intent = Stripe::PaymentIntent.retrieve(first_order.external_charge_id)
    customer = Stripe::Customer.retrieve(payment_intent.customer)
    sources = Stripe::Customer.list_sources(customer.id, { limit: 100 })
    sources.map(&:id).each { |id| Stripe::Customer.delete_source(customer.id, id) }
    logger.info("[#{Time.zone.now}] Done.")
  end
end

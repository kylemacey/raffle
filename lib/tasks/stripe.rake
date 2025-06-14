namespace :stripe do
  desc "Sync prices from Stripe for a specific product"
  task :sync_prices, [:stripe_product_id] => :environment do |t, args|
    if args[:stripe_product_id].blank?
      puts "Error: Please provide a Stripe product ID"
      puts "Usage: rake stripe:sync_prices[prod_123...]"
      exit 1
    end

    begin
      # Get all prices for the product from Stripe
      stripe_prices = Stripe::Price.list(
        product: args[:stripe_product_id],
        active: true,
        expand: ['data.product']
      )

      # Get existing prices from our database for this product
      existing_prices = RocStarPrice.where(stripe_product_id: args[:stripe_product_id])

      # Track which prices we've processed
      processed_price_ids = []

      # Process each Stripe price
      stripe_prices.data.each do |stripe_price|
        processed_price_ids << stripe_price.id

        # Find or initialize our price record
        price = existing_prices.find_or_initialize_by(stripe_price_id: stripe_price.id)

        # Update price attributes
        price.stripe_product_id = stripe_price.product.id
        price.amount = stripe_price.unit_amount
        price.interval = stripe_price.recurring.interval
        price.name = stripe_price.product.name
        price.description = stripe_price.product.description

        if price.changed?
          if price.new_record?
            puts "Creating new price: #{price.name} (#{price.amount} #{price.interval})"
          else
            puts "Updating price: #{price.name} (#{price.amount} #{price.interval})"
          end
          price.save!
        end
      end

      # Find and delete orphaned prices
      orphaned_prices = existing_prices.where.not(stripe_price_id: processed_price_ids)
      orphaned_prices.each do |price|
        puts "Deleting orphaned price: #{price.name} (#{price.amount} #{price.interval})"
        price.destroy
      end

      puts "\nSync completed:"
      puts "- Created/Updated: #{processed_price_ids.size} prices"
      puts "- Deleted: #{orphaned_prices.size} prices"

    rescue Stripe::StripeError => e
      puts "Error syncing with Stripe: #{e.message}"
      exit 1
    end
  end
end
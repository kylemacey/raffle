# Roc Stars API Documentation

## Overview
The Roc Stars API provides endpoints for managing subscription prices and creating checkout sessions for Stripe subscriptions.

## Price Management

### Syncing Prices with Stripe
The application includes a rake task to sync prices from Stripe to the local database. This ensures that your local prices stay in sync with your Stripe products.

#### Finding Your Stripe Product ID
1. Log in to your [Stripe Dashboard](https://dashboard.stripe.com)
2. Navigate to Products
3. Click on the product you want to sync
4. The Product ID will be shown at the top of the page (starts with `prod_`)
5. You can also find it in the URL: `https://dashboard.stripe.com/products/prod_xxx`

#### Running the Sync Task
```bash
# Sync prices for a specific product
rake stripe:sync_prices[prod_xxx]

# Example
rake stripe:sync_prices[prod_S5A1eGDrLWiWQT]
```

The sync task will:
- Fetch all active prices for the product from Stripe
- Create new prices that don't exist in the database
- Update existing prices that have changed
- Delete prices that no longer exist in Stripe
- Show a summary of changes made

#### Sync Output Example
```
Creating new price: Roc Star (15000 year)
Updating price: Roc Star (1500 month)

Sync completed:
- Created/Updated: 2 prices
- Deleted: 0 prices
```

## Endpoints

### List Prices
Retrieves all available subscription prices.

```http
GET /roc_stars/prices.json
```

#### Response
```json
[
  {
    "id": 1,
    "name": "Roc Star",
    "stripe_product_id": "prod_xxx",
    "stripe_price_id": "price_xxx",
    "amount": 1500,
    "interval": "month",
    "description": "Basic subscription",
    "created_at": "2024-03-21T00:00:00.000Z",
    "updated_at": "2024-03-21T00:00:00.000Z"
  }
]
```

### Create Checkout Session
Creates a Stripe checkout session for a subscription.

```http
POST /roc_stars/create_checkout_session
Content-Type: application/json
```

#### Request Body
```json
{
  "amount": 1500,
  "email": "customer@example.com",
  "name": "Customer Name",
  "interval_type": "month"
}
```

| Parameter | Type | Description |
|-----------|------|-------------|
| amount | integer | Amount in cents (e.g., 1500 for $15.00) |
| email | string | Customer's email address |
| name | string | Customer's name |
| interval_type | string | Subscription interval ("month" or "year") |

#### Response
```json
{
  "session_id": "cs_test_xxx",
  "checkout_url": "https://checkout.stripe.com/xxx"
}
```

#### Error Response
```json
{
  "error": "No suitable price found"
}
```

## Price Matching Logic

The API will attempt to find the best matching price for the requested amount:

1. First tries to find an exact match for the amount and interval
2. If no exact match is found, finds the closest lower price for the requested interval
3. If no suitable price is found, returns an error

## Examples

### List Prices
```bash
curl http://localhost:3000/roc_stars/prices.json
```

### Create Checkout Session
```bash
curl -X POST http://localhost:3000/roc_stars/create_checkout_session \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1500,
    "email": "customer@example.com",
    "name": "Customer Name",
    "interval_type": "month"
  }'
```

## Notes

- All amounts are in cents (e.g., 1500 = $15.00)
- The checkout URL returned should be used to redirect the customer to complete their subscription
- The API automatically handles customer creation/retrieval in Stripe
- Success and cancel URLs are automatically set to `/success` and `/cancel` respectively
- Always run the sync task after making changes to prices in the Stripe dashboard
- The sync task will preserve existing price records in the database, only updating them if they've changed in Stripe
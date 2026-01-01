# API Integrations

Detailed documentation for all external API integrations used in Neo.

## WhatsApp Business API

### Overview
- **Provider:** Meta (Facebook)
- **Type:** Cloud API
- **Documentation:** [developers.facebook.com/docs/whatsapp](https://developers.facebook.com/docs/whatsapp)

### Authentication
```
POST https://graph.facebook.com/v18.0/{phone-number-id}/messages
Headers:
  Authorization: Bearer {access-token}
  Content-Type: application/json
```

### Send Message
```json
{
  "messaging_product": "whatsapp",
  "to": "34681818156",
  "type": "text",
  "text": {
    "body": "Hello from Neo!"
  }
}
```

### Webhook Format
```json
{
  "object": "whatsapp_business_account",
  "entry": [{
    "changes": [{
      "value": {
        "messages": [{
          "from": "34681818156",
          "id": "wamid.xxx",
          "timestamp": "1234567890",
          "text": {
            "body": "User message"
          },
          "type": "text"
        }],
        "metadata": {
          "display_phone_number": "...",
          "phone_number_id": "..."
        }
      }
    }]
  }]
}
```

### Rate Limits
- 1000 messages/day (default)
- Upgradeable with business verification
- 80 messages/second (burst)

### Best Practices
- Always respond within 24 hours
- Use message templates for notifications
- Handle webhook retries
- Implement exponential backoff

---

## OpenAI API

### Overview
- **Model:** gpt-4o
- **Type:** Chat Completions
- **Documentation:** [platform.openai.com/docs](https://platform.openai.com/docs)

### Authentication
```
POST https://api.openai.com/v1/chat/completions
Headers:
  Authorization: Bearer {api-key}
  Content-Type: application/json
```

### Request Format
```json
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "system",
      "content": "You are Neo, a professional running coach..."
    },
    {
      "role": "user",
      "content": "What's a good pace for beginners?"
    }
  ],
  "max_tokens": 500,
  "temperature": 0.7
}
```

### Response Format
```json
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "gpt-4o",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "For beginners, a comfortable pace is..."
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 50,
    "completion_tokens": 100,
    "total_tokens": 150
  }
}
```

### Pricing
- Input: $2.50 / 1M tokens
- Output: $10.00 / 1M tokens
- ~500 tokens per conversation
- ~2000 tokens per weekly plan

### Rate Limits
- Tier 1: 500 RPM, 200,000 TPM
- Tier 2: 5,000 RPM, 2,000,000 TPM
- Upgradeable based on usage

### Best Practices
- Use system prompts effectively
- Implement streaming for better UX
- Cache common responses
- Monitor token usage
- Handle rate limit errors

---

## Stripe API

### Overview
- **Type:** Payment Processing
- **Documentation:** [stripe.com/docs](https://stripe.com/docs)

### Authentication
```
All requests:
  Authorization: Bearer {secret-key}
```

### Create Checkout Session
```
POST https://api.stripe.com/v1/checkout/sessions
```
```json
{
  "mode": "subscription",
  "line_items": [{
    "price": "price_xxx",
    "quantity": 1
  }],
  "success_url": "https://yoursite.com/success",
  "cancel_url": "https://yoursite.com/cancel",
  "metadata": {
    "user_phone": "34681818156"
  }
}
```

### Webhook Events
```json
{
  "id": "evt_xxx",
  "type": "customer.subscription.created",
  "data": {
    "object": {
      "id": "sub_xxx",
      "customer": "cus_xxx",
      "status": "active",
      "metadata": {
        "user_phone": "34681818156"
      }
    }
  }
}
```

### Webhook Verification
```javascript
const stripe = require('stripe')(secret_key);
const signature = req.headers['stripe-signature'];

let event;
try {
  event = stripe.webhooks.constructEvent(
    req.body,
    signature,
    webhook_secret
  );
} catch (err) {
  return res.status(400).send(`Webhook Error: ${err.message}`);
}
```

### Price IDs
- Monthly: `price_monthly_xxx`
- 6-Month: `price_6month_xxx`
- Annual: `price_annual_xxx`

### Best Practices
- Always use test mode first
- Verify webhook signatures
- Handle idempotency
- Store customer IDs
- Implement retry logic

---

## Supabase API

### Overview
- **Type:** PostgreSQL REST API
- **Documentation:** [supabase.com/docs](https://supabase.com/docs)

### Authentication
```
All requests:
  apikey: {anon-key}
  Authorization: Bearer {anon-key}
```

### Select Query
```
GET https://{project}.supabase.co/rest/v1/users?phone=eq.34681818156

Response:
[
  {
    "phone": "34681818156",
    "nom": "Taiye",
    "subscripcio": "active",
    ...
  }
]
```

### Insert Query
```
POST https://{project}.supabase.co/rest/v1/users
Content-Type: application/json
Prefer: return=minimal

{
  "phone": "34681818156",
  "nom": "Taiye",
  "edat": 28
}
```

### Update Query
```
PATCH https://{project}.supabase.co/rest/v1/users?phone=eq.34681818156
Content-Type: application/json
Prefer: return=minimal

{
  "subscripcio": "active"
}
```

### Query Operators
- `eq`: Equals
- `neq`: Not equals
- `gt`: Greater than
- `gte`: Greater than or equal
- `lt`: Less than
- `lte`: Less than or equal
- `in`: In list
- `order`: Order by
- `limit`: Limit results

### Best Practices
- Use proper RLS policies
- Index common queries
- Batch operations when possible
- Handle connection errors
- Monitor database size

---

## Error Handling

### WhatsApp Errors
```json
{
  "error": {
    "message": "Invalid phone number",
    "type": "invalid_parameter",
    "code": 100
  }
}
```

**Common Errors:**
- 100: Invalid parameter
- 130: Rate limit
- 131: Access token expired
- 368: Template not approved

### OpenAI Errors
```json
{
  "error": {
    "message": "Rate limit exceeded",
    "type": "rate_limit_error",
    "code": "rate_limit_exceeded"
  }
}
```

**Common Errors:**
- Rate limit exceeded
- Invalid API key
- Model not available
- Token limit exceeded

### Stripe Errors
```json
{
  "error": {
    "type": "card_error",
    "code": "card_declined",
    "message": "Your card was declined."
  }
}
```

**Common Errors:**
- card_declined
- expired_card
- insufficient_funds
- invalid_request_error

### Supabase Errors
```json
{
  "message": "duplicate key value",
  "details": "Key (phone)=(...) already exists",
  "hint": null,
  "code": "23505"
}
```

**Common Errors:**
- 23505: Unique constraint violation
- 23503: Foreign key violation
- 22P02: Invalid input syntax
- PGRST116: No rows affected

---

## Monitoring & Debugging

### API Status Pages
- WhatsApp: [developers.facebook.com/status](https://developers.facebook.com/status)
- OpenAI: [status.openai.com](https://status.openai.com)
- Stripe: [status.stripe.com](https://status.stripe.com)
- Supabase: [status.supabase.com](https://status.supabase.com)

### Logging Best Practices
- Log all API requests/responses
- Redact sensitive data (tokens, keys)
- Include request IDs
- Track response times
- Monitor error rates

### Testing Tools
- Postman: API testing
- webhook.site: Webhook testing
- Stripe CLI: Webhook simulation
- ngrok: Local webhook testing
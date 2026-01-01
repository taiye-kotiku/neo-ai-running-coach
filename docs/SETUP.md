# Setup Guide

Complete step-by-step guide to deploying Neo AI Running Coach.

## Prerequisites

### Required Accounts
- [ ] n8n account (cloud or self-hosted)
- [ ] WhatsApp Business API access
- [ ] OpenAI API account
- [ ] Stripe account
- [ ] Supabase account

### Required Skills
- Basic understanding of APIs and webhooks
- Familiarity with JSON
- Command line basics (optional)

## Step 1: WhatsApp Business API Setup

### Option A: Meta Business Platform (Recommended)
1. Go to [developers.facebook.com](https://developers.facebook.com)
2. Create a new app → "Business"
3. Add WhatsApp product
4. Go to API Setup
5. Note your:
   - Phone Number ID
   - WhatsApp Business Account ID
   - Access Token
6. Add test number for development

### Option B: Third-Party Provider
Use providers like Twilio, MessageBird, or 360dialog

### Configure Webhook
1. In WhatsApp settings → Configuration
2. Set Callback URL (will get from n8n later)
3. Set Verify Token (create a random string)
4. Subscribe to `messages` webhook field

## Step 2: OpenAI API Setup

1. Go to [platform.openai.com](https://platform.openai.com)
2. Create API key
3. Add payment method
4. Set usage limits (recommended: $50/month)
5. Note your API key

**Cost Estimate:**
- ~$0.01 per conversation
- ~$0.05 per weekly plan
- ~$10-30/month for 100 active users

## Step 3: Stripe Setup

1. Go to [stripe.com](https://stripe.com)
2. Create account
3. Activate Test Mode
4. Create Products:

**Product 1: Monthly**
- Name: "Neo Monthly Subscription"
- Price: €9.99/month
- Recurring: Monthly
- Note Price ID (e.g., `price_xxx`)

**Product 2: 6-Month**
- Name: "Neo 6-Month Subscription"
- Price: €55 (one-time, then recurring)
- Recurring: Every 6 months
- Note Price ID

**Product 3: Annual**
- Name: "Neo Annual Subscription"
- Price: €100/year
- Recurring: Yearly
- Note Price ID

4. Create discount codes (optional):
   - NEOWELCOME: 10% off
   - RUNNER50: 50% off first month

5. Go to Developers → API Keys
6. Note your:
   - Publishable key
   - Secret key (test mode)

7. Go to Developers → Webhooks
8. Add endpoint (will get URL from n8n)
9. Select events:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
10. Note webhook secret

## Step 4: Supabase Setup

1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Choose region (closest to users)
4. Note database password
5. Go to SQL Editor
6. Create new query
7. Paste contents of `database/schema.sql`
8. Run query
9. Verify tables created in Table Editor
10. Go to Settings → API
11. Note:
    - Project URL
    - Anon/public key
    - Service role key

## Step 5: n8n Setup

### Option A: n8n Cloud (Easiest)
1. Go to [n8n.io](https://n8n.io)
2. Sign up for account
3. Create new instance
4. Skip to Step 6

### Option B: Self-Hosted
```bash
# Using Docker
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# Or using npm
npm install -g n8n
n8n start
```

## Step 6: Import Workflows

1. Download workflow JSON files from `/workflows` directory
2. In n8n, go to Workflows
3. Click "+" → "Import from File"
4. Import each workflow:
   - master-router.json
   - weekly-plan-generator.json
   - workout-reminders.json
   - stripe-webhook-handler.json

## Step 7: Configure Credentials

### WhatsApp Credentials
1. In n8n → Credentials → Add Credential
2. Search "WhatsApp"
3. Enter:
   - Phone Number ID
   - Access Token
4. Test connection
5. Save

### OpenAI Credentials
1. Add Credential → "OpenAI"
2. Enter API Key
3. Test
4. Save

### Stripe Credentials
1. Add Credential → "Stripe"
2. Enter:
   - Secret Key (test mode initially)
3. Save

### Supabase/HTTP Request Credentials
Since we're using HTTP Request node:
1. Add Credential → "Header Auth"
2. Name: "Supabase Auth"
3. Add headers:
   - `apikey`: [your anon key]
   - `Authorization`: `Bearer [your anon key]`
4. Save

## Step 8: Update Workflow Variables

### Master Router
Update these values:
- Supabase URL: `https://[your-project].supabase.co`
- WhatsApp Phone Number ID: `[your phone ID]`
- Stripe Price IDs in payment link generation

### Weekly Plan Generator
- Supabase URL
- WhatsApp Phone Number ID
- Cron schedule (if timezone adjustment needed)

### Workout Reminders
- Supabase URL
- WhatsApp Phone Number ID
- Cron schedule

### Stripe Webhook Handler
- Supabase URL
- WhatsApp Phone Number ID

## Step 9: Configure Webhooks

### Master Router Webhook
1. Activate Master Router workflow
2. Copy webhook URL from WhatsApp Trigger node
3. Go to WhatsApp Business → Configuration
4. Set Callback URL: `[your webhook URL]`
5. Verify webhook (n8n handles this automatically)

### Stripe Webhook
1. Activate Stripe Webhook Handler workflow
2. Copy webhook URL from webhook trigger node
3. Go to Stripe → Developers → Webhooks
4. Add endpoint: `[your webhook URL]`
5. Copy webhook secret
6. Add to n8n Stripe webhook node

## Step 10: Test the System

### Test 1: Onboarding Flow
1. Send "Hola" to WhatsApp number
2. Verify response from Neo
3. Complete onboarding conversation
4. Check database for user record
5. Verify chat_history saved

### Test 2: Payment Flow
1. Click payment link
2. Use Stripe test card: `4242 4242 4242 4242`
3. Complete checkout
4. Verify webhook received
5. Check database subscription updated
6. Confirm welcome message sent

### Test 3: Premium Features
1. Send message to Neo
2. Verify AI response
3. Report a workout
4. Check workout saved in database

### Test 4: Weekly Plan Generator
1. Set cron to run in 5 minutes
2. Wait for execution
3. Check execution log
4. Verify plan saved
5. Confirm WhatsApp message sent

### Test 5: Workout Reminders
1. Similar to Test 4
2. Verify reminder logic
3. Check message sent

## Step 11: Go Live

### Pre-Launch Checklist
- [ ] All tests passed
- [ ] Database backup created
- [ ] Stripe in live mode
- [ ] WhatsApp approved for production
- [ ] Error monitoring set up
- [ ] Documentation reviewed

### Switch to Production
1. Stripe:
   - Toggle to Live mode
   - Get live API keys
   - Update n8n credentials
   - Re-create webhook with live endpoint

2. WhatsApp:
   - Submit for business verification
   - Request production access
   - Update phone number (if changed)

3. n8n:
   - Activate all workflows
   - Monitor execution logs
   - Set up error notifications

## Troubleshooting

### Webhook Not Receiving Messages
- Verify webhook URL is public
- Check webhook verification
- Review n8n execution logs
- Test with webhook.site

### Database Connection Errors
- Verify Supabase URL
- Check API key permissions
- Test with curl/Postman
- Review RLS policies

### Stripe Webhook Failures
- Verify webhook secret
- Check signature verification
- Review event types
- Test in Stripe dashboard

### OpenAI Errors
- Check API key valid
- Verify billing set up
- Review rate limits
- Monitor usage dashboard

## Maintenance

### Daily
- Monitor execution logs
- Check error rates
- Review user feedback

### Weekly
- Backup database
- Export workflows
- Review API usage
- Check webhook health

### Monthly
- Rotate API keys
- Review security
- Update dependencies
- Audit user data

## Support

For issues:
1. Check execution logs
2. Review this guide
3. Test individual nodes
4. Contact: [promisetaiye16@gmail.com]

## Next Steps

- [ ] Add custom domain
- [ ] Set up analytics
- [ ] Implement A/B testing
- [ ] Add more features
- [ ] Scale infrastructure
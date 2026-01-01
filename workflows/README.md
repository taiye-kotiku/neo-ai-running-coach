# n8n Workflows

This directory contains all n8n workflow JSON files for the Neo AI Running Coach platform.

## Workflows Overview

### 1. Master Router (`master-router.json`)
**Purpose:** Central message routing hub

**Features:**
- Handles all incoming WhatsApp messages
- Routes to 3 paths: Onboarding, Payment, Premium
- Manages user state and subscription status
- Integrates with Supabase for data persistence

**Trigger:** WhatsApp webhook

---

### 2. Weekly Plan Generator (`weekly-plan-generator.json`)
**Purpose:** Automated weekly plan generation

**Features:**
- Scheduled execution every Monday at 8 AM
- Fetches active users from database
- Analyzes previous week's performance
- Generates personalized plans via GPT-4o
- Sends plans via WhatsApp

**Trigger:** Cron schedule (0 8 * * 1)

---

### 3. Workout Reminders (`workout-reminders.json`)
**Purpose:** Daily workout check-in system

**Features:**
- Runs daily at 9 PM
- Checks for scheduled workouts
- Verifies completion status
- Sends motivational reminders

**Trigger:** Cron schedule (0 21 * * *)

---

### 4. Stripe Webhook Handler (`stripe-webhook-handler.json`)
**Purpose:** Subscription lifecycle management

**Features:**
- Handles Stripe webhook events
- Processes subscription created/updated/canceled
- Updates database subscription status
- Sends confirmation messages

**Trigger:** Stripe webhook

---

## Import Instructions

### Step 1: Prepare n8n Instance
1. Ensure you have n8n installed (cloud or self-hosted)
2. Navigate to Workflows section
3. Click "+ Add workflow"

### Step 2: Import Workflow
1. Click the three-dot menu (⋮)
2. Select "Import from File"
3. Choose the JSON file
4. Workflow will be imported

### Step 3: Update Credentials
Each workflow requires the following credentials:

**WhatsApp Business API:**
- Phone Number ID
- Access Token
- Verify Token

**OpenAI API:**
- API Key
- Organization ID (optional)

**Stripe:**
- Secret Key (test/live)
- Webhook Secret

**Supabase:**
- Project URL
- Anon/Public Key
- Service Role Key (for certain operations)

### Step 4: Configure Webhook URLs
After importing, update webhook URLs:

**Master Router:**
```
https://your-n8n-instance.com/webhook/[webhook-id]
```

**Stripe Webhook Handler:**
```
https://your-n8n-instance.com/webhook/[webhook-id]
```

### Step 5: Update Variables
Replace placeholder values:
- Phone numbers
- Stripe Price IDs
- Database URLs
- Custom messages (if needed)

### Step 6: Test Workflow
1. Activate workflow
2. Test with sample data
3. Check execution logs
4. Verify database updates

## Configuration Details

### Master Router Configuration

**WhatsApp Webhook:**
- Verify Token: Set in WhatsApp Business settings
- Webhook URL: n8n webhook URL

**Routes:**
- Onboarding: `onboarding_completed = false`
- Payment: Payment link clicks
- Premium: `subscripcio IN ('active', 'trial')`

### Weekly Plan Generator Configuration

**Schedule:**
- Cron: `0 8 * * 1` (Every Monday 8 AM)
- Timezone: UTC (adjust as needed)

**Batch Processing:**
- Processes 1 user at a time
- 5-second delay between users
- Prevents rate limiting

### Workout Reminders Configuration

**Schedule:**
- Cron: `0 21 * * *` (Every day 9 PM)
- Timezone: UTC (adjust as needed)

**Logic:**
- Checks active plan exists
- Verifies today's workout scheduled
- Confirms not already completed

### Stripe Webhook Configuration

**Events:**
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.payment_succeeded`
- `invoice.payment_failed`

**Webhook Secret:**
- Found in Stripe Dashboard → Webhooks
- Used to verify webhook authenticity

## Troubleshooting

### Workflow Not Executing
- Check workflow is active (toggle in top-right)
- Verify trigger is configured correctly
- Check execution logs for errors

### Webhook Issues
- Ensure webhook URL is publicly accessible
- Verify webhook secret/verify token
- Check n8n instance is running
- Test with webhook.site first

### Credential Errors
- Re-enter API keys
- Check key permissions
- Verify expiration dates
- Test credentials separately

### Database Connection Errors
- Verify Supabase URL is correct
- Check API key has correct permissions
- Ensure RLS policies allow access
- Test with direct SQL query

## Best Practices

1. **Use Test Mode First**
   - Test all workflows in Stripe test mode
   - Use test WhatsApp numbers
   - Verify all logic before production

2. **Monitor Executions**
   - Check execution logs regularly
   - Set up error notifications
   - Monitor database for anomalies

3. **Version Control**
   - Export workflows regularly
   - Keep backups of working versions
   - Document changes

4. **Security**
   - Never commit credentials
   - Use environment variables
   - Rotate API keys periodically
   - Enable webhook signature verification

## Support

For issues or questions:
- Check [docs/SETUP.md](../docs/SETUP.md)
- Review execution logs
- Test individual nodes
- Contact: [promisetaiye16@gmail.com]

## License

MIT License - See [LICENSE](../LICENSE)
# System Architecture

This document provides a detailed technical overview of the Neo AI Running Coach platform architecture.

## System Overview

Neo is a microservices-style architecture built on n8n workflow automation, integrating multiple external services to create a cohesive AI coaching platform.
```
┌─────────────────────────────────────────────────────────────┐
│                         USER                                 │
│                      (WhatsApp)                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    MASTER ROUTER                             │
│         (Intelligent Message Routing)                        │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Onboarding  │  │   Payment    │  │   Premium    │     │
│  │    Route     │  │    Route     │  │    Route     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└──────┬──────────────────┬──────────────────┬───────────────┘
       │                  │                  │
       ▼                  ▼                  ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐
│ Save User   │  │   Stripe    │  │    Premium Agent    │
│   Data      │  │  Checkout   │  │   (GPT-4o + Tools)  │
└─────────────┘  └─────────────┘  └─────────────────────┘
       │                  │                  │
       ▼                  ▼                  ▼
┌──────────────────────────────────────────────────────────┐
│                    SUPABASE DATABASE                      │
│  ┌──────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │  users   │ │ chat_history │ │  workout_history     │ │
│  └──────────┘ └──────────────┘ └──────────────────────┘ │
│  ┌──────────────┐                                        │
│  │ weekly_plans │                                        │
│  └──────────────┘                                        │
└──────────────────────────────────────────────────────────┘
       ▲                  ▲                  ▲
       │                  │                  │
┌──────┴────────┐  ┌──────┴────────┐  ┌────┴──────────┐
│   Weekly      │  │    Workout    │  │    Stripe     │
│     Plan      │  │   Reminders   │  │   Webhook     │
│  Generator    │  │   (Daily)     │  │   Handler     │
│  (Monday 8AM) │  │   (9 PM)      │  │               │
└───────────────┘  └───────────────┘  └───────────────┘
```

## Core Components

### 1. Master Router
**Type:** Webhook-triggered workflow  
**Purpose:** Central message processing hub

**Flow:**
1. Receives WhatsApp message webhook
2. Extracts user phone and message
3. Queries database for user status
4. Routes to appropriate handler:
   - `onboarding_completed = false` → Onboarding Route
   - Payment link click → Payment Route
   - `subscripcio IN ('active', 'trial')` → Premium Route

**Key Nodes:**
- WhatsApp Webhook Trigger
- Get User Data (Supabase)
- Route Decision (IF/Switch)
- Save Chat History
- Context Builder

### 2. Onboarding Route
**Purpose:** Collect user data conversationally

**Data Collected:**
- Name (nom)
- Age (edat)
- Weight (pes)
- Gender (sexe)
- Terrain preference (terreny)
- Days available (dies_disponibles)
- Running level (nivell)
- Goals (objectius)

**Agent Tools:**
- `save_onboarding_data`: Saves user profile
- `save_weekly_plan`: Generates and saves initial plan

**Completion:** Sets `onboarding_completed = true`

### 3. Payment Route
**Purpose:** Handle subscription checkout

**Flow:**
1. User clicks payment link
2. Redirect to Stripe Checkout
3. User completes payment
4. Stripe sends webhook
5. Stripe Webhook Handler updates database
6. Welcome message sent

**Stripe Integration:**
- Uses Price IDs (not Product IDs)
- Supports discount codes
- Metadata: user phone number

### 4. Premium Route
**Purpose:** AI-powered coaching interactions

**Context Building:**
- User profile
- Last 100 chat messages
- Current weekly plan
- Recent workout history

**Agent Capabilities:**
- Answer training questions
- Adjust individual sessions
- Motivational support
- Workout tracking via tools

**Tools:**
- `save_workout_completion`: Logs workouts
- `save_workout_to_db`: HTTP Request Tool

### 5. Weekly Plan Generator
**Schedule:** Every Monday 8 AM (Cron: `0 8 * * 1`)

**Process:**
1. Get Active Users (`subscripcio IN ('active', 'trial')`)
2. Split Into Batches (sequential processing)
3. For each user:
   - Get last 4 weekly plans
   - Get last 30 workout sessions
   - Analyze Progress:
     - Calculate completion rate
     - Determine average difficulty
     - Compute total distance
   - Generate Plan (GPT-4o):
     - Progression strategy
     - Personalized sessions
     - Nutrition tips
   - Save to Database
   - Mark previous week completed
   - Send via WhatsApp
   - Wait 5 seconds

**Progression Logic:**
```
IF avgDifficulty >= 8:
  REDUCE intensity 10-15%
ELSE IF avgDifficulty <= 3 AND completionRate >= 80%:
  INCREASE load 5-10%
ELSE IF completionRate < 50%:
  MAINTAIN intensity, MOTIVATE
ELSE:
  NORMAL progression
```

### 6. Workout Reminders
**Schedule:** Every day 9 PM (Cron: `0 21 * * *`)

**Process:**
1. Get Active Users
2. Split Into Batches
3. For each user:
   - Get current week plan
   - Check today's workout completion
   - Determine if reminder needed
   - Send reminder if appropriate
   - Wait 3 seconds

**Conditions for Reminder:**
- User has active plan
- Today is mentioned in plan
- Workout not yet completed

### 7. Stripe Webhook Handler
**Trigger:** Stripe webhook events

**Events Handled:**
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.payment_succeeded`
- `invoice.payment_failed`

**Actions:**
- Update `subscripcio` field in database
- Send confirmation/cancellation messages
- Log events for debugging

## Data Flow

### Message Flow
```
User sends WhatsApp message
  ↓
WhatsApp → Master Router webhook
  ↓
Extract phone + message
  ↓
Query users table
  ↓
Route based on status
  ↓
Process with appropriate handler
  ↓
Save to chat_history
  ↓
Generate response (AI or template)
  ↓
Send via WhatsApp API
```

### Subscription Flow
```
User clicks payment link
  ↓
Stripe Checkout page
  ↓
User completes payment
  ↓
Stripe webhook → Webhook Handler
  ↓
Update users.subscripcio
  ↓
Send welcome message
  ↓
User can access premium features
```

### Weekly Plan Flow
```
Monday 8 AM trigger
  ↓
Get active users
  ↓
For each user:
  ↓
  Get workout history
  ↓
  Analyze performance
  ↓
  Generate plan (GPT-4o)
  ↓
  Save to weekly_plans
  ↓
  Mark previous week completed
  ↓
  Send via WhatsApp
```

## Integration Details

### WhatsApp Business API
- **Method:** Cloud API
- **Authentication:** Phone Number ID + Access Token
- **Webhook Verification:** Verify Token
- **Message Types:** Text only (for now)
- **Rate Limits:** 1000 messages/day (adjustable)

### OpenAI GPT-4o
- **Model:** gpt-4o
- **Max Tokens:** 500 (Premium Agent), 2000 (Plan Generator)
- **Temperature:** 0.7 (Premium), 0.8 (Plan Generator)
- **Context:** System prompt + user context + tools
- **Memory:** Buffer window (100 messages)

### Stripe
- **Products:** 3 (Monthly, 6-Month, Annual)
- **Prices:** EUR pricing
- **Webhooks:** Subscription events
- **Metadata:** user_phone for linking
- **Test Mode:** Fully supported

### Supabase
- **Database:** PostgreSQL 15
- **API:** REST + Realtime
- **Authentication:** Anon key (RLS policies)
- **Storage:** Not used (yet)
- **Edge Functions:** Not used (yet)

## Security Considerations

### API Keys
- Stored in n8n credentials (encrypted)
- Never committed to version control
- Rotated periodically

### Webhooks
- Signature verification (Stripe)
- Verify token (WhatsApp)
- HTTPS only
- Rate limiting

### Database
- RLS policies enabled
- Anon key with restricted access
- Foreign key constraints
- Input validation via CHECK constraints

### User Data
- Minimal PII collection
- Phone as primary key (necessary for WhatsApp)
- No credit card storage (handled by Stripe)
- GDPR-compliant data retention policies

## Scalability

### Current Capacity
- **Concurrent Users:** Unlimited (async processing)
- **Messages/Day:** 1000 (WhatsApp limit)
- **Database:** PostgreSQL scales to millions of rows
- **n8n:** Horizontal scaling via queue mode

### Bottlenecks
- WhatsApp API rate limits
- OpenAI API rate limits (tier-based)
- n8n execution limits (plan-based)

### Optimization Strategies
- Batch processing with delays
- Database indexing on common queries
- Workflow execution caching
- Async webhook processing

## Monitoring & Observability

### n8n Execution Logs
- Success/failure tracking
- Execution duration
- Error messages
- Data inspection

### Database Metrics
- Table sizes
- Query performance
- Index usage
- Connection pool

### External Service Status
- WhatsApp API uptime
- OpenAI API status
- Stripe status
- Supabase status

## Disaster Recovery

### Backups
- Supabase: Daily automated backups (7 days)
- n8n workflows: Manual exports
- Code: Git version control

### Recovery Procedures
1. Restore database from Supabase backup
2. Re-import n8n workflows
3. Verify webhook connections
4. Test with small user subset

## Future Architecture

### Planned Enhancements
- Redis caching layer
- Celery task queue
- GraphQL API
- Mobile app backend
- Analytics dashboard
- Multi-language support

### Migration Path
- Phase 1: Add caching (Redis)
- Phase 2: Separate backend API
- Phase 3: Mobile app integration
- Phase 4: Multi-tenant architecture
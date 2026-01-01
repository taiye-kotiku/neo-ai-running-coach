# Database Schema

This directory contains the PostgreSQL/Supabase database schema for Neo AI Running Coach.

## Quick Setup

1. Log into your Supabase project
2. Navigate to SQL Editor
3. Copy and paste `schema.sql`
4. Run the script
5. Verify tables created in Table Editor

## Tables Overview

### 1. `users`
Stores user profile and subscription information.

**Key Fields:**
- `phone` (PK): User's WhatsApp number
- `subscripcio`: Subscription status (active, trial, canceled)
- `stripe_customer_id`: Links to Stripe customer
- `onboarding_completed`: Tracks onboarding status

### 2. `chat_history`
Maintains conversation history for context-aware responses.

**Key Fields:**
- `user_phone` (FK): References users table
- `role`: Either 'user' or 'assistant'
- `message`: The actual message text
- `created_at`: Timestamp for ordering

**Retention:** Last 100 messages per user

### 3. `weekly_plans`
Stores generated training plans.

**Key Fields:**
- `user_phone` (FK): References users table
- `week_number`: Sequential week counter
- `plan_text`: Full plan in Markdown format
- `status`: 'active' or 'completed'

**Lifecycle:** Active → Completed (when new week generated)

### 4. `workout_history`
Logs completed workout sessions.

**Key Fields:**
- `user_phone` (FK): References users table
- `week_number`: Which week this workout belongs to
- `session_number`: Which session (1, 2, 3, etc.)
- `distance`, `time_minutes`, `pace_min_per_km`: Performance metrics
- `difficulty_rating`: User's perceived difficulty (1-10)
- `feedback`: User's comments

## Row Level Security (RLS)

All tables have RLS enabled with policies allowing:
- `anon` role: Full access (INSERT, SELECT, UPDATE)
- Used by n8n workflows via Supabase API

**Production Recommendation:**
- Create separate service role for n8n
- Restrict `anon` role access
- Implement user-based RLS policies

## Indexes

Optimized for common queries:
- User phone lookups
- Recent chat history
- Active weekly plans
- Workout history by date

## Maintenance

### Cleanup Old Data
```sql
-- Remove chat history older than 30 days
DELETE FROM chat_history 
WHERE created_at < NOW() - INTERVAL '30 days';

-- Archive completed plans older than 6 months
-- (Implement archiving strategy as needed)
```

### Monitor Table Sizes
```sql
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Backup Strategy

**Supabase Automatic Backups:**
- Daily backups (free tier: 7 days retention)
- Point-in-time recovery (paid plans)

**Manual Exports:**
```bash
# Export to CSV via Supabase dashboard
# Or use pg_dump for complete backup
```

## Migration Notes

If updating schema:
1. Test in development database first
2. Backup production data
3. Run migrations during low-traffic period
4. Verify data integrity after migration

## Support

For schema questions:
- Review `schema.sql`
- Check Supabase documentation
- Contact: [promisetaiye16@gmail.com]

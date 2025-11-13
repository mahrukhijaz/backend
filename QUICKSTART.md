# Quick Start Guide
## Multi-LLM Query Processing System

This guide will help you get the Multi-LLM Query Processing System up and running in under 30 minutes.

## Prerequisites

Before you begin, ensure you have:

- [ ] n8n installed (self-hosted or cloud)
- [ ] PostgreSQL database (version 12+)
- [ ] AWS S3 account (or compatible object storage)
- [ ] API keys for at least one LLM service
- [ ] SMTP email account

## 🚀 Quick Setup (5 Steps)

### Step 1: Database Setup (5 minutes)

```bash
# Create database
createdb multi_llm_system

# Run schema
psql -U your_user -d multi_llm_system -f database-schema.sql

# Verify tables created
psql -U your_user -d multi_llm_system -c "\dt"
```

Expected output:
```
               List of relations
 Schema |       Name        | Type  |  Owner
--------+-------------------+-------+----------
 public | chat_sessions     | table | your_user
 public | industries        | table | your_user
 public | pricing_config    | table | your_user
 public | professions       | table | your_user
 public | query_memory      | table | your_user
 public | transactions      | table | your_user
 public | users             | table | your_user
```

### Step 2: Environment Configuration (5 minutes)

```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

**Minimum required variables:**

```bash
# Database
DB_HOST=localhost
DB_NAME=multi_llm_system
DB_USER=your_user
DB_PASSWORD=your_password

# At least one LLM (choose one to start)
OPENAI_API_KEY=sk-your-key
# OR
ANTHROPIC_API_KEY=sk-ant-your-key

# Storage
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_S3_BUCKET=your-bucket

# Email
SMTP_HOST=smtp.gmail.com
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

### Step 3: Import n8n Workflow (5 minutes)

1. **Open n8n dashboard**
   - Go to your n8n instance: `http://localhost:5678` (or your cloud URL)

2. **Import workflow**
   - Click **"Workflows"** in sidebar
   - Click **"Import from File"**
   - Select `multi-llm-query-workflow.json`
   - Click **"Import"**

3. **Verify import**
   - You should see 60+ nodes in the workflow canvas

### Step 4: Configure Credentials (10 minutes)

In n8n, configure these credentials:

#### 4.1 PostgreSQL
```
Name: PostgreSQL Account
Host: localhost
Database: multi_llm_system
User: your_user
Password: your_password
Port: 5432
```

#### 4.2 AWS S3
```
Name: AWS S3
Access Key ID: your_access_key
Secret Access Key: your_secret_key
Region: us-east-1
```

#### 4.3 OpenAI (if using)
```
Name: OpenAI
API Key: sk-your-openai-key
```

#### 4.4 Anthropic (if using)
```
Name: Anthropic
API Key: sk-ant-your-anthropic-key
```

#### 4.5 SMTP
```
Name: SMTP
Host: smtp.gmail.com
Port: 587
User: your-email@gmail.com
Password: your-app-password
From Email: noreply@yourplatform.com
```

#### 4.6 Stripe (optional for payments)
```
Name: Stripe
API Key: sk_test_your-stripe-key
```

### Step 5: Activate Workflow (5 minutes)

1. **Activate workflow**
   - Toggle the switch at top right to "Active"
   - Green indicator = workflow is running

2. **Get webhook URLs**
   - Click on "Webhook - User Registration" node
   - Copy the Production URL
   - Repeat for other webhook nodes

3. **Test webhook**
   ```bash
   curl -X POST https://your-n8n-instance.com/webhook/register-user \
     -H "Content-Type: application/json" \
     -d '{
       "username": "testuser",
       "password_hash": "$2b$10$hashedpassword",
       "email": "test@example.com",
       "phone": "+1234567890",
       "address": "123 Test St",
       "industry": "Technology",
       "profession": "Software Engineer"
     }'
   ```

## ✅ Verification

### Test User Registration

```bash
curl -X POST https://your-n8n-instance.com/webhook/register-user \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password_hash": "hashed_password_here",
    "email": "test@example.com",
    "phone": "+1234567890",
    "address": "123 Test Street",
    "industry": "Technology",
    "profession": "Software Engineer"
  }'
```

Expected response:
```json
{
  "success": true,
  "userId": 1,
  "message": "Account created successfully with $20 trial balance",
  "balance": 20.00
}
```

### Test Query Submission

```bash
curl -X POST https://your-n8n-instance.com/webhook/submit-query \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "query": "What are the benefits of artificial intelligence in healthcare?"
  }'
```

### Verify Database

```bash
# Check user was created
psql -U your_user -d multi_llm_system -c "SELECT * FROM users LIMIT 1;"

# Check query was processed
psql -U your_user -d multi_llm_system -c "SELECT * FROM query_memory LIMIT 1;"
```

## 🎯 Next Steps

### 1. Configure All LLMs

For full functionality, add all four LLM credentials:
- OpenAI (ChatGPT 5)
- Anthropic (Claude Sonnet 4.5)
- X.AI (Grok 4.0)
- Google (Gemini 2.5)

### 2. Set Up Payment Processing

```bash
# Install Stripe CLI for testing
stripe listen --forward-to https://your-n8n-instance.com/webhook/stripe
```

### 3. Configure Document Conversion

Option A: Use ConvertAPI
```bash
# Add to .env
CONVERTAPI_SECRET=your-convertapi-secret
```

Option B: Use local tools
```bash
# Install pandoc and libreoffice
sudo apt-get install pandoc libreoffice
```

### 4. Set Up Monitoring

```bash
# Enable logging in n8n
export N8N_LOG_LEVEL=debug
export N8N_LOG_OUTPUT=file,console

# View logs
tail -f ~/.n8n/logs/n8n.log
```

### 5. Create Admin User

```sql
-- Create admin user
INSERT INTO users (
  username,
  password_hash,
  email,
  account_type,
  trial_balance
) VALUES (
  'admin',
  '$2b$10$your_hashed_password',
  'admin@yourplatform.com',
  'paid',
  1000.00
);
```

## 🔧 Troubleshooting

### Issue: Webhook returns 404

**Solution:**
1. Ensure workflow is activated
2. Check webhook paths match exactly
3. Verify n8n is running

### Issue: Database connection failed

**Solution:**
```bash
# Test connection
psql -U your_user -d multi_llm_system -c "SELECT 1;"

# Check credentials in n8n match database
# Verify PostgreSQL is running
sudo systemctl status postgresql
```

### Issue: LLM API calls fail

**Solution:**
1. Verify API key is correct
2. Check API quota/limits
3. Test API key manually:

```bash
# Test OpenAI
curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "Hello"}]}'
```

### Issue: Email not sending

**Solution:**
1. For Gmail, use App Password (not regular password)
2. Enable "Less secure app access" (if needed)
3. Check SMTP logs in n8n
4. Test SMTP connection:

```bash
# Test SMTP
telnet smtp.gmail.com 587
```

### Issue: Storage upload fails

**Solution:**
```bash
# Test S3 credentials
aws s3 ls s3://your-bucket-name --profile your-profile

# Check bucket permissions
# Verify bucket exists
# Check CORS configuration
```

## 📊 Monitoring

### Check System Health

```sql
-- Active users today
SELECT COUNT(DISTINCT user_id) FROM query_memory
WHERE DATE(created_at) = CURRENT_DATE;

-- Queries processed today
SELECT COUNT(*) FROM query_memory
WHERE DATE(created_at) = CURRENT_DATE;

-- Failed queries
SELECT COUNT(*) FROM query_memory
WHERE status = 'failed' AND DATE(created_at) = CURRENT_DATE;

-- Average processing time
SELECT AVG(processing_time_seconds) FROM query_memory
WHERE DATE(created_at) = CURRENT_DATE;
```

### Monitor n8n Workflow

```bash
# View executions
n8n list:workflow --active=true

# View execution history
n8n list:execution --workflowId=YOUR_WORKFLOW_ID
```

## 🎓 Learning Resources

### n8n Documentation
- [n8n Docs](https://docs.n8n.io)
- [Webhook Guide](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/)

### API Documentation
- [OpenAI API](https://platform.openai.com/docs)
- [Anthropic API](https://docs.anthropic.com)
- [X.AI API](https://docs.x.ai)
- [Google Gemini API](https://ai.google.dev/docs)

### Database
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Full-Text Search](https://www.postgresql.org/docs/current/textsearch.html)

## 💡 Tips

1. **Start with one LLM** - Get it working with one LLM before adding others
2. **Use test mode** - Enable mock responses during development
3. **Monitor costs** - Track API usage to avoid unexpected charges
4. **Backup database** - Set up automated backups from day one
5. **Use environment variables** - Never hardcode secrets
6. **Test webhooks** - Use tools like Postman or curl to test endpoints
7. **Check logs** - n8n logs provide detailed execution information
8. **Scale gradually** - Start with small queries, then increase complexity

## 🆘 Getting Help

If you encounter issues:

1. Check workflow execution logs in n8n
2. Review database logs: `tail -f /var/log/postgresql/postgresql.log`
3. Check n8n logs: `tail -f ~/.n8n/logs/n8n.log`
4. Verify all credentials are correct
5. Test individual components separately
6. Review the detailed documentation in `WORKFLOW_README.md`

## 🎉 Success Checklist

- [ ] Database created and schema loaded
- [ ] Environment variables configured
- [ ] n8n workflow imported and activated
- [ ] All credentials configured in n8n
- [ ] Test user registration successful
- [ ] Test query processed successfully
- [ ] Email delivery working
- [ ] Storage uploads working
- [ ] Payment processing configured (optional)
- [ ] Admin dashboard accessible

## Next: Full Documentation

Once you have the basics working, review the complete documentation:
- `WORKFLOW_README.md` - Comprehensive system documentation
- `database-schema.sql` - Database schema reference
- `.env.example` - All configuration options

---

**Estimated Setup Time:** 30 minutes
**Difficulty:** Intermediate
**Prerequisites:** Basic knowledge of databases, APIs, and n8n

Good luck! 🚀

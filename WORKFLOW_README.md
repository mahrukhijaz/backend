# Multi-LLM Query Processing System - n8n Workflow

## Overview

This n8n workflow implements a comprehensive multi-LLM query processing system that:
- Manages user registration and authentication
- Processes queries through 4 different LLMs (ChatGPT 5, Claude Sonnet 4.5, Grok 4.0, Gemini 2.5)
- Consolidates and verifies outputs using AI moderators
- Generates professional reports in multiple formats (PDF, DOCX, TXT)
- Implements RAG (Retrieval-Augmented Generation) for contextual memory
- Provides admin panel for monitoring and management

## Architecture

### Main Components

1. **User Management System**
   - User registration with KYC information
   - Account balance management
   - Free trial with $20 starting balance
   - Payment processing integration (Stripe)

2. **Query Processing Pipeline**
   - Query submission and validation
   - Balance checking and deduction
   - Parallel LLM querying
   - Multi-stage consolidation and verification
   - Document generation and delivery

3. **Memory System (RAG)**
   - Stores past queries and responses
   - Retrieves relevant context for new queries
   - Enhances query responses with historical data

4. **Admin Panel**
   - Dashboard with analytics
   - User management
   - Pricing configuration
   - Revenue tracking

## Prerequisites

### Required Services

1. **n8n** (version 1.0+)
2. **PostgreSQL** database
3. **AWS S3** or compatible object storage
4. **Email SMTP** server
5. **API Keys** for:
   - OpenAI (ChatGPT)
   - Anthropic (Claude)
   - X.AI (Grok)
   - Google (Gemini)
   - Stripe (payments)
   - ConvertAPI (document conversion)

### Database Setup

Run the provided `database-schema.sql` file to create necessary tables:

```bash
psql -U your_user -d your_database -f database-schema.sql
```

## Installation

### Step 1: Import Workflow

1. Open your n8n instance
2. Go to **Workflows** → **Import from File**
3. Select `multi-llm-query-workflow.json`
4. Click **Import**

### Step 2: Configure Credentials

You need to configure the following credentials in n8n:

#### 1. PostgreSQL (ID: 1)
- Host: your-postgres-host
- Database: your-database-name
- User: your-username
- Password: your-password
- Port: 5432

#### 2. AWS S3 (ID: 2)
- Access Key ID: your-access-key
- Secret Access Key: your-secret-key
- Region: your-region
- Bucket Name: your-bucket-name

#### 3. OpenAI (ID: 3)
- API Key: your-openai-api-key

#### 4. Anthropic (ID: 4)
- API Key: your-anthropic-api-key

#### 5. X.AI (Grok)
- Configure as HTTP Header Auth
- Header: Authorization
- Value: Bearer your-grok-api-key

#### 6. Google (Gemini)
- Configure as HTTP Header Auth
- Header: x-goog-api-key
- Value: your-gemini-api-key

#### 7. Stripe (ID: 6)
- API Key: your-stripe-secret-key

#### 8. SMTP Email (ID: 5)
- Host: your-smtp-host
- Port: 587
- User: your-email
- Password: your-password
- From Email: noreply@yourplatform.com

### Step 3: Configure Webhook URLs

After importing, activate the workflow and note down the webhook URLs:

1. **User Registration**: `https://your-n8n-instance.com/webhook/register-user`
2. **Submit Query**: `https://your-n8n-instance.com/webhook/submit-query`
3. **Add Funds**: `https://your-n8n-instance.com/webhook/add-funds`
4. **Get Chat History**: `https://your-n8n-instance.com/webhook/get-chat-history/:userId`
5. **Admin Dashboard**: `https://your-n8n-instance.com/webhook/admin/dashboard`
6. **Update Pricing**: `https://your-n8n-instance.com/webhook/admin/update-pricing`

## API Endpoints

### 1. User Registration

**Endpoint**: `POST /webhook/register-user`

**Request Body**:
```json
{
  "username": "john_doe",
  "password_hash": "hashed_password_here",
  "email": "john@example.com",
  "phone": "+1234567890",
  "address": "123 Main St, City, Country",
  "industry": "Technology",
  "profession": "Software Engineer"
}
```

**Response**:
```json
{
  "success": true,
  "userId": 123,
  "message": "Account created successfully with $20 trial balance",
  "balance": 20.00
}
```

### 2. Submit Query

**Endpoint**: `POST /webhook/submit-query`

**Request Body**:
```json
{
  "userId": 123,
  "query": "What are the latest trends in AI technology?",
  "attachments": [
    {
      "attachmentName": "document.pdf",
      "attachmentData": "base64_encoded_data"
    }
  ]
}
```

**Response**:
```json
{
  "success": true,
  "queryId": "123_1699123456789",
  "message": "Query processed successfully",
  "downloadUrls": {
    "pdf": "https://storage.com/path/to/report.pdf",
    "docx": "https://storage.com/path/to/report.docx",
    "txt": "https://storage.com/path/to/report.txt",
    "auditTrail": "https://storage.com/path/to/audit.txt"
  },
  "remainingBalance": 15.50
}
```

**Error Response (Insufficient Balance)**:
```json
{
  "success": false,
  "error": "Account balance is too low for this query. Please add funds to continue using. Minimum $20 USD."
}
```

### 3. Add Funds

**Endpoint**: `POST /webhook/add-funds`

**Request Body**:
```json
{
  "userId": 123,
  "amount": 50.00,
  "stripeCustomerId": "cus_xxxxxxxxxxxxx"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Funds added successfully",
  "newBalance": 70.00
}
```

### 4. Get Chat History

**Endpoint**: `GET /webhook/get-chat-history/:userId`

**Response**:
```json
{
  "success": true,
  "chatHistory": [
    {
      "query_text": "Previous query...",
      "final_deliverable": "Previous response...",
      "created_at": "2025-11-04T10:30:00Z",
      "folder_path": "123/2025-11-04_Previous_Query"
    }
  ]
}
```

### 5. Admin Dashboard

**Endpoint**: `GET /webhook/admin/dashboard`

**Response**:
```json
{
  "success": true,
  "dashboard": {
    "dailyActiveUsers": 150,
    "dailyQueryCount": 487,
    "dailyRevenue": 2450.00
  }
}
```

### 6. Update Pricing

**Endpoint**: `POST /webhook/admin/update-pricing`

**Request Body**:
```json
{
  "newQueryCost": 5.00
}
```

**Response**:
```json
{
  "success": true,
  "message": "Pricing updated successfully"
}
```

## Workflow Details

### Query Processing Flow

1. **Validation Phase**
   - Check user balance
   - Warn if balance < $2
   - Block if balance = $0

2. **Storage Phase**
   - Create folder structure: `user_id/YYYY-MM-DD_Topic/`
   - Save user query
   - Save attachments (if any)

3. **RAG Phase**
   - Search query memory for relevant past queries
   - Extract contextual information
   - Prepare enhanced query context

4. **LLM Query Phase** (Parallel Execution)
   - Query ChatGPT 5
   - Query Claude Sonnet 4.5
   - Query Grok 4.0
   - Query Gemini 2.5
   - Store all outputs

5. **Consolidation Phase**
   - First Moderator (Claude Sonnet 4.5):
     - Consolidates all LLM outputs
     - Generates Initial Consolidated Report
     - Generates Initial Consolidation Analysis Report

6. **Verification Phase**
   - Second Moderator (PWST Core):
     - Verifies consolidated report
     - Cross-references with original query
     - Generates Verification Results

7. **Final Enhancement Phase**
   - First Moderator (Claude Sonnet 4.5):
     - Uses all previous outputs
     - Generates Final Deliverable Report
     - Generates Audit Trail

8. **Document Generation Phase**
   - Convert to PDF
   - Convert to DOCX
   - Store all formats

9. **Delivery Phase**
   - Generate download URLs
   - Email reports to user
   - Display download links in UI

10. **Memory Update Phase**
    - Store query and final deliverable in memory
    - Deduct query cost from user balance

## Folder Structure

Each query creates the following folder structure in S3:

```
user_id/
└── YYYY-MM-DD_Topic/
    ├── user_query.txt
    ├── attachments/
    │   └── [uploaded files]
    ├── llm_outputs/
    │   ├── chatgpt_output.txt
    │   ├── claude_output.txt
    │   ├── grok_output.txt
    │   └── gemini_output.txt
    ├── YYYY-MM-DD_Topic_Initial_Consolidated_Report.txt
    ├── YYYY-MM-DD_Topic_Initial_Consolidation_Analysis_Report.txt
    ├── YYYY-MM-DD_Topic_Initial_Consolidated_Report_Verification.txt
    ├── YYYY-MM-DD_Topic_Final_Deliverable_Report.txt
    ├── YYYY-MM-DD_Topic_Final_Deliverable_Report.pdf
    ├── YYYY-MM-DD_Topic_Final_Deliverable_Report.docx
    └── YYYY-MM-DD_Topic_Final_Report_Generation_Audit_Trail.txt
```

## Customization

### Proprietary Prompts

The workflow uses three proprietary prompts that you should customize:

1. **PanelPrompt Consolidation and Analysis**
   - Located in: `Moderator 1 - Initial Consolidation` node
   - Purpose: Defines how LLM outputs are consolidated

2. **PanelPrompt PWSTCore Verification**
   - Located in: `Moderator 2 - PWST Core Verification` node
   - Purpose: Defines verification criteria and process

3. **PanelPrompt Final Deliverable**
   - Located in: `Moderator 1 - Final Deliverable` node
   - Purpose: Defines final report structure and content

### Query Pricing

Default query cost structure:
- Initial setup: $2.00 per query (configurable)
- Calculated based on sum of API calls
- Adjustable via Admin Panel

### Balance Warnings

- Warning threshold: < $2.00
- Minimum deposit: $20.00
- Trial balance: $20.00

## Alternative: OpenRouter Integration

For simplified LLM management, consider using OpenRouter:

**Benefits**:
- Single API for all LLMs
- Unified billing
- Automatic failover
- Cost tracking

**Implementation**:
Replace individual LLM nodes with OpenRouter HTTP requests:

```javascript
// OpenRouter API call
{
  "url": "https://openrouter.ai/api/v1/chat/completions",
  "method": "POST",
  "headers": {
    "Authorization": "Bearer YOUR_OPENROUTER_KEY",
    "HTTP-Referer": "YOUR_SITE_URL"
  },
  "body": {
    "model": "openai/gpt-4",  // or anthropic/claude-sonnet-4.5, etc.
    "messages": [
      {
        "role": "user",
        "content": "Your query here"
      }
    ]
  }
}
```

## Monitoring and Maintenance

### Key Metrics to Monitor

1. **Query Success Rate**
   - Track failed queries
   - Monitor LLM response times
   - Check consolidation accuracy

2. **Balance Management**
   - Monitor low balance warnings
   - Track payment success rates
   - Review refund requests

3. **System Performance**
   - Storage usage
   - API rate limits
   - Database query performance

### Troubleshooting

#### Query Fails

1. Check LLM API keys are valid
2. Verify storage credentials
3. Check network connectivity
4. Review error logs in n8n

#### Email Not Sent

1. Verify SMTP credentials
2. Check email address format
3. Review spam filters
4. Verify attachment size limits

#### Balance Not Updating

1. Check database connection
2. Verify transaction records
3. Review Stripe webhook events
4. Check SQL query syntax

## Security Considerations

1. **Password Hashing**: Implement bcrypt or similar before storing
2. **API Key Security**: Store in environment variables, not in workflow
3. **Webhook Authentication**: Add API key or JWT validation
4. **Rate Limiting**: Implement to prevent abuse
5. **Data Encryption**: Enable encryption at rest for S3
6. **Access Control**: Use IAM roles for AWS services
7. **Audit Logging**: Enable comprehensive logging for all operations

## Backup and Recovery

### Database Backup

```bash
# Daily backup
pg_dump -U your_user your_database > backup_$(date +%Y%m%d).sql
```

### Storage Backup

Configure S3 versioning and lifecycle policies:
- Enable versioning on S3 bucket
- Set lifecycle rule for archiving old queries
- Implement cross-region replication

## Support

For issues or questions:
1. Check n8n execution logs
2. Review database query logs
3. Verify API response codes
4. Contact support team

## License

Proprietary - All rights reserved

## Version History

- **v1.0.0** (2025-11-05): Initial release
  - Multi-LLM query processing
  - User management
  - Admin panel
  - RAG memory system

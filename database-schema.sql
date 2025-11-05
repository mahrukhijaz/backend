-- Multi-LLM Query Processing System - Database Schema
-- PostgreSQL Database Schema
-- Version: 1.0.0
-- Date: 2025-11-05

-- ============================================================================
-- Drop existing tables (if recreating)
-- ============================================================================

DROP TABLE IF EXISTS query_memory CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS chat_sessions CASCADE;
DROP TABLE IF EXISTS pricing_config CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS industries CASCADE;
DROP TABLE IF EXISTS professions CASCADE;

-- ============================================================================
-- Industries Reference Table
-- ============================================================================

CREATE TABLE industries (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default industries
INSERT INTO industries (name, description) VALUES
    ('Technology', 'Information Technology, Software, Hardware'),
    ('Finance', 'Banking, Investment, Insurance'),
    ('Healthcare', 'Medical, Pharmaceutical, Healthcare Services'),
    ('Education', 'Schools, Universities, Training'),
    ('Manufacturing', 'Production, Assembly, Industrial'),
    ('Retail', 'E-commerce, Brick and Mortar Stores'),
    ('Consulting', 'Business Consulting, Advisory Services'),
    ('Real Estate', 'Property, Construction, Development'),
    ('Media', 'Publishing, Broadcasting, Entertainment'),
    ('Legal', 'Law Firms, Legal Services'),
    ('Other', 'Other Industries');

-- ============================================================================
-- Professions Reference Table
-- ============================================================================

CREATE TABLE professions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default professions
INSERT INTO professions (name, description) VALUES
    ('Software Engineer', 'Software Development, Programming'),
    ('Data Scientist', 'Data Analysis, Machine Learning, AI'),
    ('Product Manager', 'Product Strategy, Development'),
    ('Business Analyst', 'Business Analysis, Requirements'),
    ('Designer', 'UI/UX, Graphic Design'),
    ('Marketing Manager', 'Marketing Strategy, Campaigns'),
    ('Sales Executive', 'Sales, Business Development'),
    ('Financial Analyst', 'Financial Analysis, Reporting'),
    ('Project Manager', 'Project Planning, Execution'),
    ('Consultant', 'Business Consulting, Advisory'),
    ('Executive', 'C-Level, VP, Director'),
    ('Entrepreneur', 'Startup Founder, Business Owner'),
    ('Researcher', 'Academic, Scientific Research'),
    ('Student', 'Student, Learner'),
    ('Other', 'Other Professions');

-- ============================================================================
-- Users Table
-- ============================================================================

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    industry VARCHAR(100),
    profession VARCHAR(100),

    -- Account Status
    account_status VARCHAR(20) DEFAULT 'active' CHECK (account_status IN ('active', 'suspended', 'closed')),
    account_type VARCHAR(20) DEFAULT 'trial' CHECK (account_type IN ('trial', 'paid', 'premium')),

    -- Balance Management
    trial_balance DECIMAL(10, 2) DEFAULT 20.00 NOT NULL,
    lifetime_spent DECIMAL(10, 2) DEFAULT 0.00,

    -- Credit Card Info (encrypted or tokenized)
    stripe_customer_id VARCHAR(100),
    payment_method_id VARCHAR(100),

    -- Trial Management
    is_trial BOOLEAN DEFAULT true,
    trial_started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    trial_expires_at TIMESTAMP,

    -- Security
    last_login TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,

    -- Password Recovery
    reset_token VARCHAR(255),
    reset_token_expires TIMESTAMP,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
    FOREIGN KEY (industry) REFERENCES industries(name),
    FOREIGN KEY (profession) REFERENCES professions(name)
);

-- Create indexes for users table
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_stripe_customer_id ON users(stripe_customer_id);
CREATE INDEX idx_users_account_status ON users(account_status);

-- ============================================================================
-- Query Memory Table (for RAG)
-- ============================================================================

CREATE TABLE query_memory (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    query_text TEXT NOT NULL,
    query_id VARCHAR(100) UNIQUE NOT NULL,

    -- LLM Outputs
    chatgpt_output TEXT,
    claude_output TEXT,
    grok_output TEXT,
    gemini_output TEXT,

    -- Consolidated Reports
    initial_consolidated_report TEXT,
    initial_consolidation_analysis TEXT,
    verification_results TEXT,
    final_deliverable TEXT,
    audit_trail TEXT,

    -- Storage Information
    folder_path VARCHAR(500),

    -- Attachments
    has_attachments BOOLEAN DEFAULT false,
    attachment_count INTEGER DEFAULT 0,

    -- Query Metadata
    query_topic VARCHAR(255),
    query_date DATE,
    processing_time_seconds INTEGER,

    -- Costs
    query_cost DECIMAL(10, 2),
    api_costs JSONB, -- Store individual API costs

    -- Status
    status VARCHAR(20) DEFAULT 'completed' CHECK (status IN ('processing', 'completed', 'failed', 'cancelled')),
    error_message TEXT,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,

    -- Foreign Keys
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for query_memory table
CREATE INDEX idx_query_memory_user_id ON query_memory(user_id);
CREATE INDEX idx_query_memory_query_id ON query_memory(query_id);
CREATE INDEX idx_query_memory_created_at ON query_memory(created_at DESC);
CREATE INDEX idx_query_memory_status ON query_memory(status);

-- Create full-text search index for query text
CREATE INDEX idx_query_memory_query_text_fts ON query_memory USING gin(to_tsvector('english', query_text));
CREATE INDEX idx_query_memory_final_deliverable_fts ON query_memory USING gin(to_tsvector('english', final_deliverable));

-- ============================================================================
-- Chat Sessions Table
-- ============================================================================

CREATE TABLE chat_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    session_id VARCHAR(100) UNIQUE NOT NULL,
    session_name VARCHAR(255),

    -- Session Status
    is_active BOOLEAN DEFAULT true,

    -- Session Metadata
    message_count INTEGER DEFAULT 0,
    total_cost DECIMAL(10, 2) DEFAULT 0.00,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP,

    -- Foreign Keys
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for chat_sessions table
CREATE INDEX idx_chat_sessions_user_id ON chat_sessions(user_id);
CREATE INDEX idx_chat_sessions_session_id ON chat_sessions(session_id);
CREATE INDEX idx_chat_sessions_is_active ON chat_sessions(is_active);

-- ============================================================================
-- Transactions Table
-- ============================================================================

CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,

    -- Transaction Details
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('deposit', 'query', 'refund', 'adjustment')),
    amount DECIMAL(10, 2) NOT NULL,
    balance_before DECIMAL(10, 2) NOT NULL,
    balance_after DECIMAL(10, 2) NOT NULL,

    -- Payment Information
    payment_method VARCHAR(50), -- 'stripe', 'paypal', etc.
    payment_intent_id VARCHAR(100),
    payment_status VARCHAR(20) CHECK (payment_status IN ('pending', 'succeeded', 'failed', 'refunded')),

    -- Query Reference
    query_id VARCHAR(100),

    -- Description
    description TEXT,

    -- Admin Actions
    admin_user_id INTEGER,
    admin_notes TEXT,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (query_id) REFERENCES query_memory(query_id) ON DELETE SET NULL
);

-- Create indexes for transactions table
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX idx_transactions_transaction_type ON transactions(transaction_type);
CREATE INDEX idx_transactions_payment_intent_id ON transactions(payment_intent_id);

-- ============================================================================
-- Pricing Configuration Table
-- ============================================================================

CREATE TABLE pricing_config (
    id SERIAL PRIMARY KEY,

    -- Query Pricing
    query_base_cost DECIMAL(10, 2) DEFAULT 2.00,

    -- API Costs (per call)
    chatgpt_cost DECIMAL(10, 4) DEFAULT 0.03,
    claude_cost DECIMAL(10, 4) DEFAULT 0.03,
    grok_cost DECIMAL(10, 4) DEFAULT 0.03,
    gemini_cost DECIMAL(10, 4) DEFAULT 0.03,

    -- Moderator Costs
    consolidation_cost DECIMAL(10, 4) DEFAULT 0.05,
    verification_cost DECIMAL(10, 4) DEFAULT 0.05,
    final_deliverable_cost DECIMAL(10, 4) DEFAULT 0.05,

    -- Document Conversion Costs
    pdf_conversion_cost DECIMAL(10, 4) DEFAULT 0.01,
    docx_conversion_cost DECIMAL(10, 4) DEFAULT 0.01,

    -- Balance Thresholds
    low_balance_threshold DECIMAL(10, 2) DEFAULT 2.00,
    minimum_deposit DECIMAL(10, 2) DEFAULT 20.00,
    trial_balance DECIMAL(10, 2) DEFAULT 20.00,

    -- Feature Flags
    enable_chatgpt BOOLEAN DEFAULT true,
    enable_claude BOOLEAN DEFAULT true,
    enable_grok BOOLEAN DEFAULT true,
    enable_gemini BOOLEAN DEFAULT true,
    enable_trial_accounts BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default pricing configuration
INSERT INTO pricing_config (id) VALUES (1);

-- ============================================================================
-- Functions
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================================================
-- Triggers
-- ============================================================================

-- Trigger for users table
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for query_memory table
CREATE TRIGGER update_query_memory_updated_at BEFORE UPDATE ON query_memory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for chat_sessions table
CREATE TRIGGER update_chat_sessions_updated_at BEFORE UPDATE ON chat_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for pricing_config table
CREATE TRIGGER update_pricing_config_updated_at BEFORE UPDATE ON pricing_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Views
-- ============================================================================

-- View for user statistics
CREATE VIEW user_statistics AS
SELECT
    u.id,
    u.username,
    u.email,
    u.account_type,
    u.trial_balance,
    u.lifetime_spent,
    COUNT(DISTINCT qm.id) as total_queries,
    COUNT(DISTINCT cs.id) as total_sessions,
    MAX(qm.created_at) as last_query_at,
    u.created_at as member_since
FROM users u
LEFT JOIN query_memory qm ON u.id = qm.user_id
LEFT JOIN chat_sessions cs ON u.id = cs.user_id
GROUP BY u.id, u.username, u.email, u.account_type, u.trial_balance, u.lifetime_spent, u.created_at;

-- View for daily analytics
CREATE VIEW daily_analytics AS
SELECT
    DATE(qm.created_at) as date,
    COUNT(DISTINCT qm.user_id) as daily_active_users,
    COUNT(qm.id) as daily_queries,
    SUM(qm.query_cost) as daily_revenue,
    AVG(qm.processing_time_seconds) as avg_processing_time,
    COUNT(CASE WHEN qm.status = 'failed' THEN 1 END) as failed_queries,
    COUNT(CASE WHEN qm.status = 'completed' THEN 1 END) as successful_queries
FROM query_memory qm
GROUP BY DATE(qm.created_at)
ORDER BY date DESC;

-- View for query costs breakdown
CREATE VIEW query_costs_breakdown AS
SELECT
    qm.id,
    qm.user_id,
    qm.query_id,
    qm.query_cost,
    qm.api_costs,
    qm.created_at,
    u.username,
    u.email
FROM query_memory qm
JOIN users u ON qm.user_id = u.id
ORDER BY qm.created_at DESC;

-- ============================================================================
-- Sample Data (Optional - for testing)
-- ============================================================================

-- Uncomment to insert sample data for testing

/*
-- Sample User
INSERT INTO users (username, password_hash, email, phone, address, industry, profession)
VALUES (
    'test_user',
    '$2b$10$abcdefghijklmnopqrstuvwxyz123456789',  -- This should be a real bcrypt hash
    'test@example.com',
    '+1234567890',
    '123 Test Street, Test City, TC 12345',
    'Technology',
    'Software Engineer'
);

-- Sample Query
INSERT INTO query_memory (
    user_id,
    query_text,
    query_id,
    query_topic,
    query_date,
    query_cost,
    status,
    folder_path
) VALUES (
    1,
    'What are the latest trends in artificial intelligence?',
    '1_' || extract(epoch from now())::bigint,
    'AI_Trends_Analysis',
    CURRENT_DATE,
    2.50,
    'completed',
    '1/2025-11-05_AI_Trends_Analysis'
);
*/

-- ============================================================================
-- Permissions (Optional - adjust as needed)
-- ============================================================================

-- Create application user (if needed)
-- CREATE USER n8n_app WITH PASSWORD 'your_secure_password';

-- Grant permissions
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO n8n_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO n8n_app;

-- ============================================================================
-- Maintenance Queries
-- ============================================================================

-- Query to find users with low balance
-- SELECT id, username, email, trial_balance
-- FROM users
-- WHERE trial_balance < 2.00 AND account_status = 'active';

-- Query to find failed queries
-- SELECT * FROM query_memory WHERE status = 'failed' ORDER BY created_at DESC;

-- Query to calculate total revenue
-- SELECT SUM(amount) as total_revenue
-- FROM transactions
-- WHERE transaction_type = 'query';

-- ============================================================================
-- Backup and Maintenance
-- ============================================================================

-- To backup database:
-- pg_dump -U your_user your_database > backup_$(date +%Y%m%d).sql

-- To restore database:
-- psql -U your_user your_database < backup_YYYYMMDD.sql

-- ============================================================================
-- Notes
-- ============================================================================

-- 1. Remember to create regular backups of your database
-- 2. Monitor index performance and rebuild if necessary
-- 3. Consider partitioning query_memory table if it grows very large
-- 4. Implement data retention policies (e.g., archive old queries after 1 year)
-- 5. Encrypt sensitive data at application level before storing
-- 6. Use connection pooling for better performance
-- 7. Set up monitoring and alerts for low balance users
-- 8. Implement rate limiting at application level

-- End of Schema

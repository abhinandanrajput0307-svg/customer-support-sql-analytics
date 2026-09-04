-- 1. Create and select the database
CREATE DATABASE IF NOT EXISTS support_analytics;
USE support_analytics;

-- 2. Agents Table
CREATE TABLE agents (
    agent_id INT AUTO_INCREMENT PRIMARY KEY,
    agent_name VARCHAR(100) NOT NULL,
    tier ENUM('Tier 1', 'Tier 2', 'Tier 3') DEFAULT 'Tier 1',
    shift ENUM('Morning', 'Evening', 'Night') NOT NULL,
    hire_date DATE NOT NULL
);

-- 3. Customers Table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    account_tier ENUM('Free', 'Pro', 'Enterprise') DEFAULT 'Free',
    signup_date DATE NOT NULL
);

-- 4. Chat Interactions Table (Fact Table)
CREATE TABLE chat_interactions (
    chat_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    agent_id INT NOT NULL,
    chat_start_time DATETIME NOT NULL,
    chat_end_time DATETIME NOT NULL,
    wait_time_seconds INT NOT NULL, -- Queue time before an agent picked up
    topic VARCHAR(50) NOT NULL,     -- e.g., 'Billing', 'Account Access', 'Bug'
    resolution_status ENUM('Resolved', 'Escalated', 'Unresolved') NOT NULL,
    csat_score INT CHECK (csat_score BETWEEN 1 AND 5), -- NULL if customer skipped rating
    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (agent_id) REFERENCES agents(agent_id)
);

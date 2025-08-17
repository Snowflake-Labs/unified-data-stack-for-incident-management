# Data Dictionary - Incident Management System

## Core Tables

### `users`
Stores all system users including support agents, managers, customers, and system accounts.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `email` | VARCHAR(255) | Unique email address |
| `first_name` | VARCHAR(100) | User's first name |
| `last_name` | VARCHAR(100) | User's last name |
| `role` | VARCHAR(50) | User role: 'customer', 'support_agent', 'manager', 'admin', 'system' |
| `department` | VARCHAR(100) | Department name (e.g., 'Engineering', 'Customer Support') |
| `team` | VARCHAR(100) | Team name within department |
| `is_active` | BOOLEAN | Whether user account is active |
| `created_at` | TIMESTAMP | Account creation timestamp |
| `updated_at` | TIMESTAMP | Last update timestamp |

### `incidents`
Central table storing all incident information and lifecycle data.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `incident_number` | VARCHAR(50) | Human-readable incident ID (e.g., 'INC-2024-001') |
| `title` | VARCHAR(255) | Brief incident description |
| `category_id` | UUID | FK to incident_categories |
| `impact_level_id` | UUID | FK to impact_levels |
| `priority` | VARCHAR(20) | 'low', 'medium', 'high', 'critical' |
| `status` | VARCHAR(30) | Current incident status |
| `reporter_id` | UUID | FK to users (who reported the incident) |
| `assignee_id` | UUID | FK to users (currently assigned to) |
| `affected_customers_count` | INTEGER | Number of customers impacted |
| `estimated_revenue_impact` | DECIMAL(12,2) | Estimated financial impact |
| `customer_id` | UUID | Specific customer affected (if applicable) |
| `order_id` | VARCHAR(100) | Specific order affected (if applicable) |
| `resolution_summary` | TEXT | How the incident was resolved |
| `root_cause` | TEXT | Root cause analysis |
| `resolution_category` | VARCHAR(100) | Type of resolution applied |
| `created_at` | TIMESTAMP | When incident was created |
| `acknowledged_at` | TIMESTAMP | When incident was first acknowledged |
| `first_response_at` | TIMESTAMP | When first response was provided |
| `resolved_at` | TIMESTAMP | When incident was resolved |
| `closed_at` | TIMESTAMP | When incident was closed |
| `updated_at` | TIMESTAMP | Last update timestamp |
| `sla_breach` | BOOLEAN | Whether SLA was breached |
| `sla_due_at` | TIMESTAMP | When SLA expires/expired |
| `source_system` | VARCHAR(100) | Where incident originated |
| `external_source_id` | VARCHAR(100) | External system reference |

### `incident_categories`
Hierarchical categorization system for incidents.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `name` | VARCHAR(100) | Category name |
| `description` | TEXT | Category description |
| `parent_category_id` | UUID | FK to parent category (for hierarchy) |
| `is_active` | BOOLEAN | Whether category is active |
| `created_at` | TIMESTAMP | Creation timestamp |

### `impact_levels`
Business impact levels with SLA definitions.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `name` | VARCHAR(50) | Impact level name |
| `description` | TEXT | Impact level description |
| `severity_score` | INTEGER | Numeric severity (1-5 scale) |
| `sla_hours` | INTEGER | SLA target in hours |
| `is_active` | BOOLEAN | Whether impact level is active |
| `created_at` | TIMESTAMP | Creation timestamp |

## Historical Tracking Tables

### `incident_status_history`
Complete audit trail of status changes.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `incident_id` | UUID | FK to incidents |
| `previous_status` | VARCHAR(30) | Status before change |
| `new_status` | VARCHAR(30) | Status after change |
| `changed_by_id` | UUID | FK to users (who made the change) |
| `change_reason` | TEXT | Reason for status change |
| `created_at` | TIMESTAMP | When change was made |

### `incident_assignment_history`
Track all incident reassignments.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `incident_id` | UUID | FK to incidents |
| `previous_assignee_id` | UUID | FK to users (previous assignee) |
| `new_assignee_id` | UUID | FK to users (new assignee) |
| `assigned_by_id` | UUID | FK to users (who made assignment) |
| `assignment_reason` | TEXT | Reason for reassignment |
| `created_at` | TIMESTAMP | When assignment was made |

### `incident_comments`
All communication and notes related to incidents.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `incident_id` | UUID | FK to incidents |
| `author_id` | UUID | FK to users (comment author) |
| `content` | TEXT | Comment content |
| `is_public` | BOOLEAN | Whether visible to customers |
| `created_at` | TIMESTAMP | When comment was created |
| `updated_at` | TIMESTAMP | When comment was last updated |

## System and Business Context Tables

### `affected_systems`
Systems/services that can be affected by incidents.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `name` | VARCHAR(100) | System name |
| `description` | TEXT | System description |
| `system_type` | VARCHAR(50) | Type: 'website', 'mobile_app', 'payment', 'inventory', etc. |
| `criticality` | VARCHAR(20) | 'low', 'medium', 'high', 'critical' |
| `is_active` | BOOLEAN | Whether system is active |
| `created_at` | TIMESTAMP | Creation timestamp |

### `incident_affected_systems`
Junction table linking incidents to affected systems.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `incident_id` | UUID | FK to incidents |
| `system_id` | UUID | FK to affected_systems |
| `impact_description` | TEXT | How the system was affected |
| `created_at` | TIMESTAMP | When relationship was created |

### `incident_affected_products`
Products affected by incidents.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `incident_id` | UUID | FK to incidents |
| `product_sku` | VARCHAR(100) | Product SKU |
| `product_name` | VARCHAR(255) | Product name |
| `quantity_affected` | INTEGER | Quantity of product affected |
| `created_at` | TIMESTAMP | Creation timestamp |

## Knowledge Base Tables

### `solution_templates`
Reusable solution procedures.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `title` | VARCHAR(255) | Solution title |
| `description` | TEXT | Solution description |
| `solution_steps` | TEXT | Step-by-step solution procedure |
| `category_id` | UUID | FK to incident_categories |
| `tags` | TEXT[] | Array of searchable tags |
| `usage_count` | INTEGER | How many times used |
| `effectiveness_rating` | DECIMAL(3,2) | Average effectiveness rating (1-5) |
| `created_by_id` | UUID | FK to users (creator) |
| `created_at` | TIMESTAMP | Creation timestamp |
| `updated_at` | TIMESTAMP | Last update timestamp |
| `is_active` | BOOLEAN | Whether template is active |

### `incident_solutions`
Links incidents to solutions that were applied.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `incident_id` | UUID | FK to incidents |
| `solution_template_id` | UUID | FK to solution_templates |
| `was_effective` | BOOLEAN | Whether solution was effective |
| `effectiveness_notes` | TEXT | Notes about effectiveness |
| `applied_by_id` | UUID | FK to users (who applied solution) |
| `applied_at` | TIMESTAMP | When solution was applied |

## Escalation Management Tables

### `escalation_rules`
Defines when and how incidents should be escalated.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `name` | VARCHAR(100) | Rule name |
| `category_id` | UUID | FK to incident_categories (optional filter) |
| `impact_level_id` | UUID | FK to impact_levels (optional filter) |
| `priority` | VARCHAR(20) | Priority filter (optional) |
| `time_threshold_hours` | INTEGER | Hours before escalation triggers |
| `escalate_to_role` | VARCHAR(50) | Role to escalate to |
| `escalate_to_user_id` | UUID | FK to users (specific user to escalate to) |
| `is_active` | BOOLEAN | Whether rule is active |
| `created_at` | TIMESTAMP | Creation timestamp |

### `incident_escalations`
Record of all escalations that occurred.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `incident_id` | UUID | FK to incidents |
| `escalation_rule_id` | UUID | FK to escalation_rules |
| `escalated_from_id` | UUID | FK to users (who escalated from) |
| `escalated_to_id` | UUID | FK to users (who escalated to) |
| `escalation_reason` | TEXT | Reason for escalation |
| `escalated_at` | TIMESTAMP | When escalation occurred |
| `resolved_at` | TIMESTAMP | When escalation was resolved |

## Monitoring and Metrics Tables

### `sla_violations`
Detailed tracking of SLA violations.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `incident_id` | UUID | FK to incidents |
| `violation_type` | VARCHAR(50) | 'response_time', 'resolution_time', 'escalation_time' |
| `expected_time` | TIMESTAMP | When action was due |
| `actual_time` | TIMESTAMP | When action actually occurred |
| `violation_minutes` | INTEGER | How many minutes over SLA |
| `business_impact_description` | TEXT | Description of business impact |
| `created_at` | TIMESTAMP | When violation was recorded |

### `incident_metrics_snapshot`
Point-in-time metrics for incidents.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `incident_id` | UUID | FK to incidents |
| `metric_name` | VARCHAR(100) | Name of metric |
| `metric_value` | DECIMAL(15,4) | Metric value |
| `metric_unit` | VARCHAR(50) | Unit of measurement |
| `measured_at` | TIMESTAMP | When metric was measured |
| `context` | JSONB | Additional context as JSON |

### `incident_attachments`
File attachments for incidents.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `incident_id` | UUID | FK to incidents |
| `filename` | VARCHAR(255) | Original filename |
| `file_path` | VARCHAR(500) | Path to stored file |
| `file_size_bytes` | BIGINT | File size in bytes |
| `mime_type` | VARCHAR(100) | MIME type of file |
| `uploaded_by_id` | UUID | FK to users (who uploaded) |
| `uploaded_at` | TIMESTAMP | Upload timestamp |
| `is_public` | BOOLEAN | Whether file is publicly accessible |

## Key Enumerations

### Incident Status Values
- `open`: Newly created incident
- `in_progress`: Being actively worked on
- `pending_customer`: Waiting for customer response
- `pending_vendor`: Waiting for vendor response
- `resolved`: Solution implemented
- `closed`: Incident fully closed
- `cancelled`: Incident cancelled/invalid

### Priority Values
- `low`: Low priority
- `medium`: Medium priority
- `high`: High priority
- `critical`: Critical priority

### User Roles
- `customer`: End customer
- `support_agent`: Support team member
- `manager`: Team manager
- `admin`: System administrator
- `system`: System/automated account

### System Types
- `website`: Web application
- `mobile_app`: Mobile application
- `payment`: Payment processing system
- `inventory`: Inventory management
- `shipping`: Shipping/logistics
- `database`: Database system
- `api`: API service
- `third_party`: Third-party integration

### Comment Types
- `internal`: Internal team communication
- `customer_facing`: Communication visible to customers
- `system_generated`: Automatically generated messages

## Indexes and Performance

### Primary Indexes
All tables have UUID primary keys with B-tree indexes.

### Performance Indexes
Key indexes for query performance:
- `incidents(status)` - For active incident queries
- `incidents(created_at)` - For time-based analysis
- `incidents(assignee_id)` - For workload queries
- `incidents(priority)` - For priority filtering
- `incident_status_history(incident_id, created_at)` - For audit trails
- `incident_comments(incident_id, created_at)` - For communication history

### Analytics Indexes
Specialized indexes for analytics:
- `incidents(DATE_TRUNC('month', created_at))` - Monthly trends
- `incidents(sla_due_at)` - SLA monitoring
- Composite indexes on frequently joined columns

## Data Retention and Archival

### Suggested Retention Policies
- **Active incidents**: Indefinite retention
- **Resolved incidents**: 7 years for compliance
- **Audit logs**: 5 years minimum
- **Comments and attachments**: Same as incident retention
- **Metrics snapshots**: 2 years for trending

### Archival Strategy
- Consider partitioning by date for large datasets
- Archive old incidents to separate tables/databases
- Maintain summary statistics for historical analysis
- Implement data lifecycle management policies

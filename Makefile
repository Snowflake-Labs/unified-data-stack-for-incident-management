# Makefile for Incident Management Project Setup
# Automates installation steps as documented in README.md
#
# Every target is independently runnable — no implicit prerequisite chains.
# Use 'make install FROM=<step>' to resume from a specific step.

.PHONY: help install setup-snowflake generate-yaml setup-dbt-stack setup-accountadmin setup-sysadmin-objects setup-slack-connector setup-tasks setup-procs-funcs deploy-streamlit load-test-data teardown check-prereqs

# Step numbering (used by FROM= parameter)
#   1  generate-yaml
#   2  setup-accountadmin
#   3  setup-sysadmin-objects
#   4  setup-slack-connector
#   5  setup-tasks
#   6  setup-procs-funcs

FROM ?= 1

# Default target
help:
	@echo "Incident Management Project - Installation Automation"
	@echo ""
	@echo "Installation steps (in order):"
	@echo "  Step 1  generate-yaml          Generate snowflake.yml from template"
	@echo "  Step 2  setup-accountadmin      Account-level infra (ACCOUNTADMIN)"
	@echo "  Step 3  setup-sysadmin-objects  DB-level objects & ownership (SYSADMIN)"
	@echo "  Step 4  setup-slack-connector   Slack connector infrastructure"
	@echo "  Step 5  setup-tasks             Snowflake tasks"
	@echo "  Step 6  setup-procs-funcs       Procedures and functions"
	@echo ""
	@echo "Composite targets:"
	@echo "  install           Run steps 1-6 (or resume with FROM=<step>)"
	@echo "  setup-snowflake   Alias for install"
	@echo "  setup-dbt-stack   Run steps 2+3 together"
	@echo ""
	@echo "Optional (not included in 'install'):"
	@echo "  deploy-streamlit  Deploy Streamlit app (run separately after install)"
	@echo "  load-test-data    Load CSV test data into bronze & gold tables"
	@echo ""
	@echo "Other:"
	@echo "  teardown          Teardown all project-owned Snowflake resources"
	@echo "  check-prereqs     Verify required tools are installed"
	@echo ""
	@echo "Usage:"
	@echo "  make install ENV_FILE=.env CONN=myconn        # Full setup"
	@echo "  make install ENV_FILE=.env CONN=myconn FROM=3 # Resume from step 3"
	@echo "  make setup-accountadmin CONN=myconn            # Run a single step"
	@echo "  make setup-dbt-stack CONN=myconn               # Steps 2+3 only"
	@echo "  make deploy-streamlit CONN=myconn              # Optional Streamlit"
	@echo "  make teardown CONN=myconn                      # Teardown resources"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - Snowflake CLI installed"
	@echo "  - .env file configured (copy from .env.template)"
	@echo "  - Snowflake connection configured in ~/.snowflake/config.toml"

# ---------------------------------------------------------------------------
# Composite targets
# ---------------------------------------------------------------------------

# Complete installation with optional resume
install:
	@if [ -z "$(ENV_FILE)" ] || [ -z "$(CONN)" ]; then \
		echo "❌ Error: Both ENV_FILE and CONN parameters required"; \
		echo "Usage: make install ENV_FILE=.env CONN=<connection-name>"; \
		echo "       make install ENV_FILE=.env CONN=<connection-name> FROM=3  # resume from step 3"; \
		exit 1; \
	fi
	@echo "================================================================================================================"
	@echo "🚀 Starting Snowflake infrastructure setup (from step $(FROM))..."
	@echo "================================================================================================================"
	@if [ $(FROM) -le 1 ]; then $(MAKE) generate-yaml ENV_FILE=$(ENV_FILE); fi
	@if [ $(FROM) -le 2 ]; then $(MAKE) setup-accountadmin CONN=$(CONN); fi
	@if [ $(FROM) -le 3 ]; then $(MAKE) setup-sysadmin-objects CONN=$(CONN); fi
	@if [ $(FROM) -le 4 ]; then $(MAKE) setup-slack-connector CONN=$(CONN); fi
	@if [ $(FROM) -le 5 ]; then $(MAKE) setup-tasks CONN=$(CONN); fi
	@if [ $(FROM) -le 6 ]; then $(MAKE) setup-procs-funcs CONN=$(CONN); fi
	@echo ""
	@echo "✅ Installation complete!"
	@echo ""
	@echo "Optional next steps:"
	@echo "  make deploy-streamlit CONN=$(CONN)  # Deploy Streamlit app"
	@echo "  See README 'Running the Dashboard' section for Python setup instructions"

# Alias
setup-snowflake: install

# Run accountadmin + sysadmin-objects together
setup-dbt-stack:
	@if [ -z "$(CONN)" ]; then \
		echo "❌ Error: CONN parameter required"; \
		echo "Usage: make setup-dbt-stack CONN=<connection-name>"; \
		exit 1; \
	fi
	@$(MAKE) setup-accountadmin CONN=$(CONN)
	@$(MAKE) setup-sysadmin-objects CONN=$(CONN)
	@echo "✅ dbt Projects infrastructure setup complete!"

# ---------------------------------------------------------------------------
# Individual steps (each independently runnable)
# ---------------------------------------------------------------------------

# Shared validation fragments
define check_conn
	@if [ -z "$(CONN)" ]; then \
		echo "❌ Error: CONN parameter required"; \
		echo "Usage: make $@ CONN=<connection-name>"; \
		echo "Connection should be defined in ~/.snowflake/config.toml"; \
		exit 1; \
	fi
	@if ! command -v snow >/dev/null 2>&1; then \
		echo "❌ Error: Snowflake CLI (snow) is not installed"; \
		echo "Please install it first: https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation"; \
		exit 1; \
	fi
endef

# Step 1: Generate snowflake.yml file
generate-yaml:
	@if [ -z "$(ENV_FILE)" ]; then \
		echo "❌ Error: ENV_FILE parameter required"; \
		echo "Usage: make generate-yaml ENV_FILE=.env"; \
		exit 1; \
	fi
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo "❌ Error: Environment file $(ENV_FILE) not found"; \
		echo "Please copy .env.template to $(ENV_FILE) and configure it"; \
		exit 1; \
	fi
	@echo "================================================================================================================"
	@echo "🔧 [Step 1] Generating snowflake.yml configuration..."
	@echo "================================================================================================================"
	cd src/scripts && ./create_snowflake_yaml.sh -e ../../$(ENV_FILE)
	@if [ -f "src/sql/snowflake.yml" ]; then \
		echo "✅ snowflake.yml generated successfully in src/sql/"; \
	else \
		echo "❌ Error: snowflake.yml generation failed"; \
		exit 1; \
	fi

# Step 2: Account-level infrastructure (ACCOUNTADMIN)
setup-accountadmin:
	$(check_conn)
	@echo "================================================================================================================"
	@echo "❄️  [Step 2] Setting up account-level infrastructure (ACCOUNTADMIN)..."
	@echo "================================================================================================================"
	@echo "⚠️  Note: This requires ACCOUNTADMIN privileges"
	cd src/sql && snow sql --connection $(CONN) -f 01a_accountadmin_setup.sql
	@echo "✅ Account-level infrastructure setup complete!"

# Step 3: Database-level objects & ownership transfer (SYSADMIN)
setup-sysadmin-objects:
	$(check_conn)
	@echo "================================================================================================================"
	@echo "❄️  [Step 3] Setting up database-level objects (SYSADMIN)..."
	@echo "================================================================================================================"
	@echo "⚠️  Note: This requires SYSADMIN privileges. Assumes step 2 (setup-accountadmin) has been run."
	cd src/sql && snow sql --connection $(CONN) -f 01b_sysadmin_objects.sql
	@echo "✅ Database-level objects & ownership transfer complete!"

# Step 4: Slack connector infrastructure
setup-slack-connector:
	$(check_conn)
	@echo "================================================================================================================"
	@echo "💬 [Step 4] Setting up Slack connector backend infrastructure..."
	@echo "================================================================================================================"
	cd src/sql && snow sql --connection $(CONN) -f 02_slack_connector.sql
	@echo "✅ Slack connector backend infrastructure setup complete!"
	@echo ""
	@echo "🔗 Next steps for Slack connector:"
	@echo "1. Login to your OpenFlow SPCS runtime"
	@echo "2. Create a Slack app in your workspace"
	@echo "3. Configure the connector with database and role parameters"
	@echo "4. Start the connector and add the Slack app to your channel"
	@echo "5. Verify tables are created: SLACK_MEMBERS, SLACK_MESSAGES, etc."

# Step 5: Snowflake tasks
setup-tasks:
	$(check_conn)
	@echo "================================================================================================================"
	@echo "⏰ [Step 5] Setting up Snowflake tasks..."
	@echo "================================================================================================================"
	cd src/sql && snow sql --connection $(CONN) -f 03_tasks.sql
	@echo "✅ Snowflake tasks setup complete!"

# Step 6: Procedures and functions
setup-procs-funcs:
	$(check_conn)
	@echo "================================================================================================================"
	@echo "⚙️  [Step 6] Setting up procedures and functions..."
	@echo "================================================================================================================"
	cd src/sql && snow sql --connection $(CONN) -f 04_procs_and_funcs.sql
	@echo "✅ Procedures and functions setup complete!"

# ---------------------------------------------------------------------------
# Optional / utility targets
# ---------------------------------------------------------------------------

# Deploy Streamlit app (optional, not part of 'install')
deploy-streamlit:
	$(check_conn)
	@echo "================================================================================================================"
	@echo "🎨 Deploying Streamlit app..."
	@echo "================================================================================================================"
	cd src/sql && snow sql --connection $(CONN) -f 05_streamlit_app.sql
	@echo "✅ Streamlit app deployment complete!"
	@echo ""
	@echo "📱 Access your Streamlit app in Snowsight:"
	@echo "   Navigate to: Data Products > Streamlit > INCIDENT_MANAGEMENT_DASHBOARD"

# Load test data (optional, not part of 'install')
load-test-data:
	$(check_conn)
	@echo "================================================================================================================"
	@echo "📦 Loading test data into bronze & gold tables..."
	@echo "================================================================================================================"
	@echo "⚠️  Note: This will truncate existing data before loading. Requires step 3 (setup-sysadmin-objects) to have been run."
	cd src/sql && snow sql --connection $(CONN) -f 07_load_test_data.sql
	@echo "✅ Test data loaded successfully!"

# Teardown: Remove all project-owned Snowflake resources
teardown:
	$(check_conn)
	@echo "================================================================================================================"
	@echo "🗑️  Tearing down project-owned Snowflake resources..."
	@echo "================================================================================================================"
	@echo "⚠️  WARNING: This will drop all objects owned by dbt_project_admin_role"
	@echo "   (tasks, cortex services, streamlit app, dbt project, tables, schemas, etc.)"
	@echo "   ACCOUNTADMIN-owned resources (database, warehouses, roles) are NOT affected."
	@echo ""
	@read -p "Are you sure you want to proceed? (y/N): " confirm && [ "$$confirm" = "y" ] || { echo "Teardown cancelled."; exit 1; }
	cd src/sql && snow sql --connection $(CONN) -f 06_teardown.sql
	@echo "✅ Teardown complete! Project-owned resources have been removed."
	@echo ""
	@echo "📝 Note: ACCOUNTADMIN-owned resources (database, warehouses, integrations, roles)"
	@echo "   were NOT dropped. See src/sql/06_teardown.sql for optional manual cleanup steps."

# Check prerequisites
check-prereqs:
	@echo "🔍 Checking prerequisites..."
	@echo -n "uv: "
	@if command -v uv >/dev/null 2>&1; then echo "✅ installed"; else echo "❌ not found"; fi
	@echo -n "snow CLI: "
	@if command -v snow >/dev/null 2>&1; then echo "✅ installed"; else echo "❌ not found"; fi
	@echo -n ".env file: "
	@if [ -f ".env" ]; then echo "✅ found"; else echo "⚠️  not found (copy from .env.template)"; fi
	@echo -n "requirements.txt: "
	@if [ -f "requirements.txt" ]; then echo "✅ found"; else echo "❌ not found"; fi

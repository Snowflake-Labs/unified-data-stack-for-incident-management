# Makefile for Incident Management Project Setup
# Automates installation steps 1-3 as documented in README.md

.PHONY: help install setup-snowflake generate-yaml setup-dbt-stack setup-slack-connector all

# Default target
help:
	@echo "Incident Management Project - Installation Automation"
	@echo ""
	@echo "Available targets:"
	@echo "  help              Show this help message"
	@echo "  install           Run complete installation (step 2)"
	@echo "  setup-snowflake   Setup Snowflake infrastructure (step 2)"
	@echo "  generate-yaml     Generate snowflake.yml from template (step 2.1)"
	@echo "  setup-dbt-stack   Setup dbt Projects infrastructure (step 2.2)"
	@echo "  setup-slack-connector Setup Slack connector infrastructure (step 2.3)"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - Snowflake CLI installed"
	@echo "  - .env file configured (copy from env.template)"
	@echo "  - Snowflake connection configured in ~/.snowflake/config.toml"
	@echo ""
	@echo "Usage:"
	@echo "  make install                    # Complete setup"
	@echo "  make generate-yaml ENV_FILE=.env  # Generate snowflake.yml"
	@echo "  make setup-dbt-stack CONN=myconn  # Setup dbt with connection name"
	@echo "  make setup-slack-connector CONN=myconn  # Setup Slack connector"
	@echo ""
	@echo "Note: Python dependencies are installed separately when running the dashboard"
	@echo "See README 'Running the Dashboard' section for Python setup instructions"

# Complete installation (step 2)
install:
	@if [ -z "$(ENV_FILE)" ] || [ -z "$(CONN)" ]; then \
		echo "❌ Error: Both ENV_FILE and CONN parameters required"; \
		echo "Usage: make install ENV_FILE=.env CONN=<connection-name>"; \
		exit 1; \
	fi
	@echo "🚀 Starting complete Snowflake infrastructure setup..."
	@$(MAKE) generate-yaml ENV_FILE=$(ENV_FILE)
	@$(MAKE) setup-dbt-stack CONN=$(CONN)
	@$(MAKE) setup-slack-connector CONN=$(CONN)
	@echo "✅ Installation complete!"
	@echo "5. For Python dependencies (when running dashboard), see README 'Running the Dashboard' section"

# Step 2: Setup Snowflake Infrastructure
setup-snowflake: generate-yaml setup-dbt-stack setup-slack-connector
	@echo "✅ Snowflake infrastructure setup complete!"

# Step 2.1: Generate snowflake.yml file
generate-yaml:
	@if [ -z "$(ENV_FILE)" ]; then \
		echo "❌ Error: ENV_FILE parameter required"; \
		echo "Usage: make generate-yaml ENV_FILE=.env"; \
		exit 1; \
	fi
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo "❌ Error: Environment file $(ENV_FILE) not found"; \
		echo "Please copy env.template to $(ENV_FILE) and configure it"; \
		exit 1; \
	fi
	@echo "🔧 Generating snowflake.yml configuration..."
	cd src/scripts && ./create_snowflake_yaml.sh -e ../../$(ENV_FILE)
	@if [ -f "src/sql/snowflake.yml" ]; then \
		echo "✅ snowflake.yml generated successfully in src/sql/"; \
	else \
		echo "❌ Error: snowflake.yml generation failed"; \
		exit 1; \
	fi

# Step 2.2: Setup dbt Projects infrastructure
setup-dbt-stack:
	@if [ -z "$(CONN)" ]; then \
		echo "❌ Error: CONN parameter required"; \
		echo "Usage: make setup-dbt-stack CONN=<connection-name>"; \
		echo "Connection should be defined in ~/.snowflake/config.toml"; \
		exit 1; \
	fi
	@if ! command -v snow >/dev/null 2>&1; then \
		echo "❌ Error: Snowflake CLI (snow) is not installed"; \
		echo "Please install it first: https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation"; \
		exit 1; \
	fi
	@echo "❄️  Setting up dbt Projects infrastructure..."
	@echo "⚠️  Note: This requires ACCOUNTADMIN privileges"
	cd src/sql && snow sql --connection $(CONN) -f 01_dbt_projects_stack.sql
	@echo "✅ dbt Projects infrastructure setup complete!"
	@echo ""
	@echo "🔑 Optional next steps for remote deployment:"
	@echo "1. Generate PAT token in Snowsight for the dbt service user"
	@echo "2. Generate key-pair authentication:"
	@echo "   openssl genrsa -out rsa_private_key.pem 2048"
	@echo "   openssl rsa -in rsa_private_key.pem -pubout -out rsa_public_key.pem"
	@echo "3. Update user with public key in Snowflake"
	@echo "4. Update .env with DBT_SNOWFLAKE_PASSWORD and DBT_SNOWFLAKE_PRIVATE_KEY_PATH"

# Step 2.3: Setup Slack connector infrastructure
setup-slack-connector:
	@if [ -z "$(CONN)" ]; then \
		echo "❌ Error: CONN parameter required"; \
		echo "Usage: make setup-slack-connector CONN=<connection-name>"; \
		echo "Connection should be defined in ~/.snowflake/config.toml"; \
		exit 1; \
	fi
	@if ! command -v snow >/dev/null 2>&1; then \
		echo "❌ Error: Snowflake CLI (snow) is not installed"; \
		echo "Please install it first: https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation"; \
		exit 1; \
	fi
	@echo "💬 Setting up Slack connector infrastructure..."
	@echo "⚠️  Note: This requires ACCOUNTADMIN privileges"
	cd src/sql && snow sql --connection $(CONN) -f 02_slack_connector.sql
	@echo "✅ Slack connector infrastructure setup complete!"
	@echo ""
	@echo "🔗 Next steps for Slack connector:"
	@echo "1. Login to your OpenFlow SPCS runtime"
	@echo "2. Create a Slack app in your workspace"
	@echo "3. Configure the connector with database and role parameters"
	@echo "4. Start the connector and add the Slack app to your channel"
	@echo "5. Verify tables are created: SLACK_MEMBERS, SLACK_MESSAGES, etc."

# Check prerequisites
check-prereqs:
	@echo "🔍 Checking prerequisites..."
	@echo -n "uv: "
	@if command -v uv >/dev/null 2>&1; then echo "✅ installed"; else echo "❌ not found"; fi
	@echo -n "snow CLI: "
	@if command -v snow >/dev/null 2>&1; then echo "✅ installed"; else echo "❌ not found"; fi
	@echo -n ".env file: "
	@if [ -f ".env" ]; then echo "✅ found"; else echo "⚠️  not found (copy from env.template)"; fi
	@echo -n "requirements.txt: "
	@if [ -f "requirements.txt" ]; then echo "✅ found"; else echo "❌ not found"; fi

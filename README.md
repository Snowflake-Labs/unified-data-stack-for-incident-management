# Unified Data Stack for Incident Management

> An end-to-end AI-powered incident management platform built entirely on Snowflake, demonstrating modern data engineering practices with dbt, Cortex AI, and Streamlit.

[![Snowflake](https://img.shields.io/badge/Snowflake-Native-29B5E8?logo=snowflake)](https://www.snowflake.com/)
[![Streamlit](https://img.shields.io/badge/Streamlit-Dashboard-FF4B4B?logo=streamlit)](https://streamlit.io/)

---

## Overview

This project demonstrates a modern data stack for incident management—a real-world business process that benefits from AI-powered automation and real-time analytics. The platform ingests incident reports from Slack, intelligently classifies them using Snowflake Cortex AI, and provides real-time visualization through an interactive Streamlit dashboard.

**This is a small cross-section of a much larger process to show the art of possible.*

### Architecture at a Glance

```
Slack App → OpenFlow Slack Connector → Bronze Zone → AISQL+ transformations via dbt Projects on Snowflake  → Gold Zone → Cortex Agents → Snowflake Intelligence
                                                                                                                                       → Streamlit Dashboard  
```

### Key Features

✨ **AI-Powered Classification** - Automatically categorizes incidents using Snowflake Cortex AI  
🖼️ **Image Processing** - AI analysis of screenshots and attachments  
⚡ **Real-time Pipeline** - Near real-time ingestion from Slack via OpenFlow  
📊 **Interactive Dashboard** - Streamlit-based monitoring and management  
🔧 **Modern Data Engineering** - dbt transformations on Snowflake's native runtime  

---

## Quick Start

### Prerequisites

- Snowflake account with ACCOUNTADMIN privileges
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation) installed
- [OpenFlow SPCS](https://docs.snowflake.com/en/user-guide/data-integration/openflow/setup-openflow-spcs) deployed in your account

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/Snowflake-Labs/unified-data-stack-for-incident-management.git
cd unified-data-stack-for-incident-management
```

2. **Configure environment**

```bash
cp .env.template .env
# Edit .env with your configuration
```

3. **Run automated setup**

```bash
make install ENV_FILE=.env CONN=<your-connection-name>
```

4. **Configure Slack connector**

Follow the [detailed setup guide](docs/SETUP.md#slack-connector-configuration) to connect your Slack workspace.

**That's it!** You now have a fully functional AI-powered incident management platform.

For detailed installation instructions, see the [**Setup Guide**](docs/SETUP.md).

---

## What Can You Build?

This project showcases several modern data platform patterns:

### 🔄 Real-Time Data Ingestion
Stream data from Slack to Snowflake using OpenFlow connectors. Handles text, images, and metadata automatically.

### 🤖 AI-Native Data Processing
Embed Cortex AI functions directly in SQL transformations:

```sql
-- Intelligent categorization from text
ai_classify(text, ['payment gateway error', 'login error', 'other'])

-- Multi-modal analysis with images
ai_classify(attachment_file, ['critical', 'warning', 'info'])
```

### 📈 Analytics-Ready Data Models
Transform raw Slack messages into structured incident records with:
- Automatic ID generation
- Priority assignment
- Status tracking
- Resolution metrics

### 🎨 Interactive Dashboards
Real-time Streamlit dashboard with:
- Live incident metrics
- Attachment viewing
- Trend analysis
- Priority-based alerts

---

## Documentation

| Document | Description |
|----------|-------------|
| [**Setup Guide**](docs/SETUP.md) | Complete installation and configuration instructions |
| [**Architecture**](docs/ARCHITECTURE.md) | System design, data models, and project structure |
| [**Demo Vignettes**](docs/DEMOS.md) | Hands-on examples and usage scenarios |
| [**Troubleshooting**](docs/TROUBLESHOOTING.md) | Common issues and solutions |

---

## Project Structure

```
incident-management/
├── docs/                    # 📚 Documentation
├── data/                    # 📊 Sample data and test files
├── src/
│   ├── incident_management/ # 🔧 dbt project (data models)
│   ├── sql/                 # 🗄️  Infrastructure setup scripts
│   ├── streamlit/           # 📱 Dashboard application
│   └── cortex_agents/       # 🤖 AI agent specifications
└── Makefile                 # ⚙️  Automation tasks
```

See the [**Architecture Guide**](docs/ARCHITECTURE.md) for complete details.

---

## Use Cases & Examples

### End-to-End Incident Lifecycle

1. **Report**: User posts in Slack: *"Payment gateway returning 500 errors"* + screenshot
2. **Ingest**: OpenFlow captures message and image
3. **Process**: dbt + AI classify as critical payment issue
4. **Monitor**: Dashboard shows new critical incident
5. **Resolve**: Team addresses issue, system tracks resolution time

### Real-World Scenarios

- **Payment outages** → Critical priority, auto-escalation
- **Login issues** → High priority, authentication team notified  
- **UI bugs** → Low priority, added to backlog

Explore more examples in the [**Demo Vignettes**](docs/DEMOS.md).

---

## Technology Stack

| Component | Technology |
|-----------|-----------|
| **Data Warehouse** | Snowflake |
| **Data Transformation** | dbt (Snowflake runtime) |
| **Data Ingestion** | OpenFlow SPCS |
| **AI/ML** | Snowflake Cortex AI |
| **Visualization** | Streamlit in Snowflake |
| **Orchestration** | Snowflake Tasks |

---

## Resources

- [Snowflake Cortex AI Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/aisql)
- [dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake)
- [OpenFlow Connectors](https://docs.snowflake.com/en/user-guide/data-integration/openflow/connectors/about-openflow-connectors)
- [Streamlit in Snowflake](https://docs.streamlit.io/)

---

## Contributing

We welcome contributions! Here's how you can help:

- 🐛 **Report bugs** via [GitHub Issues](https://github.com/Snowflake-Labs/unified-data-stack-for-incident-management/issues)
- 💡 **Suggest features** or improvements
- 🔧 **Submit Pull Requests** with enhancements

---

## Questions & Support

For questions or feedback, please contact: **chinmayee.lakkad@snowflake.com**

---

## License

This project is provided as-is for demonstration purposes.

---

**Ready to get started?** Head to the [**Setup Guide**](docs/SETUP.md) →

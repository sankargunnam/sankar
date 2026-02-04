# SAP HANA and Related Tools Documentation

This repository contains documentation and guides for working with SAP HANA and related SAP tools.

## Available Guides

### Login Guides
- HOW TO LOGIN TO BODS.docx
- HOW TO LOGIN TO BW4 HANA.docx
- HOW TO LOGIN TO INFORMATION DESIGN TOOL (1).docx
- HOW TO LOGIN TO LUMIRA (2).docx
- HOW TO LOGIN TO MSSQL.docx
- HOW TO LOGIN TO S4 HANA.docx
- HOW TO LOGIN TO SLT.docx
- HOW TO LOGIN TO WEBINAR.docx
- HOW TO LOGON TO BI LAUNCH PAD.docx

### Development Guides
- **[🚀 Quick Start Guide](QUICK_START.md)** - 5-minute guide to get started with GitHub Agent for HANA
- **[GitHub Agent Mode for HANA Development](GITHUB_AGENT_FOR_HANA_DEVELOPMENT.md)** - Comprehensive guide on using GitHub Copilot Agent mode to develop SAP HANA graphical calculation views
- **[HANA Examples](hana_examples/)** - Working calculation view examples

### Version Control & CI/CD
- [GitHub Commands Reference](github_commands) - Basic Git commands and workflows
- **[🔧 HANA Git & CI/CD Integration Guide](HANA_GIT_CICD_INTEGRATION.md)** ⭐ - Complete guide for integrating Git and CI/CD with HANA Studio on-premise
- **[⚡ HANA Object Activation in CI/CD](HANA_OBJECT_ACTIVATION_CICD.md)** ⭐ NEW - How objects get activated automatically in higher environments

## Using GitHub Agent for HANA Development

Want to know if you can use GitHub Agent mode for your on-premise HANA repository controlled by SAP?

**Yes, you can!** Check out our comprehensive guide: [GITHUB_AGENT_FOR_HANA_DEVELOPMENT.md](GITHUB_AGENT_FOR_HANA_DEVELOPMENT.md)

This guide covers:
- Hybrid development workflows
- Exporting/importing HANA calculation views
- Using AI assistance for HANA development
- Best practices and integration strategies

## Integrating Git & CI/CD with HANA Studio On-Premise

Need to integrate version control and automated deployments with your HANA Studio environment?

**Yes, it's possible!** Check out our comprehensive guide: [HANA_GIT_CICD_INTEGRATION.md](HANA_GIT_CICD_INTEGRATION.md)

This guide covers:
- **The Challenge**: Why HANA Studio doesn't have native Git integration
- **3 Solution Approaches**: File-based sync, HDI, and Hybrid workflows
- **CI/CD Pipelines**: GitHub Actions and Jenkins examples
- **Deployment Automation**: Scripts for automated HANA deployments
- **Best Practices**: Repository structure, branching strategy, security

## HANA Object Activation in CI/CD

**Question:** How will objects get activated in higher environments when we move them through CI/CD?

**Answer:** Check out our comprehensive guide: [HANA_OBJECT_ACTIVATION_CICD.md](HANA_OBJECT_ACTIVATION_CICD.md)

This guide covers:
- **What is Activation**: Understanding HANA object activation
- **Activation Methods**: hdbsql, REST API, HDI deployment
- **CI/CD Integration**: Automated activation in pipelines
- **Environment-Specific**: Different strategies for DEV/TEST/PROD
- **Error Handling**: Dealing with activation failures
- **Complete Scripts**: Ready-to-use Bash and Python scripts
- **Complete Workflows**: Step-by-step implementation examples

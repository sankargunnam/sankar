# HANA Studio Git & CI/CD Integration Guide

## Overview

This guide explains how to enable Git version control and CI/CD integration for SAP HANA Studio on-premise environments, which use SAP's native repository system instead of Git.

---

## The Challenge

### SAP HANA Repository System

**HANA Studio on-premise uses:**
- SAP Native Repository (not Git)
- Proprietary version control
- Workspace-based development
- No built-in Git integration

**What this means:**
- ❌ No native `git commit` from HANA Studio
- ❌ No direct GitHub/GitLab integration
- ❌ No automatic CI/CD triggers
- ❌ Manual export/import workflow needed

---

## Solution Overview

There are **3 main approaches** to integrate Git and CI/CD with HANA Studio on-premise:

1. **File-Based Sync** (Most Common) ⭐
2. **HANA DI (Deployment Infrastructure)** (For HDI containers)
3. **Hybrid Approach** (Combination)

---

## Approach 1: File-Based Sync ⭐ RECOMMENDED

### How It Works

```
HANA Studio (SAP Repository)
    ↓ Export to File System
Local File System (.hdbcalculationview, .hdbtable, etc.)
    ↓ Git Add/Commit/Push
Git Repository (GitHub/GitLab)
    ↓ CI/CD Pipeline Triggers
Automated Build/Test/Deploy
    ↓ Import to HANA
HANA System (Development/Production)
```

### Step-by-Step Implementation

#### Step 1: Export HANA Objects to File System

**Manual Export:**
1. Open HANA Studio
2. Right-click on your package/folder
3. Select **Export** → **SAP HANA** → **Catalog Objects**
4. Choose destination folder (e.g., `/workspace/hana-project`)
5. Export creates `.hdbcalculationview`, `.hdbtable`, `.hdbprocedure` files

**Files Created:**
```
/workspace/hana-project/
├── src/
│   ├── models/
│   │   ├── CV_SALES_ANALYSIS.hdbcalculationview
│   │   ├── CV_CUSTOMER_360.hdbcalculationview
│   │   └── CV_TEST.hdbcalculationview
│   ├── tables/
│   │   ├── CUSTOMERS.hdbtable
│   │   ├── PRODUCTS.hdbtable
│   │   └── SALES.hdbtable
│   └── procedures/
│       └── GET_LINEAGE.hdbprocedure
└── .hdiconfig
```

#### Step 2: Initialize Git Repository

```bash
cd /workspace/hana-project

# Initialize Git
git init

# Create .gitignore
cat > .gitignore << 'EOF'
# Build artifacts
*.log
*.tmp
.DS_Store

# IDE files
.metadata/
.settings/
*.project
*.classpath

# HANA generated files
*.generated
.che/
EOF

# Add files
git add .
git commit -m "Initial commit: HANA objects export"

# Connect to GitHub
git remote add origin https://github.com/yourusername/hana-project.git
git push -u origin main
```

#### Step 3: Set Up CI/CD Pipeline

**Option A: GitHub Actions**

Create `.github/workflows/hana-cicd.yml`:

```yaml
name: HANA CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Validate HANA objects
        run: |
          echo "Validating .hdbcalculationview files..."
          find . -name "*.hdbcalculationview" -type f | while read file; do
            echo "Checking $file"
            # Check XML is well-formed
            xmllint --noout "$file" || exit 1
          done
          echo "✅ All files validated"
      
      - name: Check for syntax errors
        run: |
          echo "Running syntax checks..."
          # Add custom validation scripts here
          
  deploy-dev:
    needs: validate
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Deploy to DEV HANA
        env:
          HANA_HOST: ${{ secrets.HANA_DEV_HOST }}
          HANA_USER: ${{ secrets.HANA_DEV_USER }}
          HANA_PASSWORD: ${{ secrets.HANA_DEV_PASSWORD }}
        run: |
          echo "Deploying to HANA DEV..."
          # Use deployment script (see below)
          ./scripts/deploy-to-hana.sh dev
  
  deploy-prod:
    needs: validate
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Deploy to PROD HANA
        env:
          HANA_HOST: ${{ secrets.HANA_PROD_HOST }}
          HANA_USER: ${{ secrets.HANA_PROD_USER }}
          HANA_PASSWORD: ${{ secrets.HANA_PROD_PASSWORD }}
        run: |
          echo "Deploying to HANA PROD..."
          ./scripts/deploy-to-hana.sh prod
```

**Option B: Jenkins Pipeline**

Create `Jenkinsfile`:

```groovy
pipeline {
    agent any
    
    environment {
        HANA_DEV_HOST = credentials('hana-dev-host')
        HANA_DEV_USER = credentials('hana-dev-user')
        HANA_DEV_PASSWORD = credentials('hana-dev-password')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Validate') {
            steps {
                script {
                    sh '''
                        echo "Validating HANA objects..."
                        find . -name "*.hdbcalculationview" -type f | while read file; do
                            xmllint --noout "$file" || exit 1
                        done
                    '''
                }
            }
        }
        
        stage('Deploy to DEV') {
            when {
                branch 'develop'
            }
            steps {
                script {
                    sh './scripts/deploy-to-hana.sh dev'
                }
            }
        }
        
        stage('Deploy to PROD') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy'
                script {
                    sh './scripts/deploy-to-hana.sh prod'
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

#### Step 4: Create Deployment Script

Create `scripts/deploy-to-hana.sh`:

```bash
#!/bin/bash

# HANA Deployment Script
# Usage: ./deploy-to-hana.sh [dev|prod]

ENV=$1

if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

# Load environment variables
if [ "$ENV" == "dev" ]; then
    HANA_HOST=$HANA_DEV_HOST
    HANA_USER=$HANA_DEV_USER
    HANA_PASSWORD=$HANA_DEV_PASSWORD
    HANA_PORT=30015
else
    HANA_HOST=$HANA_PROD_HOST
    HANA_USER=$HANA_PROD_USER
    HANA_PASSWORD=$HANA_PROD_PASSWORD
    HANA_PORT=30015
fi

echo "===================================="
echo "Deploying to HANA $ENV"
echo "Host: $HANA_HOST"
echo "===================================="

# Install HANA Client if not present
if ! command -v hdbsql &> /dev/null; then
    echo "Installing SAP HANA Client..."
    # Add installation steps
fi

# Deploy calculation views
echo "Deploying calculation views..."
for file in $(find src/models -name "*.hdbcalculationview"); do
    echo "Deploying $file..."
    # Import using HANA SQL or REST API
    # Example using hdbsql (requires HANA client)
    # hdbsql -n $HANA_HOST:$HANA_PORT -u $HANA_USER -p $HANA_PASSWORD -i $file
done

# Deploy tables
echo "Deploying tables..."
for file in $(find src/tables -name "*.hdbtable"); do
    echo "Deploying $file..."
    # Import logic here
done

# Deploy procedures
echo "Deploying procedures..."
for file in $(find src/procedures -name "*.hdbprocedure"); do
    echo "Deploying $file..."
    # Import logic here
done

echo "✅ Deployment to $ENV completed successfully!"
```

Make it executable:
```bash
chmod +x scripts/deploy-to-hana.sh
```

---

## Approach 2: HANA DI (Deployment Infrastructure)

### For HDI Containers (HANA 2.0 SPS 00+)

If using HDI containers, you can use native Git integration:

#### Step 1: Enable HDI Git Integration

1. Install SAP Web IDE or Business Application Studio
2. Create HDI container
3. Connect to Git repository
4. Use built-in Git features

#### Step 2: CI/CD with HDI

```yaml
# .github/workflows/hdi-deploy.yml
name: HDI Deployment

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install @sap/hdi-deploy
        run: npm install -g @sap/hdi-deploy
      
      - name: Deploy to HDI
        env:
          HDI_USER: ${{ secrets.HDI_USER }}
          HDI_PASSWORD: ${{ secrets.HDI_PASSWORD }}
        run: |
          hdi-deploy --target-container $HDI_CONTAINER
```

---

## Approach 3: Hybrid Workflow

### Development Workflow

```
Developer (HANA Studio)
    ↓ Develop & Test
SAP Repository
    ↓ Export (Manual/Scheduled)
Local File System
    ↓ Git Commit
Git Repository (Feature Branch)
    ↓ Pull Request
Code Review
    ↓ Merge to Main
CI/CD Pipeline
    ↓ Automated Deploy
HANA DEV/TEST/PROD
```

### Automation Script for Export

Create `scripts/auto-export-hana-objects.sh`:

```bash
#!/bin/bash

# Automated HANA Object Export Script
# Schedule with cron: 0 */4 * * * /path/to/auto-export-hana-objects.sh

WORKSPACE="/workspace/hana-project"
EXPORT_DIR="$WORKSPACE/src"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "[$TIMESTAMP] Starting HANA object export..."

# Connect to HANA and export objects
# This requires HANA Studio CLI or custom export tool

# After export, commit to Git
cd $WORKSPACE

if [ -n "$(git status --porcelain)" ]; then
    echo "Changes detected, committing..."
    git add .
    git commit -m "Auto-export: HANA objects updated at $TIMESTAMP"
    git push origin develop
    echo "✅ Changes pushed to Git"
else
    echo "No changes detected"
fi

echo "[$TIMESTAMP] Export completed"
```

Set up cron job:
```bash
crontab -e
# Add line:
0 */4 * * * /workspace/scripts/auto-export-hana-objects.sh
```

---

## Best Practices

### 1. Repository Structure

```
hana-project/
├── .github/
│   └── workflows/
│       └── hana-cicd.yml
├── src/
│   ├── models/              # Calculation views
│   ├── tables/              # Table definitions
│   ├── procedures/          # Stored procedures
│   ├── roles/               # Security roles
│   └── synonyms/            # Synonyms
├── test/
│   ├── unit/                # Unit tests
│   └── integration/         # Integration tests
├── scripts/
│   ├── deploy-to-hana.sh    # Deployment script
│   └── validate.sh          # Validation script
├── docs/
│   └── README.md            # Documentation
├── .gitignore
├── .hdiconfig               # HDI configuration
└── README.md
```

### 2. Branching Strategy

```
main (production)
  ↑ merge after testing
develop (development)
  ↑ merge after development
feature/CV-123-new-calculation-view
feature/CV-124-update-procedure
```

### 3. Commit Message Convention

```bash
git commit -m "feat(CV): Add CV_SALES_ANALYSIS calculation view"
git commit -m "fix(procedure): Fix GET_LINEAGE parameter handling"
git commit -m "docs: Update README with new workflow"
```

### 4. Code Review Process

1. Developer exports HANA objects
2. Commits to feature branch
3. Creates Pull Request
4. Team reviews changes
5. CI/CD validates
6. Merge to develop
7. Auto-deploy to DEV
8. Test in DEV
9. Merge to main
10. Deploy to PROD

---

## Tools & Technologies

### Required Tools

1. **SAP HANA Studio** - Development IDE
2. **Git** - Version control
3. **GitHub/GitLab** - Repository hosting
4. **CI/CD Platform** - GitHub Actions, Jenkins, GitLab CI

### Optional Tools

1. **SAP HANA Client** - Command-line tools (`hdbsql`)
2. **SAP Cloud Platform** - For cloud deployments
3. **Docker** - For containerized deployments
4. **Terraform** - Infrastructure as code

---

## Example: Complete Workflow

### Day 1: Initial Setup

```bash
# 1. Create local directory
mkdir hana-project
cd hana-project

# 2. Export from HANA Studio
# (Manual: Export → Catalog Objects → Choose folder)

# 3. Initialize Git
git init
git add .
git commit -m "Initial commit: HANA objects"

# 4. Create GitHub repository
git remote add origin https://github.com/yourusername/hana-project.git
git push -u origin main

# 5. Create develop branch
git checkout -b develop
git push -u origin develop
```

### Day 2: Development Cycle

```bash
# 1. Create feature branch
git checkout -b feature/new-cv

# 2. Develop in HANA Studio
# (Make changes to calculation views)

# 3. Export from HANA Studio
# (Export → Updated objects)

# 4. Commit changes
git add src/models/CV_NEW.hdbcalculationview
git commit -m "feat(CV): Add CV_NEW calculation view"
git push origin feature/new-cv

# 5. Create Pull Request on GitHub
# (Review → Merge to develop)

# 6. CI/CD automatically deploys to DEV
# (GitHub Actions runs deployment)
```

### Day 3: Production Release

```bash
# 1. Test in DEV environment
# (Validate functionality)

# 2. Create release PR
git checkout develop
git pull
git checkout main
git merge develop
git push origin main

# 3. CI/CD deploys to PROD
# (After approval in pipeline)

# 4. Tag release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

---

## Troubleshooting

### Issue 1: Can't export from HANA Studio

**Solution:**
- Check export permissions
- Verify workspace location
- Use File → Export → SAP HANA → Catalog Objects

### Issue 2: CI/CD can't connect to HANA

**Solution:**
- Verify firewall rules allow connection
- Check HANA host/port configuration
- Validate credentials in secrets

### Issue 3: Merge conflicts in XML files

**Solution:**
- Use XML-aware diff tools
- Export fresh copy from HANA
- Manually resolve in IDE

### Issue 4: Automated deployment fails

**Solution:**
- Check deployment script permissions
- Verify HANA client installation
- Review error logs in CI/CD

---

## Security Considerations

### 1. Credentials Management

```yaml
# ❌ NEVER commit credentials
HANA_PASSWORD=mypassword

# ✅ Use secrets management
HANA_PASSWORD=${{ secrets.HANA_PASSWORD }}
```

### 2. Access Control

- Use separate credentials for DEV/PROD
- Limit CI/CD service account permissions
- Enable audit logging

### 3. Network Security

- Use VPN for on-premise connections
- Enable SSL/TLS for HANA connections
- Whitelist CI/CD IP addresses

---

## Advanced: REST API Integration

### Using HANA XS REST API

```bash
# Deploy calculation view via REST API
curl -X POST https://hana-server:8000/deploy \
  -H "Content-Type: application/json" \
  -u "$HANA_USER:$HANA_PASSWORD" \
  -d @src/models/CV_SALES.hdbcalculationview
```

### Python Deployment Script

```python
import os
import requests
from pathlib import Path

def deploy_to_hana(env):
    """Deploy HANA objects to specified environment"""
    
    config = {
        'dev': {
            'host': os.getenv('HANA_DEV_HOST'),
            'user': os.getenv('HANA_DEV_USER'),
            'password': os.getenv('HANA_DEV_PASSWORD')
        },
        'prod': {
            'host': os.getenv('HANA_PROD_HOST'),
            'user': os.getenv('HANA_PROD_USER'),
            'password': os.getenv('HANA_PROD_PASSWORD')
        }
    }
    
    env_config = config[env]
    base_url = f"https://{env_config['host']}:8000"
    
    # Deploy calculation views
    cv_dir = Path('src/models')
    for cv_file in cv_dir.glob('*.hdbcalculationview'):
        print(f"Deploying {cv_file.name}...")
        
        with open(cv_file, 'r') as f:
            content = f.read()
        
        response = requests.post(
            f"{base_url}/deploy",
            auth=(env_config['user'], env_config['password']),
            data=content,
            headers={'Content-Type': 'application/xml'}
        )
        
        if response.status_code == 200:
            print(f"✅ {cv_file.name} deployed successfully")
        else:
            print(f"❌ Failed to deploy {cv_file.name}: {response.text}")
            return False
    
    return True

if __name__ == '__main__':
    import sys
    env = sys.argv[1] if len(sys.argv) > 1 else 'dev'
    deploy_to_hana(env)
```

---

## Conclusion

While HANA Studio on-premise doesn't have native Git integration, you can successfully implement CI/CD using:

1. ✅ **File-based sync** (Export/Import)
2. ✅ **Automation scripts** (Scheduled exports)
3. ✅ **CI/CD pipelines** (GitHub Actions, Jenkins)
4. ✅ **Deployment automation** (REST API, hdbsql)

### Key Takeaways:

- 📦 Export HANA objects to file system
- 🔄 Use Git for version control
- 🚀 Automate with CI/CD pipelines
- 🔒 Secure credentials with secrets
- 📊 Monitor deployments

### Next Steps:

1. Set up your repository structure
2. Configure CI/CD pipeline
3. Create deployment scripts
4. Test in DEV environment
5. Roll out to production

---

## Additional Resources

- [SAP HANA Developer Guide](https://help.sap.com/hana)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Jenkins Pipeline Tutorial](https://www.jenkins.io/doc/book/pipeline/)
- [SAP HDI Documentation](https://help.sap.com/docs/HANA_SERVICE_CF/c2b99f19e9264c4d9ae9221b22f6f589/e28abca91a004683845805efc2bf967c.html)

---

**Need Help?** Create an issue in this repository or consult SAP Community forums.

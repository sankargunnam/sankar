# HANA Object Activation in CI/CD Pipelines

## Table of Contents
1. [Overview](#overview)
2. [What is Object Activation?](#what-is-object-activation)
3. [Why Activation is Required](#why-activation-is-required)
4. [Activation Methods](#activation-methods)
5. [CI/CD Integration](#cicd-integration)
6. [Environment-Specific Activation](#environment-specific-activation)
7. [Error Handling](#error-handling)
8. [Best Practices](#best-practices)
9. [Complete Examples](#complete-examples)
10. [Troubleshooting](#troubleshooting)

---

## Overview

When deploying SAP HANA objects through CI/CD pipelines to higher environments (DEV → TEST → PROD), simply copying the files is not enough. **Objects must be activated** to become functional.

### The Challenge

```
CI/CD Pipeline
    ↓
Deploy files to HANA
    ↓
❌ Objects are INACTIVE
    ↓
✅ Activation Required
    ↓
Objects become ACTIVE and functional
```

This guide explains **how objects get activated automatically in higher environments** during CI/CD deployments.

---

## What is Object Activation?

### In SAP HANA Context

**Activation** is the process of:
1. **Validating** the object definition
2. **Compiling** the object
3. **Generating** runtime artifacts
4. **Making** the object available for use

### Objects That Require Activation

- ✅ Calculation Views (`.hdbcalculationview`)
- ✅ Analytic Privileges (`.hdbanalyticprivilege`)
- ✅ Tables (`.hdbtable`)
- ✅ Procedures (`.hdbprocedure`)
- ✅ Functions (`.hdbfunction`)
- ✅ Synonyms (`.hdbsynonym`)
- ✅ Table Types (`.hdbtabletype`)

### States of HANA Objects

| State | Description | Can be Used? |
|-------|-------------|--------------|
| **INACTIVE** | Object defined but not compiled | ❌ No |
| **ACTIVATING** | Currently being activated | ❌ No |
| **ACTIVE** | Compiled and ready to use | ✅ Yes |
| **INVALID** | Activation failed due to errors | ❌ No |

---

## Why Activation is Required

### 1. Compilation
Objects need to be compiled into executable form:
- Calculation views → Query execution plans
- Procedures → Compiled code
- Tables → Physical storage structures

### 2. Validation
Activation validates:
- Syntax correctness
- Referenced objects exist
- Permissions are correct
- Data types are compatible

### 3. Dependency Resolution
Activation ensures:
- All dependencies are available
- Correct object versions are used
- References are resolved

### 4. Runtime Artifact Generation
Creates runtime artifacts:
- Query plans
- Indexes
- Statistics
- Metadata

---

## Activation Methods

### Method 1: Using hdbsql (Command Line) ⭐

**Best for CI/CD pipelines**

#### Activate Calculation View
```bash
#!/bin/bash
# activate-calculation-view.sh

HANA_HOST="hanaserver.company.com"
HANA_PORT="30015"
HANA_USER="DEPLOY_USER"
HANA_PASSWORD="$HANA_DEPLOY_PASSWORD"
SCHEMA="SGUNNAM"
CV_NAME="CV_TEST"

hdbsql -n ${HANA_HOST}:${HANA_PORT} \
       -u ${HANA_USER} \
       -p ${HANA_PASSWORD} \
       "CALL _SYS_REPO.GRANT_ACTIVATED_ROLE ('sap.hana.ide.roles::Developer', '${HANA_USER}')"

hdbsql -n ${HANA_HOST}:${HANA_PORT} \
       -u ${HANA_USER} \
       -p ${HANA_PASSWORD} \
       "CALL _SYS_REPO.ACTIVATE_OBJECT('${SCHEMA}.${CV_NAME}', 'CALCULATION_VIEW', 'SYSTEM')"
```

#### Activate Multiple Objects
```bash
#!/bin/bash
# activate-all-objects.sh

HANA_HOST="$1"
HANA_USER="$2"
HANA_PASSWORD="$3"
SCHEMA="$4"

# Activate all calculation views in schema
hdbsql -n ${HANA_HOST}:30015 \
       -u ${HANA_USER} \
       -p ${HANA_PASSWORD} \
       -I ./sql/activate-all-cvs.sql
```

**activate-all-cvs.sql:**
```sql
-- Activate all calculation views in schema
DO
BEGIN
    DECLARE lv_count INTEGER;
    DECLARE CURSOR cur_cvs FOR
        SELECT OBJECT_NAME
        FROM _SYS_REPO.INACTIVE_OBJECT
        WHERE OBJECT_SUFFIX = 'calculationview'
        AND PACKAGE_ID LIKE 'SGUNNAM%';
    
    FOR cur_row AS cur_cvs DO
        CALL _SYS_REPO.ACTIVATE_OBJECT(
            cur_row.OBJECT_NAME,
            'CALCULATION_VIEW',
            'SYSTEM'
        );
    END FOR;
END;
```

### Method 2: Using HANA REST API

**Best for programmatic integration**

#### Python Script
```python
#!/usr/bin/env python3
# activate_hana_objects.py

import requests
import json
import sys
import time

def activate_calculation_view(host, port, user, password, schema, cv_name):
    """Activate a calculation view using REST API"""
    
    base_url = f"https://{host}:{port}"
    
    # Step 1: Get XS CSRF Token
    csrf_url = f"{base_url}/sap/hana/xs/formLogin/token.xscrf"
    
    session = requests.Session()
    response = session.get(csrf_url, auth=(user, password), verify=False)
    
    if response.status_code != 200:
        print(f"Failed to get CSRF token: {response.status_code}")
        return False
    
    csrf_token = response.headers.get('x-csrf-token')
    
    # Step 2: Activate the object
    activate_url = f"{base_url}/sap/hana/xs/dt/base/server/ActivationService.xsjs"
    
    headers = {
        'X-CSRF-Token': csrf_token,
        'Content-Type': 'application/json'
    }
    
    payload = {
        "objects": [
            {
                "package": schema,
                "name": cv_name,
                "suffix": "calculationview"
            }
        ]
    }
    
    response = session.post(
        activate_url,
        headers=headers,
        json=payload,
        verify=False
    )
    
    if response.status_code == 200:
        result = response.json()
        if result.get('success'):
            print(f"✅ Successfully activated {schema}.{cv_name}")
            return True
        else:
            print(f"❌ Activation failed: {result.get('message')}")
            return False
    else:
        print(f"❌ HTTP Error: {response.status_code}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 6:
        print("Usage: python activate_hana_objects.py <host> <port> <user> <password> <schema.cv_name>")
        sys.exit(1)
    
    host = sys.argv[1]
    port = sys.argv[2]
    user = sys.argv[3]
    password = sys.argv[4]
    object_path = sys.argv[5]
    
    schema, cv_name = object_path.split('.')
    
    success = activate_calculation_view(host, port, user, password, schema, cv_name)
    
    sys.exit(0 if success else 1)
```

### Method 3: Using HDI Container (HANA 2.0+)

**Best for HDI-based applications**

```bash
#!/bin/bash
# deploy-and-activate-hdi.sh

# HDI containers automatically activate objects on deployment
cf deploy mta.yaml
```

---

## CI/CD Integration

### GitHub Actions Pipeline with Activation

```yaml
# .github/workflows/hana-deploy.yml
name: HANA Deploy with Activation

on:
  push:
    branches: [ main, develop ]

jobs:
  deploy-and-activate:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Install HANA Client
        run: |
          wget https://tools.hana.ondemand.com/additional/hanaclient-2.16.20.tar.gz
          tar -xzf hanaclient-2.16.20.tar.gz
          cd client
          sudo ./hdbinst --batch
          
      - name: Deploy objects to HANA
        env:
          HANA_HOST: ${{ secrets.HANA_DEV_HOST }}
          HANA_USER: ${{ secrets.HANA_DEV_USER }}
          HANA_PASSWORD: ${{ secrets.HANA_DEV_PASSWORD }}
        run: |
          # Copy files to HANA file system or use import
          ./scripts/deploy-objects.sh dev
      
      - name: Activate objects
        env:
          HANA_HOST: ${{ secrets.HANA_DEV_HOST }}
          HANA_USER: ${{ secrets.HANA_DEV_USER }}
          HANA_PASSWORD: ${{ secrets.HANA_DEV_PASSWORD }}
        run: |
          ./scripts/activate-objects.sh dev
      
      - name: Verify activation
        env:
          HANA_HOST: ${{ secrets.HANA_DEV_HOST }}
          HANA_USER: ${{ secrets.HANA_DEV_USER }}
          HANA_PASSWORD: ${{ secrets.HANA_DEV_PASSWORD }}
        run: |
          ./scripts/verify-activation.sh dev
```

### Jenkins Pipeline with Activation

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'test', 'prod'],
            description: 'Target environment'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Deploy Objects') {
            steps {
                script {
                    sh "./scripts/deploy-objects.sh ${params.ENVIRONMENT}"
                }
            }
        }
        
        stage('Activate Objects') {
            steps {
                script {
                    sh "./scripts/activate-objects.sh ${params.ENVIRONMENT}"
                }
            }
        }
        
        stage('Verify Activation') {
            steps {
                script {
                    sh "./scripts/verify-activation.sh ${params.ENVIRONMENT}"
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    sh "./scripts/run-tests.sh ${params.ENVIRONMENT}"
                }
            }
        }
    }
    
    post {
        failure {
            emailext(
                subject: "HANA Deployment Failed: ${params.ENVIRONMENT}",
                body: "Activation or deployment failed. Check logs.",
                to: "devops@company.com"
            )
        }
    }
}
```

---

## Environment-Specific Activation

### DEV Environment
```bash
#!/bin/bash
# activate-objects-dev.sh

# DEV - More lenient, auto-retry on failure
ENVIRONMENT="DEV"
MAX_RETRIES=3
RETRY_DELAY=30

for i in $(seq 1 $MAX_RETRIES); do
    if ./activate-objects.sh dev; then
        echo "✅ Activation successful on attempt $i"
        exit 0
    else
        echo "⚠️ Activation failed on attempt $i, retrying in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
    fi
done

echo "❌ Activation failed after $MAX_RETRIES attempts"
exit 1
```

### TEST Environment
```bash
#!/bin/bash
# activate-objects-test.sh

# TEST - Requires validation before activation
ENVIRONMENT="TEST"

# Step 1: Validate objects first
echo "Validating objects before activation..."
if ! ./validate-objects.sh test; then
    echo "❌ Validation failed, aborting activation"
    exit 1
fi

# Step 2: Activate
echo "Activating objects..."
if ! ./activate-objects.sh test; then
    echo "❌ Activation failed"
    exit 1
fi

# Step 3: Run smoke tests
echo "Running smoke tests..."
if ! ./run-smoke-tests.sh test; then
    echo "⚠️ Smoke tests failed after activation"
    exit 1
fi

echo "✅ TEST activation complete"
```

### PROD Environment
```bash
#!/bin/bash
# activate-objects-prod.sh

# PROD - Requires approval and backup
ENVIRONMENT="PROD"

# Step 1: Create backup
echo "Creating backup before activation..."
./backup-objects.sh prod

# Step 2: Require manual approval
echo "⏸️ Awaiting approval for PROD activation..."
if [ "$APPROVAL_REQUIRED" = "true" ]; then
    # Wait for approval (in Jenkins/GitHub Actions)
    echo "Approval granted, proceeding..."
fi

# Step 3: Activate with rollback capability
echo "Activating objects in PROD..."
if ! ./activate-objects.sh prod; then
    echo "❌ Activation failed, rolling back..."
    ./rollback-objects.sh prod
    exit 1
fi

# Step 4: Comprehensive validation
echo "Running full validation suite..."
if ! ./run-full-tests.sh prod; then
    echo "⚠️ Validation failed, consider rollback"
    exit 1
fi

echo "✅ PROD activation complete"
```

---

## Error Handling

### Common Activation Errors

#### 1. Missing Dependencies
```sql
-- Error: Referenced object does not exist
-- Solution: Activate dependencies first

-- Correct order:
1. Activate base tables
2. Activate referenced calculation views
3. Activate dependent calculation views
```

#### 2. Permission Issues
```sql
-- Error: Insufficient privileges
-- Solution: Grant required roles

CALL _SYS_REPO.GRANT_ACTIVATED_ROLE(
    'sap.hana.ide.roles::Developer',
    'DEPLOY_USER'
);
```

#### 3. Syntax Errors
```sql
-- Error: Compilation error
-- Solution: Validate XML before deployment

# Validate XML syntax
xmllint --noout file.hdbcalculationview
```

### Activation Script with Error Handling

```bash
#!/bin/bash
# activate-with-error-handling.sh

set -e  # Exit on error

HANA_HOST="$1"
HANA_USER="$2"
HANA_PASSWORD="$3"
SCHEMA="$4"
OBJECT_NAME="$5"

# Function to check activation status
check_activation_status() {
    local status=$(hdbsql -n ${HANA_HOST}:30015 \
                         -u ${HANA_USER} \
                         -p ${HANA_PASSWORD} \
                         -C \
                         "SELECT ACTIVATION_STATUS 
                          FROM _SYS_REPO.ACTIVE_OBJECT 
                          WHERE OBJECT_NAME = '${OBJECT_NAME}'")
    
    echo $status
}

# Function to get activation errors
get_activation_errors() {
    hdbsql -n ${HANA_HOST}:30015 \
           -u ${HANA_USER} \
           -p ${HANA_PASSWORD} \
           "SELECT MESSAGE 
            FROM _SYS_REPO.ACTIVATION_MESSAGES 
            WHERE OBJECT_NAME = '${OBJECT_NAME}'
            AND SEVERITY = 'ERROR'
            ORDER BY TIMESTAMP DESC"
}

echo "Activating ${SCHEMA}.${OBJECT_NAME}..."

# Attempt activation
if hdbsql -n ${HANA_HOST}:30015 \
          -u ${HANA_USER} \
          -p ${HANA_PASSWORD} \
          "CALL _SYS_REPO.ACTIVATE_OBJECT('${SCHEMA}.${OBJECT_NAME}', 'CALCULATION_VIEW', 'SYSTEM')"; then
    
    # Wait for activation to complete
    sleep 5
    
    # Check status
    STATUS=$(check_activation_status)
    
    if [ "$STATUS" = "ACTIVE" ]; then
        echo "✅ Activation successful"
        exit 0
    else
        echo "❌ Activation failed with status: $STATUS"
        echo "Errors:"
        get_activation_errors
        exit 1
    fi
else
    echo "❌ Activation command failed"
    echo "Errors:"
    get_activation_errors
    exit 1
fi
```

---

## Best Practices

### 1. Activation Order

Always activate in dependency order:

```
1. Base Tables
2. Table Types
3. Synonyms
4. Base Calculation Views (no dependencies)
5. Intermediate Calculation Views
6. Top-level Calculation Views
7. Procedures using the views
8. Analytic Privileges
```

### 2. Batch Activation

For multiple objects:

```sql
-- Batch activate all objects in a package
CALL _SYS_REPO.ACTIVATE_PACKAGE(
    'SGUNNAM',
    'RECURSIVE'
);
```

### 3. Validation Before Activation

```bash
#!/bin/bash
# validate-before-activate.sh

# Validate XML syntax
find . -name "*.hdbcalculationview" -exec xmllint --noout {} \;

# Check for missing dependencies
./check-dependencies.sh

# Then activate
./activate-objects.sh
```

### 4. Monitoring Activation

```sql
-- Monitor activation progress
SELECT 
    OBJECT_NAME,
    ACTIVATION_STATUS,
    ACTIVATED_AT,
    ACTIVATED_BY
FROM _SYS_REPO.ACTIVE_OBJECT
WHERE PACKAGE_ID LIKE 'SGUNNAM%'
ORDER BY ACTIVATED_AT DESC;

-- Check for failed activations
SELECT 
    OBJECT_NAME,
    MESSAGE,
    SEVERITY,
    TIMESTAMP
FROM _SYS_REPO.ACTIVATION_MESSAGES
WHERE SEVERITY = 'ERROR'
AND TIMESTAMP > ADD_DAYS(CURRENT_TIMESTAMP, -1)
ORDER BY TIMESTAMP DESC;
```

### 5. Rollback Strategy

```bash
#!/bin/bash
# rollback-activation.sh

# Keep track of activated objects
ACTIVATED_OBJECTS_FILE="/tmp/activated_objects_${BUILD_NUMBER}.txt"

# During activation, log each success
echo "${OBJECT_NAME}" >> ${ACTIVATED_OBJECTS_FILE}

# On failure, rollback
rollback() {
    echo "Rolling back activations..."
    while IFS= read -r object; do
        # Reactivate previous version or deactivate
        ./rollback-object.sh "$object"
    done < ${ACTIVATED_OBJECTS_FILE}
}

trap rollback ERR
```

---

## Complete Examples

### Example 1: Simple Activation Script

```bash
#!/bin/bash
# simple-activate.sh

# Configuration
ENVIRONMENT=$1
CONFIG_FILE="config/${ENVIRONMENT}.conf"

# Load environment-specific config
source ${CONFIG_FILE}

# Activate each calculation view
for cv_file in src/models/*.hdbcalculationview; do
    CV_NAME=$(basename "$cv_file" .hdbcalculationview)
    
    echo "Activating ${CV_NAME}..."
    
    hdbsql -n ${HANA_HOST}:${HANA_PORT} \
           -u ${HANA_USER} \
           -p ${HANA_PASSWORD} \
           "CALL _SYS_REPO.ACTIVATE_OBJECT('${SCHEMA}.${CV_NAME}', 'CALCULATION_VIEW', 'SYSTEM')"
    
    if [ $? -eq 0 ]; then
        echo "✅ ${CV_NAME} activated"
    else
        echo "❌ ${CV_NAME} activation failed"
        exit 1
    fi
done

echo "All objects activated successfully"
```

### Example 2: Python Activation with Logging

```python
#!/usr/bin/env python3
# activate_with_logging.py

import logging
import sys
from hdbcli import dbapi

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'activation_{sys.argv[1]}.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

def activate_object(connection, schema, object_name, object_type):
    """Activate a HANA object"""
    cursor = connection.cursor()
    
    try:
        logger.info(f"Activating {schema}.{object_name} ({object_type})")
        
        sql = f"CALL _SYS_REPO.ACTIVATE_OBJECT('{schema}.{object_name}', '{object_type}', 'SYSTEM')"
        cursor.execute(sql)
        
        logger.info(f"✅ Successfully activated {object_name}")
        return True
        
    except Exception as e:
        logger.error(f"❌ Failed to activate {object_name}: {str(e)}")
        return False
    finally:
        cursor.close()

def main():
    host = sys.argv[1]
    port = sys.argv[2]
    user = sys.argv[3]
    password = sys.argv[4]
    
    # Connect to HANA
    connection = dbapi.connect(
        address=host,
        port=int(port),
        user=user,
        password=password
    )
    
    # List of objects to activate
    objects = [
        ('SGUNNAM', 'CV_SALES_ANALYSIS', 'CALCULATION_VIEW'),
        ('SGUNNAM', 'CV_CUSTOMER_360', 'CALCULATION_VIEW'),
        ('SGUNNAM', 'CV_TEST', 'CALCULATION_VIEW'),
    ]
    
    success_count = 0
    failure_count = 0
    
    for schema, obj_name, obj_type in objects:
        if activate_object(connection, schema, obj_name, obj_type):
            success_count += 1
        else:
            failure_count += 1
    
    connection.close()
    
    logger.info(f"Activation complete: {success_count} succeeded, {failure_count} failed")
    
    sys.exit(0 if failure_count == 0 else 1)

if __name__ == "__main__":
    main()
```

---

## Troubleshooting

### Issue 1: Objects Remain INACTIVE

**Symptom:**
```
Objects deployed but status shows INACTIVE
```

**Solution:**
```bash
# Check if activation was executed
SELECT * FROM _SYS_REPO.INACTIVE_OBJECT WHERE PACKAGE_ID LIKE 'SGUNNAM%';

# Manually activate
CALL _SYS_REPO.ACTIVATE_OBJECT('SGUNNAM.CV_TEST', 'CALCULATION_VIEW', 'SYSTEM');
```

### Issue 2: Activation Timeout

**Symptom:**
```
Activation takes too long or times out
```

**Solution:**
```bash
# Increase timeout in hdbsql
hdbsql -n ${HOST}:${PORT} -u ${USER} -p ${PASS} -timeout 600 -I activation.sql

# Or activate objects in smaller batches
for cv in CV_1 CV_2 CV_3; do
    activate_object $cv
    sleep 5  # Wait between activations
done
```

### Issue 3: Circular Dependencies

**Symptom:**
```
Activation fails due to circular references
```

**Solution:**
```sql
-- Identify circular dependencies
SELECT * FROM _SYS_REPO.OBJECT_DEPENDENCIES
WHERE BASE_OBJECT_NAME IN (
    SELECT DEPENDENT_OBJECT_NAME 
    FROM _SYS_REPO.OBJECT_DEPENDENCIES
    WHERE BASE_OBJECT_NAME = DEPENDENT_OBJECT_NAME
);

-- Break the cycle by temporarily removing the reference
-- Activate objects separately
-- Re-add the reference
```

### Issue 4: Permission Denied

**Symptom:**
```
Insufficient privileges for activation
```

**Solution:**
```sql
-- Grant required roles
CALL _SYS_REPO.GRANT_ACTIVATED_ROLE('sap.hana.ide.roles::Developer', 'DEPLOY_USER');
CALL _SYS_REPO.GRANT_ACTIVATED_ROLE('sap.hana.ide.roles::CatalogDeveloper', 'DEPLOY_USER');

-- Grant schema permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA SGUNNAM TO DEPLOY_USER;
```

---

## Summary

### Activation in CI/CD Pipeline

```
1. Code Push
    ↓
2. CI/CD Triggered
    ↓
3. Deploy Files to HANA
    ↓
4. ⭐ ACTIVATE OBJECTS ⭐
    ├─ Using hdbsql
    ├─ Using REST API
    └─ Using HDI deployment
    ↓
5. Verify Activation Status
    ↓
6. Run Tests
    ↓
7. Deploy to Next Environment
```

### Key Points

✅ **Activation is Required** - Objects don't work until activated  
✅ **Automate in CI/CD** - Use scripts to activate during deployment  
✅ **Handle Errors** - Check status and log errors  
✅ **Order Matters** - Activate dependencies first  
✅ **Environment-Specific** - Different strategies for DEV/TEST/PROD  
✅ **Monitor & Verify** - Always check activation status  
✅ **Rollback Plan** - Be prepared to revert if needed  

### Quick Commands

```bash
# Activate single object
hdbsql "CALL _SYS_REPO.ACTIVATE_OBJECT('SCHEMA.OBJECT', 'TYPE', 'SYSTEM')"

# Activate all objects in schema
hdbsql "CALL _SYS_REPO.ACTIVATE_PACKAGE('SCHEMA', 'RECURSIVE')"

# Check activation status
hdbsql "SELECT * FROM _SYS_REPO.ACTIVE_OBJECT WHERE OBJECT_NAME = 'CV_TEST'"

# Check for errors
hdbsql "SELECT * FROM _SYS_REPO.ACTIVATION_MESSAGES WHERE SEVERITY = 'ERROR'"
```

---

**With proper activation integrated into your CI/CD pipeline, objects will be automatically activated in all higher environments!** 🎉

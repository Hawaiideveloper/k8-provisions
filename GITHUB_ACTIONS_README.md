# GitHub Actions Workflow for Kubernetes Cluster Setup

This repository includes a comprehensive GitHub Actions workflow that validates, tests, and packages the Kubernetes cluster setup scripts.

## Workflow Overview

The workflow (`k8s-cluster-setup.yml`) provides automated validation and testing for the Kubernetes cluster setup scripts.

## Workflow Jobs

### 1. Validate Scripts
**Trigger**: On push/PR to main/master branches
**Purpose**: Validates that the required scripts exist and contain essential components

**Checks**:
- ✅ `master-workflow.sh` exists and is executable
- ✅ `worker-workflow.sh` exists and is executable
- ✅ Master script contains `MASTER_IP=` configuration
- ✅ Master script contains `kubeadm init` command
- ✅ Worker script contains `MASTER_IP=` configuration
- ✅ Worker script contains `kubeadm join` command

### 2. Syntax Check
**Trigger**: On push/PR to main/master branches
**Purpose**: Validates shell script syntax using shellcheck

**Checks**:
- ✅ `master-workflow.sh` syntax validation
- ✅ `worker-workflow.sh` syntax validation
- ✅ No shell script errors or warnings

### 3. Documentation Check
**Trigger**: On push/PR to main/master branches
**Purpose**: Validates documentation completeness

**Checks**:
- ✅ `WORKFLOW_README.md` exists
- ✅ Contains required sections:
  - Network Configuration
  - Quick Start
  - Prerequisites
  - Troubleshooting

### 4. Security Scan
**Trigger**: On push/PR to main/master branches
**Purpose**: Performs basic security analysis

**Checks**:
- ⚠️ Potential hardcoded credentials
- ⚠️ Dangerous commands (rm -rf /, format, etc.)
- ✅ Security scan completion

### 5. Test Deployment (Simulated)
**Trigger**: Manual workflow dispatch with test_mode=true
**Purpose**: Simulates the cluster setup process

**Features**:
- 🧪 Simulates master node setup steps
- 🧪 Simulates worker node setup for specified cluster size
- 📊 Generates test deployment report
- 📋 Shows network configuration for each node

### 6. Build Package
**Trigger**: On tag push (releases)
**Purpose**: Creates deployment package for releases

**Actions**:
- 📦 Creates deployment package with all scripts
- 📦 Compresses into `k8s-cluster-setup.tar.gz`
- 📦 Uploads as GitHub artifact

## How to Use

### Automatic Validation
The workflow runs automatically on:
- Push to main/master branches
- Pull requests to main/master branches
- Only when relevant files are changed

### Manual Testing
1. Go to **Actions** tab in GitHub
2. Select **Kubernetes Cluster Setup** workflow
3. Click **Run workflow**
4. Configure options:
   - **Cluster size**: 1-5 worker nodes
   - **Test mode**: Enable for simulation
5. Click **Run workflow**

### Release Process
1. Create and push a tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. The workflow will automatically:
   - Run all validation checks
   - Create deployment package
   - Upload as artifact

## Workflow Configuration

### Environment Variables
```yaml
MASTER_IP: "172.100.10.10"
WORKER_IP_PREFIX: "172.100.10"
POD_NETWORK_CIDR: "192.168.79.0/24"
K8S_VERSION: "1.31.4-1.1"
```

### Trigger Paths
The workflow only runs when these files change:
- `master-workflow.sh`
- `worker-workflow.sh`
- `.github/workflows/k8s-cluster-setup.yml`

## Test Mode Features

When running in test mode, the workflow provides:

### Master Node Simulation
```
📋 Steps that would be executed:
  1. Configure network interface for 172.100.10.10
  2. Set hostname to k8-master
  3. Install containerd
  4. Install Kubernetes components
  5. Initialize control plane
  6. Install Calico CNI
  7. Generate join command
```

### Worker Node Simulation
For each worker node, shows:
- IP address assignment
- Hostname configuration
- Installation steps
- Cluster joining process

### Test Report
```
📊 Test Deployment Report
========================
Cluster Size: 2 worker nodes
Master IP: 172.100.10.10
Pod Network: 192.168.79.0/24
Kubernetes Version: 1.31.4-1.1

Network Configuration:
- Master: 172.100.10.10
- Worker 1: 172.100.10.11
- Worker 2: 172.100.10.12
```

## Troubleshooting

### Failed Validation
If validation fails:
1. Check that all required scripts exist
2. Verify scripts are executable (`chmod +x`)
3. Ensure required commands are present in scripts
4. Check for syntax errors

### Failed Syntax Check
If syntax check fails:
1. Install shellcheck locally: `sudo apt-get install shellcheck`
2. Run: `shellcheck master-workflow.sh worker-workflow.sh`
3. Fix any syntax issues reported

### Failed Documentation Check
If documentation check fails:
1. Ensure `WORKFLOW_README.md` exists
2. Add missing required sections
3. Verify section names match exactly

### Security Warnings
Security warnings don't fail the workflow but should be reviewed:
- Check for any hardcoded credentials
- Review dangerous commands
- Ensure proper error handling

## Artifacts

### Deployment Package
When a tag is pushed, the workflow creates:
- **File**: `k8s-cluster-setup.tar.gz`
- **Contents**: All scripts and documentation
- **Retention**: 30 days
- **Download**: Available in Actions tab

### Package Contents
```
k8s-cluster-setup/
├── master-workflow.sh
├── worker-workflow.sh
├── WORKFLOW_README.md
└── .github/workflows/
    └── k8s-cluster-setup.yml
```

## Best Practices

### For Contributors
1. **Test locally** before pushing
2. **Run syntax check**: `shellcheck *.sh`
3. **Update documentation** when changing scripts
4. **Use test mode** to validate changes

### For Maintainers
1. **Review security warnings** in workflow runs
2. **Test with different cluster sizes**
3. **Validate package contents** after releases
4. **Monitor workflow performance**

## Integration with Local Development

### Pre-commit Validation
Add to your local workflow:
```bash
# Install shellcheck
sudo apt-get install shellcheck

# Validate scripts
shellcheck master-workflow.sh worker-workflow.sh

# Check documentation
grep -q "Network Configuration" WORKFLOW_README.md
```

### Local Testing
Simulate workflow locally:
```bash
# Validate scripts exist and are executable
ls -la master-workflow.sh worker-workflow.sh

# Check for required content
grep -q "MASTER_IP=" master-workflow.sh
grep -q "kubeadm init" master-workflow.sh
grep -q "kubeadm join" worker-workflow.sh
```

## Support

For workflow issues:
1. Check the **Actions** tab for detailed logs
2. Review failed job outputs
3. Test locally with the same commands
4. Create an issue with workflow logs attached 
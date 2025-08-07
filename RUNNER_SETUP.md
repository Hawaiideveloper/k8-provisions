# Self-Hosted Runner Setup Guide

This guide helps you set up a self-hosted GitHub Actions runner with all the required dependencies for the workflows in this repository.

## Quick Setup

### 1. Run the Setup Script
```bash
# Make the script executable
chmod +x setup-runner-dependencies.sh

# Run the setup script
./setup-runner-dependencies.sh
```

### 2. Manual Installation (if needed)
If the setup script doesn't work, install these packages manually:

#### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y curl wget git python3 python3-pip shellcheck dnsutils
```

#### CentOS/RHEL:
```bash
sudo yum install -y curl wget git python3 python3-pip epel-release
sudo yum install -y shellcheck bind-utils
```

#### macOS:
```bash
brew install curl wget git python3 shellcheck bind
```

## Required Dependencies

### Essential Tools
- ✅ **curl** - HTTP requests and API calls
- ✅ **wget** - File downloads
- ✅ **git** - Repository operations
- ✅ **python3** - Python script execution
- ✅ **pip3** - Python package management

### Optional Tools (for enhanced functionality)
- ⚠️ **shellcheck** - Shell script syntax checking
- ⚠️ **nslookup/dig** - DNS resolution testing
- ⚠️ **ping** - Network connectivity testing
- ⚠️ **jq** - JSON processing

## Troubleshooting

### Common Issues

#### 1. "command not found" errors
**Solution**: Install missing packages using your system's package manager

#### 2. Permission denied errors
**Solution**: Ensure the runner user has sudo privileges or install packages as root

#### 3. Network connectivity issues
**Solution**: Check firewall settings and DNS configuration

#### 4. Python import errors
**Solution**: Install missing Python packages with `pip3 install <package>`

### Manual Package Installation

#### For Ubuntu/Debian:
```bash
# Install basic tools
sudo apt-get update
sudo apt-get install -y curl wget git python3 python3-pip

# Install shellcheck
sudo apt-get install -y shellcheck

# Install DNS tools
sudo apt-get install -y dnsutils

# Install JSON processor
sudo apt-get install -y jq
```

#### For CentOS/RHEL:
```bash
# Install basic tools
sudo yum install -y curl wget git python3 python3-pip

# Install EPEL repository
sudo yum install -y epel-release

# Install shellcheck
sudo yum install -y shellcheck

# Install DNS tools
sudo yum install -y bind-utils

# Install JSON processor
sudo yum install -y jq
```

#### For macOS:
```bash
# Install basic tools
brew install curl wget git python3

# Install shellcheck
brew install shellcheck

# Install DNS tools
brew install bind

# Install JSON processor
brew install jq
```

## Workflow Compatibility

### With All Dependencies Installed
- ✅ Full syntax checking with shellcheck
- ✅ Complete network connectivity tests
- ✅ Enhanced error reporting
- ✅ All features enabled

### With Missing Optional Dependencies
- ⚠️ Syntax checking skipped (if shellcheck missing)
- ⚠️ Limited network tests (if DNS tools missing)
- ✅ Core functionality still works
- ✅ Workflows complete successfully

## Testing the Setup

### 1. Test Basic Tools
```bash
# Test curl
curl --version

# Test Python
python3 --version

# Test git
git --version
```

### 2. Test Network Connectivity
```bash
# Test HTTP connectivity
curl -I https://httpbin.org/get

# Test DNS resolution
nslookup github.com || dig github.com

# Test GitHub API
curl -s https://api.github.com/zen
```

### 3. Test Python Scripts
```bash
# Test Python imports
python3 -c "import sys, platform, datetime, json, os; print('Python environment OK')"

# Test the hello world script
python3 hello_world.py
```

## Runner Configuration

### Environment Variables
Make sure these environment variables are set (if needed):
```bash
export GITHUB_TOKEN=your_token_here
export RUNNER_WORKDIR=/path/to/runner/work
```

### Runner Permissions
The runner user should have:
- ✅ Read/write access to the repository
- ✅ Execute permissions on scripts
- ✅ Network access for external calls
- ✅ Sudo access (for package installation)

## Monitoring

### Check Runner Status
```bash
# Check if runner is connected
ps aux | grep actions-runner

# Check runner logs
tail -f ~/.actions-runner/_diag/*.log
```

### Check Workflow Execution
1. Go to GitHub repository
2. Click on **Actions** tab
3. Monitor workflow runs
4. Check job logs for any errors

## Troubleshooting Workflows

### If Workflows Fail

#### 1. Check Runner Logs
```bash
# View recent logs
tail -f ~/.actions-runner/_diag/*.log
```

#### 2. Test Individual Commands
```bash
# Test shellcheck
shellcheck master-workflow.sh

# Test Python script
python3 hello_world.py

# Test network connectivity
curl -I https://httpbin.org/get
```

#### 3. Check Dependencies
```bash
# Run the setup script again
./setup-runner-dependencies.sh
```

### Common Error Messages

#### "command not found"
- Install the missing package
- Check PATH environment variable

#### "Permission denied"
- Check file permissions
- Ensure sudo access

#### "Connection refused"
- Check network connectivity
- Verify firewall settings

#### "ImportError"
- Install missing Python packages
- Check Python version compatibility

## Best Practices

### 1. Regular Maintenance
- Update packages regularly
- Monitor runner logs
- Test workflows periodically

### 2. Security
- Keep runner updated
- Use minimal required permissions
- Monitor for unauthorized access

### 3. Performance
- Monitor resource usage
- Clean up old artifacts
- Optimize runner configuration

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review runner logs
3. Test individual components
4. Re-run the setup script
5. Contact your system administrator if needed 
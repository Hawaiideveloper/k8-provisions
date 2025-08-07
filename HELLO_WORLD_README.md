# Hello World Python Workflow

A simple GitHub Actions workflow to test connectivity and basic functionality using Python.

## Overview

This workflow provides a comprehensive test of GitHub Actions functionality including:
- ✅ Python environment setup
- ✅ File operations
- ✅ Network connectivity
- ✅ Environment variables
- ✅ Artifact creation
- ✅ Manual trigger with inputs

## Files

### Workflow Files
- `.github/workflows/hello-world.yml` - Main workflow file
- `hello_world.py` - Python script for testing
- `test_hello_world.py` - Local test script

## How to Use

### Automatic Triggers
The workflow runs automatically on:
- Push to main/master branches
- Pull requests to main/master branches

### Manual Trigger
1. Go to **Actions** tab in GitHub
2. Select **Hello World Python** workflow
3. Click **Run workflow**
4. Configure inputs:
   - **Name**: Who to greet (default: "World")
   - **Language**: Programming language (default: "Python")
5. Click **Run workflow**

## What the Workflow Tests

### 1. Python Environment
- ✅ Python 3.11 setup
- ✅ pip package manager
- ✅ Basic Python operations
- ✅ System information retrieval

### 2. File Operations
- ✅ File creation and writing
- ✅ File reading and display
- ✅ Directory listing
- ✅ File content manipulation

### 3. Network Connectivity
- ✅ DNS resolution (github.com)
- ✅ HTTP connectivity (httpbin.org)
- ✅ GitHub API access
- ✅ External service connectivity

### 4. Environment Variables
- ✅ GitHub context variables
- ✅ Runner environment information
- ✅ Repository information
- ✅ Event information

### 5. Artifact Creation
- ✅ File generation
- ✅ Artifact upload
- ✅ Report creation
- ✅ ASCII art generation

## Test Scripts

### hello_world.py
A comprehensive Python script that tests:
- System information display
- Environment variable access
- File operations
- JSON operations
- Error handling

### test_hello_world.py
A local test script to verify:
- Python environment functionality
- hello_world.py script execution
- Basic operations before GitHub Actions

## Local Testing

### Prerequisites
```bash
# Ensure Python 3 is available
python3 --version

# Make scripts executable
chmod +x hello_world.py test_hello_world.py
```

### Run Local Tests
```bash
# Test the main script
python3 hello_world.py

# Run comprehensive tests
python3 test_hello_world.py
```

### Expected Output
```
🚀 Starting Hello World tests...
==================================================
🐍 Testing Python environment...
✅ Python version: 3.12.8
✅ Platform: macOS-13.7.2-x86_64-i386-64bit
✅ Current time: 2025-08-07 00:39:31.999599
✅ Working directory: /path/to/repo
✅ JSON operations working: {'test': 'Hello World'}
🧪 Testing hello_world.py script...
✅ hello_world.py executed successfully
==================================================
🎉 All tests passed!
✅ Python environment is working
✅ hello_world.py script is working
✅ Ready for GitHub Actions!
```

## Workflow Output

### Success Indicators
- ✅ All steps complete without errors
- ✅ Python environment properly configured
- ✅ File operations successful
- ✅ Network connectivity verified
- ✅ Artifacts uploaded successfully

### Artifacts Generated
- `test_output.txt` - Basic test output
- `workflow_report.txt` - Detailed workflow report
- `python_test_output.txt` - Python script output

### Sample Report
```
========================================
GitHub Actions Hello World Report
========================================
Date: 2025-08-07 00:39:31
Repository: user/repo
Branch: refs/heads/main
Commit: abc123def456
Actor: username
Event: push
Runner: Linux (x64)
Python: 3.11.x
========================================

🎉 SUCCESS! 🎉

╔══════════════════════════════════════╗
║     GitHub Actions is working!       ║
║                                      ║
║  ✅ Python environment ready         ║
║  ✅ File operations working          ║
║  ✅ Network connectivity OK          ║
║  ✅ Environment variables set        ║
╚══════════════════════════════════════╝
```

## Troubleshooting

### Common Issues

#### Python Not Found
```bash
# Check Python installation
python3 --version

# Install Python if needed (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install python3 python3-pip
```

#### Permission Denied
```bash
# Make scripts executable
chmod +x hello_world.py test_hello_world.py
```

#### Network Connectivity Issues
- Check firewall settings
- Verify DNS resolution
- Test with different endpoints

### Workflow Debugging

#### Check Workflow Logs
1. Go to **Actions** tab
2. Click on the workflow run
3. Click on the failed job
4. Review step outputs

#### Common Error Messages
- `python: command not found` - Python not installed
- `Permission denied` - Script not executable
- `Connection refused` - Network connectivity issue
- `Module not found` - Missing Python dependencies

## Integration with Other Workflows

This Hello World workflow can be used as a template for:
- Testing new GitHub Actions features
- Validating repository setup
- Debugging workflow issues
- Learning GitHub Actions concepts

## Best Practices

### For Development
1. **Test locally first** - Run `test_hello_world.py` before pushing
2. **Check Python version** - Ensure compatibility
3. **Verify file permissions** - Make scripts executable
4. **Test network access** - Ensure external connectivity

### For Production
1. **Use specific Python versions** - Pin version in workflow
2. **Add error handling** - Graceful failure handling
3. **Include logging** - Detailed output for debugging
4. **Test regularly** - Run workflow periodically

## Next Steps

After successful Hello World workflow:
1. ✅ GitHub Actions is working
2. ✅ Python environment is configured
3. ✅ File operations are functional
4. ✅ Network connectivity is verified
5. 🚀 Ready for more complex workflows!

## Support

For issues with this workflow:
1. Check the **Actions** tab for detailed logs
2. Run local tests with `test_hello_world.py`
3. Verify Python installation and permissions
4. Review network connectivity settings 
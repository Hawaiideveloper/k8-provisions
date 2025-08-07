#!/usr/bin/env python3
"""
Hello World Python Script
A simple script to test GitHub Actions connectivity and Python environment.
"""

import sys
import platform
import datetime
import os
import json

def print_header():
    """Print a nice header for the Hello World message."""
    print("=" * 60)
    print("🐍 Hello World from Python!")
    print("=" * 60)

def print_system_info():
    """Print system and environment information."""
    print(f"📅 Date: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"💻 Platform: {platform.platform()}")
    print(f"🐍 Python Version: {sys.version}")
    print(f"🏠 Hostname: {platform.node()}")
    print(f"📁 Working Directory: {os.getcwd()}")
    print(f"👤 User: {os.getenv('USER', 'Unknown')}")

def print_environment_vars():
    """Print relevant environment variables."""
    print("\n🔧 Environment Variables:")
    env_vars = {
        'GITHUB_REPOSITORY': os.getenv('GITHUB_REPOSITORY'),
        'GITHUB_SHA': os.getenv('GITHUB_SHA'),
        'GITHUB_REF': os.getenv('GITHUB_REF'),
        'GITHUB_ACTOR': os.getenv('GITHUB_ACTOR'),
        'RUNNER_OS': os.getenv('RUNNER_OS'),
        'RUNNER_ARCH': os.getenv('RUNNER_ARCH'),
    }
    
    for key, value in env_vars.items():
        if value:
            print(f"  {key}: {value}")

def test_file_operations():
    """Test basic file operations."""
    print("\n📁 Testing File Operations:")
    
    # Create a test file
    test_file = "python_test_output.txt"
    with open(test_file, 'w') as f:
        f.write("Hello from Python script!\n")
        f.write(f"Timestamp: {datetime.datetime.now()}\n")
        f.write(f"Python version: {sys.version}\n")
    
    print(f"  ✅ Created file: {test_file}")
    
    # Read and display the file
    with open(test_file, 'r') as f:
        content = f.read()
        print(f"  📄 File contents:\n{content}")
    
    return test_file

def test_json_operations():
    """Test JSON operations."""
    print("\n📊 Testing JSON Operations:")
    
    # Create a test JSON object
    test_data = {
        "message": "Hello World",
        "timestamp": datetime.datetime.now().isoformat(),
        "python_version": sys.version,
        "platform": platform.platform(),
        "environment": "GitHub Actions"
    }
    
    # Convert to JSON string
    json_string = json.dumps(test_data, indent=2)
    print(f"  ✅ JSON created:\n{json_string}")
    
    # Parse JSON back
    parsed_data = json.loads(json_string)
    print(f"  ✅ JSON parsed successfully")
    
    return test_data

def print_success_message():
    """Print a success message."""
    print("\n" + "=" * 60)
    print("🎉 SUCCESS! 🎉")
    print("=" * 60)
    print("✅ Python script executed successfully")
    print("✅ System information retrieved")
    print("✅ File operations working")
    print("✅ JSON operations working")
    print("✅ Environment variables accessible")
    print("=" * 60)

def main():
    """Main function to run all tests."""
    try:
        print_header()
        print_system_info()
        print_environment_vars()
        
        # Test file operations
        test_file = test_file_operations()
        
        # Test JSON operations
        test_data = test_json_operations()
        
        # Print success message
        print_success_message()
        
        # Return the test file name for cleanup
        return test_file
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 
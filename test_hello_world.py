#!/usr/bin/env python3
"""
Test script for hello_world.py
Simple test to verify the Hello World script works correctly.
"""

import subprocess
import sys
import os

def test_hello_world():
    """Test the hello_world.py script."""
    print("🧪 Testing hello_world.py script...")
    
    try:
        # Check if the script exists
        if not os.path.exists("hello_world.py"):
            print("❌ hello_world.py not found")
            return False
            
        # Run the script
        result = subprocess.run([sys.executable, "hello_world.py"], 
                              capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            print("✅ hello_world.py executed successfully")
            print("📄 Output:")
            print(result.stdout)
            return True
        else:
            print("❌ hello_world.py failed with error:")
            print(result.stderr)
            return False
            
    except subprocess.TimeoutExpired:
        print("❌ hello_world.py timed out")
        return False
    except Exception as e:
        print(f"❌ Error testing hello_world.py: {e}")
        return False

def test_python_environment():
    """Test basic Python environment."""
    print("🐍 Testing Python environment...")
    
    try:
        import sys
        import platform
        import datetime
        import json
        import os
        
        print(f"✅ Python version: {sys.version}")
        print(f"✅ Platform: {platform.platform()}")
        print(f"✅ Current time: {datetime.datetime.now()}")
        print(f"✅ Working directory: {os.getcwd()}")
        
        # Test JSON operations
        test_data = {"test": "Hello World"}
        json_str = json.dumps(test_data)
        parsed = json.loads(json_str)
        print(f"✅ JSON operations working: {parsed}")
        
        return True
        
    except Exception as e:
        print(f"❌ Python environment test failed: {e}")
        return False

def main():
    """Main test function."""
    print("🚀 Starting Hello World tests...")
    print("=" * 50)
    
    # Test Python environment
    env_ok = test_python_environment()
    
    # Test hello_world.py script
    script_ok = test_hello_world()
    
    print("=" * 50)
    if env_ok and script_ok:
        print("🎉 All tests passed!")
        print("✅ Python environment is working")
        print("✅ hello_world.py script is working")
        print("✅ Ready for GitHub Actions!")
    else:
        print("❌ Some tests failed")
        if not env_ok:
            print("❌ Python environment issues")
        if not script_ok:
            print("❌ hello_world.py script issues")
        sys.exit(1)

if __name__ == "__main__":
    main() 
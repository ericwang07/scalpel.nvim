
import time
import requests
import sys
import os

# Add current directory to path so we can import from eval.py
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from eval import start_server, kill_process_on_port, kill_process_by_name, wait_for_port_release

def check_server_health():
    try:
        resp = requests.get("http://localhost:3000/health", timeout=1)
        return resp.status_code == 200
    except:
        return False

def run_test_cycle(cycle_num):
    print(f"\n=== Cycle {cycle_num} ===")
    
    # 1. Start Server
    print("Starting server...")
    if not start_server(context_window="512"):
        print("❌ Failed to start server!")
        return False
        
    # 2. Verify Health
    print("Verifying health...")
    if check_server_health():
        print("✅ Server is healthy (Port 3000)")
    else:
        print("❌ Server is unhealthy!")
        return False

    # 3. Kill Server (Simulate end of experiment)
    print("Killing server...")
    kill_process_on_port(3000)
    kill_process_on_port(8081)
    kill_process_by_name("llama-server")
    
    # 4. Verify Cleanup
    print("Verifying cleanup...")
    if wait_for_port_release(3000, timeout=5) and wait_for_port_release(8081, timeout=5):
        print("✅ Ports 3000 and 8081 are free")
    else:
        print("❌ Ports are still in use!")
        return False
        
    return True

def main():
    print("🧪 Starting Server Restart Stress Test")
    
    for i in range(1, 4):
        if not run_test_cycle(i):
            print("\n❌ Test Failed!")
            sys.exit(1)
        time.sleep(2) # Brief pause between cycles
        
    print("\n✅ All cycles passed successfully!")

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Simple World Labs API Example
Generates a 3D world from a text prompt
"""
import os
import requests
import time
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

API_KEY = os.getenv('WORLDLABS_API_KEY')
BASE_URL = 'https://api.worldlabs.ai/marble/v1'

def generate_world(prompt_text, display_name="My World"):
    """Generate a 3D world from text"""
    print(f"🌍 Creating world: {display_name}")
    print(f"📝 Prompt: {prompt_text}\n")
    
    # Start generation
    response = requests.post(
        f'{BASE_URL}/worlds:generate',
        headers={
            'Content-Type': 'application/json',
            'WLT-Api-Key': API_KEY
        },
        json={
            'display_name': display_name,
            'world_prompt': {
                'type': 'text',
                'text_prompt': prompt_text
            }
        }
    )
    
    if response.status_code != 200:
        print(f"❌ Error: {response.text}")
        return None
    
    operation = response.json()
    operation_id = operation['operation_id']
    print(f"✅ Generation started (ID: {operation_id})")
    print("⏳ This usually takes 3-5 minutes...\n")
    
    # Poll for completion
    start_time = time.time()
    while True:
        status_response = requests.get(
            f'{BASE_URL}/operations/{operation_id}',
            headers={'WLT-Api-Key': API_KEY}
        )
        result = status_response.json()
        
        elapsed = int(time.time() - start_time)
        print(f"⏱️  Checking status... ({elapsed}s elapsed)", end='\r')
        
        if result.get('done'):
            print("\n")
            world = result.get('response', {})
            
            # Display results
            print("=" * 60)
            print("🎉 World Generated Successfully!")
            print("=" * 60)
            print(f"View in browser: {world.get('world_marble_url', 'N/A')}")
            print(f"\n3D Files:")
            
            splats = world.get('assets', {}).get('splats', {})
            spz_urls = splats.get('spz_urls', {})
            
            if 'full_res' in spz_urls:
                print(f"  • Full Resolution: {spz_urls['full_res']}")
            if 'low_res' in spz_urls:
                print(f"  • Low Resolution: {spz_urls['low_res']}")
            
            print("=" * 60)
            
            return world
        
        if result.get('error'):
            print(f"\n❌ Error: {result['error']}")
            return None
        
        time.sleep(10)  # Check every 10 seconds


if __name__ == "__main__":
    # Example: Generate a simple world
    world = generate_world(
        prompt_text="A cozy coffee shop with warm lighting and wooden furniture",
        display_name="Cozy Coffee Shop"
    )
    
    if world:
        print("\n💡 Tip: Copy the browser URL above to view your 3D world!")
        print("💡 Or use viewer.html to view the .spz file locally")

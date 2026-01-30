# World Labs API - 3D World Generator

Generate explorable 3D worlds from text prompts using the World Labs API, and view them locally with an interactive Three.js viewer.

## Project Structure

```
deeper-level/
├── generate_world.py   # Generate 3D worlds from text prompts
├── proxy_server.py     # Local server for viewing (handles auth + CORS)
├── viewer.html         # Interactive 3D viewer (SparkJS + Three.js)
├── pyproject.toml      # Python dependencies
└── .env                # API key (not committed)
```

## Setup

1. **Install uv** (if not already installed):
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

2. **Install dependencies**:
   ```bash
   uv sync
   ```

3. **Configure API key** in `.env`:
   ```
   WORLDLABS_API_KEY=your_key_here
   ```

## Usage

### 1. Generate a 3D World

```bash
uv run python generate_world.py
```

This will:
- Send a text prompt to the World Labs API
- Poll for completion (~3-5 minutes)
- Display the browser URL and .spz file URLs

### 2. View the 3D World

**Option A: World Labs Browser (easiest)**
- Click the `world_marble_url` link from the output
- No additional setup needed

**Option B: Local Viewer**

1. Start the proxy server:
   ```bash
   uv run python proxy_server.py
   ```

2. Open in your browser:
   ```
   http://localhost:8000/viewer.html
   ```

3. Paste the `.spz` file URL (Full Resolution link) and click "Load World"

**Viewer Controls:**

| Input | Action |
|-------|--------|
| **Drag** | Rotate camera |
| **Scroll** | Zoom in/out |
| **Right-click drag** | Pan |
| **W / Arrow Up** | Move forward |
| **S / Arrow Down** | Move backward |
| **A / Arrow Left** | Move left |
| **D / Arrow Right** | Move right |
| **E / Page Up** | Move up |
| **Q / Page Down** | Move down |

## Customization

Edit `generate_world.py` to change the prompt:

```python
world = generate_world(
    prompt_text="Your custom prompt here",
    display_name="Your World Name"
)
```

### Example Prompts

- "A cozy coffee shop with warm lighting and wooden furniture"
- "A mystical forest with glowing mushrooms"
- "A modern office space with large windows"
- "A beach sunset with palm trees"
- "A cyberpunk alleyway with neon signs"
- "An ancient temple overgrown with vines"

## Output Formats

The World Labs API generates:

| Format | Description |
|--------|-------------|
| **SPZ** | 3D Gaussian Splat (best quality, ~30MB) |
| **GLB** | Standard 3D mesh (Unity/Unreal compatible) |
| **Panorama** | 360° images |

## Technical Details

- **Viewer**: Uses [SparkJS](https://sparkjs.dev/) with Three.js for rendering 3D Gaussian Splats
- **Proxy Server**: Required because .spz files need API authentication and CORS headers
- **Format**: SPZ is Niantic's open-source compressed Gaussian Splat format

## Troubleshooting

**"Failed to fetch" error in viewer**
- Make sure proxy server is running: `uv run python proxy_server.py`
- Access viewer via `http://localhost:8000/viewer.html` (not file://)

**Generation takes too long**
- World generation typically takes 3-5 minutes
- Check the World Labs dashboard for status

**API key issues**
- Verify `.env` file exists with correct key
- Key format: `WORLDLABS_API_KEY=your_key_here`

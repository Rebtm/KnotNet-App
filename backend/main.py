import os
import sys
import uuid
import socket
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

# Add the knotnet_1 directory to system path
KNOTNET_PATH = "/Users/tom/documents/Github/knotnet_1"
if KNOTNET_PATH not in sys.path:
    sys.path.append(KNOTNET_PATH)

try:
    from knotnet import KnotNetPipeline, PipelineConfig
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from knotnet.stages.preprocessing import preprocess_image
    from knotnet.stages.tokenization import build_tokens
    from knotnet.utils.visualization import _draw_detections, _draw_traversal
except ImportError as e:
    print(f"Error importing knotnet: {e}")
    print("Please make sure knotnet_1 is present at the expected path.")
    raise e

app = FastAPI(
    title="KnotNet iOS Backend",
    description="FastAPI backend serving the KnotNet model pipeline to iOS devices",
    version="1.0.0"
)

# CORS configuration to allow iOS simulator and devices
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Setup directories
BASE_DIR = Path(__file__).resolve().parent
STATIC_DIR = BASE_DIR / "static"
UPLOADS_DIR = STATIC_DIR / "uploads"
RESULTS_DIR = STATIC_DIR / "results"

for d in [STATIC_DIR, UPLOADS_DIR, RESULTS_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# Mount static folder
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

# Initialize pipeline
print("Initializing KnotNet Pipeline (loading weights)...")
config = PipelineConfig(
    deployment_dir=Path(KNOTNET_PATH) / "knotnet_deployment",
    use_skeleton_cache=False, # Disable cache for server to process new requests fresh
    save_visualizations=False
)
pipeline = KnotNetPipeline(config=config)
print("KnotNet Pipeline loaded successfully!")

def get_local_ip():
    """Utility to find local network IP address."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Doesn't have to be reachable, just triggers OS network routing
        s.connect(('8.8.8.8', 1))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

LOCAL_IP = get_local_ip()
PORT = 8000

@app.get("/")
def read_root():
    return {
        "status": "online",
        "pipeline": "KnotGraphNet V5 + YOLOv8/v26",
        "device": str(config.device),
        "local_ip": LOCAL_IP,
        "api_endpoints": {
            "predict": f"http://{LOCAL_IP}:{PORT}/predict",
            "static_files": f"http://{LOCAL_IP}:{PORT}/static/"
        }
    }

def str_or_stringify(val):
    if val is None:
        return ""
    if isinstance(val, (list, tuple)):
        return ", ".join(str(v) for v in val)
    return str(val)

@app.post("/predict")
async def predict_knot(file: UploadFile = File(...)):
    # Validate extension
    ext = Path(file.filename).suffix.lower()
    if ext not in [".jpg", ".jpeg", ".png"]:
        raise HTTPException(
            status_code=400, 
            detail=f"Unsupported file format {ext}. Only JPG, JPEG, and PNG are allowed."
        )

    # Save uploaded file with a unique name
    request_id = str(uuid.uuid4())
    upload_filename = f"{request_id}{ext}"
    upload_path = UPLOADS_DIR / upload_filename

    try:
        contents = await file.read()
        with open(upload_path, "wb") as f:
            f.write(contents)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save upload: {str(e)}")

    # Run the pipeline
    try:
        print(f"Running inference on {upload_filename}...")
        result = pipeline.run(upload_path)
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Inference error: {str(e)}")

    # Create visualizations (Combined, Detection, Traversal)
    viz_filename = f"result_{request_id}.png"
    viz_path = RESULTS_DIR / viz_filename
    det_filename = f"detection_{request_id}.png"
    det_path = RESULTS_DIR / det_filename
    trav_filename = f"traversal_{request_id}.png"
    trav_path = RESULTS_DIR / trav_filename
    
    try:
        pipeline.visualize(result, upload_path, output_path=viz_path)
    except Exception as e:
        print(f"Combined visualization generation failed: {e}")
        viz_filename = None

    try:
        prep = preprocess_image(upload_path, target_full_size=1024, target_model_size=config.img_size)
        if "intermediates" in result and "tokens" in result["intermediates"]:
            tokens = result["intermediates"]["tokens"]
        else:
            tokens = build_tokens(
                result["detections"]["crossings"],
                result["detections"]["endpoints"],
                img_size=config.img_size,
            )

        # Standalone Detection visualization (large)
        fig_det, ax_det = plt.subplots(figsize=(10, 10), facecolor="#0D1117")
        _draw_detections(ax_det, prep["img_full"], result["detections"]["crossings"], result["detections"]["endpoints"])
        plt.tight_layout()
        fig_det.savefig(det_path, dpi=140, bbox_inches="tight", facecolor=fig_det.get_facecolor())
        plt.close(fig_det)

        # Standalone Traversal visualization (large)
        fig_trav, ax_trav = plt.subplots(figsize=(10, 10), facecolor="#0D1117")
        _draw_traversal(
            ax_trav,
            prep["img_small"],
            tokens,
            result.get("sequence", []),
            result["detections"]["crossings"],
            result["detections"]["endpoints"],
            config.img_size,
            result.get("knot_notation", {})
        )
        if not result.get("sequence") or len(result.get("sequence", [])) <= 1:
            ax_trav.text(
                0.5, 0.5,
                "Kein Traversal-Pfad gefunden\n(Seilenden im Bild nicht erkannt)",
                transform=ax_trav.transAxes,
                fontsize=12, color="#FFAA00", fontweight="bold",
                ha="center", va="center",
                bbox=dict(facecolor="#1E1E2E", alpha=0.9, pad=10, edgecolor="#FFAA00")
            )
        plt.tight_layout()
        fig_trav.savefig(trav_path, dpi=140, bbox_inches="tight", facecolor=fig_trav.get_facecolor())
        plt.close(fig_trav)
    except Exception as e:
        print(f"Individual visualization generation failed: {e}")
        import traceback
        traceback.print_exc()
        det_filename = None
        trav_filename = None

    # Construct absolute server URLs
    base_url = f"http://{LOCAL_IP}:{PORT}"
    
    response_data = {
        "id": request_id,
        "raw_image_url": f"{base_url}/static/uploads/{upload_filename}",
        "detection_url": f"{base_url}/static/results/{det_filename}" if det_filename else None,
        "traversal_url": f"{base_url}/static/results/{trav_filename}" if trav_filename else None,
        "visualization_url": f"{base_url}/static/results/{viz_filename}" if viz_filename else None,
        "mode": result.get("mode"),
        "sequence": result.get("sequence", []),
        "crossings_order": result.get("crossings_order", []),
        
        "knot_notation": {
            "compact": result.get("knot_notation", {}).get("compact", ""),
            "full": result.get("knot_notation", {}).get("full", "")
        },
        
        "pd_code": {
            "pd_code_str": result.get("pd_code", {}).get("pd_code_str", ""),
            "writhe": result.get("pd_code", {}).get("writhe", 0)
        },
        
        "topology": {
            "gauss_code": str_or_stringify(result.get("topology", {}).get("gauss_code", "")),
            "dt_notation": str_or_stringify(result.get("topology", {}).get("dt_notation", "")),
            "writhe": result.get("topology", {}).get("writhe", 0),
            "n_crossings": result.get("topology", {}).get("n_crossings", 0),
            "jones_str": result.get("topology", {}).get("jones_str", ""),
        },
        
        "timing": result.get("timing", {})
    }

    # Clean up uploaded raw image to avoid disk bloating if needed, 
    # but keeping it is good for debugging visual comparison in client.
    return response_data

if __name__ == "__main__":
    import uvicorn
    print(f"★ Starting KnotNet iOS Backend on http://{LOCAL_IP}:{PORT} (Accessible on your local Wi-Fi)")
    print(f"★ Please ensure your iOS device is on the same Wi-Fi network!")
    uvicorn.run("main:app", host="0.0.0.0", port=PORT, reload=True)

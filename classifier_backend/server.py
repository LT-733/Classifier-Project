from fastapi import FastAPI, UploadFile, File, Form, Request
from contextlib import asynccontextmanager
import torch
import torchvision.models as tv_models
import io
import NLP, image
import json
from PIL import Image
import tempfile

MODEL = None
ROUTER: NLP.NLProuter = None  # type: ignore

def get_compute_device() -> torch.device:
    # 1. Check for Huawei Ascend NPU
    try:
        import torch_npu
        if torch.npu.is_available():
            return torch.device("npu:0")
    except ImportError:
        pass

    # 2. Check for NVIDIA CUDA GPU
    if torch.cuda.is_available():
        return torch.device("cuda:0")
        
    # 3. Check for Apple Silicon GPU (for local laptop testing)
    elif torch.backends.mps.is_available():
        return torch.device("mps")
        
    # 4. Fallback to CPU
    return torch.device("cpu")

DEVICE = get_compute_device()

@asynccontextmanager
async def lifespan(app: FastAPI):
    global MODEL, ROUTER
    MODEL = tv_models.convnext_tiny(weights="DEFAULT")
    MODEL = MODEL.to(device=DEVICE).half()
    MODEL.eval()

    ROUTER = NLP.NLProuter()

    yield

app = FastAPI(title="Image Classification API", lifespan=lifespan)

@app.post("/predict")
async def predict_item(
    file: UploadFile = File(...),
    zones: str = Form(...)
):
    assert MODEL is not None, "Model not loaded"
    assert ROUTER is not None, "Router not loaded"
    lzones: list[str] = json.loads(zones)
    ROUTER.get_embeddings(zones=lzones) 

    img_bytes = await file.read()
    img = Image.open(io.BytesIO(img_bytes)).convert('RGB')
    with tempfile.NamedTemporaryFile(suffix=".jpg") as tmp:
        img.save(tmp.name)
        results = image.identification(model=MODEL, imgPath=tmp.name, device=DEVICE)
    # img.save(temp_path)

    # results = image.identification(model=MODEL, imgPath=temp_path, device=DEVICE)
    if results == "unknown":
        return {'status': 'cannot identify', 'message': 'why your camera so chopped lil bro'}
    target_zone = ROUTER.assign_outputs(item=results)
    return {
        "status": "success",
        "item": results,
        "assigned_zone": target_zone
    }

if __name__ == "__main__":
    import uvicorn
    # This exposes the server to your local network on port 8000
    print("Starting your image inference backend server...")
    uvicorn.run(app, host="0.0.0.0", port=7860)
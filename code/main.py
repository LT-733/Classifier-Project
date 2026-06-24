import image, NLP
import torchvision
import torchvision.models as tv_models
import torch
import os
import glob
import torch

# 1. Try to safely import torch_npu if available
try:
    import torch_npu
    HAS_NPU = True
except ImportError:
    HAS_NPU = False


def main():
    model = tv_models.resnet50(weights="DEFAULT")
    # 1. Check for Huawei Ascend NPU
    if HAS_NPU and torch.npu.is_available():
        device = torch.device("npu:0")
    # 2. Check for NVIDIA CUDA GPU
    elif torch.cuda.is_available():
        device = torch.device("cuda:0")
    # 3. Check for Apple Silicon GPU (if you ever test on a Mac laptop)
    elif torch.backends.mps.is_available():
        device = torch.device("mps")
    # 4. Fallback to CPU
    else:
        device = torch.device("cpu")

    print(f"Active compute hardware: {device}")
    # print(device)
    model = model.to(device=device).half()
    zone_names = []
    x = ""
    while True:
        x = str(input("Provide names for your item zones. Press Q to quit:"))
        if x.lower() == 'q':
            break
        zone_names.append(x)
    path_exts = ("*.jpg", "*.jpeg", "*.JPG", "*.JPEG", "*.png")
    paths = []
    current_dir = os.path.dirname(os.path.abspath(__file__))
    path_dir = os.path.join(current_dir, "..", "imgs")
    for ext in path_exts:
        paths.extend(glob.glob(os.path.join(path_dir, ext)))
    
    if not paths:
        print(f"No images found in {path_dir}")
        return
    router = NLP.NLProuter()
    router.get_embeddings(zone_names)
    for path in sorted(paths):
        results = image.identification(model=model, imgPath=path, device=device)
        if results == "unknown":
            print("The image lowkey chopped. Get a better camera lil bro, ML ain't helping you with this one. Skipped.")
            continue
        zone = router.assign_outputs(results)
        print(results)
        print(f"looks like {results} belongs to: {zone}!")

if __name__ == "__main__":
    main()
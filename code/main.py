import image, NLP
import torchvision
import torchvision.models as tv_models
import torch
import os
import glob

def main():
    model = tv_models.resnet50(weights="DEFAULT")
    device = torch.device("npu:0" if torch.npu.is_available() else "cpu")
    print(device)
    model = model.to(device=device).half()
    zone_names = []
    x = ""
    while True:
        x = str(input("Provide names for your item zones. Press Q to quit:"))
        if x.lower() == 'q':
            break
        zone_names.append(x)
    path_dir = "/home/HwHiAiUser/Developer/Classifier_project/imgs/"
    path_exts = ("*.jpg", "*.jpeg", "*.JPG", "*.JPEG", "*.png")
    paths = []
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
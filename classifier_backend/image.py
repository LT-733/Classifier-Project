import torch
import torch.nn as nn
import torch.optim as optim
import torchvision.models as tv_models
import torchvision.transforms as transforms
import numpy as np
# import torch_npu
from PIL import Image

def imageprep(imgPath: str):
    transform = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(mean= [0.485, 0.456, 0.406], std= [0.229, 0.224, 0.225])    
    ])
    i = Image.open(imgPath).convert("RGB")
    i = transform(i)
    i = i.unsqueeze(0) # type: ignore 
    # gotta give it a batch number
    return i


def identification(model, imgPath: str, device):
    model.eval()
    with torch.no_grad():
        inTensor = imageprep(imgPath=imgPath)
        inTensor = inTensor.to(device).half()
        output = model(inTensor)
        result = torch.argmax(output, dim=1).item()
        possibilities = torch.softmax(output, dim=1)
        max_prob, _ = torch.max(possibilities, dim=1)
        # if(max_prob.item() <= 0.25):
        #     return "unknown"
        weights = tv_models.ConvNeXt_Tiny_Weights.DEFAULT
        categories = weights.meta["categories"]
        predicted_output = categories[result]
        return predicted_output



# if __name__ == "__main__":
#     main()
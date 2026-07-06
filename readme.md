# This is a ML project with pre-trained models deployed on Huggingface Spaces and a concurrent request handling server deployed on Railway
Mostly because I am lazy and don't want to train my own model.
The user can either upload a photo on their computer or take a photo using their phone to get an image into the model, and the user also gets to choose what zones they are classifing their items into, then the model will return the item it recognized, the result of the inference will be takin by a Natural Language Processing model to an embedding, which will be used to calculate what the similarity score between the item name and each provided zone is, and it will eventually return where the item belongs to. 

Check out the public website on https://classifier-project.pages.dev now!

This is what the website looks like:
<img width="1512" height="859" alt="image" src="https://github.com/user-attachments/assets/af552dee-0d8b-4dcf-964b-c63e5bb2d03f" />


## Remember: if you want to try out the source files yourself, run `pip install -r requirements.txt` first!

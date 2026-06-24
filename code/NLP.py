import os
import requests
# os.environ["HF_HUB_OFFLINE"] = "1"
# os.environ["TRANSFORMERS_OFFLINE"] = "1"
from sentence_transformers import util, SentenceTransformer
import torch

class NLProuter():
    def __init__(self) -> None:
        """constructor for the class, initializes the transformer, the list for the item zones, and the embeddings placeholder."""
        current_dir = os.path.dirname(os.path.abspath(__file__))
        local_path = os.path.join(current_dir, "..", "models", "all-MiniLM-L6-v2")
        remote_path = "sentence-transformers/all-MiniLM-L6-v2"
        if os.path.isdir(local_path) and os.listdir(local_path):
            try:
                self.model = SentenceTransformer(model_name_or_path=local_path)
            except Exception as e:
                print(f"Error trying to use local model, but the model is found: {e}")
        else:
            print("local model not found, moving to remote.")
        if not hasattr(self, "model"):
            print("trying remote model.")
            try:
                self.model = SentenceTransformer(model_name_or_path=remote_path)
            except (requests.exceptions.HTTPError) as HTTPerror:
                print(f"internet is here, but Hugging Face threw an error: {HTTPerror} \n likely because the connection cannot be established?")
                raise SystemExit("Exiting: Remote model asset registry unreachable.")
            except (requests.exceptions.Timeout, requests.exceptions.ConnectionError) as internetError:
                print(f"Internet is not connected or the request took too long: {internetError}\n maybe check your device's network connection?")
                raise SystemExit("Exiting: Missing local assets and no internet connectivity.")
            except Exception as e:
                print(f"Error finding remote path: {e}")
                raise e
        self.zone_names = []
        self.zone_embeddings = None
    
    def get_embeddings(self, zones: list):
        """Assign the zones from the users to the zone_names list and encode those zones to embeddings
        making them ready for cosine similarity calculations."""
        self.zone_names = zones
        if zones:
            self.zone_embeddings = self.model.encode(self.zone_names, convert_to_tensor=True)
    
    def assign_outputs(self, item: str, threashold=0.25):
        """Use cosine similarity scores between the item and the user-given zones to decide which zone the item belongs to, returning a string which is one of the user-given zones."""
        if self.zone_embeddings is None or not self.zone_names:
            return "default zone"
        item_vector = self.model.encode(item, convert_to_tensor=True)
        similarity_score = util.cos_sim(item_vector, self.zone_embeddings)
        # shape of the similarity score should be 1 by #zones
        max_scores, max_idx = torch.max(similarity_score, dim=1)
        max_score = max_scores.item()
        max_idx = int(max_idx.item())
        if max_score < threashold:
            return "unknown"
        return self.zone_names[max_idx]

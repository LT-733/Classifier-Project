import os
os.environ["HF_HUB_OFFLINE"] = "1"
os.environ["TRANSFORMERS_OFFLINE"] = "1"
from sentence_transformers import util, SentenceTransformer
import torch

class NLProuter():
    def __init__(self) -> None:
        """constructor for the class, initializes the transformer, the list for the item zones, and the embeddings placeholder."""
        self.model = SentenceTransformer(model_name_or_path="/home/HwHiAiUser/Developer/Classifier_project/models/all-MiniLM-L6-v2")
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

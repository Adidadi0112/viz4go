from collections import Counter
from venv import logger
from flask import Blueprint, request, jsonify
from utils import clusters_by_shared_go
from data_store import get_store
from utils import clusters_by_semantic_similarity

cluster_bp = Blueprint("clusters", __name__)

@cluster_bp.route('/protein', methods=['POST'])
def cluster_protein():
    """
    Body (JSON):
    {
      "protein_to_go": { "P1": ["GO:...","GO:..."], ... },
      "algo": "louvain" | "connected",
      "mode": "semantic" | "shared_go",
      # shared_go:
      "min_shared": 3,
      # semantic:
      "measure": "wang" | "resnik" | "lin",
      "threshold": 0.6,     # albo
      "knn": null,          # np. 8
      "resolution": 1.0
    }
    """
    data = request.get_json(force=True, silent=True) or {}
    protein_to_go = data.get("protein_to_go") or {}
    if not protein_to_go:
        return jsonify({"error": "protein_to_go is required"}), 400

    algo = data.get("algo", "louvain")
    mode = data.get("mode", "shared_go")

    if mode == "semantic":
        measure = data.get("measure", "wang")
        threshold = data.get("threshold")  # może być None
        knn = data.get("knn")              # może być None
        resolution = float(data.get("resolution", 1.0))
        store = get_store()
        clusters = clusters_by_semantic_similarity(
            store.graph,
            protein_to_go,
            method=measure,
            algo=algo,
            threshold=threshold,
            knn=knn,
            resolution=resolution,
        )
        return jsonify({"clusters": clusters})

    # fallback: shared_go (obecny tryb)
    min_shared = int(data.get("min_shared", 3))
    clusters = clusters_by_shared_go(
        protein_to_go,
        min_shared=min_shared,
        algo=algo,
        resolution=float(data.get("resolution", 1.0)),
    )
    return jsonify({"clusters": clusters})



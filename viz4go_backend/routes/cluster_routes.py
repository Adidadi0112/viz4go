from collections import Counter
from venv import logger
from flask import Blueprint, request, jsonify
from utils import clusters_by_shared_go

cluster_bp = Blueprint("clusters", __name__)

@cluster_bp.route("/protein", methods=["POST"])
def protein_clusters():
    data = request.get_json()
    mapping = clusters_by_shared_go(
        data["protein_to_go"],
        min_shared=data.get("min_shared", 3),
        algo=data.get("algo", "connected"),
        resolution=data.get("resolution", 1.0)
    )
    logger.info("Louvain res=%.2f  %d clusters  sizes=%s",
                data.get("resolution",1.0),
                len(set(mapping.values())),
                Counter(mapping.values()))
    return jsonify({"clusters": mapping})


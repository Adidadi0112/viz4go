import networkx as nx
from typing import Iterable, List, Tuple, Union
from networkx.algorithms.community import louvain_communities

def check_all_shortest_paths(graph, ontology_ids):
    found_paths_with_relations = []
    for i, node1 in enumerate(ontology_ids):
        for node2 in ontology_ids[i+1:]:
            if nx.has_path(graph, node1, node2):
                path = nx.shortest_path(graph, node1, node2)
                path_with_relations = []
                
                for j in range(len(path) - 1):
                    start_node = path[j]
                    end_node = path[j + 1]
                    relations = graph[start_node][end_node]
                    relation_type = next(iter(relations), None)
                    path_with_relations.append((start_node, end_node, relation_type))
                
                found_paths_with_relations.append(path_with_relations)
             
    return found_paths_with_relations

def get_connections(
    G: nx.DiGraph,
    start_nodes: Union[str, Iterable[str]],
    direction: str = "up",        # "up" = do rodziców (ancestors), "down" = do dzieci (descendants)
    max_depth: int | None = None,  # np. 3, żeby nie rozjechać się na cały DAG
) -> List[Tuple[str, str, str]]:
    """
    Zwraca listę krawędzi (source, target, rel_type) odwiedzonych węzłów,
    zaczynając od start_nodes. Dla direction="up" idziemy do rodziców (pred),
    dla "down" do dzieci (succ). rel_type pochodzi z atrybutu krawędzi 'type'
    (np. 'is_a', 'part_of').

    Uwaga: w naszym grafie krawędź jest skierowana PARENT -> CHILD.
    Dla 'up' będziemy zwracać krawędzie jako (current, parent, type),
    dla 'down' jako (current, child, type).
    """
    if isinstance(start_nodes, str):
        stack = [(start_nodes, 0)]
    else:
        stack = [(s, 0) for s in start_nodes]

    visited = set()
    edges: List[Tuple[str, str, str]] = []

    while stack:
        node, depth = stack.pop()
        if node in visited:
            continue
        visited.add(node)

        if max_depth is not None and depth >= max_depth:
            continue

        if direction == "up":
            # rodzice: pred -> node (edge: pred -> node)
            for pred in G.predecessors(node):
                rel_type = G[pred][node].get("type", "")
                edges.append((node, pred, rel_type))   # (current, parent)
                stack.append((pred, depth + 1))
        else:
            # dzieci: node -> succ (edge: node -> succ)
            for succ in G.successors(node):
                rel_type = G[node][succ].get("type", "")
                edges.append((node, succ, rel_type))   # (current, child)
                stack.append((succ, depth + 1))

    return edges

def clusters_by_shared_go(protein_to_go: dict[str, list[str]],
                          min_shared: int = 3,
                          algo: str = "connected",
                          resolution=1.0) -> dict[str, int]:
    """
    Zwraca mapping: protein_id -> cluster_id.
    *min_shared*  – minimalna liczba wspólnych GO-termów,
    *algo*        – "connected" (składowe spójne) lub "louvain".
    """
    G = nx.Graph()
    proteins = list(protein_to_go.keys())
    for i, p1 in enumerate(proteins):
        terms1 = set(protein_to_go[p1])
        for p2 in proteins[i + 1:]: 
            common = terms1.intersection(protein_to_go[p2])
            w = len(common)
            if w >= min_shared:
                G.add_edge(p1, p2, weight=w)

    clusters = {}
    if algo == "louvain":
        comms = louvain_communities(G, weight="weight", resolution=resolution)
        for cid, comm in enumerate(comms):
            for p in comm:
                clusters[p] = cid
    else:                       
        for cid, component in enumerate(nx.connected_components(G)):
            for p in component:
                clusters[p] = cid

    unassigned = set(proteins) - clusters.keys()
    next_id = max(clusters.values(), default=-1) + 1
    for p in unassigned:
        clusters[p] = next_id
        next_id += 1
    return clusters


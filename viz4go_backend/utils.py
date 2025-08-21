import networkx as nx
import pandas as pd
from collections import defaultdict
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

def get_connections(df, start_nodes):
    connections = []
    visited = set()
    stack = start_nodes

    print(f"Initial stack nodes: {start_nodes}")
    
    while stack:
        current_node = stack.pop()
        print(f"\nPopped node from stack: {current_node}")
        
        if current_node in visited:
            print(f"Node {current_node} already visited, skipping.")
            continue
        visited.add(current_node)
        
        row = df.loc[df['id'] == current_node]
        if row.empty:
            print(f"No data found for node: {current_node}")
            continue
        print(f"Row data for {current_node}: {row}")

        is_a_values = row['is_a'].values[0]
        if isinstance(is_a_values, list) or isinstance(is_a_values, str):
            print(f"Found 'is_a' relationships for {current_node}: {is_a_values}")
            if isinstance(is_a_values, str):
                is_a_values = eval(is_a_values)  # Converts string representation of a list to an actual list
            for target_node in is_a_values:
                connections.append((current_node, target_node, 'is_a'))
                stack.append(target_node)
        else:
            print(f"No 'is_a' relationships for {current_node}")

        relationship_values = row['relationship'].values[0]
        if isinstance(relationship_values, list) or isinstance(relationship_values, str):
            print(f"Found 'relationship' values for {current_node}: {relationship_values}")
            if isinstance(relationship_values, str):
                relationship_values = eval(relationship_values)  # Converts string representation of a list to an actual list
            for relationship in relationship_values:
                parts = relationship.split(' ')
                if len(parts) == 2:
                    rel_type, target_node = parts
                    connections.append((current_node, target_node, rel_type))
                    stack.append(target_node)
                    print(f"Added connection: ({current_node}, {target_node}, {rel_type})")
                else:
                    print(f"Warning: unexpected relationship format '{relationship}' for node {current_node}")
        else:
            print(f"No 'relationship' values for {current_node}")
    
    print(f"\nFinal connections: {connections}")
    return connections

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


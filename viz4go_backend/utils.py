import networkx as nx
import pandas as pd

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

def get_connections(df, start_node):
    connections = []
    visited = set()
    stack = [start_node]

    while stack:
        current_node = stack.pop()
        if current_node in visited:
            continue
        visited.add(current_node)
        
        row = df.loc[df['id'] == current_node]
        if row.empty:
            continue
        
        is_a_values = row['is_a'].values[0]
        if type(is_a_values) != float:
            for target_node in is_a_values:
                connections.append((current_node, target_node, 'is_a'))
                stack.append(target_node)
        
        relationship_values = row['relationship'].values[0]
        if type(relationship_values) != float:
            for relationship in relationship_values:
                rel_type, target_node = relationship.split(' ')
                connections.append((current_node, target_node, rel_type))
                stack.append(target_node)
    
    return connections

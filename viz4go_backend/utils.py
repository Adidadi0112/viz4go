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

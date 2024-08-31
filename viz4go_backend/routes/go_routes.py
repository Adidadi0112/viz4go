from flask import Blueprint, jsonify, request
from config import get_db_connection, graph
from utils import check_all_shortest_paths, get_connections
import pandas as pd

go_bp = Blueprint('go', __name__)

# Trasa do wyszukiwania GO termów po ID
@go_bp.route('/term/<term_id>', methods=['GET'])
def get_go_term(term_id):
    conn = get_db_connection()
    term = conn.execute('SELECT * FROM go_terms WHERE id = ?', (term_id,)).fetchone()
    conn.close()
    
    if term is None:
        return jsonify({'error': 'Term not found'}), 404
    
    term_dict = {k: term[k] for k in term.keys()}
    return jsonify(term_dict)

@go_bp.route('/terms', methods=['POST'])
def get_go_terms():
    term_ids = request.json.get('term_ids')

    if not term_ids:
        return jsonify({'error': 'No term IDs provided'}), 400

    conn = get_db_connection()
    placeholders = ','.join('?' for _ in term_ids)
    query = f'SELECT * FROM go_terms WHERE id IN ({placeholders})'
    terms = conn.execute(query, term_ids).fetchall()
    conn.close()

    if not terms:
        return jsonify({'error': 'No terms found for the given IDs'}), 404

    terms_list = [{k: term[k] for k in term.keys()} for term in terms]
    print(terms_list)
    return jsonify(terms_list)



# Trasa do sprawdzania najkrótszych ścieżek
'''
example
curl -X POST http://127.0.0.1:5000/api/go/paths \
-H "Content-Type: application/json" \
-d '{"ontology_ids": ["GO:0030126", "GO:0030663", "GO:0030594"]}'
'''
@go_bp.route('/paths', methods=['POST'])
def get_paths():
    data = request.json
    ontology_ids = data.get('ontology_ids')
    
    if not ontology_ids:
        return jsonify({'error': 'No ontology IDs provided'}), 400
    
    paths_with_relations = check_all_shortest_paths(graph, ontology_ids)
    
    return jsonify({'paths': paths_with_relations})

'''
example
curl -X POST http://127.0.0.1:5000/api/go/connections \
-H "Content-Type: application/json" \
-d '{"start_node": "GO:0030126"}'
'''
@go_bp.route('/connections', methods=['POST'])
def get_node_connections():
    data = request.json
    start_node = data.get('start_node')
    print(start_node)
    if not start_node:
        return jsonify({'error': 'No start node provided'}), 400
    
    conn = get_db_connection()
    nodes_df = pd.read_csv('go_nodes.csv')
    conn.close()
    
    connections = get_connections(nodes_df, start_node)
    
    return jsonify(connections)

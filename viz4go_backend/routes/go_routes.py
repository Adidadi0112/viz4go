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

@go_bp.route('/connections_csv', methods=['POST'])
def get_node_connections_csv():
    # Pobranie wartości score z requestu, z domyślną wartością 0.4
    score_threshold = float(request.form.get('score', 0.4))

    # Sprawdzenie, czy przesłano jakiekolwiek pliki CSV
    if 'file1' not in request.files and 'file2' not in request.files and 'file3' not in request.files:
        return jsonify({'error': 'No CSV files were uploaded'}), 400

    # Odczytanie wszystkich przesłanych plików CSV (może być od 1 do 3)
    uploaded_files = []
    for file_key in ['file1', 'file2', 'file3']:
        file = request.files.get(file_key)
        if file:
            uploaded_files.append(file)

    # Przekazanie informacji zwrotnej, ile plików wczytano
    print(f"Number of uploaded CSV files: {len(uploaded_files)}")

    # Wczytanie zawartości przesłanych plików CSV do listy i połączenie ich w jeden DataFrame
    dfs = []
    for idx, file in enumerate(uploaded_files):
        try:
            df = pd.read_csv(file)
            dfs.append(df)
        except Exception as e:
            return jsonify({'error': f'Failed to read file {file.filename}: {str(e)}'}), 500

    # Połączenie wszystkich DataFrame'ów w jeden
    combined_df = pd.concat(dfs, ignore_index=True)

    # Sprawdzenie struktury połączonego DataFrame
    print("Combined DataFrame:")
    print(combined_df)

    # Usunięcie powielonych kolumn, jeśli występują (na podstawie nazw)
    combined_df = combined_df.loc[:, ~combined_df.columns.duplicated()]

    # Filtrowanie DataFrame na podstawie progu `score`
    filtered_df = combined_df[combined_df['Score'] >= score_threshold]

    print("Combined DataFrame:")
    print(filtered_df)

    # Tworzenie mapy białek do powiązanych z nimi GO termów
    protein_to_go_terms = {}
    for _, row in filtered_df.iterrows():
        protein = row['Protein']
        go_term = row['GO_term/EC_number']

        # Dodanie GO termu do listy, jeżeli białko istnieje w mapie
        if protein in protein_to_go_terms:
            protein_to_go_terms[protein].append(go_term)
        else:
            # Inicjalizacja listy GO termów dla nowego białka
            protein_to_go_terms[protein] = [go_term]

    # Wczytanie go_nodes.csv jako DataFrame, aby przekazać go do funkcji get_connections
    nodes_df = pd.read_csv('go_nodes.csv')

    # Zastosowanie funkcji get_connections do każdego białka i jego listy GO termów
    for protein, go_terms in protein_to_go_terms.items():
        print(f"\nProcessing protein: {protein} with GO terms: {go_terms}")

        # Wywołanie funkcji get_connections na liście GO termów
        connections = get_connections(nodes_df, go_terms)

        # Nadpisanie wartości białka w mapie `protein_to_go_terms` wynikami `get_connections`
        protein_to_go_terms[protein] = connections

    # Wypisanie zmodyfikowanej mapy
    print(f"\nFinal protein-to-connections map: {protein_to_go_terms}")

    # Zwrot mapy jako odpowiedź API
    return jsonify(protein_to_go_terms)


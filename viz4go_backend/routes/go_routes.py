from flask import Blueprint, jsonify, request


import pandas as pd

from data_store import get_store
from utils import check_all_shortest_paths, get_connections

go_bp = Blueprint('go', __name__)

# Trasa do wyszukiwania GO termów po ID
@go_bp.route('/term/<term_id>', methods=['GET'])
def get_go_term(term_id):
    store = get_store()
    row = store.get_term_row(term_id)
    if row is None:
        return jsonify({'error': 'Term not found'}), 404
    return jsonify(row)

@go_bp.route('/terms', methods=['POST'])
def get_go_terms():
    term_ids = request.json.get('term_ids')

    if not term_ids:
        return jsonify({'error': 'No term IDs provided'}), 400

    store = get_store()
    terms = [store.get_term_row(term_id) for term_id in term_ids]
    terms = [term for term in terms if term is not None]

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
    store = get_store()
    data = request.json or {}
    ids = data.get('ontology_ids') or []
    if not ids:
        return jsonify({'error': 'No ontology IDs provided'}), 400

    result = check_all_shortest_paths(store.graph, ids)
    return jsonify({'paths': result})

@go_bp.route('/connections_csv', methods=['POST'])
def get_node_connections_csv():
    """
    Przyjmuje 1–3 plików CSV (file1..file3) z kolumnami:
      - 'Protein'
      - 'GO_term/EC_number'
      - (opcjonalnie) 'Score' – filtr po progu

    Parametry (form-data):
      - score: float (domyślnie 0.4)
      - direction: 'up'|'down' (domyślnie 'up')
      - max_depth: int (domyślnie brak limitu)
      - edge_types: np. 'is_a,part_of' (domyślnie oba)
      - fail_on_missing: 'true'|'false' (domyślnie 'false')
    """
    import re
    score_threshold = float(request.form.get('score', 0.4))
    direction = (request.form.get('direction', 'up') or 'up').lower()
    if direction not in ('up', 'down'):
        return jsonify({'error': "Invalid 'direction'. Use 'up' or 'down'."}), 400

    max_depth_raw = request.form.get('max_depth')
    try:
        max_depth = int(max_depth_raw) if max_depth_raw is not None else None
    except ValueError:
        return jsonify({'error': "Invalid 'max_depth'. Must be integer."}), 400

    edge_types_raw = request.form.get('edge_types', 'is_a,part_of')
    edge_types = {t.strip() for t in edge_types_raw.split(',') if t.strip()}

    fail_on_missing = str(request.form.get('fail_on_missing', 'false')).lower() == 'true'

    files_present = any(k in request.files for k in ('file1', 'file2', 'file3'))
    if not files_present:
        return jsonify({'error': 'No CSV files were uploaded'}), 400

    # ---- wczytanie CSV ----
    dfs = []
    for key in ('file1', 'file2', 'file3'):
        f = request.files.get(key)
        if not f:
            continue
        try:
            df = pd.read_csv(f)
            dfs.append(df)
        except Exception as e:
            return jsonify({'error': f'Failed to read file {getattr(f, "filename", key)}: {str(e)}'}), 500

    if not dfs:
        return jsonify({'error': 'No valid CSV parsed'}), 400

    combined_df = pd.concat(dfs, ignore_index=True)
    combined_df = combined_df.loc[:, ~combined_df.columns.duplicated()]

    # ---- kolumny obowiązkowe ----
    required_cols = {'Protein', 'GO_term/EC_number'}
    missing_cols = required_cols - set(combined_df.columns)
    if missing_cols:
        return jsonify({'error': f"Missing columns: {', '.join(sorted(missing_cols))}"}), 400

    # ---- filtr Score (jeśli jest) ----
    if 'Score' in combined_df.columns:
        scores = pd.to_numeric(combined_df['Score'], errors='coerce')
        combined_df = combined_df.loc[scores >= score_threshold]

    # ---- normalizacja GO ID ----
    go_pat = re.compile(r'^GO:(\d+)$')
    def normalize_go_id(raw) -> str | None:
        s = str(raw).strip().upper().replace(' ', '')
        if not s.startswith('GO:'):
            return None
        m = go_pat.match(s)
        if m:
            # zero-padding do 7 cyfr
            return f"GO:{int(m.group(1)):07d}"
        # fallback: wyłuskaj cyfry po 'GO:'
        digits = ''.join(ch for ch in s[3:] if ch.isdigit())
        if digits:
            return f"GO:{int(digits):07d}"
        return None

    # ---- budowa mapy protein -> lista GO (tylko poprawne GO:xxxxxxx) ----
    protein_to_go_terms: dict[str, list[str]] = {}
    for _, row in combined_df.iterrows():
        protein = str(row['Protein']).strip()
        go_val = normalize_go_id(row['GO_term/EC_number'])
        if not go_val:
            continue
        protein_to_go_terms.setdefault(protein, []).append(go_val)

    # deduplikacja
    for p in list(protein_to_go_terms.keys()):
        protein_to_go_terms[p] = sorted(set(protein_to_go_terms[p]))

    # ---- graf + filtrowanie do istniejących węzłów ----
    store = get_store()
    G = store.graph

    result = {}
    all_missing = {}

    for protein, go_terms in protein_to_go_terms.items():
        # podziel na te, które są w grafie i brakujące
        present = [t for t in go_terms if t in G]
        missing = sorted(set(go_terms) - set(present))

        if fail_on_missing and missing:
            return jsonify({
                'error': 'Some GO terms are not in the graph.',
                'protein': protein,
                'missing_terms': missing
            }), 400

        # policz połączenia tylko od istniejących
        edges = []
        if present:
            edges = get_connections(
                G,
                start_nodes=present,
                direction=direction,
                max_depth=max_depth
            )
            # filtr typów krawędzi
            if edge_types:
                edges = [e for e in edges if not e[2] or e[2] in edge_types]
            # deduplikacja
            edges = list(dict.fromkeys(edges))

        result[protein] = {
            "edges": edges,
            "missing_terms": missing
        }
        if missing:
            all_missing[protein] = missing

    # Możesz też dodać pole zbiorcze z liczbą braków do szybkiego debugowania
    response = {
        "proteins": result,
        "summary": {
            "proteins_count": len(result),
            "with_missing": len(all_missing),
            "total_missing_terms": sum(len(v) for v in all_missing.values())
        }
    }
    return jsonify(response)



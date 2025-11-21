# similarity.py (twoja lokalna wersja)
from collections import Counter
import math
import networkx as nx

# Zamiennik wyjątków z pygosemsim
class PGSSLookupError(KeyError):
    pass

# --- helpers ---

def _require_lower_bounds(G):
    if not hasattr(G, "lower_bounds"):
        raise RuntimeError(
            "lower_bounds not computed. Call precalc_lower_bounds(G) once after building the GO graph."
        )

# --- precompute ---

def precalc_lower_bounds(G):
    """Pre-calculate the number of lower bounds (descendants incl. self) for each node."""
    G.lower_bounds = Counter()
    for n in G:
        G.lower_bounds[n] += 1
        for ans in nx.ancestors(G, n):
            G.lower_bounds[ans] += 1
    # opcjonalnie: flaga w G.graph (nieobowiązkowe)
    flags = G.graph.setdefault("pgss_flags", set())
    flags.add("lower_bounds_ready")

# --- IC / LCA ---

def information_content(G, term):
    _require_lower_bounds(G)
    if term not in G.lower_bounds:
        raise PGSSLookupError(f"Missing term: {term}")
    freq = G.lower_bounds[term] / len(G)
    return round(-1 * math.log2(freq), 3)

def lowest_common_ancestor(G, term1, term2):
    _require_lower_bounds(G)
    if term1 not in G:
        raise PGSSLookupError(f"Missing term: {term1}")
    if term2 not in G:
        raise PGSSLookupError(f"Missing term: {term2}")
    lb1 = nx.ancestors(G, term1) | {term1}
    lb2 = nx.ancestors(G, term2) | {term2}
    common_ans = lb1 & lb2
    if not common_ans:
        return None
    # najmniejsza liczba potomków (najbardziej specyficzny) → MICA
    return min(common_ans, key=lambda x: G.lower_bounds[x])

def resnik(G, term1, term2):
    mica = lowest_common_ancestor(G, term1, term2)
    if mica is not None:
        return information_content(G, mica)

def norm_resnik(G, term1, term2):
    max_ic = -1 * math.log2(1 / len(G))
    res = resnik(G, term1, term2)
    if res is None:
        return None
    return round(res / max_ic, 3)

def lin(G, term1, term2):
    ic1 = information_content(G, term1)
    ic2 = information_content(G, term2)
    ic_lca = resnik(G, term1, term2)
    try:
        return round(2 * ic_lca / (ic1 + ic2), 3)
    except (TypeError, ZeroDivisionError):
        return None

# --- Wang ---

default_wf = (("is_a", 0.8), ("part_of", 0.6))

def s_values(G, term, weight_factor=default_wf):
    if term not in G:
        raise PGSSLookupError(f"Missing term: {term}")
    wf = dict(weight_factor)
    sv = {term: 1.0}
    visited = set()
    level = {term}
    while level:
        visited |= level
        next_level = set()
        for n in level:
            # Uwaga: dla DAG kierunek ma znaczenie: krawędź parent -> child
            for pred, edge in G.pred[n].items():
                weight = sv[n] * wf.get(edge.get("type", ""), 0.0)
                if pred not in sv or weight > sv[pred]:
                    sv[pred] = weight
                if pred not in visited:
                    next_level.add(pred)
        level = next_level
    return {k: round(v, 3) for k, v in sv.items()}

def wang(G, term1, term2, weight_factor=default_wf):
    if term1 not in G:
        raise PGSSLookupError(f"Missing term: {term1}")
    if term2 not in G:
        raise PGSSLookupError(f"Missing term: {term2}")
    sa = s_values(G, term1, weight_factor)
    sb = s_values(G, term2, weight_factor)
    sva = sum(sa.values())
    svb = sum(sb.values())
    common = set(sa.keys()) & set(sb.keys())
    cv = sum(sa[c] + sb[c] for c in common)
    return round(cv / (sva + svb), 3) if (sva + svb) else None

# --- Pekar (opcjonalne) ---

def pekar(G, term1, term2):
    _require_lower_bounds(G)
    mica = lowest_common_ancestor(G, term1, term2)
    if mica is None:
        return None
    ac = nx.shortest_path_length(G, source=mica, target=term1)
    bc = nx.shortest_path_length(G, source=mica, target=term2)
    root = max(nx.ancestors(G, mica), key=lambda x: G.lower_bounds[x], default=mica)
    rootc = nx.shortest_path_length(G, source=root, target=mica)
    try:
        return round(rootc / (ac + bc + rootc), 3)
    except ZeroDivisionError:
        return None

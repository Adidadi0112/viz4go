import networkx as nx
from typing import Iterable, List, Tuple, Union
from networkx.algorithms.community import louvain_communities
from similarity import resnik, lin, wang

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
    proteins = list(protein_to_go.keys())
    
    print(f"\n{'='*80}")
    print(f"🧬 KLASTERYZACJA SHARED_GO - START")
    print(f"{'='*80}")
    print(f"📊 Parametry:")
    print(f"   - Liczba białek: {len(proteins)}")
    print(f"   - Min wspólnych terminów: {min_shared}")
    print(f"   - Algorytm klasteryzacji: {algo}")
    print(f"   - Resolution: {resolution}")
    print(f"\n📋 GO-terminy dla każdego białka:")
    for p in proteins:
        terms = protein_to_go[p]
        print(f"   {p}: {terms} ({len(terms)} terminów)")
    
    print(f"\n🕸️  Budowanie grafu białek...")
    G = nx.Graph()
    edges_added = []
    
    for i, p1 in enumerate(proteins):
        terms1 = set(protein_to_go[p1])
        for p2 in proteins[i + 1:]: 
            terms2 = set(protein_to_go[p2])
            common = terms1.intersection(terms2)
            w = len(common)
            if w >= min_shared:
                G.add_edge(p1, p2, weight=w)
                edges_added.append((p1, p2, w, list(common)))

    print(f"\n🔗 UTWORZONE KRAWĘDZIE ({len(edges_added)} połączeń):")
    if edges_added:
        edges_added.sort(key=lambda x: x[2], reverse=True)  # sortuj po liczbie wspólnych
        for p1, p2, weight, common_terms in edges_added:
            print(f"   {p1} ←→ {p2}: {weight} wspólnych terminów")
            print(f"      → {common_terms}")
    else:
        print(f"   ⚠️  Brak krawędzi! Wszystkie białka będą w osobnych klastrach.")

    print(f"\n📊 Statystyki grafu:")
    print(f"   - Węzły: {G.number_of_nodes()}")
    print(f"   - Krawędzie: {G.number_of_edges()}")
    if G.number_of_nodes() > 1:
        print(f"   - Gęstość: {nx.density(G):.3f}")
        print(f"   - Składowe spójne: {nx.number_connected_components(G)}")

    print(f"\n🎯 Detekcja klastrów (algorytm: {algo})...")
    clusters = {}
    if algo == "louvain":
        comms = louvain_communities(G, weight="weight", resolution=resolution)
        for cid, comm in enumerate(comms):
            for p in comm:
                clusters[p] = cid
        print(f"   Louvain znalazł {len(comms)} społeczności")
    else:                       
        comps = list(nx.connected_components(G))
        for cid, component in enumerate(comps):
            for p in component:
                clusters[p] = cid
        print(f"   Składowe spójne: {len(comps)} komponentów")

    unassigned = set(proteins) - clusters.keys()
    next_id = max(clusters.values(), default=-1) + 1
    if unassigned:
        print(f"   ⚠️  Izolowane białka ({len(unassigned)}): {sorted(unassigned)}")
        for p in unassigned:
            clusters[p] = next_id
            next_id += 1

    # Wyświetl finalne klastry
    print(f"\n✅ WYNIKOWE KLASTRY:")
    clusters_by_id = {}
    for protein, cid in clusters.items():
        if cid not in clusters_by_id:
            clusters_by_id[cid] = []
        clusters_by_id[cid].append(protein)
    
    for cid in sorted(clusters_by_id.keys()):
        proteins_in_cluster = sorted(clusters_by_id[cid])
        print(f"   Klaster {cid}: {proteins_in_cluster} ({len(proteins_in_cluster)} białek)")
        # Pokaż wspólne GO-terminy dla klastra
        if len(proteins_in_cluster) > 1:
            common_in_cluster = set(protein_to_go[proteins_in_cluster[0]])
            for p in proteins_in_cluster[1:]:
                common_in_cluster &= set(protein_to_go[p])
            if common_in_cluster:
                print(f"      → Wspólne terminy całego klastra: {sorted(common_in_cluster)}")

    print(f"\n{'='*80}")
    print(f"🏁 KLASTERYZACJA ZAKOŃCZONA")
    print(f"{'='*80}\n")
    
    return clusters

def _bma_similarity(G: nx.DiGraph, A: list[str], B: list[str], method: str = "wang", verbose: bool = False) -> float:
    """
    Best-Match Average dla dwóch zestawów terminów GO.
    method: 'wang' | 'resnik' | 'lin'
    """
    if not A or not B:
        return 0.0
    f = {"wang": wang, "resnik": resnik, "lin": lin}.get(method, wang)

    if verbose:
        print(f"\n      🔍 BMA Similarity ({method}):")
        print(f"         A: {A}")
        print(f"         B: {B}")

    vals1 = []
    for a in A:
        sims = [(f(G, a, b) or 0.0) for b in B]
        max_sim = max(sims)
        vals1.append(max_sim)
        if verbose:
            best_b = B[sims.index(max_sim)]
            print(f"         {a} → najlepsze dopasowanie z {best_b}: {max_sim:.3f}")

    if verbose:
        print(f"         ---")

    vals2 = []
    for b in B:
        sims = [(f(G, b, a) or 0.0) for a in A]
        max_sim = max(sims)
        vals2.append(max_sim)
        if verbose:
            best_a = A[sims.index(max_sim)]
            print(f"         {b} → najlepsze dopasowanie z {best_a}: {max_sim:.3f}")

    result = (sum(vals1)/len(vals1) + sum(vals2)/len(vals2)) / 2.0
    
    if verbose:
        print(f"         → BMA: {result:.3f}")

    return result


def clusters_by_semantic_similarity(
    G: nx.DiGraph,
    protein_to_go: dict[str, list[str]],
    method: str = "wang",
    algo: str = "louvain",
    # jedna z dwóch strategii grafu podobieństw:
    threshold: float | None = 0.6,   # jeśli ustawione → krawędź gdy sim >= threshold
    knn: int | None = None,          # alternatywnie: KNN-graf; np. knn=8
    resolution: float = 1.0,
) -> dict[str, int]:
    """
    Buduje graf białek na podstawie podobieństwa semantycznego (BMA + Resnik/Lin/Wang),
    a następnie zwraca mapowanie protein -> cluster_id (Louvain lub składowe).
    """
    proteins = list(protein_to_go.keys())
    n = len(proteins)

    print(f"\n{'='*80}")
    print(f"🧬 KLASTERYZACJA SEMANTYCZNA - START")
    print(f"{'='*80}")
    print(f"📊 Parametry:")
    print(f"   - Liczba białek: {n}")
    print(f"   - Metoda podobieństwa: {method}")
    print(f"   - Algorytm klasteryzacji: {algo}")
    print(f"   - Threshold: {threshold}")
    print(f"   - KNN: {knn}")
    print(f"   - Resolution: {resolution}")
    print(f"\n📋 GO-terminy dla każdego białka:")
    for p in proteins:
        terms = protein_to_go[p]
        print(f"   {p}: {terms} ({len(terms)} terminów)")

    # 1) policz macierz podobieństwa (na żądanie: tylko to, co potrzebne pod threshold/knn)
    # Na start: prosty O(n^2) (dla setek białek OK). Dla dużych zbiorów – rozważ równoleglenie/KNN-only.
    print(f"\n🔢 Obliczanie macierzy podobieństwa...")
    S = [[0.0]*n for _ in range(n)]
    pair_count = 0
    for i, p1 in enumerate(proteins):
        A = protein_to_go[p1]
        for j in range(i+1, n):
            p2 = proteins[j]
            B = protein_to_go[p2]
            # Szczegółowe logi tylko dla pierwszych 3 par (żeby nie zaśmiecić konsoli)
            verbose = pair_count < 3 and n <= 10
            if verbose:
                print(f"\n   Para #{pair_count + 1}: {p1} ↔ {p2}")
            s = _bma_similarity(G, A, B, method=method, verbose=verbose)
            S[i][j] = S[j][i] = s
            if verbose:
                print(f"   ✓ Podobieństwo: {s:.3f}")
            pair_count += 1

    # Wyświetl macierz podobieństwa
    print(f"\n📊 MACIERZ PODOBIEŃSTWA ({method}):")
    print(f"   {'':>10}", end="")
    for p in proteins:
        print(f"{p:>8}", end="")
    print()
    for i, p1 in enumerate(proteins):
        print(f"   {p1:>10}", end="")
        for j in range(n):
            if i == j:
                print(f"{'─':>8}", end="")
            else:
                print(f"{S[i][j]:>8.3f}", end="")
        print()

    # Statystyki podobieństwa
    all_sims = [S[i][j] for i in range(n) for j in range(i+1, n)]
    if all_sims:
        print(f"\n📈 Statystyki podobieństwa:")
        print(f"   - Min: {min(all_sims):.3f}")
        print(f"   - Max: {max(all_sims):.3f}")
        print(f"   - Średnia: {sum(all_sims)/len(all_sims):.3f}")

    # 2) graf na bazie sim: threshold albo KNN
    print(f"\n🕸️  Budowanie grafu białek...")
    GG = nx.Graph()
    GG.add_nodes_from(proteins)

    edges_added = []
    if knn is not None and knn > 0:
        print(f"   Strategia: KNN (k={knn})")
        # K najbliższych sąsiadów dla każdego węzła (po similarity)
        for i, p1 in enumerate(proteins):
            sims = [(S[i][j], j) for j in range(n) if j != i]
            sims.sort(reverse=True)  # najwyższe podobieństwa pierwsze
            for sim_val, j in sims[:knn]:
                if S[i][j] > 0:
                    GG.add_edge(p1, proteins[j], weight=S[i][j])
                    edges_added.append((p1, proteins[j], S[i][j]))
    else:
        # próg podobieństwa
        thr = 0.6 if threshold is None else float(threshold)
        print(f"   Strategia: Threshold (próg={thr:.2f})")
        for i in range(n):
            for j in range(i+1, n):
                if S[i][j] >= thr:
                    GG.add_edge(proteins[i], proteins[j], weight=S[i][j])
                    edges_added.append((proteins[i], proteins[j], S[i][j]))

    print(f"\n🔗 UTWORZONE KRAWĘDZIE ({len(edges_added)} połączeń):")
    if edges_added:
        edges_added.sort(key=lambda x: x[2], reverse=True)  # sortuj po wadze
        for p1, p2, weight in edges_added:
            print(f"   {p1} ←→ {p2}: {weight:.3f}")
    else:
        print(f"   ⚠️  Brak krawędzi! Wszystkie białka będą w osobnych klastrach.")

    # Statystyki grafu
    print(f"\n📊 Statystyki grafu:")
    print(f"   - Węzły: {GG.number_of_nodes()}")
    print(f"   - Krawędzie: {GG.number_of_edges()}")
    print(f"   - Gęstość: {nx.density(GG):.3f}")
    print(f"   - Składowe spójne: {nx.number_connected_components(GG)}")
    
    # Stopnie węzłów
    degrees = dict(GG.degree())
    if degrees:
        print(f"   - Stopnie węzłów:")
        for p, deg in sorted(degrees.items()):
            print(f"      {p}: {deg} połączeń")

    # 3) detekcja społeczności / klastry
    print(f"\n🎯 Detekcja klastrów (algorytm: {algo})...")
    clusters: dict[str, int] = {}
    if algo == "louvain":
        comms = louvain_communities(GG, weight="weight", resolution=resolution)
        for cid, comm in enumerate(comms):
            for p in comm:
                clusters[p] = cid
        print(f"   Louvain znalazł {len(comms)} społeczności")
    else:
        comps = list(nx.connected_components(GG))
        for cid, comp in enumerate(comps):
            for p in comp:
                clusters[p] = cid
        print(f"   Składowe spójne: {len(comps)} komponentów")

    # 4) nieprzypisani (izolowane białka)
    unassigned = set(proteins) - clusters.keys()
    next_id = max(clusters.values(), default=-1) + 1
    if unassigned:
        print(f"   ⚠️  Izolowane białka ({len(unassigned)}): {sorted(unassigned)}")
        for p in unassigned:
            clusters[p] = next_id
            next_id += 1

    # Wyświetl finalne klastry
    print(f"\n✅ WYNIKOWE KLASTRY:")
    clusters_by_id = {}
    for protein, cid in clusters.items():
        if cid not in clusters_by_id:
            clusters_by_id[cid] = []
        clusters_by_id[cid].append(protein)
    
    for cid in sorted(clusters_by_id.keys()):
        proteins_in_cluster = sorted(clusters_by_id[cid])
        print(f"   Klaster {cid}: {proteins_in_cluster} ({len(proteins_in_cluster)} białek)")
        # Pokaż GO-terminy dla klastra
        all_terms = set()
        for p in proteins_in_cluster:
            all_terms.update(protein_to_go[p])
        print(f"      → Wszystkie GO-terminy: {sorted(all_terms)}")

    print(f"\n{'='*80}")
    print(f"🏁 KLASTERYZACJA ZAKOŃCZONA")
    print(f"{'='*80}\n")

    return clusters



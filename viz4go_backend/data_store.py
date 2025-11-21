# data_store.py
from __future__ import annotations
import threading
import time
from pathlib import Path
from typing import Optional, Dict, Any

import pandas as pd
import networkx as nx

from download import obo  # nasz downloader z ETag/Last-Modified
from similarity import precalc_lower_bounds  # Twój skopiowany moduł z miarami

GO_FILE_NAME = "go"       
# GO_FILE_NAME = "go-basic"
# GO_FILE_NAME = "go-plus"
class GOStore:
    """
    W pamięci: graf GO + DataFrame terminów + metadane.
    Zapewnia szybki odczyt w endpointach oraz prekomputacje dla miar podobieństwa.
    """
    def __init__(self, go_name: str = GO_FILE_NAME):
        self._lock = threading.RLock()
        self._go_name = go_name
        self.graph: nx.DiGraph = nx.DiGraph()
        self.df: pd.DataFrame = pd.DataFrame()
        self.by_id: pd.DataFrame = pd.DataFrame()
        self.path: Optional[Path] = None
        self.mtime: float = 0.0

        self._load_or_update()

    # -------------------------
    # public API
    # -------------------------

    def ensure_fresh(self) -> None:
        """
        Sprawdź, czy plik OBO jest świeży. Jeśli wykryto nową wersję na dysku (np. utils.obo zaktualizował),
        przeładuj graf/DF atomowo.
        """
        with self._lock:
            if not self.path:
                return
            current_mtime = self.path.stat().st_mtime
            if current_mtime > self.mtime:
                # plik został podmieniony – odśwież
                self._load_from_path(self.path)

    def get_term_row(self, term_id: str) -> Optional[Dict[str, Any]]:
        """
        Zwróć słownik kolumn dla danego ID (None, gdy brak).
        """
        self.ensure_fresh()
        if term_id in self.by_id.index:
            row = self.by_id.loc[term_id]
            # loc może zwrócić Series lub DataFrame (gdy dublowane indexy) – normalizujemy:
            if isinstance(row, pd.Series):
                return row.to_dict()
            return row.iloc[0].to_dict()
        return None

    # -------------------------
    # wewnętrzne
    # -------------------------

    def _load_or_update(self) -> None:
        """
        Pobierz/odśwież OBO (conditional GET) i zbuduj graf + DF.
        """
        # utils.obo() zwróci ścieżkę i SAMO sprawdzi aktualizacje (ETag/Last-Modified).
        path = obo(name=self._go_name, check_updates=True)

        with self._lock:
            self._load_from_path(path)

    def _load_from_path(self, path: Path) -> None:
        """
        Wczytaj OBO → graf + DF + IC (lower_bounds). Operacja atomowa (pod lockiem).
        """
        # Parsowanie OBO do grafu + tabeli terminów
        G, df = self._parse_obo(path)

        # Precompute do Resnika/Lina (lower_bounds)
        precalc_lower_bounds(G)

        # Atomowa podmiana pól
        self.graph = G
        self.df = df
        self.by_id = df.set_index("id", drop=False)
        self.path = Path(path)
        self.mtime = self.path.stat().st_mtime

    def _parse_obo(self, path: Path) -> tuple[nx.DiGraph, pd.DataFrame]:
        """
        Minimalny parser OBO (wystarczający do relacji is_a i part_of oraz podstawowych pól termu).
        Jeśli potrzebujesz więcej pól (synonym, xref itd.) – łatwo rozbudować.
        """
        G = nx.DiGraph()
        records = []

        # Bieżący term (zbieramy do rekordu)
        cur: Dict[str, Any] = {}
        def _flush():
            if cur.get("id"):
                # Upewnij się, że węzeł istnieje
                G.add_node(cur["id"])
                # Domknięcie rekordu
                records.append({
                    "id": cur.get("id"),
                    "name": cur.get("name"),
                    "namespace": cur.get("namespace"),
                    "def": cur.get("def"),
                    "is_obsolete": cur.get("is_obsolete", "false")
                })

        with open(path, "r", encoding="utf-8") as f:
            in_term = False
            for raw in f:
                line = raw.strip()
                if not line:
                    continue
                if line == "[Term]":
                    # zamknij poprzedni term
                    if in_term:
                        _flush()
                    in_term = True
                    cur = {}
                    continue
                if line.startswith("["):
                    # sekcja inna niż Term – zamknij, ale nie przetwarzaj dalej
                    if in_term:
                        _flush()
                        in_term = False
                    continue
                if not in_term:
                    continue

                # klucz: wartość
                if line.startswith("id: "):
                    cur["id"] = line[4:]
                    continue
                if line.startswith("name: "):
                    cur["name"] = line[6:]
                    continue
                if line.startswith("namespace: "):
                    cur["namespace"] = line[11:]
                    continue
                if line.startswith("def: "):
                    cur["def"] = line[5:]
                    continue
                if line.startswith("is_obsolete: "):
                    cur["is_obsolete"] = line.split("is_obsolete: ")[1]
                    continue

                # Relacje
                if line.startswith("is_a: "):
                    parent = line.split("is_a: ")[1].split()[0]
                    if "id" in cur:
                        G.add_edge(parent, cur["id"], type="is_a")
                    continue

                if line.startswith("relationship: "):
                    # np. "relationship: part_of GO:0008150 ! ..."
                    # bierzemy tylko part_of; łatwo dodać kolejne.
                    parts = line.split()
                    if len(parts) >= 3:
                        rel = parts[1]
                        tgt = parts[2]
                        if rel == "part_of" and "id" in cur:
                            G.add_edge(tgt, cur["id"], type="part_of")
                    continue

            # flush ostatniego termu
            if in_term:
                _flush()

        df = pd.DataFrame.from_records(records)
        return G, df


# -------------
# Singleton API
# -------------

_GO_STORE: Optional[GOStore] = None
_GO_STORE_LOCK = threading.RLock()

def init_store(go_name: str = GO_FILE_NAME) -> GOStore:
    global _GO_STORE
    with _GO_STORE_LOCK:
        if _GO_STORE is None:
            _GO_STORE = GOStore(go_name)
        else:
            # Możesz wywołać to przy starcie nawet gdy _GO_STORE istnieje – upewni się, że świeże.
            _GO_STORE.ensure_fresh()
        return _GO_STORE

def get_store() -> GOStore:
    if _GO_STORE is None:
        # awaryjnie zainicjalizuj domyślny
        return init_store(GO_FILE_NAME)
    return _GO_STORE

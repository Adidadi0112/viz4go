import obonet
import sqlite3

# Wczytywanie pliku obo i tworzenie grafu
graph = obonet.read_obo("viz4go_backend/data/go.obo")

# Nawiązanie połączenia z bazą danych SQLite (lub stworzenie jej, jeśli nie istnieje)
conn = sqlite3.connect('viz4go_backend/go_terms.db')
cursor = conn.cursor()

# Tworzenie tabeli w bazie danych
cursor.execute('''
CREATE TABLE IF NOT EXISTS go_terms (
    id TEXT PRIMARY KEY,
    name TEXT,
    namespace TEXT,
    def TEXT,
    is_a TEXT,
    relationship TEXT
)
''')

# Przygotowanie listy do wsadowego wstawiania danych
batch_data = []

for node_id, data in graph.nodes(data=True):
    # Wartości domyślne dla brakujących danych
    name = data.get('name', '')
    namespace = data.get('namespace', '')
    definition = data.get('def', '')
    is_a = ','.join(data.get('is_a', []))
    relationship = ','.join(data.get('relationship', []))
    
    # Dodanie wiersza do wsadu
    batch_data.append((node_id, name, namespace, definition, is_a, relationship))
    
    # Co 1000 rekordów wykonuj wsadowe wstawienie
    if len(batch_data) >= 1000:
        cursor.executemany('''
        INSERT INTO go_terms (id, name, namespace, def, is_a, relationship)
        VALUES (?, ?, ?, ?, ?, ?)
        ''', batch_data)
        batch_data = []  # Resetowanie wsadu

# Wstawienie pozostałych rekordów
if batch_data:
    cursor.executemany('''
    INSERT INTO go_terms (id, name, namespace, def, is_a, relationship)
    VALUES (?, ?, ?, ?, ?, ?)
    ''', batch_data)

# Zatwierdzenie zmian i zamknięcie połączenia
conn.commit()
conn.close()

print("Dane zostały zaimportowane do bazy SQLite.")
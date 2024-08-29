import obonet
import sqlite3

# Konfiguracja bazy danych SQLite
DATABASE = 'go_terms.db'

def get_db_connection():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn

# Wczytanie grafu GO z pliku
graph = obonet.read_obo('viz4go_backend/data/go.obo')

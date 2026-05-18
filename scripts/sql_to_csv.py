import re
import csv
from pathlib import Path

SQL_FILE = Path('sql/p1version2_data.sql')
OUT_DIR = Path('output')
OUT_DIR.mkdir(exist_ok=True)

# regex to split on commas not inside single quotes
split_re = re.compile(r",\s*(?=(?:[^']*'[^']*')*[^']*$)")

def parse_values(s):
    # s is like "1, 'Lionel Messi', '1995-02-01', 'Delantero', 1"
    parts = split_re.split(s)
    parsed = []
    for p in parts:
        p = p.strip()
        if p.startswith("'") and p.endswith("'"):
            parsed.append(p[1:-1])
        else:
            # try int
            if p == 'NULL':
                parsed.append(None)
            else:
                try:
                    parsed.append(int(p))
                except ValueError:
                    # maybe quoted with double quotes
                    parsed.append(p.strip("\"' "))
    return parsed


def extract_inserts(table_name):
    inserts = []
    with SQL_FILE.open('r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            prefix = f"INSERT INTO {table_name} VALUES ("
            if line.startswith(prefix):
                inner = line[len(prefix):-2]  # remove prefix and ');'
                inserts.append(parse_values(inner))
    return inserts


def write_csv(filename, headers, rows):
    with open(OUT_DIR / filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        for r in rows:
            writer.writerow(r)


def main():
    # Jugador
    jugadores = extract_inserts('Jugador')
    if jugadores:
        write_csv('jugadores.csv', ['id_jugador','nombre','fecha_nac','posicion','id_equipo'], jugadores)
        print('Wrote output/jugadores.csv')
    else:
        print('No Jugador inserts found')

    # Gol
    goles = extract_inserts('Gol')
    if goles:
        write_csv('goles.csv', ['id_gol','minuto','id_partido','id_jugador'], goles)
        print('Wrote output/goles.csv')
    else:
        print('No Gol inserts found')

    # EstadisticaJugador
    estad = extract_inserts('EstadisticaJugador')
    if estad:
        write_csv('estadisticas.csv', ['id_jugador','id_torneo','goles','asistencias','tarjetas_rojas','tarjetas_amarillas'], estad)
        print('Wrote output/estadisticas.csv')
    else:
        print('No EstadisticaJugador inserts found')

if __name__ == '__main__':
    main()

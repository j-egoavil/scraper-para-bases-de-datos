#!/usr/bin/env python3
import csv, random
from collections import defaultdict

TEAM_CITIES = {
    'Manchester Utd': 'Manchester', 'Arsenal': 'London', 'Barcelona': 'Barcelona',
    'Chelsea': 'London', 'Bayern Munich': 'Munich', 'Villarreal': 'Villarreal',
    'Porto': 'Porto', 'Liverpool': 'Liverpool', 'Sporting CP': 'Lisbon',
    'Real Madrid': 'Madrid', 'Roma': 'Rome', 'Lyon': 'Lyon', 'Inter': 'Milan',
    'Atlético Madrid': 'Madrid', 'Juventus': 'Turin', 'Panathinaikos': 'Athens',
    'Schalke 04': 'Gelsenkirchen', 'Tottenham Hotspur': 'London', 'Shakhtar Donetsk': 'Donetsk',
    'FC Copenhagen': 'Copenhagen', 'Marseille': 'Marseille', 'Milan': 'Milan',
    'Valencia': 'Valencia', 'Paris Saint-Germain': 'Paris', 'Monaco': 'Monaco',
    'Dortmund': 'Dortmund', 'Manchester City': 'Manchester', 'Leverkusen': 'Leverkusen',
    'Basel': 'Basel', 'Wolfsburg': 'Wolfsburg', 'Benfica': 'Lisbon', 'Gent': 'Gent',
    'Zenit': 'Saint Petersburg', 'Dynamo Kyiv': 'Kyiv', 'PSV': 'Eindhoven', 'Ajax': 'Amsterdam',
    'AC Milan': 'Milan', 'FC Barcelona': 'Barcelona', 'Inter Milan': 'Milan', 'Manchester United': 'Manchester'
}

STADIUMS = {
    'Madrid': 'Santiago Bernabéu', 'Barcelona': 'Camp Nou', 'Turin': 'Juventus Stadium',
    'Manchester': 'Old Trafford', 'London': 'Stamford Bridge', 'Munich': 'Allianz Arena',
    'Milan': 'San Siro', 'Rome': 'Stadio Olimpico', 'Liverpool': 'Anfield',
    'Gelsenkirchen': 'Veltins-Arena', 'Dortmund': 'Signal Iduna Park',
    'Valencia': 'Mestalla', 'Marseille': 'Orange Velodrome', 'Lyon': 'Stade de Gerland',
    'Amsterdam': 'Johan Cruijff Arena', 'Eindhoven': 'PSV Stadion', 'Donbass Arena': 'Donbass Arena',
    'Donetsk': 'Donbass Arena', 'Kyiv': 'NSC Olimpiyski', 'Villarreal': 'Estadio de la Cerámica',
    'Porto': 'Dragao', 'Lisbon': 'Estádio da Luz', 'Gent': 'Gent Stadium',
    'Saint Petersburg': 'Gazprom Arena', 'Leverkusen': 'BayArena', 'Basel': 'St. Jakob-Park',
    'Wolfsburg': 'Volkswagen Arena', 'Athens': 'Apostolos Nikolaidis', 'Copenhagen': 'Parken',
    'Monaco': 'Stade Louis II', 'Paris': 'Parc des Princes'
    
}

PLAYER_NAMES = [
    'Cristiano Ronaldo', 'Lionel Messi', 'Luis Suarez', 'Sergio Aguero',
    'Robert Lewandowski', 'David Villa', 'Karim Benzema', 'Raul Gonzalez',
    'Thierry Henry', 'Zinedine Zidane', 'Ronaldinho', 'Pele',
    'Gianluigi Buffon', 'Edwin van der Sar', 'Gerard Pique', 'John Terry',
    'Xavi Hernandez', 'Andres Iniesta', 'Andrea Pirlo', 'Steven Gerrard',
    'Patrick Vieira', 'Claude Makele', 'Didier Drogba', 'Gonzalo Higuain',
    'Arjen Robben', 'Frank Ribery', 'Mesut Ozil', 'Angel Di Maria', 'Eden Hazard',
]

def read_csv(f):
    with open(f, 'r', encoding='utf-8') as fp:
        return list(csv.DictReader(fp))

partidos = read_csv('output/partidos.csv')
equipos = read_csv('output/teams.csv')
teams_by_id = {int(e['id_equipo']): e for e in equipos}

print(f"Procesando {len(equipos)} equipos y {len(partidos)} partidos...")

sql = "-- UPDATE EQUIPOS\n"
for team in equipos:
    team_id = int(team['id_equipo'])
    city = TEAM_CITIES.get(team['nombre'], 'Unknown')
    sql += f"UPDATE Equipo SET ciudad = '{city}' WHERE id_equipo = {team_id};\n"

sql += "\n-- UPDATE PARTIDOS\n"
for p in partidos:
    p_id = int(p['id_partido'])
    local_id = int(p['id_equipo_local'])
    local_city = TEAM_CITIES.get(teams_by_id.get(local_id, {}).get('nombre', ''), 'Unknown')
    stadium = STADIUMS.get(local_city, f'{local_city} Stadium')
    sql += f"UPDATE Partido SET lugar = '{stadium}' WHERE id_partido = {p_id};\n"

sql += "\n-- INSERT JUGADORES\n"
jugador_id = 1
jug_por_eq = {}
random.seed(42)

for team in equipos:
    team_id = int(team['id_equipo'])
    jug_por_eq[team_id] = []
    for i in range(12):
        pname = PLAYER_NAMES[(team_id + i) % len(PLAYER_NAMES)]
        birth = f"{random.randint(1975,1995)}-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
        pos = ['Delantero', 'Centrocampista', 'Defensa', 'Portero'][i % 4]
        sql += f"INSERT INTO Jugador VALUES ({jugador_id}, '{pname}', '{birth}', '{pos}', {team_id});\n"
        jug_por_eq[team_id].append(jugador_id)
        jugador_id += 1

sql += "\n-- INSERT GOLES\n"
gol_id = 1
goles_jug_tor = defaultdict(lambda: defaultdict(int))

for p in partidos:
    p_id = int(p['id_partido'])
    local_id, visitante_id = int(p['id_equipo_local']), int(p['id_equipo_visitante'])
    marcador_local, marcador_visitante = int(p['marcador_local']), int(p['marcador_visitante'])
    torneo_id = int(p['id_torneo'])
    
    if jug_por_eq.get(local_id):
        for _ in range(marcador_local):
            jid = random.choice(jug_por_eq[local_id])
            sql += f"INSERT INTO Gol VALUES ({gol_id}, {random.randint(1,90)}, {p_id}, {jid});\n"
            goles_jug_tor[jid][torneo_id] += 1
            gol_id += 1
    
    if jug_por_eq.get(visitante_id):
        for _ in range(marcador_visitante):
            jid = random.choice(jug_por_eq[visitante_id])
            sql += f"INSERT INTO Gol VALUES ({gol_id}, {random.randint(1,90)}, {p_id}, {jid});\n"
            goles_jug_tor[jid][torneo_id] += 1
            gol_id += 1

sql += "\n-- INSERT ESTADISTICAS\n"
for jid in range(1, jugador_id):
    for tid in goles_jug_tor[jid]:
        g = goles_jug_tor[jid][tid]
        a = g // 3
        sql += f"INSERT INTO EstadisticaJugador VALUES ({jid}, {tid}, {g}, {a}, {random.randint(0,1) if g > 0 else 0}, {random.randint(0,3) if g > 0 else 0});\n"

with open('p1version2_data.sql', 'w', encoding='utf-8') as f:
    f.write(sql)

print(f"OK: {len(equipos)} eq, {len(partidos)} part, {jugador_id-1} jug, {gol_id-1} goles")

# --- Also produce final CSVs ready for direct DB import
try:
    # Tournaments: keep only rows with both dates and add 'deporte'
    tournaments = read_csv('output/tournaments.csv')
    out_t = []
    valid_t_ids = set()
    for t in tournaments:
        if t.get('fecha_inicio') and t.get('fecha_fin'):
            out_t.append({'id_torneo': t['id_torneo'], 'nombre': t['nombre'],
                          'fecha_inicio': t['fecha_inicio'], 'fecha_fin': t['fecha_fin'],
                          'deporte': 'Fútbol'})
            valid_t_ids.add(int(t['id_torneo']))

    with open('output/tournaments.csv', 'w', encoding='utf-8', newline='') as tf:
        writer = csv.DictWriter(tf, fieldnames=['id_torneo', 'nombre', 'fecha_inicio', 'fecha_fin', 'deporte'])
        writer.writeheader()
        for r in out_t:
            writer.writerow(r)

    # Teams: fill ciudad from TEAM_CITIES mapping (default 'Unknown')
    out_teams = []
    for e in equipos:
        cname = TEAM_CITIES.get(e['nombre'], 'Unknown')
        out_teams.append({'id_equipo': e['id_equipo'], 'nombre': e['nombre'], 'ciudad': cname})

    with open('output/teams.csv', 'w', encoding='utf-8', newline='') as tf:
        writer = csv.DictWriter(tf, fieldnames=['id_equipo', 'nombre', 'ciudad'])
        writer.writeheader()
        for r in out_teams:
            writer.writerow(r)

    # Partidos: write only DB columns and fill 'lugar' using local team's city -> stadium
    out_partidos = []
    for p in partidos:
        try:
            p_id = p['id_partido']
            fecha = p['fecha']
            ml = p['marcador_local'] or '0'
            mv = p['marcador_visitante'] or '0'
            id_t = int(p['id_torneo'])
            if id_t not in valid_t_ids:
                continue
            local_id = int(p['id_equipo_local'])
            local_name = teams_by_id.get(local_id, {}).get('nombre', '')
            local_city = TEAM_CITIES.get(local_name, 'Unknown')
            lugar = STADIUMS.get(local_city, f"{local_city} Stadium")
            out_partidos.append({
                'id_partido': p_id,
                'fecha': fecha,
                'marcador_local': ml,
                'marcador_visitante': mv,
                'lugar': lugar,
                'id_torneo': p['id_torneo'],
                'id_equipo_local': p['id_equipo_local'],
                'id_equipo_visitante': p['id_equipo_visitante']
            })
        except Exception:
            continue

    with open('output/partidos.csv', 'w', encoding='utf-8', newline='') as pf:
        writer = csv.DictWriter(pf, fieldnames=['id_partido','fecha','marcador_local','marcador_visitante','lugar','id_torneo','id_equipo_local','id_equipo_visitante'])
        writer.writeheader()
        for r in out_partidos:
            writer.writerow(r)

    # Participa: filter by valid tournaments
    participa = read_csv('output/participa.csv')
    out_part = [ {'id_torneo': p['id_torneo'], 'id_equipo': p['id_equipo']} for p in participa if p.get('id_torneo') and int(p['id_torneo']) in valid_t_ids ]
    with open('output/participa.csv', 'w', encoding='utf-8', newline='') as pf:
        writer = csv.DictWriter(pf, fieldnames=['id_torneo','id_equipo'])
        writer.writeheader()
        for r in out_part:
            writer.writerow(r)

    print('Wrote final CSVs: tournaments, teams, partidos, participa')
except FileNotFoundError:
    print('Warning: expected CSV inputs in output/ not found; skipping CSV finalization')

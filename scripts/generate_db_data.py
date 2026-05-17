#!/usr/bin/env python3
import csv, random
from collections import defaultdict

TEAM_CITIES = {
    'Real Madrid': 'Madrid', 'Barcelona': 'Barcelona', 'Juventus': 'Turin',
    'Manchester Utd': 'Manchester', 'Arsenal': 'London', 'Chelsea': 'London',
    'Bayern Munich': 'Munich', 'Inter': 'Milan', 'Roma': 'Rome',
    'Tottenham Hotspur': 'London', 'Manchester City': 'Manchester',
    'Liverpool': 'Liverpool', 'Schalke 04': 'Gelsenkirchen', 'Dortmund': 'Dortmund',
    'Valencia': 'Valencia', 'Marseille': 'Marseille', 'Lyon': 'Lyon',
    'Ajax': 'Amsterdam', 'PSV': 'Eindhoven', 'Shakhtar Donetsk': 'Donetsk', 'Dynamo Kyiv': 'Kyiv',
    # Additional teams from extended seasons
    'Villarreal': 'Villarreal', 'Porto': 'Porto', 'Sporting CP': 'Lisbon',
    'Panathinaikos': 'Athens', 'Benfica': 'Lisbon', 'Gent': 'Gent',
    'Zenit': 'Saint Petersburg', 'Leverkusen': 'Leverkusen', 'Basel': 'Basel',
    'Wolfsburg': 'Wolfsburg', 'AC Milan': 'Milan', 'FC Barcelona': 'Barcelona',
    'Inter Milan': 'Milan', 'Manchester United': 'Manchester',
    # Variations/duplicates
    'Atlético Madrid': 'Madrid', 'AtlÃ©tico Madrid': 'Madrid',
    'FC Copenhagen': 'Copenhagen', 'Monaco': 'Monaco', 'Milan': 'Milan'
}

STADIUMS = {
    'Madrid': 'Santiago Bernabéu', 'Barcelona': 'Camp Nou', 'Turin': 'Juventus Stadium',
    'Manchester': 'Old Trafford', 'London': 'Stamford Bridge', 'Munich': 'Allianz Arena',
    'Milan': 'San Siro', 'Rome': 'Stadio Olimpico', 'Liverpool': 'Anfield',
    'Gelsenkirchen': 'Veltins-Arena', 'Dortmund': 'Signal Iduna Park',
    'Valencia': 'Mestalla', 'Marseille': 'Orange Velodrome', 'Lyon': 'Stade de Gerland',
    'Amsterdam': 'Johan Cruijff Arena', 'Eindhoven': 'PSV Stadion', 'Donetsk': 'Donbass Arena', 
    'Kyiv': 'NSC Olimpiyski', 'Villarreal': 'Estadio de la Cerámica', 'Porto': 'Dragao',
    'Lisbon': 'Estádio da Luz', 'Gent': 'Gent Stadium', 'Saint Petersburg': 'Gazprom Arena',
    'Leverkusen': 'BayArena', 'Basel': 'St. Jakob-Park', 'Wolfsburg': 'Volkswagen Arena',
    'Athens': 'Apostolos Nikolaidis', 'Copenhagen': 'Parken', 'Monaco': 'Stade Louis II'
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

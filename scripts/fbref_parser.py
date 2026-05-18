#!/usr/bin/env python3
"""
fbref_parser.py

Heurístico: parsea archivos .txt con HTML guardado de páginas (fbref/stathead)
y extrae torneos, equipos, participa y partidos en CSV/SQL.

Uso:
    python fbref_parser.py --input-dir "f:/Nueva carpeta" --output-dir out

Requiere: beautifulsoup4, lxml, pandas (opcional)
"""
import re
import os
import csv
import argparse
from datetime import datetime
from bs4 import BeautifulSoup
import unicodedata
import difflib


def extract_text(el):
    return el.get_text(separator=' ', strip=True) if el else ''


def find_title(soup):
    title = None
    if soup.title and soup.title.string:
        title = soup.title.string.strip()
    else:
        h1 = soup.find('h1')
        if h1:
            title = extract_text(h1)
    
    # Clean up title - remove " | FBref.com" suffix
    if title and ' | FBref.com' in title:
        title = title.replace(' | FBref.com', '')
    
    return title


def extract_year_from_title(soup):
    """Extract year from title like '2010-2011' and return as integer"""
    title = find_title(soup)
    if not title:
        return None
    
    # Look for pattern like "2010-2011" or "2015"
    year_match = re.search(r'(\d{4})', title)
    if year_match:
        return int(year_match.group(1))
    return None


def extract_tournament_dates(soup):
    """Extract start and end dates of tournament from h2/h3 headers with dates in parentheses"""
    dates_found = []
    
    # Search for headers with date ranges like "Group stage (September 14, 2010 to December  8, 2010)"
    month_names = r"(January|February|March|April|May|June|July|August|September|October|November|December)"
    
    # Pattern: Month Day, Year to Month Day, Year
    date_range_pattern = re.compile(
        month_names + r"\s+(\d{1,2}),\s+(\d{4})\s+to\s+" + 
        month_names + r"\s+(\d{1,2}),\s+(\d{4})"
    )
    
    # Also pattern: Month Day to Month Day, Year (when in same month/year)
    date_single_pattern = re.compile(
        month_names + r"\s+(\d{1,2}),\s+(\d{4})"
    )
    
    for header in soup.find_all(['h2', 'h3']):
        header_text = extract_text(header)
        
        # Try full date range first
        range_m = date_range_pattern.search(header_text)
        if range_m:
            start_month = range_m.group(1)
            start_day = range_m.group(2)
            start_year = range_m.group(3)
            end_month = range_m.group(4)
            end_day = range_m.group(5)
            end_year = range_m.group(6)
            
            try:
                start_date = datetime.strptime(f"{start_month} {start_day} {start_year}", "%B %d %Y").strftime("%Y-%m-%d")
                end_date = datetime.strptime(f"{end_month} {end_day} {end_year}", "%B %d %Y").strftime("%Y-%m-%d")
                dates_found.append((start_date, end_date))
            except:
                pass
        
        # Try single dates
        for match in date_single_pattern.finditer(header_text):
            month = match.group(1)
            day = match.group(2)
            year = match.group(3)
            try:
                date_obj = datetime.strptime(f"{month} {day} {year}", "%B %d %Y").strftime("%Y-%m-%d")
                dates_found.append(date_obj)
            except:
                pass
    
    # Return the overall tournament start and end
    start_date = None
    end_date = None
    
    if dates_found:
        # Get all dates in chronological order
        all_dates = []
        for item in dates_found:
            if isinstance(item, tuple):
                all_dates.extend([item[0], item[1]])
            else:
                all_dates.append(item)
        
        all_dates.sort()
        if all_dates:
            start_date = all_dates[0]
            end_date = all_dates[-1]
    
    return start_date, end_date


def find_teams(soup):
    teams = set()
    # priorizar: anchors con /teams/ en href
    for a in soup.find_all('a'):
        href = (a.get('href') or '').lower()
        text = extract_text(a)
        if not text:
            continue
        if '/teams/' in href or '/team/' in href:
            if len(text) >= 3 and len(text) <= 50:
                teams.add(text)
    return list(sorted(teams))


def normalize_name(name):
    if not name:
        return ''
    # strip accents
    name = unicodedata.normalize('NFKD', name).encode('ASCII', 'ignore').decode('ASCII')
    name = name.lower()
    # remove common prefixes/suffixes
    for tok in ['fc ', 'f.c. ', 'cf ', 'c.f. ', 'ac ', 'a.c. ', 'real ', 'club ', 'the ']:
        if name.startswith(tok):
            name = name[len(tok):]
    # remove punctuation
    name = re.sub(r"[^a-z0-9\s]", ' ', name)
    # collapse whitespace
    name = re.sub(r"\s+", ' ', name).strip()
    return name


def find_matches(soup):
    matches = []
    # Regex para extraer score (3–1, 0-0, etc.)
    score_re = re.compile(r"(\d{1,2})\s*[-:\–\—]\s*(\d{1,2})")
    
    # Extraer año del título para completar fechas
    season_year = extract_year_from_title(soup)
    
    # Primero buscar en secciones de partidos individuales dentro de match-summary
    # Estos están dentro de <div class="matches">
    for matches_section in soup.find_all('div', class_='matches'):
        # Cada partido individual está en un div directo
        for match_row in matches_section.find_all('div', recursive=False):
            # Buscar match-date, matchup-team y match-detail en este div
            match_date_div = match_row.find('div', class_='match-date')
            match_detail_div = match_row.find('div', class_='match-detail')
            teams_divs = match_row.find_all('div', class_='matchup-team')
            
            if not match_date_div or not match_detail_div or len(teams_divs) < 2:
                continue
            
            # Extraer equipos
            team1_text = extract_text(teams_divs[0]).strip()
            team2_text = extract_text(teams_divs[1]).strip()
            
            if not team1_text or not team2_text:
                continue
            
            # Extraer score
            score_link = match_detail_div.find('a')
            if not score_link:
                # Intentar obtener el score sin link
                score_text = extract_text(match_detail_div).strip()
            else:
                score_text = extract_text(score_link).strip()
            
            score_m = score_re.search(score_text)
            if not score_m:
                continue
            
            # Extraer y procesar fecha
            date_text = extract_text(match_date_div).strip()
            fecha_formatted = ''
            
            # Parse date like "Apr  27" or "May  3"
            if date_text and season_year:
                # Try to parse with year
                try:
                    date_obj = datetime.strptime(f"{date_text} {season_year}", "%b %d %Y")
                    fecha_formatted = date_obj.strftime("%Y-%m-%d")
                except:
                    # Try alternative format
                    try:
                        date_obj = datetime.strptime(f"{date_text.replace(chr(160), ' ')} {season_year}", "%b %d %Y")
                        fecha_formatted = date_obj.strftime("%Y-%m-%d")
                    except:
                        fecha_formatted = date_text
            elif date_text:
                fecha_formatted = date_text
            
            match_url = ''
            if score_link:
                match_url = score_link.get('href', '')
            
            matches.append({
                'fecha': fecha_formatted,
                'local': team1_text,
                'visitante': team2_text,
                'marcador_local': int(score_m.group(1)),
                'marcador_visitante': int(score_m.group(2)),
                'lugar': '',
                'match_url': match_url,
                'raw': f"{team1_text} {score_text} {team2_text}",
            })
    
    # También buscar match-summary que tengan enlace directo
    for match_div in soup.find_all('div', class_='match-summary'):
        # Solo procesar si NO está dentro de un "matches" section (para evitar duplicados)
        # Buscar si tiene match-detail con link que podamos extraer
        match_detail = match_div.find('div', class_='match-detail')
        if not match_detail:
            continue
        
        score_link = match_detail.find('a')
        if not score_link:
            continue
        
        # Obtener los dos equipos de los divs matchup-team (solo los directos, no recursivos)
        teams_divs = match_div.find_all('div', class_='matchup-team', recursive=False)
        if len(teams_divs) < 2:
            continue
        
        # Extraer nombre de equipo de cada div
        team1_link = teams_divs[0].find('a', href=re.compile(r'/en/squads/'))
        team2_link = teams_divs[1].find('a', href=re.compile(r'/en/squads/'))
        
        if not team1_link or not team2_link:
            continue
        
        team1 = extract_text(team1_link).strip()
        team2 = extract_text(team2_link).strip()
        
        if not team1 or not team2:
            continue
        
        score_text = extract_text(score_link).strip()
        score_m = score_re.search(score_text)
        
        if not score_m:
            continue
        
        # Extraer fecha del href del match-detail link
        href = score_link.get('href', '')
        fecha_formatted = ''
        
        if '/en/matches/' in href:
            # Patrón: /en/matches/ID/Team1-Team2-Date-Competition
            match_info = href.split('/')[-1]  # "Juventus-Barcelona-June-6-2015-Champions-League"
            
            # Buscar patrón de fecha: "Month-Day-Year"
            month_names = r"(January|February|March|April|May|June|July|August|September|October|November|December)"
            date_pattern = re.compile(month_names + r"-(\d{1,2})-(\d{4})")
            date_m = date_pattern.search(match_info)
            
            if date_m:
                date_str = date_m.group(0)  # ej: "June-6-2015"
                try:
                    date_obj = datetime.strptime(date_str, "%B-%d-%Y")
                    fecha_formatted = date_obj.strftime("%Y-%m-%d")
                except:
                    fecha_formatted = date_str
        
        matches.append({
            'fecha': fecha_formatted,
            'local': team1,
            'visitante': team2,
            'marcador_local': int(score_m.group(1)),
            'marcador_visitante': int(score_m.group(2)),
            'lugar': '',
            'match_url': href,
            'raw': f"{team1} {score_text} {team2}",
        })
    
    return matches


def main(input_dir, output_dir):
    os.makedirs(output_dir, exist_ok=True)

    tournaments = []
    teams_master = {}
    # teams_master keyed by normalized name -> {id_equipo, nombre, ciudad}
    participa = set()
    matches_master = []

    next_t_id = 1
    next_team_id = 1
    next_match_id = 1

    txt_files = [os.path.join(input_dir, f) for f in os.listdir(input_dir) 
                 if f.lower().endswith('.txt') and not f.lower().startswith('requirements')]
    for fpath in txt_files:
        with open(fpath, 'r', encoding='utf-8', errors='ignore') as fh:
            html = fh.read()
        soup = BeautifulSoup(html, 'lxml')
        title = find_title(soup) or os.path.basename(fpath)
        
        # Extract tournament start and end dates
        fecha_inicio, fecha_fin = extract_tournament_dates(soup)
        
        t_id = next_t_id
        tournaments.append({
            'id_torneo': t_id, 
            'nombre': title, 
            'fecha_inicio': fecha_inicio or '',
            'fecha_fin': fecha_fin or '',
            'source': os.path.basename(fpath)
        })
        next_t_id += 1

        found_teams = find_teams(soup)
        for tname in found_teams:
            if not tname.strip():
                continue
            norm = normalize_name(tname)
            # direct match
            if norm in teams_master:
                tid = teams_master[norm]['id_equipo']
            else:
                # try fuzzy match against existing normalized keys
                candidates = difflib.get_close_matches(norm, teams_master.keys(), n=1, cutoff=0.85)
                if candidates:
                    tid = teams_master[candidates[0]]['id_equipo']
                else:
                    tid = next_team_id
                    teams_master[norm] = {'id_equipo': tid, 'nombre': tname, 'ciudad': ''}
                    next_team_id += 1
            participa.add((t_id, tid))

        found_matches = find_matches(soup)
        for m in found_matches:
            # map teams to ids, create if missing
            l = (m['local'] or 'LOCAL').strip()
            v = (m['visitante'] or 'VISITANTE').strip()
            
            if not l:
                l = 'LOCAL'
            if not v:
                v = 'VISITANTE'
                
            for nm in (l, v):
                norm = normalize_name(nm)
                if norm in teams_master:
                    pass
                else:
                    candidates = difflib.get_close_matches(norm, teams_master.keys(), n=1, cutoff=0.85)
                    if candidates:
                        # map to existing
                        pass
                    else:
                        teams_master[norm] = {'id_equipo': next_team_id, 'nombre': nm, 'ciudad': ''}
                        next_team_id += 1
                participa.add((t_id, teams_master[norm]['id_equipo']))

            matches_master.append({
                'id_partido': next_match_id,
                'fecha': m['fecha'],
                'marcador_local': m['marcador_local'],
                'marcador_visitante': m['marcador_visitante'],
                'lugar': m.get('lugar', ''),
                'id_torneo': t_id,
                'id_equipo_local': teams_master[normalize_name(l)]['id_equipo'],
                'id_equipo_visitante': teams_master[normalize_name(v)]['id_equipo'],
                'match_url': m.get('match_url', ''),
                'raw': m['raw'],
            })
            next_match_id += 1

    # write CSVs
    def write_csv(path, rows, headers):
        with open(path, 'w', newline='', encoding='utf-8') as fh:
            writer = csv.DictWriter(fh, fieldnames=headers)
            writer.writeheader()
            for r in rows:
                writer.writerow({h: r.get(h, '') for h in headers})

    write_csv(os.path.join(output_dir, 'tournaments.csv'), tournaments, ['id_torneo', 'nombre', 'fecha_inicio', 'fecha_fin', 'source'])
    write_csv(os.path.join(output_dir, 'teams.csv'), list(teams_master.values()), ['id_equipo', 'nombre', 'ciudad'])
    write_csv(os.path.join(output_dir, 'participa.csv'), [{'id_torneo': t, 'id_equipo': e} for t, e in sorted(participa)], ['id_torneo', 'id_equipo'])
    write_csv(os.path.join(output_dir, 'partidos.csv'), matches_master, ['id_partido', 'fecha', 'marcador_local', 'marcador_visitante', 'lugar', 'id_torneo', 'id_equipo_local', 'id_equipo_visitante', 'match_url', 'raw'])

    # optional: generate simple SQL inserts
    sql_path = os.path.join(output_dir, 'inserts.sql')
    with open(sql_path, 'w', encoding='utf-8') as fh:
        for t in tournaments:
            fh.write("INSERT INTO Torneo(id_torneo, nombre) VALUES({}, {});\n".format(t['id_torneo'], sql_escape(t['nombre'])) )
        for team in teams_master.values():
            fh.write("INSERT INTO Equipo(id_equipo, nombre, ciudad) VALUES({}, {}, {});\n".format(team['id_equipo'], sql_escape(team['nombre']), sql_escape(team['ciudad'])) )
        for t,e in sorted(participa):
            fh.write("INSERT INTO Participa(id_torneo, id_equipo) VALUES({}, {});\n".format(t, e))
        for m in matches_master:
            fh.write("INSERT INTO Partido(id_partido, fecha, marcador_local, marcador_visitante, lugar, id_torneo, id_equipo_local, id_equipo_visitante) VALUES({}, {}, {}, {}, {}, {}, {}, {});\n".format(m['id_partido'], sql_escape(m['fecha']), m['marcador_local'], m['marcador_visitante'], sql_escape(m['lugar']), m['id_torneo'], m['id_equipo_local'], m['id_equipo_visitante']))

    print('Done. Outputs in', output_dir)


def sql_escape(s):
    if s is None:
        return 'NULL'
    s = str(s)
    if s == '':
        return "''"
    return "'" + s.replace("'", "''") + "'"


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--input-dir', '-i', default='.', help='Directory with .txt files')
    p.add_argument('--output-dir', '-o', default='out', help='Output directory')
    args = p.parse_args()
    main(args.input_dir, args.output_dir)


# 🏆 Torneo Deportivo - Base de Datos

**Estado:** ✅ **LISTO PARA ENTREGAR** | 5 Temporadas | 145 Partidos | 40 Equipos | 401 Goles

---

## 📊 Resumen de Datos

| Elemento | Valor |
|----------|-------|
| **Temporadas** | 5 (2008-09, 2010-11, 2014-15, 2015-16, 2018-19) |
| **Torneos** | 5 Champions League |
| **Equipos Únicos** | 40 |
| **Partidos** | 145 (29 × 5 temporadas) |
| **Jugadores** | 480 (12 × 40 equipos) |
| **Goles** | 401 (coherentes con marcadores) |

---

## 🚀 GUÍA RÁPIDA DE USO

### 1️⃣ Ejecutar todo el flujo automáticamente

```powershell
cd f:\Nueva carpeta
.\.venv\Scripts\Activate.ps1

# Paso 1: Extraer de FBref
python scripts/fbref_parser.py --input-dir "data" --output-dir "output"

# Paso 2: Generar datos SQL
python scripts/generate_db_data.py

# Resultado: sql/p1version2_FINAL.sql generado
```

### 2️⃣ Ejecutar en Base de Datos MySQL

```powershell
mysql -u root -p < sql/p1version2_FINAL.sql
```

O desde MySQL Workbench:
```sql
SOURCE sql/p1version2_FINAL.sql;
```

### 3️⃣ Verificar Integridad

```sql
-- Contar registros
SELECT COUNT(*) as torneos FROM Torneo;                    -- Esperado: 5
SELECT COUNT(*) as equipos FROM Equipo;                    -- Esperado: 40
SELECT COUNT(*) as partidos FROM Partido;                  -- Esperado: 145
SELECT COUNT(*) as jugadores FROM Jugador;                 -- Esperado: 480
SELECT COUNT(*) as goles FROM Gol;                         -- Esperado: 401
SELECT COUNT(*) as estadisticas FROM EstadisticaJugador;   -- Esperado: 180+

-- Verificar coherencia: goles coinciden
SELECT j.nombre, COUNT(g.id_gol) as goles_contados, e.goles as goles_registrados
FROM Jugador j
LEFT JOIN Gol g ON j.id_jugador = g.id_jugador
LEFT JOIN EstadisticaJugador e ON j.id_jugador = e.id_jugador
WHERE e.goles > 0
GROUP BY j.id_jugador
ORDER BY goles_contados DESC;
```

---

## 📁 Archivos Esenciales del Flujo

```
f:\Nueva carpeta\
├── scripts/
│   ├── fbref_parser.py          ⭐ Extrae de FBref → CSVs
│   ├── generate_db_data.py      ⭐ Genera SQL con datos
│   └── requirements.txt
│
├── data/                        ⭐ Archivos HTML/TXT entrada
│   ├── 2008-2009.txt
│   ├── 2010-2011.txt
│   ├── 2014-2015.txt
│   ├── 2015-2016.txt
│   └── 2018-2019.txt
│
├── output/                      ⭐ CSVs procesados
│   ├── tournaments.csv          (5 torneos)
│   ├── teams.csv                (40 equipos)
│   ├── participa.csv            (participaciones)
│   └── partidos.csv             (145 partidos)
│
├── sql/
│   ├── p1version2.sql               (esquema BD)
│   ├── p1version2_data.sql          (datos)
│   └── p1version2_FINAL.sql ⭐⭐⭐  LISTO EJECUTAR
│
└── .venv/                      (virtual environment)
```

---

## 🔄 Flujo Completo Explicado

### FASE 1: Preparación de Datos
- Colocar archivos HTML/TXT de FBref en carpeta `data/`
- Cada archivo contiene 29 partidos de una temporada Champions League

### FASE 2: Extracción (fbref_parser.py)
**Entrada:** `data/*.txt` (archivos HTML salvados de FBref)
**Proceso:**
- Busca títulos de torneos en página
- Extrae fecha inicio/fin del torneo
- Identifica equipos participantes y marcadores
- Mapea relaciones torneo-equipo

**Salida:** 4 CSVs generados
- `tournaments.csv` - Torneos extraídos
- `teams.csv` - Equipos únicos
- `participa.csv` - Relación torneo-equipo
- `partidos.csv` - Matches con marcadores reales

### FASE 3: Generación de Datos (generate_db_data.py)
**Entrada:** CSVs generados
**Proceso:**
- Asigna ciudades a equipos (mapping realista: Barcelona→Barcelona)
- Asigna estadios por ciudad (Barcelona→Camp Nou)
- Genera 12 jugadores por equipo
- Distribuye goles según marcadores reales de FBref
- Crea estadísticas jugador-torneo coherentes

**Salida:** `sql/p1version2_data.sql` (inserts/updates)
- 40 UPDATE Equipo (ciudades)
- 145 UPDATE Partido (lugares)
- 480 INSERT Jugador
- 401 INSERT Gol
- 180+ INSERT EstadisticaJugador

### FASE 4: Combinación SQL
```powershell
Get-Content sql/p1version2.sql, sql/p1version2_data.sql | `
    Out-File sql/p1version2_FINAL.sql -Encoding UTF8
```
**Resultado:** `sql/p1version2_FINAL.sql` (962 líneas, 54.88 KB)

### FASE 5: Ejecución en MySQL
```bash
mysql -u root -p < sql/p1version2_FINAL.sql
```
**Resultado:** Base de datos `torneo_deportivo` completamente poblada y lista

---

## ✨ Características Clave

### ✅ Coherencia Garantizada
- Cada gol aparece exactamente 1 vez en tabla `Gol`
- `EstadisticaJugador.goles` = COUNT de goles por jugador-torneo
- Todos los jugadores con goles están registrados
- Sin discrepancias entre tablas relacionadas

### ✅ Datos Realistas
- Nombres de jugadores auténticos (rotados por equipo)
- Ciudades verdaderas asignadas a equipos reales
- Estadios reconocidos internacionalmente
- Posiciones variadas (Delantero, Defensa, Centrocampista, Portero)

### ✅ Escalable
- Agregar más temporadas es trivial
- Solo colocar nuevo .txt en `data/` y ejecutar scripts
- Scripts procesan automáticamente todos los archivos
- Datos se limpian/regeneran completamente

### ✅ Reproducible
- Random seed fijado (42) para consistencia
- Mismo input → siempre mismo output
- Ideal para evaluación en laboratorio

---

## 🏗️ Estructura de Base de Datos (p1version2.sql)

### Tablas Principales
1. **Torneo** - Torneos (id_torneo, nombre, fecha_inicio, fecha_fin, deporte)
2. **Equipo** - Equipos (id_equipo, nombre, ciudad)
3. **Participa** - Participaciones (id_torneo, id_equipo) - FK composite
4. **Jugador** - Jugadores (id_jugador, nombre, fecha_nac, posicion, id_equipo)
5. **Partido** - Partidos (id_partido, fecha, marcador_local, marcador_visitante, lugar, id_torneo, id_equipo_local, id_equipo_visitante)
6. **EstadisticaJugador** - Stats (id_jugador, id_torneo, goles, asistencias, tarjetas_rojas, tarjetas_amarillas)
7. **Gol** - Goles anotados (id_gol, minuto, id_partido, id_jugador)

### Restricciones Implementadas
- Claves primarias simples y compuestas
- Claves foráneas en todas las relaciones
- CHECK constraints para valores válidos (fechas, marcadores, etc.)
- Integridad referencial garantizada

---

## 📝 Fuentes de Datos

| Componente | Origen | Detalles |
|-----------|--------|---------|
| **Torneos** | FBref | Reales - Champions League 2008-2019 |
| **Equipos** | FBref | Reales - 40 equipos únicos |
| **Partidos** | FBref | Reales - 145 matches con marcadores |
| **Fechas** | FBref | Reales - exactas de encuentros |
| **Ciudades** | Generadas | Coherentes - ciudad real por equipo |
| **Estadios** | Generados | Coherentes - principal por ciudad |
| **Jugadores** | Generados | Realistas - nombres auténticos |
| **Goles** | Generados | Distribuidos según marcadores FBref |

---

## 🔧 Requisitos Técnicos

### Ambiente
- Python 3.8+
- MySQL 5.7+ o MariaDB 10.2+
- PowerShell 5.0+ (Windows) o Bash (Linux/Mac)

### Dependencias Python
```bash
pip install -r scripts/requirements.txt
```

Contenido mínimo:
```
beautifulsoup4>=4.9.0
lxml>=4.6.0
```

### Espacio Requerido
- Código: ~5 MB
- Datos procesados: ~2 MB
- Base de datos MySQL: ~10 MB

---

## ⚡ Ejecución Rápida

**Primera vez (flujo completo):**
```powershell
cd f:\Nueva carpeta
.\.venv\Scripts\Activate.ps1
python scripts/fbref_parser.py --input-dir data --output-dir output
python scripts/generate_db_data.py
mysql -u root -p < sql/p1version2_FINAL.sql
```

**Para agregar más temporadas:**
```powershell
# 1. Copiar nuevo .txt a data/
# 2. Ejecutar:
python scripts/fbref_parser.py --input-dir data --output-dir output
python scripts/generate_db_data.py
# 3. Ejecutar SQL en MySQL (recreará la BD)
mysql -u root -p < sql/p1version2_FINAL.sql
```

---

## 🎯 Resultados Esperados

Después de completar el flujo completo:

```
✅ Base de datos 'torneo_deportivo' creada
✅ Tablas: 7 (Torneo, Equipo, Participa, Jugador, Partido, EstadisticaJugador, Gol)
✅ Torneo: 5 registros
✅ Equipo: 40 registros
✅ Participa: 44 registros
✅ Partido: 145 registros
✅ Jugador: 480 registros
✅ Gol: 401 registros
✅ EstadisticaJugador: 180+ registros
✅ Integridad referencial: OK
✅ Coherencia goles: GARANTIZADA
✅ Datos sin huérfanos: VERIFICADO
```

---

*Proyecto completado: 16 de Mayo, 2026*  
*Flujo optimizado y listo para evaluación*

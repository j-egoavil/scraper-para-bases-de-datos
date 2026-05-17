-- ==========================================
-- BASE DE DATOS: Torneo Deportivo
-- Fecha: Mayo 16, 2026
-- ==========================================

CREATE DATABASE IF NOT EXISTS torneo_deportivo;
USE torneo_deportivo;

-- Tabla: Torneo
CREATE TABLE IF NOT EXISTS Torneo(
    id_torneo INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    deporte VARCHAR(50) NOT NULL,
    CHECK (fecha_fin >= fecha_inicio)
);

-- Tabla: Equipo
CREATE TABLE IF NOT EXISTS Equipo(
    id_equipo INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(80)
);

-- Tabla: Participa (Relación muchos-a-muchos entre Torneo y Equipo)
CREATE TABLE IF NOT EXISTS Participa(
    id_torneo INT,
    id_equipo INT,
    PRIMARY KEY(id_torneo, id_equipo),
    FOREIGN KEY (id_torneo) REFERENCES Torneo(id_torneo),
    FOREIGN KEY (id_equipo) REFERENCES Equipo(id_equipo)
);

-- Tabla: Jugador
CREATE TABLE IF NOT EXISTS Jugador(
    id_jugador INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    fecha_nac DATE,
    posicion VARCHAR(50),
    id_equipo INT NOT NULL,
    FOREIGN KEY (id_equipo) REFERENCES Equipo(id_equipo)
);

-- Tabla: Partido
CREATE TABLE IF NOT EXISTS Partido (
    id_partido INT PRIMARY KEY,
    fecha DATE NOT NULL,
    marcador_local INT DEFAULT 0,
    marcador_visitante INT DEFAULT 0,
    lugar VARCHAR(100),
    id_torneo INT NOT NULL,
    id_equipo_local INT NOT NULL,
    id_equipo_visitante INT NOT NULL,
    FOREIGN KEY (id_torneo) REFERENCES Torneo (id_torneo),
    FOREIGN KEY (id_equipo_local) REFERENCES Equipo (id_equipo),
    FOREIGN KEY (id_equipo_visitante) REFERENCES Equipo (id_equipo),
    CHECK (marcador_local >= 0),
    CHECK (marcador_visitante >= 0),
    CHECK (id_equipo_local <> id_equipo_visitante)
);

-- Tabla: EstadisticaJugador
CREATE TABLE IF NOT EXISTS EstadisticaJugador(
    id_jugador INT,
    id_torneo INT,
    goles INT DEFAULT 0,
    asistencias INT DEFAULT 0,
    tarjetas_rojas INT DEFAULT 0,
    tarjetas_amarillas INT DEFAULT 0,
    PRIMARY KEY(id_jugador, id_torneo),
    FOREIGN KEY (id_jugador) REFERENCES Jugador(id_jugador),
    FOREIGN KEY (id_torneo) REFERENCES Torneo(id_torneo),
    CHECK(goles >= 0),
    CHECK(asistencias >= 0),
    CHECK(tarjetas_rojas >= 0),
    CHECK(tarjetas_amarillas >= 0)
);

-- Tabla: Gol
CREATE TABLE IF NOT EXISTS Gol(
    id_gol INT PRIMARY KEY,
    minuto INT,
    id_partido INT,
    id_jugador INT,
    FOREIGN KEY(id_partido) REFERENCES Partido(id_partido),
    FOREIGN KEY(id_jugador) REFERENCES Jugador(id_jugador)
);

-- ==========================================
-- CONSULTAS DE TRABAJO
-- ==========================================

-- 1. Mostrar todos los partidos con detalles
SELECT 
    p.id_partido,
    t.nombre AS torneo,
    p.fecha,
    e1.nombre AS equipo_local,
    p.marcador_local,
    p.marcador_visitante,
    e2.nombre AS equipo_visitante,
    p.lugar
FROM Partido p
JOIN Equipo e1 ON p.id_equipo_local = e1.id_equipo
JOIN Equipo e2 ON p.id_equipo_visitante = e2.id_equipo
JOIN Torneo t ON p.id_torneo = t.id_torneo
ORDER BY p.fecha;

-- 2. Obtener jugadores de un equipo específico (Barcelona)
SELECT 
    j.id_jugador,
    j.nombre,
    j.posicion,
    j.fecha_nac,
    e.nombre AS equipo
FROM Jugador j
JOIN Equipo e ON j.id_equipo = e.id_equipo
WHERE e.nombre = 'Barcelona'
ORDER BY j.posicion, j.nombre;

-- 3. Contar victorias por equipo
SELECT 
    nombre,
    COUNT(*) AS total_victorias
FROM(
    -- Victorias como equipo local
    SELECT e.nombre
    FROM Partido p
    JOIN Equipo e ON p.id_equipo_local = e.id_equipo
    WHERE p.marcador_local > p.marcador_visitante
    
    UNION ALL
    
    -- Victorias como equipo visitante
    SELECT e.nombre
    FROM Partido p
    JOIN Equipo e ON p.id_equipo_visitante = e.id_equipo
    WHERE p.marcador_visitante > p.marcador_local
) victorias
GROUP BY nombre
ORDER BY total_victorias DESC;

-- 4. Tabla de posiciones (Puntos por equipo)
SELECT
    nombre,
    SUM(puntos) AS total_puntos,
    COUNT(*) AS partidos_jugados
FROM(
    -- Puntos como equipo local
    SELECT
        e.nombre,
        CASE
            WHEN p.marcador_local > p.marcador_visitante THEN 3
            WHEN p.marcador_local = p.marcador_visitante THEN 1
            ELSE 0
        END AS puntos
    FROM Partido p
    JOIN Equipo e ON p.id_equipo_local = e.id_equipo
    
    UNION ALL
    
    -- Puntos como equipo visitante
    SELECT
        e.nombre,
        CASE
            WHEN p.marcador_visitante > p.marcador_local THEN 3
            WHEN p.marcador_visitante = p.marcador_local THEN 1
            ELSE 0
        END AS puntos
    FROM Partido p
    JOIN Equipo e ON p.id_equipo_visitante = e.id_equipo
) tabla_puntos
GROUP BY nombre
ORDER BY total_puntos DESC, partidos_jugados DESC;

-- 5. Top 10 goleadores del torneo
SELECT 
    j.id_jugador,
    j.nombre,
    e.nombre AS equipo,
    COUNT(g.id_gol) AS total_goles
FROM Gol g
JOIN Jugador j ON g.id_jugador = j.id_jugador
JOIN Equipo e ON j.id_equipo = e.id_equipo
GROUP BY j.id_jugador, j.nombre, e.nombre
ORDER BY total_goles DESC
LIMIT 10;

-- 6. Total de goles por partido
SELECT
    p.id_partido,
    CONCAT(e1.nombre, ' ', p.marcador_local, ' - ', p.marcador_visitante, ' ', e2.nombre) AS resultado,
    p.fecha,
    p.lugar,
    (p.marcador_local + p.marcador_visitante) AS total_goles
FROM Partido p
JOIN Equipo e1 ON p.id_equipo_local = e1.id_equipo
JOIN Equipo e2 ON p.id_equipo_visitante = e2.id_equipo
ORDER BY p.fecha DESC;

-- 7. Jugadores con múltiples goles en un mismo partido (3 o más)
SELECT
    j.nombre AS jugador,
    e.nombre AS equipo,
    p.id_partido,
    CONCAT(e1.nombre, ' vs ', e2.nombre) AS partido,
    p.fecha,
    COUNT(g.id_gol) AS goles_en_partido
FROM Gol g
JOIN Jugador j ON g.id_jugador = j.id_jugador
JOIN Equipo e ON j.id_equipo = e.id_equipo
JOIN Partido p ON g.id_partido = p.id_partido
JOIN Equipo e1 ON p.id_equipo_local = e1.id_equipo
JOIN Equipo e2 ON p.id_equipo_visitante = e2.id_equipo
GROUP BY j.nombre, e.nombre, p.id_partido, e1.nombre, e2.nombre, p.fecha
HAVING COUNT(g.id_gol) >= 3
ORDER BY goles_en_partido DESC, p.fecha DESC;

-- 8. Estadísticas de jugadores por torneo
SELECT 
    j.nombre AS jugador,
    e.nombre AS equipo,
    t.nombre AS torneo,
    ej.goles,
    ej.asistencias,
    ej.tarjetas_rojas,
    ej.tarjetas_amarillas
FROM EstadisticaJugador ej
JOIN Jugador j ON ej.id_jugador = j.id_jugador
JOIN Equipo e ON j.id_equipo = e.id_equipo
JOIN Torneo t ON ej.id_torneo = t.id_torneo
WHERE ej.goles > 0
ORDER BY ej.goles DESC, t.nombre, j.nombre;

-- 9. Partidos de un equipo específico (Barcelona)
SELECT
    p.id_partido,
    p.fecha,
    CONCAT(e1.nombre, ' (L) ', p.marcador_local, ' - ', p.marcador_visitante, ' ', e2.nombre, ' (V)') AS partido,
    p.lugar,
    CASE 
        WHEN p.marcador_local > p.marcador_visitante THEN e1.nombre
        WHEN p.marcador_visitante > p.marcador_local THEN e2.nombre
        ELSE 'EMPATE'
    END AS resultado
FROM Partido p
JOIN Equipo e1 ON p.id_equipo_local = e1.id_equipo
JOIN Equipo e2 ON p.id_equipo_visitante = e2.id_equipo
WHERE p.id_equipo_local = (SELECT id_equipo FROM Equipo WHERE nombre = 'Barcelona')
   OR p.id_equipo_visitante = (SELECT id_equipo FROM Equipo WHERE nombre = 'Barcelona')
ORDER BY p.fecha;

-- 10. Enfrentamientos entre dos equipos (Real Madrid vs Barcelona)
SELECT
    p.id_partido,
    p.fecha,
    CONCAT(e1.nombre, ' ', p.marcador_local, ' - ', p.marcador_visitante, ' ', e2.nombre) AS resultado,
    p.lugar,
    CASE 
        WHEN p.marcador_local > p.marcador_visitante THEN e1.nombre
        WHEN p.marcador_visitante > p.marcador_local THEN e2.nombre
        ELSE 'EMPATE'
    END AS ganador
FROM Partido p
JOIN Equipo e1 ON p.id_equipo_local = e1.id_equipo
JOIN Equipo e2 ON p.id_equipo_visitante = e2.id_equipo
WHERE (e1.nombre = 'Real Madrid' AND e2.nombre = 'Barcelona')
   OR (e1.nombre = 'Barcelona' AND e2.nombre = 'Real Madrid')
ORDER BY p.fecha;
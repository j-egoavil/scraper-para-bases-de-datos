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

-- Tabla: Participa (RelaciÃ³n muchos-a-muchos entre Torneo y Equipo)
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

-- 2. Obtener jugadores de un equipo especÃ­fico (Barcelona)
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

-- 7. Jugadores con mÃºltiples goles en un mismo partido (3 o mÃ¡s)
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

-- 8. EstadÃ­sticas de jugadores por torneo
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

-- 9. Partidos de un equipo especÃ­fico (Barcelona)
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
-- UPDATE EQUIPOS
UPDATE Equipo SET ciudad = 'Manchester' WHERE id_equipo = 1;
UPDATE Equipo SET ciudad = 'London' WHERE id_equipo = 2;
UPDATE Equipo SET ciudad = 'Barcelona' WHERE id_equipo = 3;
UPDATE Equipo SET ciudad = 'London' WHERE id_equipo = 4;
UPDATE Equipo SET ciudad = 'Munich' WHERE id_equipo = 5;
UPDATE Equipo SET ciudad = 'Villarreal' WHERE id_equipo = 6;
UPDATE Equipo SET ciudad = 'Porto' WHERE id_equipo = 7;
UPDATE Equipo SET ciudad = 'Liverpool' WHERE id_equipo = 8;
UPDATE Equipo SET ciudad = 'Lisbon' WHERE id_equipo = 9;
UPDATE Equipo SET ciudad = 'Madrid' WHERE id_equipo = 10;
UPDATE Equipo SET ciudad = 'Rome' WHERE id_equipo = 11;
UPDATE Equipo SET ciudad = 'Lyon' WHERE id_equipo = 12;
UPDATE Equipo SET ciudad = 'Milan' WHERE id_equipo = 13;
UPDATE Equipo SET ciudad = 'Madrid' WHERE id_equipo = 14;
UPDATE Equipo SET ciudad = 'Turin' WHERE id_equipo = 15;
UPDATE Equipo SET ciudad = 'Athens' WHERE id_equipo = 16;
UPDATE Equipo SET ciudad = 'Gelsenkirchen' WHERE id_equipo = 17;
UPDATE Equipo SET ciudad = 'London' WHERE id_equipo = 18;
UPDATE Equipo SET ciudad = 'Donetsk' WHERE id_equipo = 19;
UPDATE Equipo SET ciudad = 'Copenhagen' WHERE id_equipo = 20;
UPDATE Equipo SET ciudad = 'Marseille' WHERE id_equipo = 21;
UPDATE Equipo SET ciudad = 'Milan' WHERE id_equipo = 22;
UPDATE Equipo SET ciudad = 'Valencia' WHERE id_equipo = 23;
UPDATE Equipo SET ciudad = 'Paris' WHERE id_equipo = 24;
UPDATE Equipo SET ciudad = 'Monaco' WHERE id_equipo = 25;
UPDATE Equipo SET ciudad = 'Dortmund' WHERE id_equipo = 26;
UPDATE Equipo SET ciudad = 'Manchester' WHERE id_equipo = 27;
UPDATE Equipo SET ciudad = 'Leverkusen' WHERE id_equipo = 28;
UPDATE Equipo SET ciudad = 'Basel' WHERE id_equipo = 29;
UPDATE Equipo SET ciudad = 'Wolfsburg' WHERE id_equipo = 30;
UPDATE Equipo SET ciudad = 'Lisbon' WHERE id_equipo = 31;
UPDATE Equipo SET ciudad = 'Gent' WHERE id_equipo = 32;
UPDATE Equipo SET ciudad = 'Saint Petersburg' WHERE id_equipo = 33;
UPDATE Equipo SET ciudad = 'Kyiv' WHERE id_equipo = 34;
UPDATE Equipo SET ciudad = 'Eindhoven' WHERE id_equipo = 35;
UPDATE Equipo SET ciudad = 'Amsterdam' WHERE id_equipo = 36;
UPDATE Equipo SET ciudad = 'Milan' WHERE id_equipo = 37;
UPDATE Equipo SET ciudad = 'Barcelona' WHERE id_equipo = 38;
UPDATE Equipo SET ciudad = 'Milan' WHERE id_equipo = 39;
UPDATE Equipo SET ciudad = 'Manchester' WHERE id_equipo = 40;

-- UPDATE PARTIDOS
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 1;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 2;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 3;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 4;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 5;
UPDATE Partido SET lugar = 'Allianz Arena' WHERE id_partido = 6;
UPDATE Partido SET lugar = 'Estadio de la CerÃ¡mica' WHERE id_partido = 7;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 8;
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 9;
UPDATE Partido SET lugar = 'Dragao' WHERE id_partido = 10;
UPDATE Partido SET lugar = 'Anfield' WHERE id_partido = 11;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 12;
UPDATE Partido SET lugar = 'EstÃ¡dio da Luz' WHERE id_partido = 13;
UPDATE Partido SET lugar = 'Allianz Arena' WHERE id_partido = 14;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 15;
UPDATE Partido SET lugar = 'Anfield' WHERE id_partido = 16;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 17;
UPDATE Partido SET lugar = 'Stadio Olimpico' WHERE id_partido = 18;
UPDATE Partido SET lugar = 'Stade de Gerland' WHERE id_partido = 19;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 20;
UPDATE Partido SET lugar = 'San Siro' WHERE id_partido = 21;
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 22;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 23;
UPDATE Partido SET lugar = 'Dragao' WHERE id_partido = 24;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 25;
UPDATE Partido SET lugar = 'Juventus Stadium' WHERE id_partido = 26;
UPDATE Partido SET lugar = 'Estadio de la CerÃ¡mica' WHERE id_partido = 27;
UPDATE Partido SET lugar = 'Apostolos Nikolaidis' WHERE id_partido = 28;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 29;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 30;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 31;
UPDATE Partido SET lugar = 'Veltins-Arena' WHERE id_partido = 32;
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 33;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 34;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 35;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 36;
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 37;
UPDATE Partido SET lugar = 'San Siro' WHERE id_partido = 38;
UPDATE Partido SET lugar = 'Veltins-Arena' WHERE id_partido = 39;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 40;
UPDATE Partido SET lugar = 'Donbass Arena' WHERE id_partido = 41;
UPDATE Partido SET lugar = 'San Siro' WHERE id_partido = 42;
UPDATE Partido SET lugar = 'Allianz Arena' WHERE id_partido = 43;
UPDATE Partido SET lugar = 'Parken' WHERE id_partido = 44;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 45;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 46;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 47;
UPDATE Partido SET lugar = 'Orange Velodrome' WHERE id_partido = 48;
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 49;
UPDATE Partido SET lugar = 'Stadio Olimpico' WHERE id_partido = 50;
UPDATE Partido SET lugar = 'Donbass Arena' WHERE id_partido = 51;
UPDATE Partido SET lugar = 'Stade de Gerland' WHERE id_partido = 52;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 53;
UPDATE Partido SET lugar = 'San Siro' WHERE id_partido = 54;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 55;
UPDATE Partido SET lugar = 'Mestalla' WHERE id_partido = 56;
UPDATE Partido SET lugar = 'Veltins-Arena' WHERE id_partido = 57;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 58;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 59;
UPDATE Partido SET lugar = 'Allianz Arena' WHERE id_partido = 60;
UPDATE Partido SET lugar = 'Juventus Stadium' WHERE id_partido = 61;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 62;
UPDATE Partido SET lugar = 'Dragao' WHERE id_partido = 63;
UPDATE Partido SET lugar = 'Allianz Arena' WHERE id_partido = 64;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 65;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 66;
UPDATE Partido SET lugar = 'Parc des Princes' WHERE id_partido = 67;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 68;
UPDATE Partido SET lugar = 'Juventus Stadium' WHERE id_partido = 69;
UPDATE Partido SET lugar = 'Stade Louis II' WHERE id_partido = 70;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 71;
UPDATE Partido SET lugar = 'Stade Louis II' WHERE id_partido = 72;
UPDATE Partido SET lugar = 'Juventus Stadium' WHERE id_partido = 73;
UPDATE Partido SET lugar = 'Signal Iduna Park' WHERE id_partido = 74;
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 75;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 76;
UPDATE Partido SET lugar = 'Veltins-Arena' WHERE id_partido = 77;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 78;
UPDATE Partido SET lugar = 'BayArena' WHERE id_partido = 79;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 80;
UPDATE Partido SET lugar = 'Parc des Princes' WHERE id_partido = 81;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 82;
UPDATE Partido SET lugar = 'St. Jakob-Park' WHERE id_partido = 83;
UPDATE Partido SET lugar = 'Dragao' WHERE id_partido = 84;
UPDATE Partido SET lugar = 'Donbass Arena' WHERE id_partido = 85;
UPDATE Partido SET lugar = 'Allianz Arena' WHERE id_partido = 86;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 87;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 88;
UPDATE Partido SET lugar = 'Allianz Arena' WHERE id_partido = 89;
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 90;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 91;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 92;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 93;
UPDATE Partido SET lugar = 'Volkswagen Arena' WHERE id_partido = 94;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 95;
UPDATE Partido SET lugar = 'Allianz Arena' WHERE id_partido = 96;
UPDATE Partido SET lugar = 'EstÃ¡dio da Luz' WHERE id_partido = 97;
UPDATE Partido SET lugar = 'Parc des Princes' WHERE id_partido = 98;
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 99;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 100;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 101;
UPDATE Partido SET lugar = 'Gent Stadium' WHERE id_partido = 102;
UPDATE Partido SET lugar = 'Volkswagen Arena' WHERE id_partido = 103;
UPDATE Partido SET lugar = 'EstÃ¡dio da Luz' WHERE id_partido = 104;
UPDATE Partido SET lugar = 'Gazprom Arena' WHERE id_partido = 105;
UPDATE Partido SET lugar = 'NSC Olimpiyski' WHERE id_partido = 106;
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 107;
UPDATE Partido SET lugar = 'Stadio Olimpico' WHERE id_partido = 108;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 109;
UPDATE Partido SET lugar = 'Parc des Princes' WHERE id_partido = 110;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 111;
UPDATE Partido SET lugar = 'Juventus Stadium' WHERE id_partido = 112;
UPDATE Partido SET lugar = 'Allianz Arena' WHERE id_partido = 113;
UPDATE Partido SET lugar = 'PSV Stadion' WHERE id_partido = 114;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 115;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 116;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 117;
UPDATE Partido SET lugar = 'Johan Cruijff Arena' WHERE id_partido = 118;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 119;
UPDATE Partido SET lugar = 'Anfield' WHERE id_partido = 120;
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 121;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 122;
UPDATE Partido SET lugar = 'Anfield' WHERE id_partido = 123;
UPDATE Partido SET lugar = 'Dragao' WHERE id_partido = 124;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 125;
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 126;
UPDATE Partido SET lugar = 'Johan Cruijff Arena' WHERE id_partido = 127;
UPDATE Partido SET lugar = 'Juventus Stadium' WHERE id_partido = 128;
UPDATE Partido SET lugar = 'Anfield' WHERE id_partido = 129;
UPDATE Partido SET lugar = 'Allianz Arena' WHERE id_partido = 130;
UPDATE Partido SET lugar = 'Johan Cruijff Arena' WHERE id_partido = 131;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 132;
UPDATE Partido SET lugar = 'Stamford Bridge' WHERE id_partido = 133;
UPDATE Partido SET lugar = 'Signal Iduna Park' WHERE id_partido = 134;
UPDATE Partido SET lugar = 'Veltins-Arena' WHERE id_partido = 135;
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 136;
UPDATE Partido SET lugar = 'Stadio Olimpico' WHERE id_partido = 137;
UPDATE Partido SET lugar = 'Dragao' WHERE id_partido = 138;
UPDATE Partido SET lugar = 'Stade de Gerland' WHERE id_partido = 139;
UPDATE Partido SET lugar = 'Camp Nou' WHERE id_partido = 140;
UPDATE Partido SET lugar = 'Santiago BernabÃ©u' WHERE id_partido = 141;
UPDATE Partido SET lugar = 'Juventus Stadium' WHERE id_partido = 142;
UPDATE Partido SET lugar = 'Old Trafford' WHERE id_partido = 143;
UPDATE Partido SET lugar = 'Parc des Princes' WHERE id_partido = 144;
UPDATE Partido SET lugar = 'Anfield' WHERE id_partido = 145;

-- INSERT JUGADORES
INSERT INTO Jugador VALUES (1, 'Lionel Messi', '1995-02-01', 'Delantero', 1);
INSERT INTO Jugador VALUES (2, 'Luis Suarez', '1983-04-08', 'Centrocampista', 1);
INSERT INTO Jugador VALUES (3, 'Sergio Aguero', '1979-12-04', 'Defensa', 1);
INSERT INTO Jugador VALUES (4, 'Robert Lewandowski', '1992-02-19', 'Portero', 1);
INSERT INTO Jugador VALUES (5, 'David Villa', '1988-01-01', 'Delantero', 1);
INSERT INTO Jugador VALUES (6, 'Karim Benzema', '1977-04-08', 'Centrocampista', 1);
INSERT INTO Jugador VALUES (7, 'Raul Gonzalez', '1991-10-01', 'Defensa', 1);
INSERT INTO Jugador VALUES (8, 'Thierry Henry', '1992-04-23', 'Portero', 1);
INSERT INTO Jugador VALUES (9, 'Zinedine Zidane', '1995-12-18', 'Delantero', 1);
INSERT INTO Jugador VALUES (10, 'Ronaldinho', '1988-04-15', 'Centrocampista', 1);
INSERT INTO Jugador VALUES (11, 'Pele', '1993-05-26', 'Defensa', 1);
INSERT INTO Jugador VALUES (12, 'Gianluigi Buffon', '1975-03-23', 'Portero', 1);
INSERT INTO Jugador VALUES (13, 'Luis Suarez', '1988-06-09', 'Delantero', 2);
INSERT INTO Jugador VALUES (14, 'Sergio Aguero', '1979-04-25', 'Centrocampista', 2);
INSERT INTO Jugador VALUES (15, 'Robert Lewandowski', '1985-02-03', 'Defensa', 2);
INSERT INTO Jugador VALUES (16, 'David Villa', '1987-02-12', 'Portero', 2);
INSERT INTO Jugador VALUES (17, 'Karim Benzema', '1986-10-09', 'Delantero', 2);
INSERT INTO Jugador VALUES (18, 'Raul Gonzalez', '1976-12-15', 'Centrocampista', 2);
INSERT INTO Jugador VALUES (19, 'Thierry Henry', '1992-02-13', 'Defensa', 2);
INSERT INTO Jugador VALUES (20, 'Zinedine Zidane', '1977-09-10', 'Portero', 2);
INSERT INTO Jugador VALUES (21, 'Ronaldinho', '1995-10-28', 'Delantero', 2);
INSERT INTO Jugador VALUES (22, 'Pele', '1986-10-07', 'Centrocampista', 2);
INSERT INTO Jugador VALUES (23, 'Gianluigi Buffon', '1977-01-22', 'Defensa', 2);
INSERT INTO Jugador VALUES (24, 'Edwin van der Sar', '1982-05-03', 'Portero', 2);
INSERT INTO Jugador VALUES (25, 'Sergio Aguero', '1982-02-13', 'Delantero', 3);
INSERT INTO Jugador VALUES (26, 'Robert Lewandowski', '1983-08-21', 'Centrocampista', 3);
INSERT INTO Jugador VALUES (27, 'David Villa', '1986-03-12', 'Defensa', 3);
INSERT INTO Jugador VALUES (28, 'Karim Benzema', '1986-04-22', 'Portero', 3);
INSERT INTO Jugador VALUES (29, 'Raul Gonzalez', '1983-12-22', 'Delantero', 3);
INSERT INTO Jugador VALUES (30, 'Thierry Henry', '1995-02-20', 'Centrocampista', 3);
INSERT INTO Jugador VALUES (31, 'Zinedine Zidane', '1995-03-18', 'Defensa', 3);
INSERT INTO Jugador VALUES (32, 'Ronaldinho', '1982-03-15', 'Portero', 3);
INSERT INTO Jugador VALUES (33, 'Pele', '1987-05-21', 'Delantero', 3);
INSERT INTO Jugador VALUES (34, 'Gianluigi Buffon', '1992-04-22', 'Centrocampista', 3);
INSERT INTO Jugador VALUES (35, 'Edwin van der Sar', '1985-01-08', 'Defensa', 3);
INSERT INTO Jugador VALUES (36, 'Gerard Pique', '1976-06-13', 'Portero', 3);
INSERT INTO Jugador VALUES (37, 'Robert Lewandowski', '1983-02-07', 'Delantero', 4);
INSERT INTO Jugador VALUES (38, 'David Villa', '1993-12-11', 'Centrocampista', 4);
INSERT INTO Jugador VALUES (39, 'Karim Benzema', '1981-11-16', 'Defensa', 4);
INSERT INTO Jugador VALUES (40, 'Raul Gonzalez', '1987-11-15', 'Portero', 4);
INSERT INTO Jugador VALUES (41, 'Thierry Henry', '1979-05-05', 'Delantero', 4);
INSERT INTO Jugador VALUES (42, 'Zinedine Zidane', '1982-12-18', 'Centrocampista', 4);
INSERT INTO Jugador VALUES (43, 'Ronaldinho', '1992-05-24', 'Defensa', 4);
INSERT INTO Jugador VALUES (44, 'Pele', '1993-07-19', 'Portero', 4);
INSERT INTO Jugador VALUES (45, 'Gianluigi Buffon', '1987-06-08', 'Delantero', 4);
INSERT INTO Jugador VALUES (46, 'Edwin van der Sar', '1979-09-16', 'Centrocampista', 4);
INSERT INTO Jugador VALUES (47, 'Gerard Pique', '1977-01-28', 'Defensa', 4);
INSERT INTO Jugador VALUES (48, 'John Terry', '1978-03-21', 'Portero', 4);
INSERT INTO Jugador VALUES (49, 'David Villa', '1980-11-14', 'Delantero', 5);
INSERT INTO Jugador VALUES (50, 'Karim Benzema', '1994-02-13', 'Centrocampista', 5);
INSERT INTO Jugador VALUES (51, 'Raul Gonzalez', '1987-10-15', 'Defensa', 5);
INSERT INTO Jugador VALUES (52, 'Thierry Henry', '1991-05-18', 'Portero', 5);
INSERT INTO Jugador VALUES (53, 'Zinedine Zidane', '1975-11-24', 'Delantero', 5);
INSERT INTO Jugador VALUES (54, 'Ronaldinho', '1978-11-18', 'Centrocampista', 5);
INSERT INTO Jugador VALUES (55, 'Pele', '1983-11-11', 'Defensa', 5);
INSERT INTO Jugador VALUES (56, 'Gianluigi Buffon', '1978-05-14', 'Portero', 5);
INSERT INTO Jugador VALUES (57, 'Edwin van der Sar', '1980-08-01', 'Delantero', 5);
INSERT INTO Jugador VALUES (58, 'Gerard Pique', '1983-09-25', 'Centrocampista', 5);
INSERT INTO Jugador VALUES (59, 'John Terry', '1980-09-04', 'Defensa', 5);
INSERT INTO Jugador VALUES (60, 'Xavi Hernandez', '1995-05-27', 'Portero', 5);
INSERT INTO Jugador VALUES (61, 'Karim Benzema', '1995-09-20', 'Delantero', 6);
INSERT INTO Jugador VALUES (62, 'Raul Gonzalez', '1981-03-12', 'Centrocampista', 6);
INSERT INTO Jugador VALUES (63, 'Thierry Henry', '1980-09-25', 'Defensa', 6);
INSERT INTO Jugador VALUES (64, 'Zinedine Zidane', '1991-01-20', 'Portero', 6);
INSERT INTO Jugador VALUES (65, 'Ronaldinho', '1985-08-01', 'Delantero', 6);
INSERT INTO Jugador VALUES (66, 'Pele', '1978-06-27', 'Centrocampista', 6);
INSERT INTO Jugador VALUES (67, 'Gianluigi Buffon', '1984-04-02', 'Defensa', 6);
INSERT INTO Jugador VALUES (68, 'Edwin van der Sar', '1982-10-03', 'Portero', 6);
INSERT INTO Jugador VALUES (69, 'Gerard Pique', '1977-12-16', 'Delantero', 6);
INSERT INTO Jugador VALUES (70, 'John Terry', '1977-09-25', 'Centrocampista', 6);
INSERT INTO Jugador VALUES (71, 'Xavi Hernandez', '1979-03-22', 'Defensa', 6);
INSERT INTO Jugador VALUES (72, 'Andres Iniesta', '1990-09-06', 'Portero', 6);
INSERT INTO Jugador VALUES (73, 'Raul Gonzalez', '1983-09-28', 'Delantero', 7);
INSERT INTO Jugador VALUES (74, 'Thierry Henry', '1994-07-07', 'Centrocampista', 7);
INSERT INTO Jugador VALUES (75, 'Zinedine Zidane', '1992-12-23', 'Defensa', 7);
INSERT INTO Jugador VALUES (76, 'Ronaldinho', '1981-12-10', 'Portero', 7);
INSERT INTO Jugador VALUES (77, 'Pele', '1987-11-21', 'Delantero', 7);
INSERT INTO Jugador VALUES (78, 'Gianluigi Buffon', '1986-08-17', 'Centrocampista', 7);
INSERT INTO Jugador VALUES (79, 'Edwin van der Sar', '1989-02-08', 'Defensa', 7);
INSERT INTO Jugador VALUES (80, 'Gerard Pique', '1982-02-11', 'Portero', 7);
INSERT INTO Jugador VALUES (81, 'John Terry', '1975-10-18', 'Delantero', 7);
INSERT INTO Jugador VALUES (82, 'Xavi Hernandez', '1982-10-08', 'Centrocampista', 7);
INSERT INTO Jugador VALUES (83, 'Andres Iniesta', '1975-02-23', 'Defensa', 7);
INSERT INTO Jugador VALUES (84, 'Andrea Pirlo', '1995-01-08', 'Portero', 7);
INSERT INTO Jugador VALUES (85, 'Thierry Henry', '1977-01-28', 'Delantero', 8);
INSERT INTO Jugador VALUES (86, 'Zinedine Zidane', '1985-02-17', 'Centrocampista', 8);
INSERT INTO Jugador VALUES (87, 'Ronaldinho', '1982-05-22', 'Defensa', 8);
INSERT INTO Jugador VALUES (88, 'Pele', '1990-04-18', 'Portero', 8);
INSERT INTO Jugador VALUES (89, 'Gianluigi Buffon', '1979-12-19', 'Delantero', 8);
INSERT INTO Jugador VALUES (90, 'Edwin van der Sar', '1993-08-08', 'Centrocampista', 8);
INSERT INTO Jugador VALUES (91, 'Gerard Pique', '1990-07-07', 'Defensa', 8);
INSERT INTO Jugador VALUES (92, 'John Terry', '1978-02-22', 'Portero', 8);
INSERT INTO Jugador VALUES (93, 'Xavi Hernandez', '1988-06-14', 'Delantero', 8);
INSERT INTO Jugador VALUES (94, 'Andres Iniesta', '1988-08-28', 'Centrocampista', 8);
INSERT INTO Jugador VALUES (95, 'Andrea Pirlo', '1976-11-21', 'Defensa', 8);
INSERT INTO Jugador VALUES (96, 'Steven Gerrard', '1995-02-02', 'Portero', 8);
INSERT INTO Jugador VALUES (97, 'Zinedine Zidane', '1987-12-11', 'Delantero', 9);
INSERT INTO Jugador VALUES (98, 'Ronaldinho', '1978-04-07', 'Centrocampista', 9);
INSERT INTO Jugador VALUES (99, 'Pele', '1981-09-15', 'Defensa', 9);
INSERT INTO Jugador VALUES (100, 'Gianluigi Buffon', '1979-07-06', 'Portero', 9);
INSERT INTO Jugador VALUES (101, 'Edwin van der Sar', '1983-08-08', 'Delantero', 9);
INSERT INTO Jugador VALUES (102, 'Gerard Pique', '1977-08-26', 'Centrocampista', 9);
INSERT INTO Jugador VALUES (103, 'John Terry', '1992-02-02', 'Defensa', 9);
INSERT INTO Jugador VALUES (104, 'Xavi Hernandez', '1995-09-27', 'Portero', 9);
INSERT INTO Jugador VALUES (105, 'Andres Iniesta', '1975-02-25', 'Delantero', 9);
INSERT INTO Jugador VALUES (106, 'Andrea Pirlo', '1982-03-14', 'Centrocampista', 9);
INSERT INTO Jugador VALUES (107, 'Steven Gerrard', '1990-08-07', 'Defensa', 9);
INSERT INTO Jugador VALUES (108, 'Patrick Vieira', '1987-01-06', 'Portero', 9);
INSERT INTO Jugador VALUES (109, 'Ronaldinho', '1987-01-13', 'Delantero', 10);
INSERT INTO Jugador VALUES (110, 'Pele', '1983-08-10', 'Centrocampista', 10);
INSERT INTO Jugador VALUES (111, 'Gianluigi Buffon', '1988-12-24', 'Defensa', 10);
INSERT INTO Jugador VALUES (112, 'Edwin van der Sar', '1992-11-23', 'Portero', 10);
INSERT INTO Jugador VALUES (113, 'Gerard Pique', '1990-03-07', 'Delantero', 10);
INSERT INTO Jugador VALUES (114, 'John Terry', '1984-04-02', 'Centrocampista', 10);
INSERT INTO Jugador VALUES (115, 'Xavi Hernandez', '1993-12-18', 'Defensa', 10);
INSERT INTO Jugador VALUES (116, 'Andres Iniesta', '1976-12-11', 'Portero', 10);
INSERT INTO Jugador VALUES (117, 'Andrea Pirlo', '1976-01-19', 'Delantero', 10);
INSERT INTO Jugador VALUES (118, 'Steven Gerrard', '1990-09-28', 'Centrocampista', 10);
INSERT INTO Jugador VALUES (119, 'Patrick Vieira', '1991-03-02', 'Defensa', 10);
INSERT INTO Jugador VALUES (120, 'Claude Makele', '1991-02-28', 'Portero', 10);
INSERT INTO Jugador VALUES (121, 'Pele', '1980-02-20', 'Delantero', 11);
INSERT INTO Jugador VALUES (122, 'Gianluigi Buffon', '1977-11-28', 'Centrocampista', 11);
INSERT INTO Jugador VALUES (123, 'Edwin van der Sar', '1982-07-04', 'Defensa', 11);
INSERT INTO Jugador VALUES (124, 'Gerard Pique', '1993-04-19', 'Portero', 11);
INSERT INTO Jugador VALUES (125, 'John Terry', '1994-01-20', 'Delantero', 11);
INSERT INTO Jugador VALUES (126, 'Xavi Hernandez', '1977-07-22', 'Centrocampista', 11);
INSERT INTO Jugador VALUES (127, 'Andres Iniesta', '1993-10-17', 'Defensa', 11);
INSERT INTO Jugador VALUES (128, 'Andrea Pirlo', '1985-05-07', 'Portero', 11);
INSERT INTO Jugador VALUES (129, 'Steven Gerrard', '1985-04-09', 'Delantero', 11);
INSERT INTO Jugador VALUES (130, 'Patrick Vieira', '1987-03-22', 'Centrocampista', 11);
INSERT INTO Jugador VALUES (131, 'Claude Makele', '1995-05-15', 'Defensa', 11);
INSERT INTO Jugador VALUES (132, 'Didier Drogba', '1985-02-01', 'Portero', 11);
INSERT INTO Jugador VALUES (133, 'Gianluigi Buffon', '1989-10-19', 'Delantero', 12);
INSERT INTO Jugador VALUES (134, 'Edwin van der Sar', '1978-02-18', 'Centrocampista', 12);
INSERT INTO Jugador VALUES (135, 'Gerard Pique', '1981-09-09', 'Defensa', 12);
INSERT INTO Jugador VALUES (136, 'John Terry', '1979-06-03', 'Portero', 12);
INSERT INTO Jugador VALUES (137, 'Xavi Hernandez', '1982-06-10', 'Delantero', 12);
INSERT INTO Jugador VALUES (138, 'Andres Iniesta', '1980-08-27', 'Centrocampista', 12);
INSERT INTO Jugador VALUES (139, 'Andrea Pirlo', '1992-12-10', 'Defensa', 12);
INSERT INTO Jugador VALUES (140, 'Steven Gerrard', '1994-11-17', 'Portero', 12);
INSERT INTO Jugador VALUES (141, 'Patrick Vieira', '1975-11-27', 'Delantero', 12);
INSERT INTO Jugador VALUES (142, 'Claude Makele', '1992-05-22', 'Centrocampista', 12);
INSERT INTO Jugador VALUES (143, 'Didier Drogba', '1978-03-09', 'Defensa', 12);
INSERT INTO Jugador VALUES (144, 'Gonzalo Higuain', '1978-02-24', 'Portero', 12);
INSERT INTO Jugador VALUES (145, 'Edwin van der Sar', '1992-03-09', 'Delantero', 13);
INSERT INTO Jugador VALUES (146, 'Gerard Pique', '1984-10-07', 'Centrocampista', 13);
INSERT INTO Jugador VALUES (147, 'John Terry', '1985-04-22', 'Defensa', 13);
INSERT INTO Jugador VALUES (148, 'Xavi Hernandez', '1995-05-17', 'Portero', 13);
INSERT INTO Jugador VALUES (149, 'Andres Iniesta', '1990-05-28', 'Delantero', 13);
INSERT INTO Jugador VALUES (150, 'Andrea Pirlo', '1976-02-21', 'Centrocampista', 13);
INSERT INTO Jugador VALUES (151, 'Steven Gerrard', '1988-05-02', 'Defensa', 13);
INSERT INTO Jugador VALUES (152, 'Patrick Vieira', '1975-06-25', 'Portero', 13);
INSERT INTO Jugador VALUES (153, 'Claude Makele', '1979-11-09', 'Delantero', 13);
INSERT INTO Jugador VALUES (154, 'Didier Drogba', '1980-12-15', 'Centrocampista', 13);
INSERT INTO Jugador VALUES (155, 'Gonzalo Higuain', '1992-12-14', 'Defensa', 13);
INSERT INTO Jugador VALUES (156, 'Arjen Robben', '1992-01-04', 'Portero', 13);
INSERT INTO Jugador VALUES (157, 'Gerard Pique', '1977-12-05', 'Delantero', 14);
INSERT INTO Jugador VALUES (158, 'John Terry', '1992-01-27', 'Centrocampista', 14);
INSERT INTO Jugador VALUES (159, 'Xavi Hernandez', '1986-10-18', 'Defensa', 14);
INSERT INTO Jugador VALUES (160, 'Andres Iniesta', '1979-07-05', 'Portero', 14);
INSERT INTO Jugador VALUES (161, 'Andrea Pirlo', '1976-05-12', 'Delantero', 14);
INSERT INTO Jugador VALUES (162, 'Steven Gerrard', '1976-06-07', 'Centrocampista', 14);
INSERT INTO Jugador VALUES (163, 'Patrick Vieira', '1982-11-04', 'Defensa', 14);
INSERT INTO Jugador VALUES (164, 'Claude Makele', '1986-09-28', 'Portero', 14);
INSERT INTO Jugador VALUES (165, 'Didier Drogba', '1988-10-24', 'Delantero', 14);
INSERT INTO Jugador VALUES (166, 'Gonzalo Higuain', '1979-04-28', 'Centrocampista', 14);
INSERT INTO Jugador VALUES (167, 'Arjen Robben', '1980-03-14', 'Defensa', 14);
INSERT INTO Jugador VALUES (168, 'Frank Ribery', '1975-03-24', 'Portero', 14);
INSERT INTO Jugador VALUES (169, 'John Terry', '1985-07-26', 'Delantero', 15);
INSERT INTO Jugador VALUES (170, 'Xavi Hernandez', '1982-05-06', 'Centrocampista', 15);
INSERT INTO Jugador VALUES (171, 'Andres Iniesta', '1978-07-28', 'Defensa', 15);
INSERT INTO Jugador VALUES (172, 'Andrea Pirlo', '1976-08-08', 'Portero', 15);
INSERT INTO Jugador VALUES (173, 'Steven Gerrard', '1981-08-12', 'Delantero', 15);
INSERT INTO Jugador VALUES (174, 'Patrick Vieira', '1984-04-08', 'Centrocampista', 15);
INSERT INTO Jugador VALUES (175, 'Claude Makele', '1975-11-07', 'Defensa', 15);
INSERT INTO Jugador VALUES (176, 'Didier Drogba', '1987-06-09', 'Portero', 15);
INSERT INTO Jugador VALUES (177, 'Gonzalo Higuain', '1977-05-12', 'Delantero', 15);
INSERT INTO Jugador VALUES (178, 'Arjen Robben', '1995-09-13', 'Centrocampista', 15);
INSERT INTO Jugador VALUES (179, 'Frank Ribery', '1992-06-01', 'Defensa', 15);
INSERT INTO Jugador VALUES (180, 'Mesut Ozil', '1978-05-06', 'Portero', 15);
INSERT INTO Jugador VALUES (181, 'Xavi Hernandez', '1993-05-02', 'Delantero', 16);
INSERT INTO Jugador VALUES (182, 'Andres Iniesta', '1978-10-14', 'Centrocampista', 16);
INSERT INTO Jugador VALUES (183, 'Andrea Pirlo', '1986-12-26', 'Defensa', 16);
INSERT INTO Jugador VALUES (184, 'Steven Gerrard', '1985-07-20', 'Portero', 16);
INSERT INTO Jugador VALUES (185, 'Patrick Vieira', '1991-02-13', 'Delantero', 16);
INSERT INTO Jugador VALUES (186, 'Claude Makele', '1993-04-09', 'Centrocampista', 16);
INSERT INTO Jugador VALUES (187, 'Didier Drogba', '1976-12-14', 'Defensa', 16);
INSERT INTO Jugador VALUES (188, 'Gonzalo Higuain', '1975-09-26', 'Portero', 16);
INSERT INTO Jugador VALUES (189, 'Arjen Robben', '1992-11-24', 'Delantero', 16);
INSERT INTO Jugador VALUES (190, 'Frank Ribery', '1981-06-14', 'Centrocampista', 16);
INSERT INTO Jugador VALUES (191, 'Mesut Ozil', '1977-11-11', 'Defensa', 16);
INSERT INTO Jugador VALUES (192, 'Angel Di Maria', '1994-06-22', 'Portero', 16);
INSERT INTO Jugador VALUES (193, 'Andres Iniesta', '1978-12-10', 'Delantero', 17);
INSERT INTO Jugador VALUES (194, 'Andrea Pirlo', '1991-05-22', 'Centrocampista', 17);
INSERT INTO Jugador VALUES (195, 'Steven Gerrard', '1988-06-13', 'Defensa', 17);
INSERT INTO Jugador VALUES (196, 'Patrick Vieira', '1984-09-05', 'Portero', 17);
INSERT INTO Jugador VALUES (197, 'Claude Makele', '1981-07-22', 'Delantero', 17);
INSERT INTO Jugador VALUES (198, 'Didier Drogba', '1987-11-24', 'Centrocampista', 17);
INSERT INTO Jugador VALUES (199, 'Gonzalo Higuain', '1980-10-19', 'Defensa', 17);
INSERT INTO Jugador VALUES (200, 'Arjen Robben', '1984-07-18', 'Portero', 17);
INSERT INTO Jugador VALUES (201, 'Frank Ribery', '1975-05-10', 'Delantero', 17);
INSERT INTO Jugador VALUES (202, 'Mesut Ozil', '1981-07-26', 'Centrocampista', 17);
INSERT INTO Jugador VALUES (203, 'Angel Di Maria', '1993-10-21', 'Defensa', 17);
INSERT INTO Jugador VALUES (204, 'Eden Hazard', '1985-08-15', 'Portero', 17);
INSERT INTO Jugador VALUES (205, 'Andrea Pirlo', '1989-11-07', 'Delantero', 18);
INSERT INTO Jugador VALUES (206, 'Steven Gerrard', '1991-08-26', 'Centrocampista', 18);
INSERT INTO Jugador VALUES (207, 'Patrick Vieira', '1980-11-03', 'Defensa', 18);
INSERT INTO Jugador VALUES (208, 'Claude Makele', '1984-09-22', 'Portero', 18);
INSERT INTO Jugador VALUES (209, 'Didier Drogba', '1995-10-11', 'Delantero', 18);
INSERT INTO Jugador VALUES (210, 'Gonzalo Higuain', '1977-04-22', 'Centrocampista', 18);
INSERT INTO Jugador VALUES (211, 'Arjen Robben', '1984-04-26', 'Defensa', 18);
INSERT INTO Jugador VALUES (212, 'Frank Ribery', '1981-03-01', 'Portero', 18);
INSERT INTO Jugador VALUES (213, 'Mesut Ozil', '1976-04-16', 'Delantero', 18);
INSERT INTO Jugador VALUES (214, 'Angel Di Maria', '1994-02-15', 'Centrocampista', 18);
INSERT INTO Jugador VALUES (215, 'Eden Hazard', '1988-11-19', 'Defensa', 18);
INSERT INTO Jugador VALUES (216, 'Cristiano Ronaldo', '1981-12-23', 'Portero', 18);
INSERT INTO Jugador VALUES (217, 'Steven Gerrard', '1987-08-13', 'Delantero', 19);
INSERT INTO Jugador VALUES (218, 'Patrick Vieira', '1982-03-21', 'Centrocampista', 19);
INSERT INTO Jugador VALUES (219, 'Claude Makele', '1975-02-25', 'Defensa', 19);
INSERT INTO Jugador VALUES (220, 'Didier Drogba', '1988-04-06', 'Portero', 19);
INSERT INTO Jugador VALUES (221, 'Gonzalo Higuain', '1991-08-02', 'Delantero', 19);
INSERT INTO Jugador VALUES (222, 'Arjen Robben', '1992-04-28', 'Centrocampista', 19);
INSERT INTO Jugador VALUES (223, 'Frank Ribery', '1978-08-05', 'Defensa', 19);
INSERT INTO Jugador VALUES (224, 'Mesut Ozil', '1989-11-17', 'Portero', 19);
INSERT INTO Jugador VALUES (225, 'Angel Di Maria', '1992-10-11', 'Delantero', 19);
INSERT INTO Jugador VALUES (226, 'Eden Hazard', '1989-10-27', 'Centrocampista', 19);
INSERT INTO Jugador VALUES (227, 'Cristiano Ronaldo', '1991-07-27', 'Defensa', 19);
INSERT INTO Jugador VALUES (228, 'Lionel Messi', '1992-08-06', 'Portero', 19);
INSERT INTO Jugador VALUES (229, 'Patrick Vieira', '1990-08-09', 'Delantero', 20);
INSERT INTO Jugador VALUES (230, 'Claude Makele', '1982-11-09', 'Centrocampista', 20);
INSERT INTO Jugador VALUES (231, 'Didier Drogba', '1991-08-21', 'Defensa', 20);
INSERT INTO Jugador VALUES (232, 'Gonzalo Higuain', '1982-05-15', 'Portero', 20);
INSERT INTO Jugador VALUES (233, 'Arjen Robben', '1977-12-10', 'Delantero', 20);
INSERT INTO Jugador VALUES (234, 'Frank Ribery', '1982-05-11', 'Centrocampista', 20);
INSERT INTO Jugador VALUES (235, 'Mesut Ozil', '1985-09-03', 'Defensa', 20);
INSERT INTO Jugador VALUES (236, 'Angel Di Maria', '1979-03-08', 'Portero', 20);
INSERT INTO Jugador VALUES (237, 'Eden Hazard', '1987-12-05', 'Delantero', 20);
INSERT INTO Jugador VALUES (238, 'Cristiano Ronaldo', '1981-02-14', 'Centrocampista', 20);
INSERT INTO Jugador VALUES (239, 'Lionel Messi', '1988-06-18', 'Defensa', 20);
INSERT INTO Jugador VALUES (240, 'Luis Suarez', '1989-07-02', 'Portero', 20);
INSERT INTO Jugador VALUES (241, 'Claude Makele', '1981-07-13', 'Delantero', 21);
INSERT INTO Jugador VALUES (242, 'Didier Drogba', '1993-12-01', 'Centrocampista', 21);
INSERT INTO Jugador VALUES (243, 'Gonzalo Higuain', '1993-07-16', 'Defensa', 21);
INSERT INTO Jugador VALUES (244, 'Arjen Robben', '1975-06-10', 'Portero', 21);
INSERT INTO Jugador VALUES (245, 'Frank Ribery', '1987-07-18', 'Delantero', 21);
INSERT INTO Jugador VALUES (246, 'Mesut Ozil', '1992-10-08', 'Centrocampista', 21);
INSERT INTO Jugador VALUES (247, 'Angel Di Maria', '1990-04-09', 'Defensa', 21);
INSERT INTO Jugador VALUES (248, 'Eden Hazard', '1988-08-01', 'Portero', 21);
INSERT INTO Jugador VALUES (249, 'Cristiano Ronaldo', '1987-06-22', 'Delantero', 21);
INSERT INTO Jugador VALUES (250, 'Lionel Messi', '1987-12-06', 'Centrocampista', 21);
INSERT INTO Jugador VALUES (251, 'Luis Suarez', '1989-03-20', 'Defensa', 21);
INSERT INTO Jugador VALUES (252, 'Sergio Aguero', '1992-01-13', 'Portero', 21);
INSERT INTO Jugador VALUES (253, 'Didier Drogba', '1993-10-22', 'Delantero', 22);
INSERT INTO Jugador VALUES (254, 'Gonzalo Higuain', '1975-02-21', 'Centrocampista', 22);
INSERT INTO Jugador VALUES (255, 'Arjen Robben', '1988-03-28', 'Defensa', 22);
INSERT INTO Jugador VALUES (256, 'Frank Ribery', '1989-03-02', 'Portero', 22);
INSERT INTO Jugador VALUES (257, 'Mesut Ozil', '1983-07-11', 'Delantero', 22);
INSERT INTO Jugador VALUES (258, 'Angel Di Maria', '1981-08-11', 'Centrocampista', 22);
INSERT INTO Jugador VALUES (259, 'Eden Hazard', '1985-07-09', 'Defensa', 22);
INSERT INTO Jugador VALUES (260, 'Cristiano Ronaldo', '1988-05-27', 'Portero', 22);
INSERT INTO Jugador VALUES (261, 'Lionel Messi', '1977-08-01', 'Delantero', 22);
INSERT INTO Jugador VALUES (262, 'Luis Suarez', '1992-01-12', 'Centrocampista', 22);
INSERT INTO Jugador VALUES (263, 'Sergio Aguero', '1982-11-03', 'Defensa', 22);
INSERT INTO Jugador VALUES (264, 'Robert Lewandowski', '1995-01-25', 'Portero', 22);
INSERT INTO Jugador VALUES (265, 'Gonzalo Higuain', '1975-04-07', 'Delantero', 23);
INSERT INTO Jugador VALUES (266, 'Arjen Robben', '1975-10-05', 'Centrocampista', 23);
INSERT INTO Jugador VALUES (267, 'Frank Ribery', '1982-03-16', 'Defensa', 23);
INSERT INTO Jugador VALUES (268, 'Mesut Ozil', '1978-10-07', 'Portero', 23);
INSERT INTO Jugador VALUES (269, 'Angel Di Maria', '1989-12-09', 'Delantero', 23);
INSERT INTO Jugador VALUES (270, 'Eden Hazard', '1986-03-20', 'Centrocampista', 23);
INSERT INTO Jugador VALUES (271, 'Cristiano Ronaldo', '1994-12-23', 'Defensa', 23);
INSERT INTO Jugador VALUES (272, 'Lionel Messi', '1978-03-10', 'Portero', 23);
INSERT INTO Jugador VALUES (273, 'Luis Suarez', '1978-10-01', 'Delantero', 23);
INSERT INTO Jugador VALUES (274, 'Sergio Aguero', '1984-10-22', 'Centrocampista', 23);
INSERT INTO Jugador VALUES (275, 'Robert Lewandowski', '1987-07-23', 'Defensa', 23);
INSERT INTO Jugador VALUES (276, 'David Villa', '1981-02-19', 'Portero', 23);
INSERT INTO Jugador VALUES (277, 'Arjen Robben', '1995-04-04', 'Delantero', 24);
INSERT INTO Jugador VALUES (278, 'Frank Ribery', '1984-11-20', 'Centrocampista', 24);
INSERT INTO Jugador VALUES (279, 'Mesut Ozil', '1978-10-26', 'Defensa', 24);
INSERT INTO Jugador VALUES (280, 'Angel Di Maria', '1976-06-18', 'Portero', 24);
INSERT INTO Jugador VALUES (281, 'Eden Hazard', '1988-11-12', 'Delantero', 24);
INSERT INTO Jugador VALUES (282, 'Cristiano Ronaldo', '1977-09-21', 'Centrocampista', 24);
INSERT INTO Jugador VALUES (283, 'Lionel Messi', '1985-01-28', 'Defensa', 24);
INSERT INTO Jugador VALUES (284, 'Luis Suarez', '1988-08-04', 'Portero', 24);
INSERT INTO Jugador VALUES (285, 'Sergio Aguero', '1988-06-21', 'Delantero', 24);
INSERT INTO Jugador VALUES (286, 'Robert Lewandowski', '1989-12-05', 'Centrocampista', 24);
INSERT INTO Jugador VALUES (287, 'David Villa', '1988-03-24', 'Defensa', 24);
INSERT INTO Jugador VALUES (288, 'Karim Benzema', '1991-11-09', 'Portero', 24);
INSERT INTO Jugador VALUES (289, 'Frank Ribery', '1994-09-25', 'Delantero', 25);
INSERT INTO Jugador VALUES (290, 'Mesut Ozil', '1990-08-14', 'Centrocampista', 25);
INSERT INTO Jugador VALUES (291, 'Angel Di Maria', '1993-05-11', 'Defensa', 25);
INSERT INTO Jugador VALUES (292, 'Eden Hazard', '1982-02-09', 'Portero', 25);
INSERT INTO Jugador VALUES (293, 'Cristiano Ronaldo', '1989-04-25', 'Delantero', 25);
INSERT INTO Jugador VALUES (294, 'Lionel Messi', '1989-10-20', 'Centrocampista', 25);
INSERT INTO Jugador VALUES (295, 'Luis Suarez', '1987-06-01', 'Defensa', 25);
INSERT INTO Jugador VALUES (296, 'Sergio Aguero', '1990-06-06', 'Portero', 25);
INSERT INTO Jugador VALUES (297, 'Robert Lewandowski', '1990-04-12', 'Delantero', 25);
INSERT INTO Jugador VALUES (298, 'David Villa', '1983-06-09', 'Centrocampista', 25);
INSERT INTO Jugador VALUES (299, 'Karim Benzema', '1994-12-09', 'Defensa', 25);
INSERT INTO Jugador VALUES (300, 'Raul Gonzalez', '1992-01-17', 'Portero', 25);
INSERT INTO Jugador VALUES (301, 'Mesut Ozil', '1981-02-08', 'Delantero', 26);
INSERT INTO Jugador VALUES (302, 'Angel Di Maria', '1988-08-18', 'Centrocampista', 26);
INSERT INTO Jugador VALUES (303, 'Eden Hazard', '1982-12-16', 'Defensa', 26);
INSERT INTO Jugador VALUES (304, 'Cristiano Ronaldo', '1995-12-16', 'Portero', 26);
INSERT INTO Jugador VALUES (305, 'Lionel Messi', '1989-01-03', 'Delantero', 26);
INSERT INTO Jugador VALUES (306, 'Luis Suarez', '1984-04-13', 'Centrocampista', 26);
INSERT INTO Jugador VALUES (307, 'Sergio Aguero', '1982-05-22', 'Defensa', 26);
INSERT INTO Jugador VALUES (308, 'Robert Lewandowski', '1993-06-16', 'Portero', 26);
INSERT INTO Jugador VALUES (309, 'David Villa', '1992-09-12', 'Delantero', 26);
INSERT INTO Jugador VALUES (310, 'Karim Benzema', '1988-12-18', 'Centrocampista', 26);
INSERT INTO Jugador VALUES (311, 'Raul Gonzalez', '1985-06-23', 'Defensa', 26);
INSERT INTO Jugador VALUES (312, 'Thierry Henry', '1989-05-10', 'Portero', 26);
INSERT INTO Jugador VALUES (313, 'Angel Di Maria', '1983-04-04', 'Delantero', 27);
INSERT INTO Jugador VALUES (314, 'Eden Hazard', '1981-06-04', 'Centrocampista', 27);
INSERT INTO Jugador VALUES (315, 'Cristiano Ronaldo', '1992-12-06', 'Defensa', 27);
INSERT INTO Jugador VALUES (316, 'Lionel Messi', '1981-04-24', 'Portero', 27);
INSERT INTO Jugador VALUES (317, 'Luis Suarez', '1990-05-24', 'Delantero', 27);
INSERT INTO Jugador VALUES (318, 'Sergio Aguero', '1993-09-20', 'Centrocampista', 27);
INSERT INTO Jugador VALUES (319, 'Robert Lewandowski', '1984-02-27', 'Defensa', 27);
INSERT INTO Jugador VALUES (320, 'David Villa', '1981-05-08', 'Portero', 27);
INSERT INTO Jugador VALUES (321, 'Karim Benzema', '1986-03-10', 'Delantero', 27);
INSERT INTO Jugador VALUES (322, 'Raul Gonzalez', '1975-12-18', 'Centrocampista', 27);
INSERT INTO Jugador VALUES (323, 'Thierry Henry', '1979-05-02', 'Defensa', 27);
INSERT INTO Jugador VALUES (324, 'Zinedine Zidane', '1976-09-10', 'Portero', 27);
INSERT INTO Jugador VALUES (325, 'Eden Hazard', '1979-11-28', 'Delantero', 28);
INSERT INTO Jugador VALUES (326, 'Cristiano Ronaldo', '1990-02-28', 'Centrocampista', 28);
INSERT INTO Jugador VALUES (327, 'Lionel Messi', '1975-10-10', 'Defensa', 28);
INSERT INTO Jugador VALUES (328, 'Luis Suarez', '1990-08-15', 'Portero', 28);
INSERT INTO Jugador VALUES (329, 'Sergio Aguero', '1985-03-02', 'Delantero', 28);
INSERT INTO Jugador VALUES (330, 'Robert Lewandowski', '1983-08-04', 'Centrocampista', 28);
INSERT INTO Jugador VALUES (331, 'David Villa', '1977-07-16', 'Defensa', 28);
INSERT INTO Jugador VALUES (332, 'Karim Benzema', '1977-10-21', 'Portero', 28);
INSERT INTO Jugador VALUES (333, 'Raul Gonzalez', '1976-03-05', 'Delantero', 28);
INSERT INTO Jugador VALUES (334, 'Thierry Henry', '1993-05-03', 'Centrocampista', 28);
INSERT INTO Jugador VALUES (335, 'Zinedine Zidane', '1982-02-18', 'Defensa', 28);
INSERT INTO Jugador VALUES (336, 'Ronaldinho', '1988-10-20', 'Portero', 28);
INSERT INTO Jugador VALUES (337, 'Cristiano Ronaldo', '1994-04-25', 'Delantero', 29);
INSERT INTO Jugador VALUES (338, 'Lionel Messi', '1991-07-15', 'Centrocampista', 29);
INSERT INTO Jugador VALUES (339, 'Luis Suarez', '1989-05-28', 'Defensa', 29);
INSERT INTO Jugador VALUES (340, 'Sergio Aguero', '1993-07-10', 'Portero', 29);
INSERT INTO Jugador VALUES (341, 'Robert Lewandowski', '1993-10-02', 'Delantero', 29);
INSERT INTO Jugador VALUES (342, 'David Villa', '1994-12-04', 'Centrocampista', 29);
INSERT INTO Jugador VALUES (343, 'Karim Benzema', '1981-11-07', 'Defensa', 29);
INSERT INTO Jugador VALUES (344, 'Raul Gonzalez', '1983-11-03', 'Portero', 29);
INSERT INTO Jugador VALUES (345, 'Thierry Henry', '1980-04-06', 'Delantero', 29);
INSERT INTO Jugador VALUES (346, 'Zinedine Zidane', '1992-02-06', 'Centrocampista', 29);
INSERT INTO Jugador VALUES (347, 'Ronaldinho', '1975-07-15', 'Defensa', 29);
INSERT INTO Jugador VALUES (348, 'Pele', '1994-08-10', 'Portero', 29);
INSERT INTO Jugador VALUES (349, 'Lionel Messi', '1976-04-10', 'Delantero', 30);
INSERT INTO Jugador VALUES (350, 'Luis Suarez', '1984-12-28', 'Centrocampista', 30);
INSERT INTO Jugador VALUES (351, 'Sergio Aguero', '1989-02-22', 'Defensa', 30);
INSERT INTO Jugador VALUES (352, 'Robert Lewandowski', '1982-05-26', 'Portero', 30);
INSERT INTO Jugador VALUES (353, 'David Villa', '1995-10-22', 'Delantero', 30);
INSERT INTO Jugador VALUES (354, 'Karim Benzema', '1981-07-04', 'Centrocampista', 30);
INSERT INTO Jugador VALUES (355, 'Raul Gonzalez', '1992-04-21', 'Defensa', 30);
INSERT INTO Jugador VALUES (356, 'Thierry Henry', '1979-05-27', 'Portero', 30);
INSERT INTO Jugador VALUES (357, 'Zinedine Zidane', '1979-02-02', 'Delantero', 30);
INSERT INTO Jugador VALUES (358, 'Ronaldinho', '1980-05-20', 'Centrocampista', 30);
INSERT INTO Jugador VALUES (359, 'Pele', '1993-05-15', 'Defensa', 30);
INSERT INTO Jugador VALUES (360, 'Gianluigi Buffon', '1978-08-23', 'Portero', 30);
INSERT INTO Jugador VALUES (361, 'Luis Suarez', '1984-12-13', 'Delantero', 31);
INSERT INTO Jugador VALUES (362, 'Sergio Aguero', '1983-09-18', 'Centrocampista', 31);
INSERT INTO Jugador VALUES (363, 'Robert Lewandowski', '1990-08-03', 'Defensa', 31);
INSERT INTO Jugador VALUES (364, 'David Villa', '1994-01-14', 'Portero', 31);
INSERT INTO Jugador VALUES (365, 'Karim Benzema', '1985-10-09', 'Delantero', 31);
INSERT INTO Jugador VALUES (366, 'Raul Gonzalez', '1975-02-08', 'Centrocampista', 31);
INSERT INTO Jugador VALUES (367, 'Thierry Henry', '1993-10-01', 'Defensa', 31);
INSERT INTO Jugador VALUES (368, 'Zinedine Zidane', '1983-10-02', 'Portero', 31);
INSERT INTO Jugador VALUES (369, 'Ronaldinho', '1980-08-17', 'Delantero', 31);
INSERT INTO Jugador VALUES (370, 'Pele', '1995-08-09', 'Centrocampista', 31);
INSERT INTO Jugador VALUES (371, 'Gianluigi Buffon', '1980-10-14', 'Defensa', 31);
INSERT INTO Jugador VALUES (372, 'Edwin van der Sar', '1995-08-03', 'Portero', 31);
INSERT INTO Jugador VALUES (373, 'Sergio Aguero', '1990-06-14', 'Delantero', 32);
INSERT INTO Jugador VALUES (374, 'Robert Lewandowski', '1985-06-22', 'Centrocampista', 32);
INSERT INTO Jugador VALUES (375, 'David Villa', '1978-03-11', 'Defensa', 32);
INSERT INTO Jugador VALUES (376, 'Karim Benzema', '1988-12-16', 'Portero', 32);
INSERT INTO Jugador VALUES (377, 'Raul Gonzalez', '1984-11-13', 'Delantero', 32);
INSERT INTO Jugador VALUES (378, 'Thierry Henry', '1992-01-15', 'Centrocampista', 32);
INSERT INTO Jugador VALUES (379, 'Zinedine Zidane', '1977-06-09', 'Defensa', 32);
INSERT INTO Jugador VALUES (380, 'Ronaldinho', '1985-02-25', 'Portero', 32);
INSERT INTO Jugador VALUES (381, 'Pele', '1987-09-27', 'Delantero', 32);
INSERT INTO Jugador VALUES (382, 'Gianluigi Buffon', '1975-11-28', 'Centrocampista', 32);
INSERT INTO Jugador VALUES (383, 'Edwin van der Sar', '1992-08-14', 'Defensa', 32);
INSERT INTO Jugador VALUES (384, 'Gerard Pique', '1976-04-17', 'Portero', 32);
INSERT INTO Jugador VALUES (385, 'Robert Lewandowski', '1986-10-25', 'Delantero', 33);
INSERT INTO Jugador VALUES (386, 'David Villa', '1990-11-15', 'Centrocampista', 33);
INSERT INTO Jugador VALUES (387, 'Karim Benzema', '1976-04-09', 'Defensa', 33);
INSERT INTO Jugador VALUES (388, 'Raul Gonzalez', '1992-03-10', 'Portero', 33);
INSERT INTO Jugador VALUES (389, 'Thierry Henry', '1989-12-16', 'Delantero', 33);
INSERT INTO Jugador VALUES (390, 'Zinedine Zidane', '1978-01-21', 'Centrocampista', 33);
INSERT INTO Jugador VALUES (391, 'Ronaldinho', '1994-04-23', 'Defensa', 33);
INSERT INTO Jugador VALUES (392, 'Pele', '1980-05-18', 'Portero', 33);
INSERT INTO Jugador VALUES (393, 'Gianluigi Buffon', '1975-09-14', 'Delantero', 33);
INSERT INTO Jugador VALUES (394, 'Edwin van der Sar', '1977-04-27', 'Centrocampista', 33);
INSERT INTO Jugador VALUES (395, 'Gerard Pique', '1978-08-04', 'Defensa', 33);
INSERT INTO Jugador VALUES (396, 'John Terry', '1995-03-16', 'Portero', 33);
INSERT INTO Jugador VALUES (397, 'David Villa', '1984-09-23', 'Delantero', 34);
INSERT INTO Jugador VALUES (398, 'Karim Benzema', '1983-07-27', 'Centrocampista', 34);
INSERT INTO Jugador VALUES (399, 'Raul Gonzalez', '1990-08-08', 'Defensa', 34);
INSERT INTO Jugador VALUES (400, 'Thierry Henry', '1989-09-05', 'Portero', 34);
INSERT INTO Jugador VALUES (401, 'Zinedine Zidane', '1987-04-20', 'Delantero', 34);
INSERT INTO Jugador VALUES (402, 'Ronaldinho', '1991-12-05', 'Centrocampista', 34);
INSERT INTO Jugador VALUES (403, 'Pele', '1977-05-25', 'Defensa', 34);
INSERT INTO Jugador VALUES (404, 'Gianluigi Buffon', '1988-06-26', 'Portero', 34);
INSERT INTO Jugador VALUES (405, 'Edwin van der Sar', '1991-05-27', 'Delantero', 34);
INSERT INTO Jugador VALUES (406, 'Gerard Pique', '1975-05-24', 'Centrocampista', 34);
INSERT INTO Jugador VALUES (407, 'John Terry', '1984-10-19', 'Defensa', 34);
INSERT INTO Jugador VALUES (408, 'Xavi Hernandez', '1990-03-15', 'Portero', 34);
INSERT INTO Jugador VALUES (409, 'Karim Benzema', '1992-08-12', 'Delantero', 35);
INSERT INTO Jugador VALUES (410, 'Raul Gonzalez', '1985-09-25', 'Centrocampista', 35);
INSERT INTO Jugador VALUES (411, 'Thierry Henry', '1992-07-15', 'Defensa', 35);
INSERT INTO Jugador VALUES (412, 'Zinedine Zidane', '1985-04-23', 'Portero', 35);
INSERT INTO Jugador VALUES (413, 'Ronaldinho', '1982-10-13', 'Delantero', 35);
INSERT INTO Jugador VALUES (414, 'Pele', '1982-07-02', 'Centrocampista', 35);
INSERT INTO Jugador VALUES (415, 'Gianluigi Buffon', '1985-12-16', 'Defensa', 35);
INSERT INTO Jugador VALUES (416, 'Edwin van der Sar', '1987-07-22', 'Portero', 35);
INSERT INTO Jugador VALUES (417, 'Gerard Pique', '1995-03-16', 'Delantero', 35);
INSERT INTO Jugador VALUES (418, 'John Terry', '1976-03-17', 'Centrocampista', 35);
INSERT INTO Jugador VALUES (419, 'Xavi Hernandez', '1993-06-28', 'Defensa', 35);
INSERT INTO Jugador VALUES (420, 'Andres Iniesta', '1978-08-04', 'Portero', 35);
INSERT INTO Jugador VALUES (421, 'Raul Gonzalez', '1991-08-01', 'Delantero', 36);
INSERT INTO Jugador VALUES (422, 'Thierry Henry', '1979-07-28', 'Centrocampista', 36);
INSERT INTO Jugador VALUES (423, 'Zinedine Zidane', '1995-03-03', 'Defensa', 36);
INSERT INTO Jugador VALUES (424, 'Ronaldinho', '1990-05-11', 'Portero', 36);
INSERT INTO Jugador VALUES (425, 'Pele', '1994-12-13', 'Delantero', 36);
INSERT INTO Jugador VALUES (426, 'Gianluigi Buffon', '1995-02-28', 'Centrocampista', 36);
INSERT INTO Jugador VALUES (427, 'Edwin van der Sar', '1985-11-28', 'Defensa', 36);
INSERT INTO Jugador VALUES (428, 'Gerard Pique', '1992-07-11', 'Portero', 36);
INSERT INTO Jugador VALUES (429, 'John Terry', '1995-12-25', 'Delantero', 36);
INSERT INTO Jugador VALUES (430, 'Xavi Hernandez', '1990-09-02', 'Centrocampista', 36);
INSERT INTO Jugador VALUES (431, 'Andres Iniesta', '1994-02-08', 'Defensa', 36);
INSERT INTO Jugador VALUES (432, 'Andrea Pirlo', '1995-11-10', 'Portero', 36);
INSERT INTO Jugador VALUES (433, 'Thierry Henry', '1982-12-03', 'Delantero', 37);
INSERT INTO Jugador VALUES (434, 'Zinedine Zidane', '1988-02-25', 'Centrocampista', 37);
INSERT INTO Jugador VALUES (435, 'Ronaldinho', '1995-12-28', 'Defensa', 37);
INSERT INTO Jugador VALUES (436, 'Pele', '1978-08-06', 'Portero', 37);
INSERT INTO Jugador VALUES (437, 'Gianluigi Buffon', '1984-01-02', 'Delantero', 37);
INSERT INTO Jugador VALUES (438, 'Edwin van der Sar', '1985-01-10', 'Centrocampista', 37);
INSERT INTO Jugador VALUES (439, 'Gerard Pique', '1986-06-14', 'Defensa', 37);
INSERT INTO Jugador VALUES (440, 'John Terry', '1979-04-17', 'Portero', 37);
INSERT INTO Jugador VALUES (441, 'Xavi Hernandez', '1988-10-22', 'Delantero', 37);
INSERT INTO Jugador VALUES (442, 'Andres Iniesta', '1980-03-06', 'Centrocampista', 37);
INSERT INTO Jugador VALUES (443, 'Andrea Pirlo', '1977-10-28', 'Defensa', 37);
INSERT INTO Jugador VALUES (444, 'Steven Gerrard', '1987-10-22', 'Portero', 37);
INSERT INTO Jugador VALUES (445, 'Zinedine Zidane', '1982-08-19', 'Delantero', 38);
INSERT INTO Jugador VALUES (446, 'Ronaldinho', '1979-04-15', 'Centrocampista', 38);
INSERT INTO Jugador VALUES (447, 'Pele', '1995-05-15', 'Defensa', 38);
INSERT INTO Jugador VALUES (448, 'Gianluigi Buffon', '1983-11-01', 'Portero', 38);
INSERT INTO Jugador VALUES (449, 'Edwin van der Sar', '1989-05-22', 'Delantero', 38);
INSERT INTO Jugador VALUES (450, 'Gerard Pique', '1992-03-03', 'Centrocampista', 38);
INSERT INTO Jugador VALUES (451, 'John Terry', '1989-06-19', 'Defensa', 38);
INSERT INTO Jugador VALUES (452, 'Xavi Hernandez', '1984-11-14', 'Portero', 38);
INSERT INTO Jugador VALUES (453, 'Andres Iniesta', '1983-08-28', 'Delantero', 38);
INSERT INTO Jugador VALUES (454, 'Andrea Pirlo', '1984-04-13', 'Centrocampista', 38);
INSERT INTO Jugador VALUES (455, 'Steven Gerrard', '1990-02-08', 'Defensa', 38);
INSERT INTO Jugador VALUES (456, 'Patrick Vieira', '1987-10-12', 'Portero', 38);
INSERT INTO Jugador VALUES (457, 'Ronaldinho', '1993-05-23', 'Delantero', 39);
INSERT INTO Jugador VALUES (458, 'Pele', '1984-01-27', 'Centrocampista', 39);
INSERT INTO Jugador VALUES (459, 'Gianluigi Buffon', '1987-05-01', 'Defensa', 39);
INSERT INTO Jugador VALUES (460, 'Edwin van der Sar', '1993-11-25', 'Portero', 39);
INSERT INTO Jugador VALUES (461, 'Gerard Pique', '1976-10-24', 'Delantero', 39);
INSERT INTO Jugador VALUES (462, 'John Terry', '1990-05-25', 'Centrocampista', 39);
INSERT INTO Jugador VALUES (463, 'Xavi Hernandez', '1982-10-26', 'Defensa', 39);
INSERT INTO Jugador VALUES (464, 'Andres Iniesta', '1986-04-21', 'Portero', 39);
INSERT INTO Jugador VALUES (465, 'Andrea Pirlo', '1981-10-09', 'Delantero', 39);
INSERT INTO Jugador VALUES (466, 'Steven Gerrard', '1979-11-04', 'Centrocampista', 39);
INSERT INTO Jugador VALUES (467, 'Patrick Vieira', '1995-11-02', 'Defensa', 39);
INSERT INTO Jugador VALUES (468, 'Claude Makele', '1984-08-02', 'Portero', 39);
INSERT INTO Jugador VALUES (469, 'Pele', '1993-06-24', 'Delantero', 40);
INSERT INTO Jugador VALUES (470, 'Gianluigi Buffon', '1979-02-10', 'Centrocampista', 40);
INSERT INTO Jugador VALUES (471, 'Edwin van der Sar', '1985-12-14', 'Defensa', 40);
INSERT INTO Jugador VALUES (472, 'Gerard Pique', '1980-04-05', 'Portero', 40);
INSERT INTO Jugador VALUES (473, 'John Terry', '1992-06-17', 'Delantero', 40);
INSERT INTO Jugador VALUES (474, 'Xavi Hernandez', '1991-05-27', 'Centrocampista', 40);
INSERT INTO Jugador VALUES (475, 'Andres Iniesta', '1980-05-27', 'Defensa', 40);
INSERT INTO Jugador VALUES (476, 'Andrea Pirlo', '1990-05-24', 'Portero', 40);
INSERT INTO Jugador VALUES (477, 'Steven Gerrard', '1985-02-15', 'Delantero', 40);
INSERT INTO Jugador VALUES (478, 'Patrick Vieira', '1977-03-25', 'Centrocampista', 40);
INSERT INTO Jugador VALUES (479, 'Claude Makele', '1982-11-24', 'Defensa', 40);
INSERT INTO Jugador VALUES (480, 'Didier Drogba', '1987-09-12', 'Portero', 40);

-- INSERT GOLES
INSERT INTO Gol VALUES (1, 51, 1, 2);
INSERT INTO Gol VALUES (2, 34, 2, 13);
INSERT INTO Gol VALUES (3, 16, 2, 9);
INSERT INTO Gol VALUES (4, 48, 2, 8);
INSERT INTO Gol VALUES (5, 87, 2, 11);
INSERT INTO Gol VALUES (6, 75, 4, 41);
INSERT INTO Gol VALUES (7, 82, 4, 31);
INSERT INTO Gol VALUES (8, 14, 5, 30);
INSERT INTO Gol VALUES (9, 30, 5, 35);
INSERT INTO Gol VALUES (10, 4, 5, 32);
INSERT INTO Gol VALUES (11, 72, 5, 34);
INSERT INTO Gol VALUES (12, 79, 6, 54);
INSERT INTO Gol VALUES (13, 83, 6, 28);
INSERT INTO Gol VALUES (14, 82, 7, 62);
INSERT INTO Gol VALUES (15, 90, 7, 20);
INSERT INTO Gol VALUES (16, 84, 8, 17);
INSERT INTO Gol VALUES (17, 15, 8, 19);
INSERT INTO Gol VALUES (18, 6, 8, 15);
INSERT INTO Gol VALUES (19, 39, 9, 1);
INSERT INTO Gol VALUES (20, 15, 9, 8);
INSERT INTO Gol VALUES (21, 31, 9, 74);
INSERT INTO Gol VALUES (22, 18, 9, 81);
INSERT INTO Gol VALUES (23, 59, 10, 7);
INSERT INTO Gol VALUES (24, 86, 11, 90);
INSERT INTO Gol VALUES (25, 90, 11, 48);
INSERT INTO Gol VALUES (26, 54, 11, 45);
INSERT INTO Gol VALUES (27, 20, 11, 46);
INSERT INTO Gol VALUES (28, 84, 12, 43);
INSERT INTO Gol VALUES (29, 63, 12, 38);
INSERT INTO Gol VALUES (30, 53, 12, 46);
INSERT INTO Gol VALUES (31, 5, 12, 41);
INSERT INTO Gol VALUES (32, 48, 12, 96);
INSERT INTO Gol VALUES (33, 57, 12, 88);
INSERT INTO Gol VALUES (34, 31, 12, 92);
INSERT INTO Gol VALUES (35, 13, 12, 90);
INSERT INTO Gol VALUES (36, 48, 13, 59);
INSERT INTO Gol VALUES (37, 83, 13, 57);
INSERT INTO Gol VALUES (38, 8, 13, 54);
INSERT INTO Gol VALUES (39, 36, 13, 55);
INSERT INTO Gol VALUES (40, 16, 13, 52);
INSERT INTO Gol VALUES (41, 12, 14, 56);
INSERT INTO Gol VALUES (42, 28, 14, 59);
INSERT INTO Gol VALUES (43, 82, 14, 59);
INSERT INTO Gol VALUES (44, 3, 14, 58);
INSERT INTO Gol VALUES (45, 43, 14, 49);
INSERT INTO Gol VALUES (46, 17, 14, 52);
INSERT INTO Gol VALUES (47, 27, 14, 58);
INSERT INTO Gol VALUES (48, 71, 14, 98);
INSERT INTO Gol VALUES (49, 76, 15, 88);
INSERT INTO Gol VALUES (50, 30, 16, 88);
INSERT INTO Gol VALUES (51, 19, 16, 90);
INSERT INTO Gol VALUES (52, 1, 16, 94);
INSERT INTO Gol VALUES (53, 19, 16, 89);
INSERT INTO Gol VALUES (54, 70, 17, 15);
INSERT INTO Gol VALUES (55, 23, 18, 125);
INSERT INTO Gol VALUES (56, 85, 19, 134);
INSERT INTO Gol VALUES (57, 17, 19, 25);
INSERT INTO Gol VALUES (58, 46, 20, 25);
INSERT INTO Gol VALUES (59, 76, 20, 28);
INSERT INTO Gol VALUES (60, 3, 20, 30);
INSERT INTO Gol VALUES (61, 34, 20, 27);
INSERT INTO Gol VALUES (62, 17, 20, 25);
INSERT INTO Gol VALUES (63, 54, 20, 144);
INSERT INTO Gol VALUES (64, 15, 20, 141);
INSERT INTO Gol VALUES (65, 9, 22, 12);
INSERT INTO Gol VALUES (66, 58, 22, 8);
INSERT INTO Gol VALUES (67, 66, 23, 162);
INSERT INTO Gol VALUES (68, 14, 23, 166);
INSERT INTO Gol VALUES (69, 65, 23, 80);
INSERT INTO Gol VALUES (70, 79, 23, 76);
INSERT INTO Gol VALUES (71, 85, 25, 37);
INSERT INTO Gol VALUES (72, 39, 26, 177);
INSERT INTO Gol VALUES (73, 83, 26, 176);
INSERT INTO Gol VALUES (74, 8, 26, 37);
INSERT INTO Gol VALUES (75, 52, 26, 44);
INSERT INTO Gol VALUES (76, 88, 27, 67);
INSERT INTO Gol VALUES (77, 63, 27, 182);
INSERT INTO Gol VALUES (78, 57, 28, 192);
INSERT INTO Gol VALUES (79, 11, 28, 62);
INSERT INTO Gol VALUES (80, 78, 28, 66);
INSERT INTO Gol VALUES (81, 9, 29, 27);
INSERT INTO Gol VALUES (82, 36, 29, 27);
INSERT INTO Gol VALUES (83, 82, 30, 34);
INSERT INTO Gol VALUES (84, 71, 30, 34);
INSERT INTO Gol VALUES (85, 42, 31, 36);
INSERT INTO Gol VALUES (86, 77, 31, 115);
INSERT INTO Gol VALUES (87, 38, 32, 9);
INSERT INTO Gol VALUES (88, 65, 32, 8);
INSERT INTO Gol VALUES (89, 56, 33, 10);
INSERT INTO Gol VALUES (90, 90, 33, 2);
INSERT INTO Gol VALUES (91, 84, 33, 2);
INSERT INTO Gol VALUES (92, 71, 33, 11);
INSERT INTO Gol VALUES (93, 28, 33, 204);
INSERT INTO Gol VALUES (94, 58, 34, 115);
INSERT INTO Gol VALUES (95, 53, 34, 112);
INSERT INTO Gol VALUES (96, 59, 34, 114);
INSERT INTO Gol VALUES (97, 54, 34, 115);
INSERT INTO Gol VALUES (98, 13, 35, 120);
INSERT INTO Gol VALUES (99, 55, 36, 6);
INSERT INTO Gol VALUES (100, 86, 37, 6);
INSERT INTO Gol VALUES (101, 48, 37, 5);
INSERT INTO Gol VALUES (102, 88, 37, 39);
INSERT INTO Gol VALUES (103, 9, 38, 152);
INSERT INTO Gol VALUES (104, 11, 38, 146);
INSERT INTO Gol VALUES (105, 56, 38, 194);
INSERT INTO Gol VALUES (106, 48, 38, 194);
INSERT INTO Gol VALUES (107, 72, 38, 195);
INSERT INTO Gol VALUES (108, 76, 38, 193);
INSERT INTO Gol VALUES (109, 72, 38, 201);
INSERT INTO Gol VALUES (110, 86, 39, 198);
INSERT INTO Gol VALUES (111, 53, 39, 194);
INSERT INTO Gol VALUES (112, 86, 39, 150);
INSERT INTO Gol VALUES (113, 7, 40, 31);
INSERT INTO Gol VALUES (114, 77, 40, 29);
INSERT INTO Gol VALUES (115, 46, 40, 29);
INSERT INTO Gol VALUES (116, 74, 40, 26);
INSERT INTO Gol VALUES (117, 28, 40, 33);
INSERT INTO Gol VALUES (118, 85, 40, 219);
INSERT INTO Gol VALUES (119, 29, 41, 32);
INSERT INTO Gol VALUES (120, 45, 42, 50);
INSERT INTO Gol VALUES (121, 48, 43, 57);
INSERT INTO Gol VALUES (122, 36, 43, 50);
INSERT INTO Gol VALUES (123, 29, 43, 154);
INSERT INTO Gol VALUES (124, 72, 43, 151);
INSERT INTO Gol VALUES (125, 79, 43, 154);
INSERT INTO Gol VALUES (126, 83, 44, 47);
INSERT INTO Gol VALUES (127, 4, 44, 45);
INSERT INTO Gol VALUES (128, 85, 46, 22);
INSERT INTO Gol VALUES (129, 35, 46, 24);
INSERT INTO Gol VALUES (130, 24, 46, 25);
INSERT INTO Gol VALUES (131, 90, 47, 29);
INSERT INTO Gol VALUES (132, 44, 47, 29);
INSERT INTO Gol VALUES (133, 1, 47, 30);
INSERT INTO Gol VALUES (134, 19, 47, 15);
INSERT INTO Gol VALUES (135, 85, 49, 10);
INSERT INTO Gol VALUES (136, 9, 49, 7);
INSERT INTO Gol VALUES (137, 82, 49, 243);
INSERT INTO Gol VALUES (138, 12, 50, 121);
INSERT INTO Gol VALUES (139, 68, 50, 132);
INSERT INTO Gol VALUES (140, 49, 50, 220);
INSERT INTO Gol VALUES (141, 59, 50, 223);
INSERT INTO Gol VALUES (142, 21, 50, 222);
INSERT INTO Gol VALUES (143, 40, 51, 222);
INSERT INTO Gol VALUES (144, 42, 51, 228);
INSERT INTO Gol VALUES (145, 77, 51, 226);
INSERT INTO Gol VALUES (146, 7, 52, 134);
INSERT INTO Gol VALUES (147, 21, 52, 111);
INSERT INTO Gol VALUES (148, 7, 53, 118);
INSERT INTO Gol VALUES (149, 11, 53, 119);
INSERT INTO Gol VALUES (150, 57, 53, 113);
INSERT INTO Gol VALUES (151, 55, 54, 215);
INSERT INTO Gol VALUES (152, 78, 56, 272);
INSERT INTO Gol VALUES (153, 54, 56, 200);
INSERT INTO Gol VALUES (154, 28, 57, 197);
INSERT INTO Gol VALUES (155, 15, 57, 201);
INSERT INTO Gol VALUES (156, 56, 57, 198);
INSERT INTO Gol VALUES (157, 37, 57, 266);
INSERT INTO Gol VALUES (158, 87, 58, 35);
INSERT INTO Gol VALUES (159, 63, 58, 34);
INSERT INTO Gol VALUES (160, 86, 58, 33);
INSERT INTO Gol VALUES (161, 6, 58, 5);
INSERT INTO Gol VALUES (162, 51, 59, 28);
INSERT INTO Gol VALUES (163, 8, 59, 34);
INSERT INTO Gol VALUES (164, 27, 59, 25);
INSERT INTO Gol VALUES (165, 28, 60, 53);
INSERT INTO Gol VALUES (166, 33, 60, 51);
INSERT INTO Gol VALUES (167, 42, 60, 53);
INSERT INTO Gol VALUES (168, 1, 60, 26);
INSERT INTO Gol VALUES (169, 56, 60, 32);
INSERT INTO Gol VALUES (170, 17, 61, 171);
INSERT INTO Gol VALUES (171, 69, 61, 175);
INSERT INTO Gol VALUES (172, 30, 61, 120);
INSERT INTO Gol VALUES (173, 72, 62, 117);
INSERT INTO Gol VALUES (174, 46, 62, 179);
INSERT INTO Gol VALUES (175, 51, 63, 74);
INSERT INTO Gol VALUES (176, 6, 63, 84);
INSERT INTO Gol VALUES (177, 3, 63, 79);
INSERT INTO Gol VALUES (178, 10, 63, 56);
INSERT INTO Gol VALUES (179, 74, 64, 54);
INSERT INTO Gol VALUES (180, 74, 64, 55);
INSERT INTO Gol VALUES (181, 82, 64, 55);
INSERT INTO Gol VALUES (182, 38, 64, 55);
INSERT INTO Gol VALUES (183, 52, 64, 50);
INSERT INTO Gol VALUES (184, 42, 64, 49);
INSERT INTO Gol VALUES (185, 80, 64, 75);
INSERT INTO Gol VALUES (186, 89, 66, 116);
INSERT INTO Gol VALUES (187, 12, 67, 282);
INSERT INTO Gol VALUES (188, 14, 67, 31);
INSERT INTO Gol VALUES (189, 56, 67, 28);
INSERT INTO Gol VALUES (190, 52, 67, 34);
INSERT INTO Gol VALUES (191, 11, 68, 33);
INSERT INTO Gol VALUES (192, 40, 68, 31);
INSERT INTO Gol VALUES (193, 44, 69, 180);
INSERT INTO Gol VALUES (194, 43, 71, 16);
INSERT INTO Gol VALUES (195, 10, 71, 291);
INSERT INTO Gol VALUES (196, 82, 71, 297);
INSERT INTO Gol VALUES (197, 68, 71, 290);
INSERT INTO Gol VALUES (198, 25, 72, 21);
INSERT INTO Gol VALUES (199, 45, 72, 18);
INSERT INTO Gol VALUES (200, 83, 73, 180);
INSERT INTO Gol VALUES (201, 31, 73, 171);
INSERT INTO Gol VALUES (202, 19, 73, 302);
INSERT INTO Gol VALUES (203, 26, 74, 173);
INSERT INTO Gol VALUES (204, 78, 74, 171);
INSERT INTO Gol VALUES (205, 84, 74, 171);
INSERT INTO Gol VALUES (206, 23, 75, 314);
INSERT INTO Gol VALUES (207, 64, 75, 35);
INSERT INTO Gol VALUES (208, 73, 75, 32);
INSERT INTO Gol VALUES (209, 58, 76, 34);
INSERT INTO Gol VALUES (210, 73, 77, 119);
INSERT INTO Gol VALUES (211, 82, 77, 119);
INSERT INTO Gol VALUES (212, 42, 78, 118);
INSERT INTO Gol VALUES (213, 41, 78, 119);
INSERT INTO Gol VALUES (214, 57, 78, 111);
INSERT INTO Gol VALUES (215, 61, 78, 194);
INSERT INTO Gol VALUES (216, 81, 78, 200);
INSERT INTO Gol VALUES (217, 36, 78, 197);
INSERT INTO Gol VALUES (218, 8, 78, 202);
INSERT INTO Gol VALUES (219, 65, 79, 330);
INSERT INTO Gol VALUES (220, 40, 80, 158);
INSERT INTO Gol VALUES (221, 58, 81, 284);
INSERT INTO Gol VALUES (222, 8, 81, 37);
INSERT INTO Gol VALUES (223, 37, 82, 42);
INSERT INTO Gol VALUES (224, 83, 82, 38);
INSERT INTO Gol VALUES (225, 79, 82, 278);
INSERT INTO Gol VALUES (226, 65, 82, 286);
INSERT INTO Gol VALUES (227, 60, 83, 343);
INSERT INTO Gol VALUES (228, 71, 83, 82);
INSERT INTO Gol VALUES (229, 6, 84, 84);
INSERT INTO Gol VALUES (230, 74, 84, 80);
INSERT INTO Gol VALUES (231, 25, 84, 83);
INSERT INTO Gol VALUES (232, 78, 84, 78);
INSERT INTO Gol VALUES (233, 65, 86, 56);
INSERT INTO Gol VALUES (234, 8, 86, 51);
INSERT INTO Gol VALUES (235, 14, 86, 56);
INSERT INTO Gol VALUES (236, 11, 86, 54);
INSERT INTO Gol VALUES (237, 83, 86, 57);
INSERT INTO Gol VALUES (238, 6, 86, 51);
INSERT INTO Gol VALUES (239, 57, 86, 52);
INSERT INTO Gol VALUES (240, 68, 87, 32);
INSERT INTO Gol VALUES (241, 79, 87, 33);
INSERT INTO Gol VALUES (242, 47, 87, 27);
INSERT INTO Gol VALUES (243, 37, 87, 174);
INSERT INTO Gol VALUES (244, 53, 88, 163);
INSERT INTO Gol VALUES (245, 87, 89, 54);
INSERT INTO Gol VALUES (246, 7, 89, 58);
INSERT INTO Gol VALUES (247, 83, 89, 167);
INSERT INTO Gol VALUES (248, 9, 91, 114);
INSERT INTO Gol VALUES (249, 13, 92, 30);
INSERT INTO Gol VALUES (250, 87, 92, 33);
INSERT INTO Gol VALUES (251, 37, 92, 163);
INSERT INTO Gol VALUES (252, 85, 93, 161);
INSERT INTO Gol VALUES (253, 20, 93, 166);
INSERT INTO Gol VALUES (254, 11, 94, 354);
INSERT INTO Gol VALUES (255, 85, 94, 358);
INSERT INTO Gol VALUES (256, 45, 95, 111);
INSERT INTO Gol VALUES (257, 84, 95, 113);
INSERT INTO Gol VALUES (258, 85, 95, 120);
INSERT INTO Gol VALUES (259, 17, 96, 55);
INSERT INTO Gol VALUES (260, 11, 97, 370);
INSERT INTO Gol VALUES (261, 72, 97, 365);
INSERT INTO Gol VALUES (262, 83, 97, 55);
INSERT INTO Gol VALUES (263, 17, 97, 54);
INSERT INTO Gol VALUES (264, 90, 98, 287);
INSERT INTO Gol VALUES (265, 88, 98, 288);
INSERT INTO Gol VALUES (266, 12, 98, 321);
INSERT INTO Gol VALUES (267, 86, 98, 323);
INSERT INTO Gol VALUES (268, 66, 99, 319);
INSERT INTO Gol VALUES (269, 3, 100, 30);
INSERT INTO Gol VALUES (270, 40, 100, 30);
INSERT INTO Gol VALUES (271, 28, 101, 27);
INSERT INTO Gol VALUES (272, 63, 101, 30);
INSERT INTO Gol VALUES (273, 29, 101, 28);
INSERT INTO Gol VALUES (274, 20, 101, 15);
INSERT INTO Gol VALUES (275, 38, 102, 374);
INSERT INTO Gol VALUES (276, 65, 102, 374);
INSERT INTO Gol VALUES (277, 68, 102, 357);
INSERT INTO Gol VALUES (278, 85, 102, 349);
INSERT INTO Gol VALUES (279, 80, 102, 354);
INSERT INTO Gol VALUES (280, 77, 103, 351);
INSERT INTO Gol VALUES (281, 20, 104, 367);
INSERT INTO Gol VALUES (282, 24, 105, 387);
INSERT INTO Gol VALUES (283, 80, 105, 372);
INSERT INTO Gol VALUES (284, 57, 105, 363);
INSERT INTO Gol VALUES (285, 53, 106, 397);
INSERT INTO Gol VALUES (286, 87, 106, 318);
INSERT INTO Gol VALUES (287, 31, 106, 324);
INSERT INTO Gol VALUES (288, 79, 106, 320);
INSERT INTO Gol VALUES (289, 58, 108, 113);
INSERT INTO Gol VALUES (290, 69, 108, 112);
INSERT INTO Gol VALUES (291, 40, 109, 112);
INSERT INTO Gol VALUES (292, 25, 109, 116);
INSERT INTO Gol VALUES (293, 87, 110, 282);
INSERT INTO Gol VALUES (294, 57, 110, 286);
INSERT INTO Gol VALUES (295, 37, 110, 44);
INSERT INTO Gol VALUES (296, 65, 111, 43);
INSERT INTO Gol VALUES (297, 54, 111, 285);
INSERT INTO Gol VALUES (298, 26, 111, 279);
INSERT INTO Gol VALUES (299, 18, 112, 178);
INSERT INTO Gol VALUES (300, 7, 112, 173);
INSERT INTO Gol VALUES (301, 62, 112, 59);
INSERT INTO Gol VALUES (302, 71, 112, 54);
INSERT INTO Gol VALUES (303, 67, 113, 50);
INSERT INTO Gol VALUES (304, 37, 113, 50);
INSERT INTO Gol VALUES (305, 21, 113, 50);
INSERT INTO Gol VALUES (306, 58, 113, 53);
INSERT INTO Gol VALUES (307, 19, 113, 177);
INSERT INTO Gol VALUES (308, 12, 113, 175);
INSERT INTO Gol VALUES (309, 58, 116, 112);
INSERT INTO Gol VALUES (310, 4, 116, 162);
INSERT INTO Gol VALUES (311, 7, 117, 427);
INSERT INTO Gol VALUES (312, 65, 118, 427);
INSERT INTO Gol VALUES (313, 31, 118, 426);
INSERT INTO Gol VALUES (314, 11, 118, 211);
INSERT INTO Gol VALUES (315, 29, 118, 210);
INSERT INTO Gol VALUES (316, 41, 118, 205);
INSERT INTO Gol VALUES (317, 84, 119, 26);
INSERT INTO Gol VALUES (318, 19, 119, 30);
INSERT INTO Gol VALUES (319, 5, 119, 27);
INSERT INTO Gol VALUES (320, 61, 120, 89);
INSERT INTO Gol VALUES (321, 18, 120, 96);
INSERT INTO Gol VALUES (322, 61, 120, 96);
INSERT INTO Gol VALUES (323, 79, 120, 92);
INSERT INTO Gol VALUES (324, 11, 121, 25);
INSERT INTO Gol VALUES (325, 33, 122, 25);
INSERT INTO Gol VALUES (326, 20, 122, 28);
INSERT INTO Gol VALUES (327, 78, 122, 33);
INSERT INTO Gol VALUES (328, 55, 123, 93);
INSERT INTO Gol VALUES (329, 37, 123, 86);
INSERT INTO Gol VALUES (330, 39, 124, 76);
INSERT INTO Gol VALUES (331, 7, 124, 86);
INSERT INTO Gol VALUES (332, 54, 124, 88);
INSERT INTO Gol VALUES (333, 80, 124, 95);
INSERT INTO Gol VALUES (334, 9, 124, 92);
INSERT INTO Gol VALUES (335, 64, 125, 206);
INSERT INTO Gol VALUES (336, 69, 126, 322);
INSERT INTO Gol VALUES (337, 81, 126, 313);
INSERT INTO Gol VALUES (338, 74, 126, 321);
INSERT INTO Gol VALUES (339, 19, 126, 316);
INSERT INTO Gol VALUES (340, 55, 126, 209);
INSERT INTO Gol VALUES (341, 79, 126, 205);
INSERT INTO Gol VALUES (342, 31, 126, 210);
INSERT INTO Gol VALUES (343, 54, 127, 430);
INSERT INTO Gol VALUES (344, 86, 127, 171);
INSERT INTO Gol VALUES (345, 11, 128, 179);
INSERT INTO Gol VALUES (346, 47, 128, 429);
INSERT INTO Gol VALUES (347, 68, 128, 422);
INSERT INTO Gol VALUES (348, 65, 130, 57);
INSERT INTO Gol VALUES (349, 71, 130, 93);
INSERT INTO Gol VALUES (350, 50, 130, 85);
INSERT INTO Gol VALUES (351, 6, 130, 92);
INSERT INTO Gol VALUES (352, 50, 131, 431);
INSERT INTO Gol VALUES (353, 33, 131, 114);
INSERT INTO Gol VALUES (354, 3, 131, 120);
INSERT INTO Gol VALUES (355, 9, 132, 114);
INSERT INTO Gol VALUES (356, 31, 132, 426);
INSERT INTO Gol VALUES (357, 85, 132, 432);
INSERT INTO Gol VALUES (358, 14, 132, 431);
INSERT INTO Gol VALUES (359, 43, 132, 430);
INSERT INTO Gol VALUES (360, 6, 133, 207);
INSERT INTO Gol VALUES (361, 70, 133, 210);
INSERT INTO Gol VALUES (362, 83, 133, 210);
INSERT INTO Gol VALUES (363, 88, 134, 207);
INSERT INTO Gol VALUES (364, 90, 135, 200);
INSERT INTO Gol VALUES (365, 81, 135, 200);
INSERT INTO Gol VALUES (366, 18, 135, 315);
INSERT INTO Gol VALUES (367, 59, 135, 314);
INSERT INTO Gol VALUES (368, 38, 135, 313);
INSERT INTO Gol VALUES (369, 6, 136, 316);
INSERT INTO Gol VALUES (370, 6, 136, 316);
INSERT INTO Gol VALUES (371, 40, 136, 318);
INSERT INTO Gol VALUES (372, 51, 136, 321);
INSERT INTO Gol VALUES (373, 61, 136, 321);
INSERT INTO Gol VALUES (374, 5, 136, 317);
INSERT INTO Gol VALUES (375, 25, 136, 323);
INSERT INTO Gol VALUES (376, 46, 137, 125);
INSERT INTO Gol VALUES (377, 84, 137, 121);
INSERT INTO Gol VALUES (378, 35, 137, 78);
INSERT INTO Gol VALUES (379, 48, 138, 74);
INSERT INTO Gol VALUES (380, 52, 138, 79);
INSERT INTO Gol VALUES (381, 57, 138, 84);
INSERT INTO Gol VALUES (382, 44, 138, 127);
INSERT INTO Gol VALUES (383, 64, 140, 27);
INSERT INTO Gol VALUES (384, 64, 140, 36);
INSERT INTO Gol VALUES (385, 67, 140, 30);
INSERT INTO Gol VALUES (386, 11, 140, 29);
INSERT INTO Gol VALUES (387, 55, 140, 36);
INSERT INTO Gol VALUES (388, 56, 140, 134);
INSERT INTO Gol VALUES (389, 24, 141, 166);
INSERT INTO Gol VALUES (390, 38, 141, 165);
INSERT INTO Gol VALUES (391, 14, 142, 174);
INSERT INTO Gol VALUES (392, 42, 142, 170);
INSERT INTO Gol VALUES (393, 38, 142, 179);
INSERT INTO Gol VALUES (394, 58, 143, 281);
INSERT INTO Gol VALUES (395, 55, 143, 286);
INSERT INTO Gol VALUES (396, 89, 144, 279);
INSERT INTO Gol VALUES (397, 45, 144, 8);
INSERT INTO Gol VALUES (398, 6, 144, 8);
INSERT INTO Gol VALUES (399, 46, 144, 12);
INSERT INTO Gol VALUES (400, 56, 145, 94);
INSERT INTO Gol VALUES (401, 82, 145, 89);

-- INSERT ESTADISTICAS
INSERT INTO EstadisticaJugador VALUES (1, 1, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (2, 1, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (2, 2, 2, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (5, 2, 2, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (6, 2, 2, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (7, 1, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (7, 2, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (8, 1, 3, 1, 1, 0);
INSERT INTO EstadisticaJugador VALUES (8, 2, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (8, 5, 2, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (9, 1, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (9, 2, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (10, 2, 2, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (11, 1, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (11, 2, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (12, 1, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (12, 5, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (13, 1, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (15, 1, 2, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (15, 2, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (15, 4, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (16, 3, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (17, 1, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (18, 3, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (19, 1, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (20, 1, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (21, 3, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (22, 2, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (24, 2, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (25, 1, 3, 1, 0, 1);
INSERT INTO EstadisticaJugador VALUES (25, 2, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (25, 3, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (25, 5, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (26, 2, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (26, 3, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (26, 5, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (27, 1, 3, 1, 1, 3);
INSERT INTO EstadisticaJugador VALUES (27, 3, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (27, 4, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (27, 5, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (28, 1, 2, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (28, 3, 2, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (28, 4, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (28, 5, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (29, 2, 4, 1, 1, 1);
INSERT INTO EstadisticaJugador VALUES (29, 5, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (30, 1, 2, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (30, 2, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (30, 4, 4, 1, 1, 1);
INSERT INTO EstadisticaJugador VALUES (30, 5, 2, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (31, 1, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (31, 2, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (31, 3, 2, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (32, 1, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (32, 2, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (32, 3, 3, 1, 1, 1);
INSERT INTO EstadisticaJugador VALUES (33, 2, 2, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (33, 3, 2, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (33, 4, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (33, 5, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (34, 1, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (34, 2, 3, 1, 0, 0);
INSERT INTO EstadisticaJugador VALUES (34, 3, 3, 1, 0, 3);
INSERT INTO EstadisticaJugador VALUES (35, 1, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (35, 2, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (35, 3, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (36, 2, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (36, 5, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (37, 1, 2, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (37, 3, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (38, 1, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (38, 3, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (39, 2, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (41, 1, 2, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (42, 3, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (43, 1, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (43, 4, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (44, 1, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (44, 4, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (45, 1, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (45, 2, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (46, 1, 2, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (47, 2, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (48, 1, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (49, 1, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (49, 3, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (50, 2, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (50, 3, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (50, 4, 3, 1, 0, 0);
INSERT INTO EstadisticaJugador VALUES (51, 3, 3, 1, 1, 1);
INSERT INTO EstadisticaJugador VALUES (52, 1, 2, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (52, 3, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (53, 3, 2, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (53, 4, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (54, 1, 2, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (54, 3, 2, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (54, 4, 3, 1, 1, 2);
INSERT INTO EstadisticaJugador VALUES (55, 1, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (55, 3, 3, 1, 0, 3);
INSERT INTO EstadisticaJugador VALUES (55, 4, 2, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (56, 1, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (56, 3, 3, 1, 0, 3);
INSERT INTO EstadisticaJugador VALUES (57, 1, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (57, 2, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (57, 3, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (57, 5, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (58, 1, 2, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (58, 4, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (59, 1, 3, 1, 1, 2);
INSERT INTO EstadisticaJugador VALUES (59, 4, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (62, 1, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (66, 1, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (67, 1, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (74, 1, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (74, 3, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (74, 5, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (75, 3, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (76, 1, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (76, 5, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (78, 3, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (78, 5, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (79, 3, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (79, 5, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (80, 1, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (80, 3, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (81, 1, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (82, 3, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (83, 3, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (84, 3, 2, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (84, 5, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (85, 5, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (86, 5, 2, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (88, 1, 3, 1, 0, 2);
INSERT INTO EstadisticaJugador VALUES (88, 5, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (89, 1, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (89, 5, 2, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (90, 1, 3, 1, 1, 3);
INSERT INTO EstadisticaJugador VALUES (92, 1, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (92, 5, 3, 1, 1, 0);
INSERT INTO EstadisticaJugador VALUES (93, 5, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (94, 1, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (94, 5, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (95, 5, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (96, 1, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (96, 5, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (98, 1, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (111, 2, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (111, 3, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (111, 4, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (112, 2, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (112, 4, 3, 1, 0, 0);
INSERT INTO EstadisticaJugador VALUES (113, 2, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (113, 4, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (114, 2, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (114, 4, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (114, 5, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (115, 2, 3, 1, 1, 1);
INSERT INTO EstadisticaJugador VALUES (116, 3, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (116, 4, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (117, 3, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (118, 2, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (118, 3, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (119, 2, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (119, 3, 3, 1, 1, 1);
INSERT INTO EstadisticaJugador VALUES (120, 2, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (120, 3, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (120, 4, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (120, 5, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (121, 2, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (121, 5, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (125, 1, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (125, 5, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (127, 5, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (132, 2, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (134, 1, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (134, 2, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (134, 5, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (141, 1, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (144, 1, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (146, 2, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (150, 2, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (151, 2, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (152, 2, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (154, 2, 2, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (158, 3, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (161, 4, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (162, 1, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (162, 4, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (163, 4, 2, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (165, 5, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (166, 1, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (166, 4, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (166, 5, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (167, 4, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (170, 5, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (171, 3, 4, 1, 1, 2);
INSERT INTO EstadisticaJugador VALUES (171, 5, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (173, 3, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (173, 4, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (174, 3, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (174, 5, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (175, 3, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (175, 4, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (176, 1, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (177, 1, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (177, 4, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (178, 4, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (179, 3, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (179, 5, 2, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (180, 3, 2, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (182, 1, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (192, 1, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (193, 2, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (194, 2, 3, 1, 0, 3);
INSERT INTO EstadisticaJugador VALUES (194, 3, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (195, 2, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (197, 2, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (197, 3, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (198, 2, 2, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (200, 2, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (200, 3, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (200, 5, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (201, 2, 2, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (202, 3, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (204, 2, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (205, 5, 2, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (206, 5, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (207, 5, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (209, 5, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (210, 5, 4, 1, 0, 1);
INSERT INTO EstadisticaJugador VALUES (211, 5, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (215, 2, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (219, 2, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (220, 2, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (222, 2, 2, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (223, 2, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (226, 2, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (228, 2, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (243, 2, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (266, 2, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (272, 2, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (278, 3, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (279, 4, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (279, 5, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (281, 5, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (282, 3, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (282, 4, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (284, 3, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (285, 4, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (286, 3, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (286, 4, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (286, 5, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (287, 4, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (288, 4, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (290, 3, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (291, 3, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (297, 3, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (302, 3, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (313, 5, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (314, 3, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (314, 5, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (315, 5, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (316, 5, 3, 1, 0, 3);
INSERT INTO EstadisticaJugador VALUES (317, 5, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (318, 4, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (318, 5, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (319, 4, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (320, 4, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (321, 4, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (321, 5, 3, 1, 1, 2);
INSERT INTO EstadisticaJugador VALUES (322, 5, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (323, 4, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (323, 5, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (324, 4, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (330, 3, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (343, 3, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (349, 4, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (351, 4, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (354, 4, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (357, 4, 1, 0, 1, 0);
INSERT INTO EstadisticaJugador VALUES (358, 4, 1, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (363, 4, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (365, 4, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (367, 4, 1, 0, 0, 1);
INSERT INTO EstadisticaJugador VALUES (370, 4, 1, 0, 0, 0);
INSERT INTO EstadisticaJugador VALUES (372, 4, 1, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (374, 4, 2, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (387, 4, 1, 0, 0, 2);
INSERT INTO EstadisticaJugador VALUES (397, 4, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (422, 5, 1, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (426, 5, 2, 0, 1, 2);
INSERT INTO EstadisticaJugador VALUES (427, 5, 2, 0, 1, 3);
INSERT INTO EstadisticaJugador VALUES (429, 5, 1, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (430, 5, 2, 0, 1, 1);
INSERT INTO EstadisticaJugador VALUES (431, 5, 2, 0, 0, 3);
INSERT INTO EstadisticaJugador VALUES (432, 5, 1, 0, 0, 0);

/*
=============================================================================
SCRIPT DE GENERACIÓN MASIVA DE DATOS (DML)
PROYECTO CORPORATIVO DE SEGUROS
=============================================================================
*/

USE CorporateInsuranceDB;
GO

SET NOCOUNT ON;

BEGIN TRANSACTION;

-- ============================================================
-- 1. INSERCIÓN DE CLIENTES (50 Registros de prueba)
-- ============================================================
INSERT INTO Clientes (nombre_completo, email, telefono, direccion, pais, tipo_documento, numero_documento) VALUES 
('Roberto Gomez Bolaños', 'chespirito@tv.com', '555-0001', 'Vecindad 8', 'Mexico', 'INE', 'MX-001'),
('Walter White', 'heisenberg@blue.com', '505-1234', 'Negra Arroyo Lane', 'USA', 'Passport', 'US-001'),
('Tony Stark', 'ironman@avengers.com', '212-9999', 'Stark Tower', 'USA', 'Passport', 'US-002'),
('Bruce Wayne', 'batman@wayne.com', '123-4567', 'Wayne Manor', 'USA', 'Passport', 'US-003'),
('Clark Kent', 'superman@daily.com', '999-8888', 'Metropolis 1', 'USA', 'Passport', 'US-004'),
('Diana Prince', 'ww@themyscira.com', '777-7777', 'Island 1', 'Grecia', 'Passport', 'EU-001'),
('Peter Parker', 'spidey@dailybugle.com', '555-WEB1', 'Queens Apt 20', 'USA', 'Passport', 'US-005'),
('Natasha Romanoff', 'bw@shield.gov', '000-0000', 'Unknown', 'Rusia', 'Passport', 'RU-001'),
('Steve Rogers', 'cap@shield.gov', '194-5000', 'Brooklyn 1', 'USA', 'Passport', 'US-006'),
('Thor Odinson', 'god@asgard.com', '111-LIGHT', 'Asgard 1', 'Noruega', 'Passport', 'EU-002'),
('Lois Lane', 'lois@daily.com', '555-REPT', 'Metropolis 2', 'USA', 'Passport', 'US-007'),
('Lex Luthor', 'lex@lexcorp.com', '555-EVIL', 'Lex Tower', 'USA', 'Passport', 'US-008'),
('Barry Allen', 'flash@central.com', '555-FAST', 'Central City', 'USA', 'Passport', 'US-009'),
('Arthur Curry', 'aquaman@atlantis.com', '555-FISH', 'Atlantis', 'USA', 'Passport', 'US-010'),
('Hal Jordan', 'gl@oa.com', '555-RING', 'Coast City', 'USA', 'Passport', 'US-011'),
('Wanda Maximoff', 'witch@magic.com', '555-HEX1', 'Westview', 'USA', 'Passport', 'US-012'),
('Vision Android', 'vis@mindstone.com', '555-DATA', 'Westview', 'USA', 'Passport', 'US-013'),
('Stephen Strange', 'doc@sanctum.com', '555-MAGIC', 'Bleecker St', 'USA', 'Passport', 'US-014'),
('TChalla King', 'bp@wakanda.gov', '555-VIBRA', 'Wakanda Palace', 'Sudafrica', 'Passport', 'AF-001'),
('Carol Danvers', 'cm@marvel.com', '555-STAR', 'Space', 'USA', 'Passport', 'US-015'),
('Luis Miguel', 'sol@mexico.com', '555-SOL1', 'Acapulco', 'Mexico', 'INE', 'MX-002'),
('Vicente Fernandez', 'chente@ranch.com', '555-SONG', 'Rancho 3 Potrillos', 'Mexico', 'INE', 'MX-003'),
('Juan Gabriel', 'juanga@noa.com', '555-AMOR', 'Juarez', 'Mexico', 'INE', 'MX-004'),
('Thalia Sodi', 'thalia@maria.com', '555-MARI', 'New York', 'USA', 'Passport', 'US-016'),
('Salma Hayek', 'salma@hollywood.com', '555-CINE', 'LA', 'USA', 'Passport', 'US-017'),
('Guillermo del Toro', 'memo@monsters.com', '555-OSCAR', 'Guadalajara', 'Mexico', 'INE', 'MX-005'),
('Alfonso Cuaron', 'alfonso@roma.com', '555-FILM', 'CDMX', 'Mexico', 'INE', 'MX-006'),
('Alejandro Inarritu', 'negro@birdman.com', '555-SHOT', 'CDMX', 'Mexico', 'INE', 'MX-007'),
('Diego Luna', 'diego@starwars.com', '555-R1', 'CDMX', 'Mexico', 'INE', 'MX-008'),
('Gael Garcia', 'gael@yitu.com', '555-MAMA', 'CDMX', 'Mexico', 'INE', 'MX-009'),
('Lionel Messi', 'leo@goat.com', '555-GOAT', 'Miami', 'Argentina', 'DNI', 'AR-001'),
('Cristiano Ronaldo', 'cr7@siu.com', '555-GOAL', 'Riyadh', 'Portugal', 'Passport', 'EU-003'),
('Neymar Jr', 'ney@brazil.com', '555-SAMBA', 'Santos', 'Brasil', 'Passport', 'BR-001'),
('Kylian Mbappe', 'km@paris.com', '555-SPEED', 'Paris', 'Francia', 'Passport', 'EU-004'),
('Luka Modric', 'luka@madrid.com', '555-MID', 'Madrid', 'Croacia', 'Passport', 'EU-005'),
('Sergio Perez', 'checo@f1.com', '555-RACE', 'Guadalajara', 'Mexico', 'INE', 'MX-010'),
('Max Verstappen', 'max@f1.com', '555-WIN', 'Monaco', 'Holanda', 'Passport', 'EU-006'),
('Lewis Hamilton', 'lewis@f1.com', '555-HAM', 'London', 'UK', 'Passport', 'EU-007'),
('Fernando Alonso', 'nano@f1.com', '555-MAGIC', 'Oviedo', 'Espana', 'Passport', 'EU-008'),
('Carlos Sainz', 'chili@f1.com', '555-SMOOTH', 'Madrid', 'Espana', 'Passport', 'EU-009'),
('Shakira Mebarak', 'shaki@waka.com', '555-HIPS', 'Barcelona', 'Colombia', 'Passport', 'CO-001'),
('Karol G', 'bichota@col.com', '555-MAKIN', 'Medellin', 'Colombia', 'Passport', 'CO-002'),
('J Balvin', 'jose@colores.com', '555-RITMO', 'Medellin', 'Colombia', 'Passport', 'CO-003'),
('Maluma Baby', 'juan@hawaii.com', '555-PAPI', 'Medellin', 'Colombia', 'Passport', 'CO-004'),
('Bad Bunny', 'benito@pr.com', '555-CONEJO', 'San Juan', 'Puerto Rico', 'Passport', 'PR-001'),
('Daddy Yankee', 'boss@reggaeton.com', '555-GASO', 'San Juan', 'Puerto Rico', 'Passport', 'PR-002'),
('Rosalia Vila', 'rosi@moto.com', '555-MAMI', 'Barcelona', 'Espana', 'Passport', 'EU-010'),
('Harry Styles', 'harry@sugar.com', '555-WATER', 'London', 'UK', 'Passport', 'EU-011'),
('Taylor Swift', 'taylor@eras.com', '555-SONGS', 'Nashville', 'USA', 'Passport', 'US-018'),
('Adele Adkins', 'adele@hello.com', '555-ROLL', 'London', 'UK', 'Passport', 'EU-012');

-- ============================================================
-- 2. GENERACIÓN DE PÓLIZAS (70 Registros aleatorios)
-- ============================================================
DECLARE @i INT = 1;
DECLARE @cliente_random INT;
DECLARE @tipo_random VARCHAR(50);
DECLARE @region_random VARCHAR(50);
DECLARE @estado_random VARCHAR(30);
DECLARE @prima_random DECIMAL(10,2);

WHILE @i <= 70
BEGIN
    -- Selección aleatoria de relaciones y atributos
    SELECT TOP 1 @cliente_random = cliente_id, @region_random = pais FROM Clientes ORDER BY NEWID();
    SELECT TOP 1 @tipo_random = Valor FROM (VALUES ('Auto'), ('Vida'), ('Salud'), ('Hogar'), ('Empresarial')) AS T(Valor) ORDER BY NEWID();
    SELECT TOP 1 @estado_random = Valor FROM (VALUES ('Activa'), ('Activa'), ('Activa'), ('Suspendida'), ('Vencida'), ('Cancelada')) AS T(Valor) ORDER BY NEWID();
    
    -- Cálculo de prima variable
    SET @prima_random = CAST(RAND() * 49000 + 1000 AS DECIMAL(10,2));

    INSERT INTO Polizas (cliente_id, tipo_poliza, cobertura, prima_anual, fecha_inicio, fecha_fin, estado_poliza, region)
    VALUES (
        @cliente_random, 
        @tipo_random, 
        'Cobertura ' + @tipo_random + ' Premium', 
        @prima_random, 
        DATEADD(DAY, -CAST(RAND()*365 AS INT), GETDATE()), -- Fecha inicio aleatoria (último año)
        DATEADD(DAY, CAST(RAND()*365 AS INT), GETDATE()),  -- Fecha fin aleatoria (futuro cercano)
        @estado_random, 
        @region_random
    );

    SET @i = @i + 1;
END;

-- ============================================================
-- 3. GENERACIÓN DE SINIESTROS (50 Registros)
-- ============================================================
SET @i = 1;
DECLARE @poliza_activa INT;
DECLARE @tipo_siniestro VARCHAR(50);
DECLARE @monto_siniestro DECIMAL(10,2);
DECLARE @estado_siniestro VARCHAR(20);

WHILE @i <= 50
BEGIN
    -- Validación: Solo asociar siniestros a pólizas ACTIVAS para mantener integridad referencial
    SELECT TOP 1 @poliza_activa = poliza_id FROM Polizas WHERE estado_poliza = 'Activa' ORDER BY NEWID();

    IF @poliza_activa IS NOT NULL
    BEGIN
        SELECT TOP 1 @tipo_siniestro = Valor FROM (VALUES ('Choque'), ('Robo'), ('Incendio'), ('Enfermedad'), ('Inundacion')) AS T(Valor) ORDER BY NEWID();
        SELECT TOP 1 @estado_siniestro = Valor FROM (VALUES ('En revisión'), ('Aprobado'), ('Pagado'), ('Rechazado')) AS T(Valor) ORDER BY NEWID();
        SET @monto_siniestro = CAST(RAND() * 200000 + 500 AS DECIMAL(10,2));

        INSERT INTO Siniestros (poliza_id, tipo_siniestro, monto_estimado, estado_siniestro, descripcion, agente_id)
        VALUES (@poliza_activa, @tipo_siniestro, @monto_siniestro, @estado_siniestro, 'Incidente reportado aleatoriamente para pruebas de carga.', 1);
    END

    SET @i = @i + 1;
END;

-- ============================================================
-- 4. AJUSTE DE FECHAS (Distribución anual)
-- ============================================================
-- Distribuye los siniestros aleatoriamente en los últimos 12 meses para visualizar datos en el Dashboard PIVOT
UPDATE Siniestros
SET fecha_reporte = DATEADD(MONTH, -ABS(CHECKSUM(NEWID()) % 12), GETDATE());

COMMIT TRANSACTION;
GO
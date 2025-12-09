/*
=============================================================================
UNIVERSIDAD TECNOLÓGICA DE MÉXICO
PROYECTO FINAL: GESTIÓN DE BASES DE DATOS
SISTEMA INTEGRAL DE SEGUROS A NIVEL CONTINENTAL
=============================================================================
Descripción: Script DDL y DML para la creación de la estructura de base de datos,
             procedimientos almacenados, triggers, vistas y configuración de
             replicación simulada.
Autor:       David Mosco Gasca
Fecha:       Noviembre 2025
=============================================================================
*/


CREATE DATABASE CorporateInsuranceDB;
GO

USE CorporateInsuranceDB;
GO

/*
=============================================================================
1. DEFINICIÓN DE TABLAS (DDL)
=============================================================================
*/

-- Tabla de Clientes: Almacena la información personal y de contacto.
CREATE TABLE Clientes (
    cliente_id INT PRIMARY KEY IDENTITY(1,1),
    nombre_completo VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(150),
    pais VARCHAR(50) NOT NULL, 
    tipo_documento VARCHAR(20), 
    numero_documento VARCHAR(30) UNIQUE NOT NULL,
    fecha_registro DATE DEFAULT GETDATE()
);

-- Tabla de Agentes: Usuarios del sistema con roles y credenciales.
CREATE TABLE Agentes (
    agente_id INT PRIMARY KEY IDENTITY(1,1),
    nombre_completo VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    puesto VARCHAR(50) NOT NULL, -- Roles: Administrador Global, Agente Regional, Analista de Riesgo
    usuario VARCHAR(50) UNIQUE NOT NULL, 
    contrasena VARCHAR(100) NOT NULL,
    fecha_ingreso DATE DEFAULT GETDATE(),
    estado VARCHAR(20) NOT NULL -- Activo / Inactivo
);

-- Tabla Central de Pólizas: Registro maestro de contratos.
CREATE TABLE Polizas (
    poliza_id INT PRIMARY KEY IDENTITY(1,1),
    cliente_id INT NOT NULL,
    tipo_poliza VARCHAR(50) NOT NULL, 
    cobertura VARCHAR(100),
    prima_anual DECIMAL(10,2) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado_poliza VARCHAR(30) NOT NULL DEFAULT 'Activa', 
    region VARCHAR(50) NOT NULL, 
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id)
);

-- Tablas para Simulación de Fragmentación Horizontal (Nodos Regionales)
-- Nodo 1: Registros exclusivos de la región México.
CREATE TABLE Polizas_Nodo_Mexico (
    poliza_id INT PRIMARY KEY,
    cliente_id INT,
    tipo_poliza VARCHAR(50),
    prima_anual DECIMAL(10,2),
    estado_poliza VARCHAR(30),
    fecha_registro_nodo DATETIME DEFAULT GETDATE()
);

-- Nodo 2: Registros internacionales (USA, Canadá, Latam, Europa).
CREATE TABLE Polizas_Nodo_Internacional (
    poliza_id INT PRIMARY KEY,
    cliente_id INT,
    tipo_poliza VARCHAR(50),
    prima_anual DECIMAL(10,2),
    estado_poliza VARCHAR(30),
    pais_origen VARCHAR(50),
    fecha_registro_nodo DATETIME DEFAULT GETDATE()
);

-- Tabla de Siniestros: Registro de incidentes asociados a pólizas.
CREATE TABLE Siniestros (
    siniestro_id INT PRIMARY KEY IDENTITY(1,1),
    poliza_id INT NOT NULL,
    fecha_reporte DATE DEFAULT GETDATE(),
    tipo_siniestro VARCHAR(50) NOT NULL,
    monto_estimado DECIMAL(10,2),
    estado_siniestro VARCHAR(20) NOT NULL DEFAULT 'En revisión', 
    descripcion VARCHAR(MAX),
    agente_id INT,
    FOREIGN KEY (poliza_id) REFERENCES Polizas(poliza_id),
    FOREIGN KEY (agente_id) REFERENCES Agentes(agente_id)
);

-- Tabla de Pagos: Registro transaccional de ingresos.
CREATE TABLE Pagos (
    pago_id INT PRIMARY KEY IDENTITY(1,1),
    poliza_id INT NOT NULL,
    fecha_pago DATE DEFAULT GETDATE(),
    monto DECIMAL(10,2) NOT NULL,
    metodo_pago VARCHAR(30), 
    estado_pago VARCHAR(20) NOT NULL DEFAULT 'Confirmado', 
    FOREIGN KEY (poliza_id) REFERENCES Polizas(poliza_id)
);

-- Tablas de Auditoría: Trazabilidad y Seguridad.
CREATE TABLE Auditoria_General (
    auditoria_id INT PRIMARY KEY IDENTITY(1,1), 
    tabla_afectada VARCHAR(50) NOT NULL,
    accion VARCHAR(20) NOT NULL,
    usuario VARCHAR(50) NOT NULL,
    fecha_cambio DATETIME DEFAULT GETDATE(), 
    detalles_cambio VARCHAR(MAX) 
);

CREATE TABLE Auditoria_Fallos_Transaccion (
    fallo_id INT PRIMARY KEY IDENTITY(1,1),
    fecha_hora DATETIME DEFAULT GETDATE(),
    procedimiento_afectado VARCHAR(100) NOT NULL,
    mensaje_error VARCHAR(MAX) NOT NULL,
    datos_entrada VARCHAR(MAX),
    usuario VARCHAR(50)
);
GO

/*
=============================================================================
2. ÍNDICES DE RENDIMIENTO
=============================================================================
*/
CREATE INDEX IDX_Polizas_Tipo_Region ON Polizas (tipo_poliza, region);
CREATE INDEX IDX_Siniestros_Estado ON Siniestros (estado_siniestro);
CREATE INDEX IDX_Siniestros_FechaReporte ON Siniestros (fecha_reporte);
GO

/*
=============================================================================
3. VISTAS DEL SISTEMA
=============================================================================
*/

-- Vista para monitoreo de pólizas próximas a vencer (30 días).
CREATE VIEW vw_Alertas_Vencimiento AS
SELECT 
    P.poliza_id,
    C.nombre_completo AS nombre_cliente,
    P.tipo_poliza,
    P.fecha_fin,
    P.estado_poliza,
    DATEDIFF(day, GETDATE(), P.fecha_fin) AS dias_restantes
FROM 
    Polizas P
JOIN 
    Clientes C ON P.cliente_id = C.cliente_id
WHERE 
    P.estado_poliza IN ('Activa', 'Suspendida')
    AND P.fecha_fin <= DATEADD(day, 30, GETDATE()); 
GO

/*
=============================================================================
4. DATOS INICIALES (Semilla del Sistema)
=============================================================================
*/
-- Inserción de usuarios base para administración.
SET IDENTITY_INSERT Agentes ON;
INSERT INTO Agentes (agente_id, nombre_completo, region, puesto, usuario, contrasena, estado) 
VALUES (1, 'Admin Global Corp', 'Global', 'Administrador Global', 'admin', 'adminpass', 'Activo');
INSERT INTO Agentes (agente_id, nombre_completo, region, puesto, usuario, contrasena, estado) 
VALUES (2, 'Agente Regional MX', 'Mexico', 'Agente Regional', 'empleado', 'emppass', 'Activo');
INSERT INTO Agentes (agente_id, nombre_completo, region, puesto, usuario, contrasena, estado) 
VALUES (3, 'Auditor de Riesgos', 'Global', 'Analista de Riesgo', 'auditor', 'auditorpass', 'Activo');
SET IDENTITY_INSERT Agentes OFF;
GO

/*
=============================================================================
5. PROCEDIMIENTOS ALMACENADOS (Lógica de Negocio)
=============================================================================
*/

-- SP: Validación de Credenciales (Login).
CREATE PROCEDURE sp_validar_agente @p_usuario VARCHAR(50), @p_contrasena VARCHAR(100) AS 
BEGIN 
    SET NOCOUNT ON; 
    DECLARE @v_agente_id INT, @v_nombre_completo VARCHAR(100), @v_puesto VARCHAR(50), @v_estado VARCHAR(20), @v_contrasena_db VARCHAR(100); 
    SELECT @v_agente_id = agente_id, @v_nombre_completo = nombre_completo, @v_puesto = puesto, @v_estado = estado, @v_contrasena_db = LTRIM(RTRIM(contrasena)) 
    FROM Agentes WHERE UPPER(LTRIM(RTRIM(usuario))) = UPPER(LTRIM(RTRIM(@p_usuario))); 
    IF @v_agente_id IS NULL BEGIN SELECT NULL AS agente_id, 'Error: Usuario no encontrado.' AS nombre_completo, NULL AS puesto, CAST(0 AS BIT) AS autenticado; RETURN; END; 
    IF @v_estado <> 'Activo' BEGIN SELECT NULL, 'Error: El agente no está activo.', NULL, CAST(0 AS BIT); RETURN; END; 
    IF LTRIM(RTRIM(@p_contrasena)) <> @v_contrasena_db BEGIN SELECT NULL, 'Error: Contraseña incorrecta.', NULL, CAST(0 AS BIT); RETURN; END; 
    SELECT @v_agente_id, @v_nombre_completo, @v_puesto, CAST(1 AS BIT) AS autenticado; 
END;
GO

-- SP: Creación de Agentes (Administración).
CREATE PROCEDURE sp_admin_crear_agente @p_nombre_completo VARCHAR(100), @p_region VARCHAR(50), @p_puesto VARCHAR(50), @p_usuario VARCHAR(50), @p_contrasena VARCHAR(100) AS 
BEGIN 
    SET NOCOUNT ON; 
    BEGIN TRY 
        IF EXISTS (SELECT 1 FROM Agentes WHERE UPPER(usuario) = UPPER(@p_usuario)) THROW 50001, 'Error: El usuario ya existe.', 1; 
        INSERT INTO Agentes (nombre_completo, region, puesto, usuario, contrasena, estado) VALUES (@p_nombre_completo, @p_region, @p_puesto, @p_usuario, @p_contrasena, 'Activo'); 
        SELECT CAST(1 AS BIT) AS resultado, 'Agente creado.' AS mensaje; 
    END TRY 
    BEGIN CATCH SELECT CAST(0 AS BIT), ERROR_MESSAGE(); END CATCH 
END;
GO

-- SP: Registro de Siniestros con Transacción Atómica.
CREATE PROCEDURE sp_registrar_siniestro
    @p_poliza_id INT,
    @p_tipo_siniestro VARCHAR(50),
    @p_monto_estimado DECIMAL(10,2),
    @p_descripcion VARCHAR(MAX),
    @p_agente_id INT,
    @p_usuario_web VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Validaciones de estado
        DECLARE @v_estado_poliza VARCHAR(30);
        SELECT @v_estado_poliza = estado_poliza FROM Polizas WHERE poliza_id = @p_poliza_id;
        
        IF @v_estado_poliza IS NULL BEGIN THROW 50001, 'Error: La Póliza ID no existe.', 1; END;
        IF @v_estado_poliza NOT IN ('Activa', 'Con Siniestro Reportado')
        BEGIN
            THROW 50002, 'Error: La póliza no está activa. No se puede registrar el siniestro.', 1;
        END;

        INSERT INTO Siniestros (poliza_id, tipo_siniestro, monto_estimado, descripcion, agente_id)
        VALUES (@p_poliza_id, @p_tipo_siniestro, @p_monto_estimado, @p_descripcion, @p_agente_id);
        
        UPDATE Polizas SET estado_poliza = 'Con Siniestro Reportado' WHERE poliza_id = @p_poliza_id;
        COMMIT TRANSACTION;
        SELECT CAST(1 AS BIT) AS resultado, 'Siniestro registrado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        INSERT INTO Auditoria_Fallos_Transaccion (procedimiento_afectado, mensaje_error, datos_entrada, usuario)
        VALUES ('sp_registrar_siniestro', ERROR_MESSAGE(), 'PolizaID: ' + CONVERT(VARCHAR, @p_poliza_id), @p_usuario_web);
        SELECT CAST(0 AS BIT), 'FALLO: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- SP: Registro de Pagos y Renovación Automática.
-- Incluye lógica para reactivar pólizas Vencidas o Suspendidas.
CREATE PROCEDURE sp_registrar_pago
    @p_poliza_id INT,
    @p_monto DECIMAL(10,2),
    @p_metodo_pago VARCHAR(30),
    @p_usuario_web VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @v_estado_poliza VARCHAR(30);
        DECLARE @v_prima DECIMAL(10,2);
        
        SELECT @v_estado_poliza = estado_poliza, @v_prima = prima_anual 
        FROM Polizas WHERE poliza_id = @p_poliza_id;

        IF @v_estado_poliza IS NULL BEGIN THROW 50001, 'Error: Póliza no encontrada.', 1; END;
        IF @v_estado_poliza = 'Cancelada' BEGIN THROW 50003, 'Error: Póliza Cancelada. Pago rechazado.', 1; END;

        INSERT INTO Pagos (poliza_id, monto, metodo_pago, estado_pago)
        VALUES (@p_poliza_id, @p_monto, @p_metodo_pago, 'Confirmado');

        -- Lógica de renovación/reactivación
        IF @p_monto >= (@v_prima * 0.9)
        BEGIN
            IF @v_estado_poliza = 'Vencida'
            BEGIN
                UPDATE Polizas SET estado_poliza = 'Activa', fecha_inicio = GETDATE(), fecha_fin = DATEADD(YEAR, 1, GETDATE()) WHERE poliza_id = @p_poliza_id;
            END
            ELSE IF @v_estado_poliza = 'Activa'
            BEGIN
                UPDATE Polizas SET fecha_fin = DATEADD(YEAR, 1, fecha_fin) WHERE poliza_id = @p_poliza_id;
            END
            ELSE IF @v_estado_poliza = 'Suspendida'
            BEGIN
                UPDATE Polizas SET estado_poliza = 'Activa' WHERE poliza_id = @p_poliza_id;
            END
        END

        COMMIT TRANSACTION;
        SELECT CAST(1 AS BIT) AS resultado, 'Pago registrado y vigencia actualizada.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        INSERT INTO Auditoria_Fallos_Transaccion (procedimiento_afectado, mensaje_error, datos_entrada, usuario)
        VALUES ('sp_registrar_pago', ERROR_MESSAGE(), 'PolizaID: ' + CONVERT(VARCHAR, @p_poliza_id), @p_usuario_web);
        SELECT CAST(0 AS BIT), 'FALLO: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- SP: Cancelación de Póliza (Transaccional).
CREATE PROCEDURE sp_cancelar_poliza @p_poliza_id INT, @p_usuario_web VARCHAR(50) AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Polizas WHERE poliza_id = @p_poliza_id) THROW 50001, 'Error: Póliza inexistente.', 1;
        UPDATE Polizas SET estado_poliza = 'Cancelada' WHERE poliza_id = @p_poliza_id;
        INSERT INTO Pagos (poliza_id, monto, metodo_pago, estado_pago) VALUES (@p_poliza_id, 0, 'Reversión', 'Revertido');
        COMMIT TRANSACTION;
        SELECT CAST(1 AS BIT), 'Póliza cancelada correctamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        INSERT INTO Auditoria_Fallos_Transaccion (procedimiento_afectado, mensaje_error, datos_entrada, usuario)
        VALUES ('sp_cancelar_poliza', ERROR_MESSAGE(), 'ID: ' + CAST(@p_poliza_id AS VARCHAR), @p_usuario_web);
        SELECT CAST(0 AS BIT), ERROR_MESSAGE();
    END CATCH
END;
GO

-- SP: Reporte Avanzado (PIVOT y RANKING).
CREATE PROCEDURE sp_reporte_avanzado_corporativo AS
BEGIN
    SET NOCOUNT ON;
    -- 1. Ranking de Países y Clasificación de Riesgo
    SELECT TOP 5
        C.pais AS Pais,
        SUM(P.prima_anual) AS Prima_Total,
        RANK() OVER (ORDER BY SUM(P.prima_anual) DESC) AS Ranking_Global,
        CASE 
            WHEN AVG(P.prima_anual) >= 5000.00 THEN 'Alto Riesgo Promedio'
            WHEN AVG(P.prima_anual) >= 1000.00 THEN 'Riesgo Moderado Promedio'
            ELSE 'Bajo Riesgo Promedio'
        END AS Clasificacion_Riesgo_Pais
    FROM Polizas P JOIN Clientes C ON P.cliente_id = C.cliente_id
    GROUP BY C.pais ORDER BY Ranking_Global;

    -- 2. PIVOT: Siniestros por Mes y País
    SELECT * FROM 
    (
        SELECT C.pais, DATENAME(month, S.fecha_reporte) AS Mes, S.siniestro_id 
        FROM Siniestros S JOIN Polizas P ON S.poliza_id = P.poliza_id JOIN Clientes C ON P.cliente_id = C.cliente_id
    ) AS Fuente
    PIVOT ( COUNT(siniestro_id) FOR Mes IN ([Enero], [Febrero], [Marzo], [Abril], [Mayo], [Junio], [Julio], [Agosto], [Septiembre], [Octubre], [Noviembre], [Diciembre]) ) AS PivotTable;
END;
GO

-- Otros Procedimientos Auxiliares (Listados y Consultas)
CREATE PROCEDURE sp_reporte_listar_clientes AS BEGIN SET NOCOUNT ON; SELECT * FROM Clientes ORDER BY cliente_id DESC; END;
GO
CREATE PROCEDURE sp_reporte_listar_polizas @p_cliente_id INT = NULL AS BEGIN SET NOCOUNT ON; SELECT P.*, C.nombre_completo AS nombre_cliente, C.pais AS pais_cliente FROM Polizas P JOIN Clientes C ON P.cliente_id = C.cliente_id WHERE (@p_cliente_id IS NULL OR P.cliente_id = @p_cliente_id) ORDER BY P.poliza_id DESC; END;
GO
CREATE PROCEDURE sp_listar_agentes_activos AS BEGIN SET NOCOUNT ON; SELECT agente_id, nombre_completo, estado FROM Agentes WHERE estado = 'Activo'; END;
GO
CREATE PROCEDURE sp_consultar_alertas_vencimiento AS BEGIN SET NOCOUNT ON; SELECT * FROM vw_Alertas_Vencimiento ORDER BY dias_restantes; END;
GO
CREATE PROCEDURE sp_admin_listar_agentes AS BEGIN SET NOCOUNT ON; SELECT * FROM Agentes; END;
GO
CREATE PROCEDURE sp_auditor_ver_cambios_polizas AS BEGIN SET NOCOUNT ON; SELECT * FROM Auditoria_General ORDER BY fecha_cambio DESC; END;
GO
CREATE PROCEDURE sp_auditor_ver_fallos_transaccion AS BEGIN SET NOCOUNT ON; SELECT * FROM Auditoria_Fallos_Transaccion ORDER BY fecha_hora DESC; END;
GO
CREATE PROCEDURE sp_crear_cliente @p_nombre_completo VARCHAR(100), @p_email VARCHAR(100), @p_telefono VARCHAR(20), @p_direccion VARCHAR(150), @p_pais VARCHAR(50), @p_tipo_documento VARCHAR(20), @p_numero_documento VARCHAR(30), @p_usuario_web VARCHAR(50) AS BEGIN SET NOCOUNT ON; INSERT INTO Clientes (nombre_completo, email, telefono, direccion, pais, tipo_documento, numero_documento) VALUES (@p_nombre_completo, @p_email, @p_telefono, @p_direccion, @p_pais, @p_tipo_documento, @p_numero_documento); SELECT CAST(1 AS BIT), 'Cliente registrado.'; END;
GO
CREATE PROCEDURE sp_crear_poliza @p_cliente_id INT, @p_tipo_poliza VARCHAR(50), @p_cobertura VARCHAR(100), @p_prima_anual DECIMAL(10,2), @p_fecha_inicio DATE, @p_fecha_fin DATE, @p_region_poliza VARCHAR(50), @p_usuario_web VARCHAR(50) AS BEGIN SET NOCOUNT ON; INSERT INTO Polizas (cliente_id, tipo_poliza, cobertura, prima_anual, fecha_inicio, fecha_fin, estado_poliza, region) VALUES (@p_cliente_id, @p_tipo_poliza, @p_cobertura, @p_prima_anual, @p_fecha_inicio, @p_fecha_fin, 'Activa', @p_region_poliza); SELECT CAST(1 AS BIT), 'Póliza creada.'; END;
GO
CREATE PROCEDURE sp_admin_actualizar_estado_agente @p_agente_id INT, @p_nuevo_estado VARCHAR(20) AS BEGIN SET NOCOUNT ON; UPDATE Agentes SET estado = @p_nuevo_estado WHERE agente_id = @p_agente_id; SELECT CAST(1 AS BIT), 'Estado actualizado.'; END;
GO
CREATE PROCEDURE sp_admin_reset_password @p_agente_id INT, @p_nueva_contrasena VARCHAR(100) AS BEGIN SET NOCOUNT ON; UPDATE Agentes SET contrasena = @p_nueva_contrasena WHERE agente_id = @p_agente_id; SELECT CAST(1 AS BIT), 'Contraseña actualizada.'; END;
GO
CREATE PROCEDURE sp_consultar_historial_siniestros @p_cliente_id INT = NULL, @p_pais_cliente VARCHAR(50) = NULL, @p_tipo_poliza VARCHAR(50) = NULL, @p_poliza_id INT = NULL AS BEGIN SET NOCOUNT ON; SELECT S.siniestro_id, S.fecha_reporte, S.tipo_siniestro, S.estado_siniestro, S.monto_estimado, C.nombre_completo AS nombre_cliente, P.tipo_poliza AS tipo_poliza_asociada, C.pais AS pais_cliente FROM Siniestros S JOIN Polizas P ON S.poliza_id = P.poliza_id JOIN Clientes C ON P.cliente_id = C.cliente_id WHERE (@p_cliente_id IS NULL OR C.cliente_id = @p_cliente_id) AND (@p_pais_cliente IS NULL OR C.pais LIKE @p_pais_cliente + '%') AND (@p_tipo_poliza IS NULL OR P.tipo_poliza LIKE @p_tipo_poliza + '%') AND (@p_poliza_id IS NULL OR P.poliza_id = @p_poliza_id) ORDER BY S.fecha_reporte DESC; END;
GO

/*
=============================================================================
6. TRIGGERS (Automatización y Seguridad)
=============================================================================
*/

-- Trigger: Validación de vigencia antes de registrar siniestro.
CREATE TRIGGER trg_Validar_Vigencia_Siniestro
ON Siniestros
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i JOIN Polizas P ON i.poliza_id = P.poliza_id
        WHERE P.estado_poliza NOT IN ('Activa', 'Con Siniestro Reportado')
    )
    BEGIN
        RAISERROR('Error (TRG): La póliza no está activa. Siniestro rechazado.', 16, 1);
        RETURN;
    END
    INSERT INTO Siniestros (poliza_id, fecha_reporte, tipo_siniestro, monto_estimado, estado_siniestro, descripcion, agente_id)
    SELECT poliza_id, fecha_reporte, tipo_siniestro, monto_estimado, estado_siniestro, descripcion, agente_id FROM inserted;
END;
GO

-- Trigger: Simulación de Fragmentación y Replicación Horizontal.
-- Distribuye los datos a nodos regionales según el país de origen.
CREATE OR ALTER TRIGGER trg_Replicacion_Fragmentacion
ON Polizas
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    -- Replicar hacia el Nodo México
    INSERT INTO Polizas_Nodo_Mexico (poliza_id, cliente_id, tipo_poliza, prima_anual, estado_poliza)
    SELECT i.poliza_id, i.cliente_id, i.tipo_poliza, i.prima_anual, i.estado_poliza
    FROM inserted i WHERE i.region = 'Mexico';

    -- Replicar hacia el Nodo Internacional
    INSERT INTO Polizas_Nodo_Internacional (poliza_id, cliente_id, tipo_poliza, prima_anual, estado_poliza, pais_origen)
    SELECT i.poliza_id, i.cliente_id, i.tipo_poliza, i.prima_anual, i.estado_poliza, i.region
    FROM inserted i WHERE i.region <> 'Mexico';

    -- Auditoría de la replicación
    DECLARE @count_mx INT, @count_int INT;
    SELECT @count_mx = COUNT(*) FROM inserted WHERE region = 'Mexico';
    SELECT @count_int = COUNT(*) FROM inserted WHERE region <> 'Mexico';

    IF (@count_mx > 0 OR @count_int > 0)
    BEGIN
        INSERT INTO Auditoria_General (tabla_afectada, accion, usuario, detalles_cambio)
        VALUES ('Polizas', 'REPLICACION', 'SystemTrigger', 
                'Replicación completada: ' + CAST(@count_mx AS VARCHAR) + ' a Nodo MX, ' + CAST(@count_int AS VARCHAR) + ' a Nodo INT.');
    END
END;
GO

-- Triggers de Auditoría (UPDATE, INSERT, DELETE en Pólizas)
CREATE TRIGGER trg_Audit_Polizas_UPDATE ON Polizas AFTER UPDATE AS BEGIN SET NOCOUNT ON; DECLARE @Detalles VARCHAR(MAX); SELECT @Detalles = 'Póliza ID: ' + CAST(i.poliza_id AS VARCHAR) + ' cambió estado de [' + d.estado_poliza + '] a [' + i.estado_poliza + '].' FROM inserted i JOIN deleted d ON i.poliza_id = d.poliza_id WHERE i.estado_poliza <> d.estado_poliza; IF @Detalles IS NOT NULL INSERT INTO Auditoria_General (tabla_afectada, accion, usuario, detalles_cambio) VALUES ('Polizas', 'UPDATE', SUSER_SNAME(), @Detalles); END;
GO
CREATE TRIGGER trg_Audit_Polizas_INSERT ON Polizas AFTER INSERT AS BEGIN SET NOCOUNT ON; DECLARE @Detalles VARCHAR(MAX); SELECT @Detalles = 'Nueva Póliza ID: ' + CAST(i.poliza_id AS VARCHAR) + ', Cliente: ' + CAST(i.cliente_id AS VARCHAR) + ', Tipo: ' + i.tipo_poliza + ', Estado: ' + i.estado_poliza FROM inserted i; INSERT INTO Auditoria_General (tabla_afectada, accion, usuario, detalles_cambio) VALUES ('Polizas', 'INSERT', SUSER_SNAME(), @Detalles); END;
GO
CREATE TRIGGER trg_Audit_Polizas_DELETE ON Polizas AFTER DELETE AS BEGIN SET NOCOUNT ON; DECLARE @Detalles VARCHAR(MAX); SELECT @Detalles = 'Póliza Borrada ID: ' + CAST(d.poliza_id AS VARCHAR) + ', Cliente: ' + CAST(d.cliente_id AS VARCHAR) FROM deleted d; INSERT INTO Auditoria_General (tabla_afectada, accion, usuario, detalles_cambio) VALUES ('Polizas', 'DELETE', SUSER_SNAME(), @Detalles); END;
GO




--Gestion siniestros

CREATE OR ALTER PROCEDURE sp_gestion_siniestro
    @p_siniestro_id INT,
    @p_nuevo_estado VARCHAR(20), -- Ej: 'Pagado', 'Rechazado', 'Aprobado'
    @p_comentarios VARCHAR(MAX),
    @p_usuario_web VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @v_poliza_id INT;
        SELECT @v_poliza_id = poliza_id FROM Siniestros WHERE siniestro_id = @p_siniestro_id;

        IF @v_poliza_id IS NULL BEGIN THROW 50001, 'Error: Siniestro no encontrado.', 1; END;
        UPDATE Siniestros 
        SET estado_siniestro = @p_nuevo_estado,
            descripcion = descripcion + ' | Actualización (' + CONVERT(VARCHAR, GETDATE(), 23) + '): ' + @p_comentarios
        WHERE siniestro_id = @p_siniestro_id;
        IF @p_nuevo_estado IN ('Pagado', 'Rechazado', 'Concluido')
        BEGIN
            UPDATE Polizas 
            SET estado_poliza = 'Activa' 
            WHERE poliza_id = @v_poliza_id;
        END

        -- 4. Auditoría
        INSERT INTO Auditoria_General (tabla_afectada, accion, usuario, detalles_cambio)
        VALUES ('Siniestros', 'UPDATE', @p_usuario_web, 'Siniestro ID ' + CAST(@p_siniestro_id AS VARCHAR) + ' cambiado a ' + @p_nuevo_estado);

        COMMIT TRANSACTION;
        SELECT CAST(1 AS BIT) AS resultado, 'Siniestro actualizado y póliza liberada.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT CAST(0 AS BIT), ERROR_MESSAGE();
    END CATCH
END;
GO




/*
=============================================================================
SCRIPT DE IMPLEMENTACIÓN: FRAGMENTACIÓN VERTICAL (CORREGIDO)
=============================================================================
Descripción: Divide la tabla monolítica 'Clientes' en dos fragmentos lógicos
             para separar datos generales de datos sensibles.
Autor:       David Mosco Gasca
=============================================================================
*/

USE CorporateInsuranceDB;
GO

PRINT '>>> INICIANDO FRAGMENTACIÓN VERTICAL DE CLIENTES...';

-- Iniciamos transacción para asegurar integridad
BEGIN TRANSACTION;

BEGIN TRY

    -- =========================================================
    -- 1. CREAR LAS NUEVAS TABLAS FRAGMENTADAS
    -- =========================================================
    
    -- A. Tabla General (Datos Públicos)
    IF OBJECT_ID('Clientes_General', 'U') IS NULL
    BEGIN
        CREATE TABLE Clientes_General (
            cliente_id INT PRIMARY KEY IDENTITY(1,1),
            nombre_completo VARCHAR(100) NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL,
            pais VARCHAR(50) NOT NULL,
            fecha_registro DATE DEFAULT GETDATE()
        );
        PRINT '1. Tabla Clientes_General creada.';
    END

    -- B. Tabla Sensible (Datos Privados)
    IF OBJECT_ID('Clientes_Sensible', 'U') IS NULL
    BEGIN
        CREATE TABLE Clientes_Sensible (
            cliente_id INT PRIMARY KEY, -- Relación 1:1
            telefono VARCHAR(20),
            direccion VARCHAR(150),
            tipo_documento VARCHAR(20),
            numero_documento VARCHAR(30) UNIQUE NOT NULL,
            FOREIGN KEY (cliente_id) REFERENCES Clientes_General(cliente_id)
        );
        PRINT '2. Tabla Clientes_Sensible creada.';
    END

    -- =========================================================
    -- 2. MIGRACIÓN DE DATOS
    -- =========================================================
    -- Solo migramos si la tabla original 'Clientes' existe y tiene datos
    IF OBJECT_ID('Clientes', 'U') IS NOT NULL
    BEGIN
        -- Migrar a General
        SET IDENTITY_INSERT Clientes_General ON;
        INSERT INTO Clientes_General (cliente_id, nombre_completo, email, pais, fecha_registro)
        SELECT cliente_id, nombre_completo, email, pais, fecha_registro 
        FROM Clientes
        WHERE cliente_id NOT IN (SELECT cliente_id FROM Clientes_General);
        SET IDENTITY_INSERT Clientes_General OFF;

        -- Migrar a Sensible
        INSERT INTO Clientes_Sensible (cliente_id, telefono, direccion, tipo_documento, numero_documento)
        SELECT cliente_id, telefono, direccion, tipo_documento, numero_documento 
        FROM Clientes
        WHERE cliente_id NOT IN (SELECT cliente_id FROM Clientes_Sensible);
        
        PRINT '3. Datos migrados exitosamente.';
    END

    -- =========================================================
    -- 3. ELIMINACIÓN SEGURA DE LA TABLA ANTIGUA
    -- =========================================================
    
    -- A. Eliminar FK en 'Polizas' que apunta a 'Clientes' (Dinámico)
    DECLARE @sql NVARCHAR(MAX) = '';
    
    SELECT @sql += 'ALTER TABLE Polizas DROP CONSTRAINT ' + name + ';'
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID('Polizas') 
      AND referenced_object_id = OBJECT_ID('Clientes');
    
    IF @sql <> ''
    BEGIN
        EXEC sp_executesql @sql;
        PRINT '4. Restricción FK antigua eliminada dinámicamente.';
    END

    -- B. Eliminar tabla antigua 'Clientes'
    IF OBJECT_ID('Clientes', 'U') IS NOT NULL
    BEGIN
        DROP TABLE Clientes;
        PRINT '5. Tabla antigua Clientes eliminada.';
    END

    -- C. Crear nueva FK en 'Polizas' apuntando a 'Clientes_General'
    -- Validamos que no exista ya para no duplicar error
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Polizas_Clientes_General')
    BEGIN
        ALTER TABLE Polizas WITH CHECK ADD CONSTRAINT FK_Polizas_Clientes_General 
        FOREIGN KEY(cliente_id) REFERENCES Clientes_General (cliente_id);
        PRINT '6. Nueva FK creada apuntando a Clientes_General.';
    END

    -- =========================================================
    -- 4. ACTUALIZACIÓN DE OBJETOS (SPs)
    -- =========================================================
    
    -- (Aquí van los ALTER PROCEDURE que ya tenías, ejecutados dentro de la transacción)
    -- Nota: SQL Server requiere que los CREATE/ALTER PROCEDURE sean el primer comando del batch.
    -- Por eso, en un script transaccional complejo, a veces es mejor usar EXEC sp_executesql
    -- o simplemente confirmar la transacción aquí y luego correr los SPs.
    
    COMMIT TRANSACTION;
    PRINT '>>> FRAGMENTACIÓN ESTRUCTURAL COMPLETADA EXITOSAMENTE <<<';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'Error Ocurrido: ' + ERROR_MESSAGE();
END CATCH;
GO

-- =========================================================
-- 5. REGENERACIÓN DE PROCEDIMIENTOS (Fuera de la transacción)
-- =========================================================

-- SP CREAR CLIENTE
CREATE OR ALTER PROCEDURE sp_crear_cliente
    @p_nombre_completo VARCHAR(100),
    @p_email VARCHAR(100),
    @p_telefono VARCHAR(20),
    @p_direccion VARCHAR(150),
    @p_pais VARCHAR(50),
    @p_tipo_documento VARCHAR(20),
    @p_numero_documento VARCHAR(30),
    @p_usuario_web VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF EXISTS (SELECT 1 FROM Clientes_General WHERE email = @p_email) THROW 50001, 'Email duplicado.', 1;
        IF EXISTS (SELECT 1 FROM Clientes_Sensible WHERE numero_documento = @p_numero_documento) THROW 50002, 'Documento duplicado.', 1;

        INSERT INTO Clientes_General (nombre_completo, email, pais)
        VALUES (@p_nombre_completo, @p_email, @p_pais);
        
        DECLARE @new_id INT = SCOPE_IDENTITY();

        INSERT INTO Clientes_Sensible (cliente_id, telefono, direccion, tipo_documento, numero_documento)
        VALUES (@new_id, @p_telefono, @p_direccion, @p_tipo_documento, @p_numero_documento);

        INSERT INTO Auditoria_General (tabla_afectada, accion, usuario, detalles_cambio)
        VALUES ('Clientes', 'INSERT', @p_usuario_web, 'Cliente fragmentado ID ' + CAST(@new_id AS VARCHAR));

        COMMIT TRANSACTION;
        SELECT CAST(1 AS BIT) AS resultado, 'Cliente registrado (Fragmentado).' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT CAST(0 AS BIT), ERROR_MESSAGE();
    END CATCH
END;
GO

-- SP LISTAR CLIENTES
CREATE OR ALTER PROCEDURE sp_reporte_listar_clientes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        G.cliente_id, 
        G.nombre_completo, 
        G.email, 
        S.telefono, 
        G.pais, 
        S.numero_documento, 
        G.fecha_registro 
    FROM Clientes_General G
    JOIN Clientes_Sensible S ON G.cliente_id = S.cliente_id
    ORDER BY G.cliente_id DESC;
END;
GO

-- SP REPORTE POLIZAS
CREATE OR ALTER PROCEDURE sp_reporte_listar_polizas 
    @p_cliente_id INT = NULL 
AS 
BEGIN 
    SET NOCOUNT ON; 
    SELECT 
        P.*, 
        G.nombre_completo AS nombre_cliente, 
        G.pais AS pais_cliente 
    FROM Polizas P 
    JOIN Clientes_General G ON P.cliente_id = G.cliente_id 
    WHERE (@p_cliente_id IS NULL OR P.cliente_id = @p_cliente_id) 
    ORDER BY P.poliza_id DESC; 
END;
GO

-- SP REPORTE AVANZADO
CREATE OR ALTER PROCEDURE sp_reporte_avanzado_corporativo
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 5
        G.pais AS Pais,
        SUM(P.prima_anual) AS Prima_Total,
        RANK() OVER (ORDER BY SUM(P.prima_anual) DESC) AS Ranking_Global,
        CASE 
            WHEN AVG(P.prima_anual) >= 5000.00 THEN 'Alto Riesgo Promedio'
            WHEN AVG(P.prima_anual) >= 1000.00 THEN 'Riesgo Moderado Promedio'
            ELSE 'Bajo Riesgo Promedio'
        END AS Clasificacion_Riesgo_Pais
    FROM Polizas P
    JOIN Clientes_General G ON P.cliente_id = G.cliente_id
    GROUP BY G.pais
    ORDER BY Ranking_Global;

    SELECT * FROM 
    (
        SELECT G.pais, DATENAME(month, S.fecha_reporte) AS Mes, S.siniestro_id 
        FROM Siniestros S 
        JOIN Polizas P ON S.poliza_id = P.poliza_id 
        JOIN Clientes_General G ON P.cliente_id = G.cliente_id
    ) AS Fuente
    PIVOT ( COUNT(siniestro_id) FOR Mes IN ([Enero], [Febrero], [Marzo], [Abril], [Mayo], [Junio], [Julio], [Agosto], [Septiembre], [Octubre], [Noviembre], [Diciembre]) ) AS PivotTable;
END;
GO

-- SP ALERTAS
CREATE OR ALTER PROCEDURE sp_consultar_alertas_vencimiento
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        P.poliza_id,
        G.nombre_completo AS nombre_cliente,
        P.tipo_poliza,
        CONVERT(VARCHAR(50), P.fecha_fin, 120) AS fecha_fin,
        P.estado_poliza,
        DATEDIFF(day, GETDATE(), P.fecha_fin) AS dias_restantes
    FROM Polizas P
    JOIN Clientes_General G ON P.cliente_id = G.cliente_id
    WHERE P.estado_poliza IN ('Activa', 'Suspendida')
    AND P.fecha_fin <= DATEADD(day, 30, GETDATE())
    ORDER BY dias_restantes ASC;
END;
GO

-- SP HISTORIAL SINIESTROS
CREATE OR ALTER PROCEDURE sp_consultar_historial_siniestros 
    @p_cliente_id INT = NULL, 
    @p_pais_cliente VARCHAR(50) = NULL, 
    @p_tipo_poliza VARCHAR(50) = NULL, 
    @p_poliza_id INT = NULL 
AS 
BEGIN 
    SET NOCOUNT ON; 
    SELECT 
        S.siniestro_id, S.fecha_reporte, S.tipo_siniestro, S.estado_siniestro, S.monto_estimado, 
        G.nombre_completo AS nombre_cliente, 
        P.tipo_poliza AS tipo_poliza_asociada, 
        G.pais AS pais_cliente 
    FROM Siniestros S 
    JOIN Polizas P ON S.poliza_id = P.poliza_id 
    JOIN Clientes_General G ON P.cliente_id = G.cliente_id 
    WHERE (@p_cliente_id IS NULL OR G.cliente_id = @p_cliente_id) 
    AND (@p_pais_cliente IS NULL OR G.pais LIKE @p_pais_cliente + '%') 
    AND (@p_tipo_poliza IS NULL OR P.tipo_poliza LIKE @p_tipo_poliza + '%') 
    AND (@p_poliza_id IS NULL OR P.poliza_id = @p_poliza_id) 
    ORDER BY S.fecha_reporte DESC; 
END;
GO

PRINT '>>> ACTUALIZACIÓN DE SPs COMPLETADA <<<';



USE CorporateInsuranceDB;
GO

PRINT '>>> APLICANDO CANDADOS DE SEGURIDAD FINANCIERA...';

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Protección en Pólizas (Prima Anual no puede ser negativa)
    IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Polizas_Prima_Positiva')
    BEGIN
        ALTER TABLE Polizas
        ADD CONSTRAINT CK_Polizas_Prima_Positiva CHECK (prima_anual >= 0);
        PRINT '1. Candado aplicado en Pólizas (Prima >= 0).';
    END

    -- 2. Protección en Siniestros (Monto Estimado no puede ser negativo)
    IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Siniestros_Monto_Positivo')
    BEGIN
        ALTER TABLE Siniestros
        ADD CONSTRAINT CK_Siniestros_Monto_Positivo CHECK (monto_estimado >= 0);
        PRINT '2. Candado aplicado en Siniestros (Monto >= 0).';
    END

    -- 3. Protección en Pagos (El pago debe ser estrictamente mayor a 0)
    IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE name = 'CK_Pagos_Monto_Positivo')
    BEGIN
        ALTER TABLE Pagos
        ADD CONSTRAINT CK_Pagos_Monto_Positivo CHECK (monto > 0);
        PRINT '3. Candado aplicado en Pagos (Monto > 0).';
    END

    COMMIT TRANSACTION;
    PRINT '>>> SISTEMA BLINDADO CONTRA MONTOS NEGATIVOS <<<';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'Error al aplicar seguridad: ' + ERROR_MESSAGE();
END CATCH;
GO




USE CorporateInsuranceDB;
GO

-- =========================================================
-- CORRECCIÓN: ACTUALIZAR SP_CREAR_POLIZA
-- Descripción: Apuntar a 'Clientes_General' en lugar de 'Clientes'
--              porque la tabla original ya no existe por la fragmentación.
-- =========================================================

CREATE OR ALTER PROCEDURE sp_crear_poliza
    @p_cliente_id INT,
    @p_tipo_poliza VARCHAR(50),
    @p_cobertura VARCHAR(100),
    @p_prima_anual DECIMAL(10,2),
    @p_fecha_inicio DATE,
    @p_fecha_fin DATE,
    @p_region_poliza VARCHAR(50),
    @p_usuario_web VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Validar que el cliente exista (CORREGIDO: Usar Clientes_General)
        IF NOT EXISTS (SELECT 1 FROM Clientes_General WHERE cliente_id = @p_cliente_id) 
        BEGIN 
            THROW 50001, 'Error: El Cliente ID proporcionado no existe.', 1; 
        END;

        -- 2. Insertar la Póliza
        -- Nota: La FK en la tabla Polizas ya apunta a Clientes_General, así que esto pasará sin problemas.
        INSERT INTO Polizas (cliente_id, tipo_poliza, cobertura, prima_anual, fecha_inicio, fecha_fin, estado_poliza, region)
        VALUES (@p_cliente_id, @p_tipo_poliza, @p_cobertura, @p_prima_anual, @p_fecha_inicio, @p_fecha_fin, 'Activa', @p_region_poliza);

        -- 3. Auditoría
        INSERT INTO Auditoria_General (tabla_afectada, accion, usuario, detalles_cambio)
        VALUES ('Polizas', 'INSERT', @p_usuario_web, 'Nueva Póliza para Cliente ID ' + CAST(@p_cliente_id AS VARCHAR));

        COMMIT TRANSACTION;
        SELECT CAST(1 AS BIT) AS resultado_operacion, 'Póliza registrada exitosamente.' AS mensaje_salida;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        -- Registrar fallo
        INSERT INTO Auditoria_Fallos_Transaccion (procedimiento_afectado, mensaje_error, datos_entrada, usuario)
        VALUES ('sp_crear_poliza', ERROR_MESSAGE(), 'ClienteID: ' + CONVERT(VARCHAR, @p_cliente_id), @p_usuario_web);
        
        SELECT CAST(0 AS BIT) AS resultado_operacion, 'FALLO: ' + ERROR_MESSAGE() AS mensaje_salida;
    END CATCH
END;
GO









USE CorporateInsuranceDB;
GO

-- 1. Crear Tabla de Configuración
IF OBJECT_ID('Configuracion_Sistema', 'U') IS NULL
BEGIN
    CREATE TABLE Configuracion_Sistema (
        clave VARCHAR(50) PRIMARY KEY,
        valor VARCHAR(100) NOT NULL,
        descripcion VARCHAR(200)
    );
    
    -- Insertar valor por defecto (90%)
    INSERT INTO Configuracion_Sistema (clave, valor, descripcion)
    VALUES ('PORCENTAJE_PAGO_REACTIVACION', '0.90', 'Porcentaje mínimo de la prima para reactivar póliza');
    
    PRINT 'Tabla de Configuración creada.';
END
GO

-- 2. Actualizar SP de Pagos para usar el valor dinámico
CREATE OR ALTER PROCEDURE sp_registrar_pago
    @p_poliza_id INT,
    @p_monto DECIMAL(10,2),
    @p_metodo_pago VARCHAR(30),
    @p_usuario_web VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @v_estado_poliza VARCHAR(30);
        DECLARE @v_prima DECIMAL(10,2);
        DECLARE @v_porcentaje_minimo DECIMAL(10,2);
        
        -- Obtener datos de la póliza
        SELECT @v_estado_poliza = estado_poliza, @v_prima = prima_anual 
        FROM Polizas WHERE poliza_id = @p_poliza_id;

        -- Obtener regla de negocio dinámica (Si no existe, usa 0.9 por defecto)
        SELECT @v_porcentaje_minimo = CAST(valor AS DECIMAL(10,2))
        FROM Configuracion_Sistema WHERE clave = 'PORCENTAJE_PAGO_REACTIVACION';
        
        IF @v_porcentaje_minimo IS NULL SET @v_porcentaje_minimo = 0.90;

        IF @v_estado_poliza IS NULL BEGIN THROW 50001, 'Error: Póliza no encontrada.', 1; END;
        IF @v_estado_poliza = 'Cancelada' BEGIN THROW 50003, 'Error: Póliza Cancelada. Pago rechazado.', 1; END;

        INSERT INTO Pagos (poliza_id, monto, metodo_pago, estado_pago)
        VALUES (@p_poliza_id, @p_monto, @p_metodo_pago, 'Confirmado');

        -- Lógica de renovación/reactivación DINÁMICA
        IF @p_monto >= (@v_prima * @v_porcentaje_minimo)
        BEGIN
            IF @v_estado_poliza = 'Vencida'
            BEGIN
                UPDATE Polizas SET estado_poliza = 'Activa', fecha_inicio = GETDATE(), fecha_fin = DATEADD(YEAR, 1, GETDATE()) WHERE poliza_id = @p_poliza_id;
            END
            ELSE IF @v_estado_poliza = 'Activa'
            BEGIN
                UPDATE Polizas SET fecha_fin = DATEADD(YEAR, 1, fecha_fin) WHERE poliza_id = @p_poliza_id;
            END
            ELSE IF @v_estado_poliza = 'Suspendida'
            BEGIN
                UPDATE Polizas SET estado_poliza = 'Activa' WHERE poliza_id = @p_poliza_id;
            END
        END

        COMMIT TRANSACTION;
        SELECT CAST(1 AS BIT) AS resultado, 'Pago registrado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        INSERT INTO Auditoria_Fallos_Transaccion (procedimiento_afectado, mensaje_error, datos_entrada, usuario)
        VALUES ('sp_registrar_pago', ERROR_MESSAGE(), 'PolizaID: ' + CONVERT(VARCHAR, @p_poliza_id), @p_usuario_web);
        SELECT CAST(0 AS BIT), 'FALLO: ' + ERROR_MESSAGE();
    END CATCH
END;
GO











USE CorporateInsuranceDB;
GO

-- 1. Tabla de Cola
CREATE TABLE Cola_Replicacion (
    cola_id INT IDENTITY(1,1) PRIMARY KEY,
    tabla_destino VARCHAR(50),
    datos_json VARCHAR(MAX), -- Guardamos los datos a replicar
    estado VARCHAR(20) DEFAULT 'PENDIENTE', -- PENDIENTE, PROCESADO, ERROR
    fecha_creacion DATETIME DEFAULT GETDATE()
);
GO

-- 2. Modificar Trigger para usar la Cola
CREATE OR ALTER TRIGGER trg_Replicacion_Fragmentacion
ON Polizas
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Nodo México
    INSERT INTO Cola_Replicacion (tabla_destino, datos_json)
    SELECT 'Polizas_Nodo_Mexico', 
           '{"id":' + CAST(i.poliza_id AS VARCHAR) + ', "cliente":' + CAST(i.cliente_id AS VARCHAR) + '}'
    FROM inserted i WHERE i.region = 'Mexico';

    -- Nodo Internacional
    INSERT INTO Cola_Replicacion (tabla_destino, datos_json)
    SELECT 'Polizas_Nodo_Internacional', 
           '{"id":' + CAST(i.poliza_id AS VARCHAR) + ', "cliente":' + CAST(i.cliente_id AS VARCHAR) + ', "region":"' + i.region + '"}'
    FROM inserted i WHERE i.region <> 'Mexico';
    
    -- Procesar MX
    INSERT INTO Polizas_Nodo_Mexico (poliza_id, cliente_id, tipo_poliza, prima_anual, estado_poliza)
    SELECT i.poliza_id, i.cliente_id, i.tipo_poliza, i.prima_anual, i.estado_poliza
    FROM inserted i WHERE i.region = 'Mexico';

    -- Procesar INT
    INSERT INTO Polizas_Nodo_Internacional (poliza_id, cliente_id, tipo_poliza, prima_anual, estado_poliza, pais_origen)
    SELECT i.poliza_id, i.cliente_id, i.tipo_poliza, i.prima_anual, i.estado_poliza, i.region
    FROM inserted i WHERE i.region <> 'Mexico';

    -- Actualizar Cola
    UPDATE Cola_Replicacion SET estado = 'PROCESADO' WHERE estado = 'PENDIENTE';

    -- Auditoría
    INSERT INTO Auditoria_General (tabla_afectada, accion, usuario, detalles_cambio)
    VALUES ('Polizas', 'REPLICACION_COLA', 'SystemTrigger', 'Datos encolados y procesados exitosamente.');
END;
GO





USE CorporateInsuranceDB;
GO

-- ============================================================
-- 1. CORRECCIÓN: LISTAR AGENTES (Alinear con Python)
-- ============================================================


CREATE OR ALTER PROCEDURE sp_admin_listar_agentes
AS 
BEGIN 
    SET NOCOUNT ON; 
    SELECT 
        agente_id, 
        nombre_completo, 
        region, 
        puesto, 
        usuario, 
        contrasena,      
        fecha_ingreso, 
        estado          
    FROM Agentes 
    ORDER BY agente_id; 
END;
GO

-- ============================================================
-- 2. CORRECCIÓN: LISTAR PÓLIZAS (Alinear con Python)
-- ============================================================

CREATE OR ALTER PROCEDURE sp_reporte_listar_polizas 
    @p_cliente_id INT = NULL 
AS 
BEGIN 
    SET NOCOUNT ON; 
    SELECT 
        P.*, -- Esto trae las 9 columnas de la tabla Polizas en orden
        C.nombre_completo AS nombre_cliente, 
        C.pais AS pais_cliente 
    FROM Polizas P 
    JOIN Clientes_General C ON P.cliente_id = C.cliente_id -- Usamos Clientes_General por la fragmentación
    WHERE (@p_cliente_id IS NULL OR P.cliente_id = @p_cliente_id) 
    ORDER BY P.poliza_id DESC; 
END;
GO








USE CorporateInsuranceDB;
GO

-- Procedimiento para el reporte de desempeño de agentes
CREATE OR ALTER PROCEDURE sp_reporte_desempeno_agentes
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 10
        A.agente_id,
        A.nombre_completo,
        A.region,
        COUNT(S.siniestro_id) AS Siniestros_Atendidos,
        CASE 
            WHEN COUNT(S.siniestro_id) >= 5 THEN 'Estrella'
            WHEN COUNT(S.siniestro_id) BETWEEN 1 AND 4 THEN 'Regular'
            ELSE 'Sin Actividad'
        END AS Nivel_Productividad
    FROM Agentes A
    LEFT JOIN Siniestros S ON A.agente_id = S.agente_id
    WHERE A.estado = 'Activo'
    GROUP BY A.agente_id, A.nombre_completo, A.region
    ORDER BY Siniestros_Atendidos DESC;
END;
GO






USE CorporateInsuranceDB;
GO

CREATE OR ALTER PROCEDURE sp_reporte_avanzado_corporativo
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Ranking de Países (Sin cambios)
    SELECT TOP 5
        G.pais AS Pais,
        SUM(P.prima_anual) AS Prima_Total,
        RANK() OVER (ORDER BY SUM(P.prima_anual) DESC) AS Ranking_Global,
        CASE 
            WHEN AVG(P.prima_anual) >= 5000.00 THEN 'Alto Riesgo Promedio'
            WHEN AVG(P.prima_anual) >= 1000.00 THEN 'Riesgo Moderado Promedio'
            ELSE 'Bajo Riesgo Promedio'
        END AS Clasificacion_Riesgo_Pais
    FROM Polizas P
    JOIN Clientes_General G ON P.cliente_id = G.cliente_id
    GROUP BY G.pais
    ORDER BY Ranking_Global;

    -- 2. PIVOT BLINDADO (Forzamos nombres en Español usando CASE)
    SELECT * FROM 
    (
        SELECT 
            G.pais, 
            -- AQUÍ ESTÁ EL CAMBIO MÁGICO:
            CASE MONTH(S.fecha_reporte)
                WHEN 1 THEN 'Enero'
                WHEN 2 THEN 'Febrero'
                WHEN 3 THEN 'Marzo'
                WHEN 4 THEN 'Abril'
                WHEN 5 THEN 'Mayo'
                WHEN 6 THEN 'Junio'
                WHEN 7 THEN 'Julio'
                WHEN 8 THEN 'Agosto'
                WHEN 9 THEN 'Septiembre'
                WHEN 10 THEN 'Octubre'
                WHEN 11 THEN 'Noviembre'
                WHEN 12 THEN 'Diciembre'
            END AS Mes, 
            S.siniestro_id 
        FROM Siniestros S 
        JOIN Polizas P ON S.poliza_id = P.poliza_id 
        JOIN Clientes_General G ON P.cliente_id = G.cliente_id
    ) AS Fuente
    PIVOT (
        COUNT(siniestro_id) 
        FOR Mes IN ([Enero], [Febrero], [Marzo], [Abril], [Mayo], [Junio], [Julio], [Agosto], [Septiembre], [Octubre], [Noviembre], [Diciembre])
    ) AS PivotTable;
END;
GO


select * from Clientes_General
-- ==========================================================
-- SCRIPT DE INICIALIZACIÓN: ITI-BB ASSET SCANNER v2.2.3.1
-- OBJETIVO: Replicar la estructura de Supabase en MySQL Local
-- ==========================================================

-- 1. Crear y seleccionar la base de datos
CREATE DATABASE IF NOT EXISTS itibb_db;
USE itibb_db;

-- 2. Eliminar tabla previa si existe para evitar conflictos de estructura
DROP TABLE IF EXISTS inventario_registros;

-- 3. Crear tabla con soporte para multimedia y georreferenciación
CREATE TABLE inventario_registros (
    id VARCHAR(50) NOT NULL, -- ID del QR (ITIBB-INF-IND-XXXX)
    id_institucional VARCHAR(50) DEFAULT 'N/A',
    nombre_equipo VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) DEFAULT 'Informática',
    marca_modelo VARCHAR(100),
    nro_serie VARCHAR(100),
    origen VARCHAR(50),
    estado VARCHAR(50),
    estado_documentacion VARCHAR(50),
    laboratorio VARCHAR(100),
    registrante VARCHAR(100),
    fecha_censo DATETIME, -- Fecha capturada del censo original
    observaciones TEXT,
    foto_url TEXT, -- URL de la evidencia en Supabase
    gps_lat DOUBLE, -- Precisión decimal para mapas
    gps_long DOUBLE, -- Precisión decimal para mapas
    fecha_sincronizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Registro local
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
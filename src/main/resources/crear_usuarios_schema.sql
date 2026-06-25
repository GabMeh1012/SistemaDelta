-- ============================================================
-- Script: crear_usuarios_schema.sql
-- Descripción: Normalización de facultades/carreras y columnas
--              adicionales para estudiantes y profesores.
-- Ejecutar UNA sola vez sobre la BD sistema_delta.
-- ============================================================

-- 1. Tabla facultades
CREATE TABLE IF NOT EXISTS facultades (
  id     INT(11)      NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(150) NOT NULL,
  codigo VARCHAR(20)  NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_facultad_codigo (codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

INSERT IGNORE INTO facultades (id, nombre, codigo)
VALUES (1, 'Facultad de Sistemas Computacionales', 'FSC');

-- 2. Tabla carreras
CREATE TABLE IF NOT EXISTS carreras (
  id          INT(11)      NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(150) NOT NULL,
  codigo      VARCHAR(20)  NOT NULL,
  facultad_id INT(11)      NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_carrera_codigo (codigo),
  FOREIGN KEY (facultad_id) REFERENCES facultades(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

INSERT IGNORE INTO carreras (id, nombre, codigo, facultad_id)
VALUES (1, 'Ingeniería en Sistemas Computacionales', 'ISC', 1);

-- 3. Agregar columnas a estudiantes
ALTER TABLE estudiantes
  ADD COLUMN IF NOT EXISTS carrera_id          INT(11)                     DEFAULT NULL     AFTER carrera,
  ADD COLUMN IF NOT EXISTS facultad_id         INT(11)                     DEFAULT NULL     AFTER carrera_id,
  ADD COLUMN IF NOT EXISTS nacionalidad        VARCHAR(50)                 DEFAULT 'panameño' AFTER facultad_id,
  ADD COLUMN IF NOT EXISTS tipo_identificacion ENUM('cedula','extranjero') DEFAULT 'cedula' AFTER nacionalidad;

-- FKs (protegidas contra duplicados via procedimiento dinámico)
SET @fk1 = (SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'estudiantes'
               AND CONSTRAINT_NAME = 'fk_est_carrera');
SET @sql1 = IF(@fk1 = 0,
  'ALTER TABLE estudiantes ADD CONSTRAINT fk_est_carrera  FOREIGN KEY (carrera_id)  REFERENCES carreras(id)   ON DELETE SET NULL',
  'SELECT 1');
PREPARE s1 FROM @sql1; EXECUTE s1; DEALLOCATE PREPARE s1;

SET @fk2 = (SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'estudiantes'
               AND CONSTRAINT_NAME = 'fk_est_facultad');
SET @sql2 = IF(@fk2 = 0,
  'ALTER TABLE estudiantes ADD CONSTRAINT fk_est_facultad FOREIGN KEY (facultad_id) REFERENCES facultades(id) ON DELETE SET NULL',
  'SELECT 1');
PREPARE s2 FROM @sql2; EXECUTE s2; DEALLOCATE PREPARE s2;

-- Vincular estudiantes existentes a ISC / FSC
UPDATE estudiantes SET carrera_id = 1, facultad_id = 1 WHERE carrera_id IS NULL;

-- 4. Agregar columnas a profesores
ALTER TABLE profesores
  ADD COLUMN IF NOT EXISTS facultad_id         INT(11)                     DEFAULT NULL     AFTER departamento,
  ADD COLUMN IF NOT EXISTS nacionalidad        VARCHAR(50)                 DEFAULT 'panameño' AFTER facultad_id,
  ADD COLUMN IF NOT EXISTS tipo_identificacion ENUM('cedula','extranjero') DEFAULT 'cedula' AFTER nacionalidad;

SET @fk3 = (SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'profesores'
               AND CONSTRAINT_NAME = 'fk_prof_facultad');
SET @sql3 = IF(@fk3 = 0,
  'ALTER TABLE profesores ADD CONSTRAINT fk_prof_facultad FOREIGN KEY (facultad_id) REFERENCES facultades(id) ON DELETE SET NULL',
  'SELECT 1');
PREPARE s3 FROM @sql3; EXECUTE s3; DEALLOCATE PREPARE s3;

UPDATE profesores SET facultad_id = 1 WHERE facultad_id IS NULL;

-- 5. Tabla de asignación directa de materias a profesores (N:N)
CREATE TABLE IF NOT EXISTS profesor_materias (
  id          INT(11) NOT NULL AUTO_INCREMENT,
  profesor_id INT(11) NOT NULL,
  materia_id  INT(11) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_prof_mat (profesor_id, materia_id),
  FOREIGN KEY (profesor_id) REFERENCES profesores(id) ON DELETE CASCADE,
  FOREIGN KEY (materia_id)  REFERENCES materias(id)   ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

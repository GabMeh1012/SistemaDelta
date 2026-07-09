-- Ejecutar en MySQL (sistema_delta) para el plan de Carreras, Salones y Horarios
-- Ver docs/plan_carreras_salones_horarios.md para el detalle completo.

USE sistema_delta;

-- 1) Catalogo de periodos academicos (formaliza grupos.semestre, hoy texto libre)
CREATE TABLE IF NOT EXISTS periodos (
  codigo       VARCHAR(20) PRIMARY KEY,
  nombre       VARCHAR(50) NULL,
  fecha_inicio DATE NULL,
  fecha_fin    DATE NULL,
  activo       TINYINT(1) NOT NULL DEFAULT 0
);

INSERT INTO periodos (codigo, nombre, activo)
SELECT '2026-I', 'I Semestre 2026', 1
WHERE NOT EXISTS (SELECT 1 FROM periodos WHERE codigo = '2026-I');

-- 2) materias: vinculo a carrera y nivel del plan de estudios
ALTER TABLE materias ADD COLUMN IF NOT EXISTS carrera_id INT NULL;
ALTER TABLE materias ADD COLUMN IF NOT EXISTS nivel INT NULL;

-- 3) grupos: permitir salon vacante (sin profesor) y atar semestre al catalogo de periodos
ALTER TABLE grupos MODIFY profesor_id INT NULL;

-- FKs (solo si no existen ya; MySQL no soporta "ADD CONSTRAINT IF NOT EXISTS" directamente,
-- por eso se listan aparte para poder omitirlas manualmente si ya corrieron antes)
ALTER TABLE materias ADD CONSTRAINT fk_materias_carrera FOREIGN KEY (carrera_id) REFERENCES carreras(id);
ALTER TABLE grupos   ADD CONSTRAINT fk_grupos_periodo   FOREIGN KEY (semestre)   REFERENCES periodos(codigo);

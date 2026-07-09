USE sistema_delta;

-- Siembra profesor_materias para los profesores que ya dictan las 6 materias
-- de la carrera "Ingeniería de Software", para que el filtro nuevo del selector
-- de profesor no los excluya.
INSERT IGNORE INTO profesor_materias (profesor_id, materia_id)
SELECT g.profesor_id, g.materia_id
FROM grupos g
JOIN materias m ON m.id = g.materia_id
WHERE m.codigo IN ('BD-301','IS-401','RC-402','WD-201','IA-401','SO-301')
  AND g.profesor_id IS NOT NULL;

SELECT pm.profesor_id, CONCAT(p.nombre,' ',p.apellido) AS profesor, m.codigo, m.nombre
FROM profesor_materias pm
JOIN profesores p ON p.id = pm.profesor_id
JOIN materias m ON m.id = pm.materia_id
ORDER BY pm.profesor_id;

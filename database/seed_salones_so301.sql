USE sistema_delta;

-- Salon 2 de SO-301: profesor Ana Rodriguez (6), Aula 7A
INSERT INTO grupos (codigo_grupo, materia_id, profesor_id, semestre, aula, capacidad)
SELECT 'GRP-SO-301-B', (SELECT id FROM materias WHERE codigo='SO-301'), 6, '2026-I', 'Aula 7A', 30
WHERE NOT EXISTS (SELECT 1 FROM grupos WHERE codigo_grupo='GRP-SO-301-B');

-- Salon 3 de SO-301: profesor Luis Torres (9), Aula 7B
INSERT INTO grupos (codigo_grupo, materia_id, profesor_id, semestre, aula, capacidad)
SELECT 'GRP-SO-301-C', (SELECT id FROM materias WHERE codigo='SO-301'), 9, '2026-I', 'Aula 7B', 30
WHERE NOT EXISTS (SELECT 1 FROM grupos WHERE codigo_grupo='GRP-SO-301-C');

-- Clonar el horario del salon 1 (4 bloques: lunes/martes/miercoles/jueves 7:00-9:00) a los 2 nuevos
INSERT INTO horarios (grupo_id, dia_semana, hora_inicio, hora_fin)
SELECT g2.id, h.dia_semana, h.hora_inicio, h.hora_fin
FROM horarios h
JOIN grupos g1 ON g1.id = h.grupo_id AND g1.codigo_grupo = 'GRP-SO-301'
JOIN grupos g2 ON g2.codigo_grupo = 'GRP-SO-301-B'
WHERE NOT EXISTS (
  SELECT 1 FROM horarios h2 WHERE h2.grupo_id = g2.id AND h2.dia_semana = h.dia_semana
);

INSERT INTO horarios (grupo_id, dia_semana, hora_inicio, hora_fin)
SELECT g2.id, h.dia_semana, h.hora_inicio, h.hora_fin
FROM horarios h
JOIN grupos g1 ON g1.id = h.grupo_id AND g1.codigo_grupo = 'GRP-SO-301'
JOIN grupos g2 ON g2.codigo_grupo = 'GRP-SO-301-C'
WHERE NOT EXISTS (
  SELECT 1 FROM horarios h2 WHERE h2.grupo_id = g2.id AND h2.dia_semana = h.dia_semana
);

-- Sembrar profesor_materias para los 2 profesores nuevos
INSERT IGNORE INTO profesor_materias (profesor_id, materia_id)
VALUES (6, (SELECT id FROM materias WHERE codigo='SO-301')),
       (9, (SELECT id FROM materias WHERE codigo='SO-301'));

SELECT g.id, g.codigo_grupo, g.aula, g.profesor_id, CONCAT(p.nombre,' ',p.apellido) profesor
FROM grupos g LEFT JOIN profesores p ON p.id=g.profesor_id
WHERE g.materia_id = (SELECT id FROM materias WHERE codigo='SO-301');

SELECT g.codigo_grupo, h.dia_semana, h.hora_inicio, h.hora_fin
FROM horarios h JOIN grupos g ON g.id=h.grupo_id
WHERE g.materia_id = (SELECT id FROM materias WHERE codigo='SO-301')
ORDER BY g.codigo_grupo, h.dia_semana;

USE sistema_delta;

INSERT INTO carreras (nombre, codigo, facultad_id)
SELECT 'Ingeniería de Software', 'IDS', (SELECT id FROM facultades WHERE codigo='FSC')
WHERE NOT EXISTS (SELECT 1 FROM carreras WHERE codigo='IDS');

SET @ids := (SELECT id FROM carreras WHERE codigo='IDS');

UPDATE materias SET carrera_id=@ids, nivel=5 WHERE codigo IN ('BD-301','IS-401','RC-402','WD-201','IA-401','SO-301');

UPDATE estudiantes SET carrera_id=@ids, carrera='Ingeniería de Software';

SELECT * FROM carreras;
SELECT codigo, nombre, carrera_id, nivel FROM materias ORDER BY codigo;

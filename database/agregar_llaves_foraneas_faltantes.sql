-- Agrega las llaves foraneas que faltaban en 9 tablas (BUG-002), siguiendo el
-- mismo patron ON DELETE que ya usan las 20 FK existentes en este esquema:
--   CASCADE   -> la fila hija no tiene sentido sin el padre (horarios, notas,
--                asistencia, notas_historial, notas_autorizaciones.inscripcion_id,
--                notificaciones)
--   SET NULL  -> el padre es una referencia opcional/categoria (avisos.profesor_id
--                y avisos.grupo_id ya son nullable; solicitudes_matricula.inscripcion_id
--                idem)
--   RESTRICT  -> registro de auditoria/consecuencia: protege la fila referenciada
--                de borrarse mientras exista historia asociada (mismo patron que
--                historial_asignacion_profesores.admin_usuario_id y
--                materias_bloqueadas), aplicado a notas_autorizaciones.admin_usuario_id,
--                mensajes (ambos lados) y solicitudes_matricula (estudiante_id,
--                grupo_id, admin_usuario_id)
--
-- Verificado antes de escribir esto: el codigo de la aplicacion nunca borra
-- grupos, inscripciones, usuarios, estudiantes ni profesores (los unicos 3
-- DELETE que existen en todo el backend borran filas hijas directamente), asi
-- que estas reglas no cambian ningun comportamiento actual — son una red de
-- seguridad para limpiezas manuales futuras.

START TRANSACTION;

-- Limpieza previa: 11 solicitudes de retiro aprobadas ANTES de la correccion
-- de BUG-004 (cuando el retiro todavia borraba la inscripcion en vez de solo
-- cambiar su estado) quedaron con inscripcion_id apuntando a filas que ya no
-- existen. Se ponen en NULL -- la solicitud en si sigue siendo un registro
-- valido, solo se pierde la referencia a una inscripcion que el propio bug
-- ya elimino hace tiempo.
UPDATE solicitudes_matricula
SET inscripcion_id = NULL
WHERE inscripcion_id IS NOT NULL AND inscripcion_id NOT IN (SELECT id FROM inscripciones);

-- horarios
ALTER TABLE horarios
  ADD CONSTRAINT fk_horarios_grupo FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE CASCADE;

-- notas
ALTER TABLE notas
  ADD CONSTRAINT fk_notas_inscripcion FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id) ON DELETE CASCADE;

-- asistencia
ALTER TABLE asistencia
  ADD CONSTRAINT fk_asistencia_inscripcion FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id) ON DELETE CASCADE;

-- notas_historial
ALTER TABLE notas_historial
  ADD CONSTRAINT fk_notas_hist_inscripcion FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id) ON DELETE CASCADE;

-- notas_autorizaciones
ALTER TABLE notas_autorizaciones
  ADD CONSTRAINT fk_notas_auth_inscripcion FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id) ON DELETE CASCADE,
  ADD CONSTRAINT fk_notas_auth_admin FOREIGN KEY (admin_usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT;

-- notificaciones
ALTER TABLE notificaciones
  ADD CONSTRAINT fk_notif_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

-- avisos
ALTER TABLE avisos
  ADD CONSTRAINT fk_avisos_profesor FOREIGN KEY (profesor_id) REFERENCES profesores(id) ON DELETE SET NULL,
  ADD CONSTRAINT fk_avisos_grupo FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE SET NULL;

-- mensajes
ALTER TABLE mensajes
  ADD CONSTRAINT fk_mensajes_remitente FOREIGN KEY (remitente_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
  ADD CONSTRAINT fk_mensajes_destinatario FOREIGN KEY (destinatario_id) REFERENCES usuarios(id) ON DELETE RESTRICT;

-- solicitudes_matricula
ALTER TABLE solicitudes_matricula
  ADD CONSTRAINT fk_solmat_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id) ON DELETE RESTRICT,
  ADD CONSTRAINT fk_solmat_grupo FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE RESTRICT,
  ADD CONSTRAINT fk_solmat_admin FOREIGN KEY (admin_usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
  ADD CONSTRAINT fk_solmat_inscripcion FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id) ON DELETE SET NULL;

COMMIT;

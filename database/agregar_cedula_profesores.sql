-- Agrega la columna cedula a profesores, que faltaba desde el inicio del
-- esquema. Sin ella, CrearUsuarioDAO.crearProfesor() validaba duplicados
-- comparando contra `codigo` (el identificador PROF-XXX autogenerado) en vez
-- de la cedula real, asi que la validacion nunca detectaba nada -- y la
-- cedula capturada en el formulario de "Crear Profesor" se perdia despues de
-- mostrarse una sola vez en las credenciales.
--
-- Es nullable (a diferencia de estudiantes.cedula) porque los profesores ya
-- existentes no tienen este dato guardado en ningun lado y no se puede
-- recuperar retroactivamente.
ALTER TABLE profesores
  ADD COLUMN cedula VARCHAR(20) NULL UNIQUE AFTER codigo;

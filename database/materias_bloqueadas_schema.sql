-- Ejecutar en MySQL (sistema_delta) antes de usar el bloqueo permanente de re-inscripcion

USE sistema_delta;

-- Registra, por (estudiante, grupo), que la materia fue retirada y no puede
-- volver a inscribirse mientras exista esta fila. Se llena al aprobar un retiro
-- (MatriculaHelper.ejecutarRetiro) y se borra al desbloquear (admin) o al
-- reiniciar oportunidades (SolicitudMatriculaDAO.reiniciarOportunidades).
CREATE TABLE IF NOT EXISTS materias_bloqueadas (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  estudiante_id    INT NOT NULL,
  grupo_id         INT NOT NULL,
  fecha_retiro     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  admin_usuario_id INT NULL,
  CONSTRAINT uq_materia_bloqueada UNIQUE (estudiante_id, grupo_id),
  CONSTRAINT fk_mb_est   FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id),
  CONSTRAINT fk_mb_grupo FOREIGN KEY (grupo_id)       REFERENCES grupos(id)
);

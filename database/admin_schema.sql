-- Ejecutar en MySQL (sistema_delta) antes de usar el portal administrador

USE sistema_delta;

CREATE TABLE IF NOT EXISTS solicitudes_matricula (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  estudiante_id    INT NOT NULL,
  grupo_id         INT NOT NULL,
  tipo             ENUM('inscripcion','retiro') NOT NULL,
  estado           ENUM('pendiente','aprobada','rechazada') NOT NULL DEFAULT 'pendiente',
  inscripcion_id   INT NULL,
  motivo           VARCHAR(500) NULL,
  admin_usuario_id INT NULL,
  fecha_solicitud  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_resolucion DATETIME NULL,
  CONSTRAINT fk_sol_est   FOREIGN KEY (estudiante_id)  REFERENCES estudiantes(id),
  CONSTRAINT fk_sol_grupo FOREIGN KEY (grupo_id)       REFERENCES grupos(id),
  CONSTRAINT fk_sol_insc  FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id) ON DELETE SET NULL
);

-- Avisos activos/inactivos (ignorar si la columna ya existe)
ALTER TABLE avisos ADD COLUMN IF NOT EXISTS activo TINYINT(1) NOT NULL DEFAULT 1;

-- Usuario administrador demo (clave: 1234, hash SHA-256 igual que UsuarioDAO.java)
INSERT INTO usuarios (username, password, rol, activo)
SELECT 'admin', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f', 'admin', 1
WHERE NOT EXISTS (SELECT 1 FROM usuarios WHERE username = 'admin');

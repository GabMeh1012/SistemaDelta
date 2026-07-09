package com.delta.util;

import java.sql.*;

/**
 * Lógica compartida de inscripción/retiro efectiva (tras aprobación administrativa).
 */
public final class MatriculaHelper {

    private MatriculaHelper() {}

    public static int ejecutarInscripcion(Connection con, int estudianteId, String codigoMateria) throws SQLException {
        int activas = contarInscripcionesActivas(con, estudianteId);
        if (activas >= 6) {
            throw new SQLException("Ha alcanzado el limite de 6 materias permitidas.");
        }

        int grupoId = -1;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT g.id FROM grupos g JOIN materias m ON m.id = g.materia_id WHERE m.codigo = ? LIMIT 1")) {
            ps.setString(1, codigoMateria);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) grupoId = rs.getInt(1);
            }
        }
        if (grupoId == -1) throw new SQLException("materia/grupo no encontrado");

        try (PreparedStatement ps = con.prepareStatement(
                "SELECT id FROM materias_bloqueadas WHERE estudiante_id = ? AND grupo_id = ?")) {
            ps.setInt(1, estudianteId);
            ps.setInt(2, grupoId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) throw new SQLException(
                    "Esta materia fue retirada previamente y no puede volver a inscribirse. "
                  + "Debe ser desbloqueada por un administrador.");
            }
        }

        try (PreparedStatement ps = con.prepareStatement(
                "SELECT id FROM inscripciones WHERE estudiante_id = ? AND grupo_id = ? AND estado = 'activo'")) {
            ps.setInt(1, estudianteId);
            ps.setInt(2, grupoId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) throw new SQLException("ya inscrito");
            }
        }

        // Si el estudiante ya tuvo una inscripcion retirada en este mismo grupo
        // (que ahora se conserva como registro en vez de borrarse), se reactiva
        // esa misma fila en vez de insertar una nueva: la restriccion unica de
        // (estudiante_id, grupo_id) no permite dos filas para el mismo par, y
        // ademas mantiene el historial de notas/asistencia como una sola linea
        // continua (inscrito -> retirado -> vuelto a inscribir).
        Integer inscripcionRetiradaId = null;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT id FROM inscripciones WHERE estudiante_id = ? AND grupo_id = ? AND estado = 'retirado'")) {
            ps.setInt(1, estudianteId);
            ps.setInt(2, grupoId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) inscripcionRetiradaId = rs.getInt(1);
            }
        }
        if (inscripcionRetiradaId != null) {
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE inscripciones SET estado = 'activo' WHERE id = ?")) {
                ps.setInt(1, inscripcionRetiradaId);
                ps.executeUpdate();
            }
            return inscripcionRetiradaId;
        }

        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO inscripciones (estudiante_id, grupo_id, estado) VALUES (?,?,'activo')",
                Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, estudianteId);
            ps.setInt(2, grupoId);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return -1;
    }

    public static void ejecutarRetiro(Connection con, int estudianteId, String codigoMateria, int adminUsuarioId) throws SQLException {
        Integer inscripcionId = null;
        Integer grupoId = null;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT i.id, i.grupo_id FROM inscripciones i "
              + "JOIN grupos g ON g.id = i.grupo_id "
              + "JOIN materias m ON m.id = g.materia_id "
              + "WHERE i.estudiante_id = ? AND m.codigo = ? AND i.estado = 'activo'")) {
            ps.setInt(1, estudianteId);
            ps.setString(2, codigoMateria);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    inscripcionId = rs.getInt(1);
                    grupoId = rs.getInt(2);
                }
            }
        }
        if (inscripcionId == null) throw new SQLException("inscripcion no encontrada");

        // Se conserva la inscripcion (y sus notas/asistencia) como registro en
        // vez de borrarla: solo cambia su estado a 'retirado'. Todo lo que lee
        // inscripciones para reportes, cupos, riesgo academico, etc. ya filtra
        // por estado='activo', asi que un retiro sigue dejando de contar en
        // esos lugares exactamente igual que antes.
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE inscripciones SET estado = 'retirado' WHERE id = ?")) {
            ps.setInt(1, inscripcionId);
            ps.executeUpdate();
        }

        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO materias_bloqueadas (estudiante_id, grupo_id, admin_usuario_id) VALUES (?,?,?) "
              + "ON DUPLICATE KEY UPDATE fecha_retiro = NOW(), admin_usuario_id = VALUES(admin_usuario_id)")) {
            ps.setInt(1, estudianteId);
            ps.setInt(2, grupoId);
            ps.setInt(3, adminUsuarioId);
            ps.executeUpdate();
        }
    }

    public static int obtenerEstudianteId(Connection con, int usuarioId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("SELECT id FROM estudiantes WHERE usuario_id = ?")) {
            ps.setInt(1, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return -1;
    }

    public static int contarInscripcionesActivas(Connection con, int estudianteId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM inscripciones WHERE estudiante_id = ? AND estado = 'activo'")) {
            ps.setInt(1, estudianteId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }
}

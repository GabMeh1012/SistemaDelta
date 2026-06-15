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
                "SELECT id FROM inscripciones WHERE estudiante_id = ? AND grupo_id = ? AND estado = 'activo'")) {
            ps.setInt(1, estudianteId);
            ps.setInt(2, grupoId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) throw new SQLException("ya inscrito");
            }
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

    public static void ejecutarRetiro(Connection con, int estudianteId, String codigoMateria) throws SQLException {
        Integer inscripcionId = null;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT i.id FROM inscripciones i "
              + "JOIN grupos g ON g.id = i.grupo_id "
              + "JOIN materias m ON m.id = g.materia_id "
              + "WHERE i.estudiante_id = ? AND m.codigo = ? AND i.estado = 'activo'")) {
            ps.setInt(1, estudianteId);
            ps.setString(2, codigoMateria);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) inscripcionId = rs.getInt(1);
            }
        }
        if (inscripcionId == null) throw new SQLException("inscripcion no encontrada");

        try (PreparedStatement ps = con.prepareStatement("DELETE FROM notas WHERE inscripcion_id = ?")) {
            ps.setInt(1, inscripcionId);
            ps.executeUpdate();
        }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM asistencia WHERE inscripcion_id = ?")) {
            ps.setInt(1, inscripcionId);
            ps.executeUpdate();
        }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM inscripciones WHERE id = ?")) {
            ps.setInt(1, inscripcionId);
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

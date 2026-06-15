package com.delta.dao;

import com.delta.modelo.Asistencia;
import com.delta.util.ConexionDB;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Acceso a datos para el control de asistencia.
 */
public class AsistenciaDAO {

    /** Estudiante con inscripción activa en un grupo (para la lista de asistencia). */
    public static class EstudianteInscrito {
        public int inscripcionId;
        public String nombre;
        public String cedula;
    }

    /**
     * Lista los estudiantes con inscripción activa en un grupo, ordenados por nombre.
     */
    public List<EstudianteInscrito> listarEstudiantesPorGrupo(int grupoId) throws SQLException {
        List<EstudianteInscrito> lista = new ArrayList<>();
        String sql = "SELECT i.id AS inscripcion_id, CONCAT(e.nombre,' ',e.apellido) AS nombre, e.cedula "
                   + "FROM inscripciones i JOIN estudiantes e ON e.id = i.estudiante_id "
                   + "WHERE i.grupo_id = ? AND i.estado = 'activo' "
                   + "ORDER BY e.nombre, e.apellido";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, grupoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    EstudianteInscrito ei = new EstudianteInscrito();
                    ei.inscripcionId = rs.getInt("inscripcion_id");
                    ei.nombre = rs.getString("nombre");
                    ei.cedula = rs.getString("cedula");
                    lista.add(ei);
                }
            }
        }
        return lista;
    }

    /**
     * Devuelve un mapa {"inscripcionId-fecha": Asistencia} con los registros existentes
     * para un grupo dentro de un rango de fechas (inclusive).
     */
    public Map<String, Asistencia> listarAsistenciaSemana(int grupoId, LocalDate desde, LocalDate hasta) throws SQLException {
        Map<String, Asistencia> mapa = new HashMap<>();
        String sql = "SELECT a.id, a.inscripcion_id, a.fecha, a.estado, a.observacion "
                   + "FROM asistencia a "
                   + "JOIN inscripciones i ON i.id = a.inscripcion_id "
                   + "WHERE i.grupo_id = ? AND a.fecha BETWEEN ? AND ?";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, grupoId);
            ps.setDate(2, Date.valueOf(desde));
            ps.setDate(3, Date.valueOf(hasta));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Asistencia a = new Asistencia();
                    a.setId(rs.getInt("id"));
                    a.setInscripcionId(rs.getInt("inscripcion_id"));
                    a.setFecha(rs.getDate("fecha").toLocalDate());
                    a.setEstado(rs.getString("estado"));
                    a.setObservacion(rs.getString("observacion"));
                    mapa.put(a.getInscripcionId() + "-" + a.getFecha(), a);
                }
            }
        }
        return mapa;
    }

    /**
     * Crea o actualiza el registro de asistencia de un estudiante en una fecha
     * (upsert basado en la clave única inscripcion_id+fecha).
     */
    public void guardar(int inscripcionId, LocalDate fecha, String estado, String observacion) throws SQLException {
        String estadoFinal = mapEstado(estado);
        String sql = "INSERT INTO asistencia (inscripcion_id, fecha, estado, observacion) VALUES (?,?,?,?) "
                   + "ON DUPLICATE KEY UPDATE estado = VALUES(estado), observacion = VALUES(observacion)";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, inscripcionId);
            ps.setDate(2, Date.valueOf(fecha));
            ps.setString(3, estadoFinal);
            if (observacion == null || observacion.trim().isEmpty()) {
                ps.setNull(4, Types.VARCHAR);
            } else {
                ps.setString(4, observacion.trim());
            }
            ps.executeUpdate();
        }
    }

    /** Traduce los estados usados en el frontend ('present'/'late'/'absent') al ENUM de la BD. */
    public static String mapEstado(String estadoFrontend) {
        if (estadoFrontend == null) return "presente";
        switch (estadoFrontend) {
            case "present": return "presente";
            case "late":    return "tardanza";
            case "absent":  return "ausente";
            case "presente": case "tardanza": case "ausente": return estadoFrontend;
            default: return "presente";
        }
    }

    /** Traduce el ENUM de la BD ('presente'/'tardanza'/'ausente') al formato usado en el frontend. */
    public static String mapEstadoFrontend(String estadoBD) {
        if (estadoBD == null) return "present";
        switch (estadoBD) {
            case "presente": return "present";
            case "tardanza": return "late";
            case "ausente":  return "absent";
            default: return "present";
        }
    }
}

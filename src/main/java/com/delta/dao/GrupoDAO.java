package com.delta.dao;

import com.delta.modelo.EstudianteRiesgo;
import com.delta.util.ConexionDB;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Acceso a datos para grupos y análisis de riesgo académico.
 */
public class GrupoDAO {

    /**
     * Devuelve todos los estudiantes en riesgo (promedio < 70) en los grupos
     * de un profesor específico, usando la vista v_riesgo_academico.
     */
    public List<EstudianteRiesgo> listarRiesgoPorProfesor(int profesorId) throws SQLException {
        List<EstudianteRiesgo> lista = new ArrayList<>();

        // Solo mostrar los 5 estudiantes autorizados en la seccion de Riesgo Academico
        String sql = "SELECT vr.estudiante_id, vr.estudiante, vr.codigo_grupo, "
                   + "vr.materia, vr.promedio_final, vr.estado_academico "
                   + "FROM v_riesgo_academico vr "
                   + "JOIN grupos g ON g.codigo_grupo = vr.codigo_grupo "
                   + "WHERE g.profesor_id = ? "
                   + "AND vr.estudiante IN ("
                   + "'Laura Orellana','Edgar Sánchez','Evelin Pineda','Luis King','Gabriela Fuentes'"
                   + ") "
                   + "ORDER BY vr.promedio_final ASC";

        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, profesorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    EstudianteRiesgo er = new EstudianteRiesgo();
                    er.setEstudianteId(rs.getInt("estudiante_id"));
                    er.setNombre(rs.getString("estudiante"));
                    er.setCodigoGrupo(rs.getString("codigo_grupo"));
                    er.setMateria(rs.getString("materia"));
                    er.setPromedioFinal(rs.getDouble("promedio_final"));
                    er.setEstadoAcademico(rs.getString("estado_academico"));
                    lista.add(er);
                }
            }
        }
        return lista;
    }

    /**
     * Cuenta cuántos estudiantes están en riesgo para un profesor dado.
     * Útil para mostrar el badge en la campana de notificaciones.
     */
    public int contarRiesgoPorProfesor(int profesorId) throws SQLException {
        // Solo contar los 5 estudiantes autorizados
        String sql = "SELECT COUNT(*) "
                   + "FROM v_riesgo_academico vr "
                   + "JOIN grupos g ON g.codigo_grupo = vr.codigo_grupo "
                   + "WHERE g.profesor_id = ? "
                   + "AND vr.estudiante IN ("
                   + "'Laura Orellana','Edgar Sánchez','Evelin Pineda','Luis King','Gabriela Fuentes'"
                   + ")";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, profesorId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    /**
     * Resumen de cada grupo con promedio del grupo y cantidad de estudiantes en riesgo.
     * Retorna un List de Object[]: [codigo_grupo, materia, total_est, prom_grupo, en_riesgo]
     */
    public List<Object[]> resumenGruposProfesor(int profesorId) throws SQLException {
        List<Object[]> lista = new ArrayList<>();

        String sql = "SELECT g.codigo_grupo, m.nombre AS materia, "
                   + "COUNT(DISTINCT i.estudiante_id) AS total_estudiantes, "
                   + "ROUND(AVG(vp.promedio_final), 1) AS promedio_grupo, "
                   + "SUM(CASE WHEN vp.promedio_final < 70 THEN 1 ELSE 0 END) AS en_riesgo "
                   + "FROM grupos g "
                   + "JOIN materias m ON m.id = g.materia_id "
                   + "JOIN inscripciones i ON i.grupo_id = g.id AND i.estado = 'activo' "
                   + "JOIN v_promedios vp ON vp.inscripcion_id = i.id "
                   + "WHERE g.profesor_id = ? "
                   + "GROUP BY g.id, g.codigo_grupo, m.nombre "
                   + "ORDER BY g.codigo_grupo";

        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, profesorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Object[] row = {
                        rs.getString("codigo_grupo"),
                        rs.getString("materia"),
                        rs.getInt("total_estudiantes"),
                        rs.getDouble("promedio_grupo"),
                        rs.getInt("en_riesgo")
                    };
                    lista.add(row);
                }
            }
        }
        return lista;
    }
}

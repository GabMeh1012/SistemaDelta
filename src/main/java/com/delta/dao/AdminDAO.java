package com.delta.dao;

import com.delta.util.ConexionDB;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class AdminDAO {

    public Map<String, Object> dashboard() throws SQLException {
        Map<String, Object> d = new HashMap<>();
        try (Connection con = ConexionDB.obtenerConexion();
             Statement st = con.createStatement()) {
            d.put("totalEstudiantes", scalar(st, "SELECT COUNT(*) FROM estudiantes"));
            d.put("totalProfesores",  scalar(st, "SELECT COUNT(*) FROM profesores"));
            d.put("totalMaterias",    scalar(st, "SELECT COUNT(*) FROM materias"));
            try {
                d.put("pendInscripcion", scalar(st, "SELECT COUNT(*) FROM solicitudes_matricula WHERE tipo='inscripcion' AND estado='pendiente'"));
                d.put("pendRetiro",      scalar(st, "SELECT COUNT(*) FROM solicitudes_matricula WHERE tipo='retiro' AND estado='pendiente'"));
            } catch (SQLException ex) {
                d.put("pendInscripcion", 0);
                d.put("pendRetiro", 0);
            }
            try {
                d.put("avisosActivos", scalar(st, "SELECT COUNT(*) FROM avisos WHERE activo=1"));
            } catch (SQLException ex) {
                d.put("avisosActivos", scalar(st, "SELECT COUNT(*) FROM avisos"));
            }
        }
        return d;
    }

    public List<Map<String, Object>> listarEstudiantes(String carrera, String materia, String nombre, String cedula) throws SQLException {
        String sql = "SELECT e.id, e.cedula, CONCAT(e.nombre,' ',e.apellido) AS nombre, e.carrera, e.semestre, "
                   + "(SELECT COUNT(*) FROM inscripciones i WHERE i.estudiante_id=e.id AND i.estado='activo') AS materias_activas "
                   + "FROM estudiantes e WHERE 1=1";
        if (carrera != null && !carrera.isEmpty()) sql += " AND e.carrera = ?";
        if (nombre != null && !nombre.isEmpty()) sql += " AND CONCAT(e.nombre,' ',e.apellido) LIKE ?";
        if (cedula != null && !cedula.isEmpty()) sql += " AND e.cedula LIKE ?";
        if (materia != null && !materia.isEmpty()) {
            sql += " AND EXISTS (SELECT 1 FROM inscripciones i JOIN grupos g ON g.id=i.grupo_id "
                 + "JOIN materias m ON m.id=g.materia_id WHERE i.estudiante_id=e.id AND i.estado='activo' "
                 + "AND (m.codigo LIKE ? OR m.nombre LIKE ?))";
        }
        sql += " ORDER BY e.apellido, e.nombre";

        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            int i = 1;
            if (carrera != null && !carrera.isEmpty()) ps.setString(i++, carrera);
            if (nombre != null && !nombre.isEmpty()) ps.setString(i++, "%" + nombre + "%");
            if (cedula != null && !cedula.isEmpty()) ps.setString(i++, "%" + cedula + "%");
            if (materia != null && !materia.isEmpty()) {
                ps.setString(i++, "%" + materia + "%");
                ps.setString(i++, "%" + materia + "%");
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("cedula", rs.getString("cedula"));
                    row.put("nombre", rs.getString("nombre"));
                    row.put("carrera", rs.getString("carrera"));
                    row.put("semestre", rs.getInt("semestre"));
                    row.put("materiasActivas", rs.getInt("materias_activas"));
                    lista.add(row);
                }
            }
        }
        return lista;
    }

    public List<Map<String, Object>> listarProfesores(String materia, String departamento, String nombre) throws SQLException {
        String sql = "SELECT p.id, p.cedula, CONCAT(p.nombre,' ',p.apellido) AS nombre, p.departamento, "
                   + "COUNT(DISTINCT g.id) AS grupos, COALESCE(SUM(m.creditos),0) AS creditos "
                   + "FROM profesores p "
                   + "LEFT JOIN grupos g ON g.profesor_id = p.id "
                   + "LEFT JOIN materias m ON m.id = g.materia_id WHERE 1=1";
        if (departamento != null && !departamento.isEmpty()) sql += " AND p.departamento LIKE ?";
        if (nombre != null && !nombre.isEmpty()) sql += " AND CONCAT(p.nombre,' ',p.apellido) LIKE ?";
        if (materia != null && !materia.isEmpty()) {
            sql += " AND EXISTS (SELECT 1 FROM grupos g2 JOIN materias m2 ON m2.id=g2.materia_id "
                 + "WHERE g2.profesor_id=p.id AND (m2.codigo LIKE ? OR m2.nombre LIKE ?))";
        }
        sql += " GROUP BY p.id ORDER BY p.apellido, p.nombre";

        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            int i = 1;
            if (departamento != null && !departamento.isEmpty()) ps.setString(i++, "%" + departamento + "%");
            if (nombre != null && !nombre.isEmpty()) ps.setString(i++, "%" + nombre + "%");
            if (materia != null && !materia.isEmpty()) {
                ps.setString(i++, "%" + materia + "%");
                ps.setString(i++, "%" + materia + "%");
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("cedula", rs.getString("cedula"));
                    row.put("nombre", rs.getString("nombre"));
                    row.put("departamento", rs.getString("departamento"));
                    row.put("grupos", rs.getInt("grupos"));
                    row.put("creditos", rs.getInt("creditos"));
                    lista.add(row);
                }
            }
        }
        return lista;
    }

    public List<Map<String, Object>> listarMaterias() throws SQLException {
        String sql = "SELECT m.id, m.codigo, m.nombre, m.creditos, g.capacidad, "
                   + "CONCAT(p.nombre,' ',p.apellido) AS profesor, g.codigo_grupo, "
                   + "(SELECT COUNT(*) FROM inscripciones i WHERE i.grupo_id=g.id AND i.estado='activo') AS inscritos "
                   + "FROM materias m "
                   + "LEFT JOIN grupos g ON g.materia_id = m.id "
                   + "LEFT JOIN profesores p ON p.id = g.profesor_id "
                   + "ORDER BY m.codigo";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("codigo", rs.getString("codigo"));
                row.put("nombre", rs.getString("nombre"));
                row.put("creditos", rs.getInt("creditos"));
                row.put("capacidad", rs.getInt("capacidad"));
                row.put("profesor", rs.getString("profesor"));
                row.put("grupo", rs.getString("codigo_grupo"));
                row.put("inscritos", rs.getInt("inscritos"));
                lista.add(row);
            }
        }
        return lista;
    }

    public void actualizarCreditos(int materiaId, int creditos) throws SQLException {
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement("UPDATE materias SET creditos=? WHERE id=?")) {
            ps.setInt(1, creditos);
            ps.setInt(2, materiaId);
            ps.executeUpdate();
        }
    }

    public void actualizarCapacidad(int grupoId, int capacidad) throws SQLException {
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement("UPDATE grupos SET capacidad=? WHERE id=?")) {
            ps.setInt(1, capacidad);
            ps.setInt(2, grupoId);
            ps.executeUpdate();
        }
    }

    public void reasignarProfesor(int grupoId, int profesorId) throws SQLException {
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement("UPDATE grupos SET profesor_id=? WHERE id=?")) {
            ps.setInt(1, profesorId);
            ps.setInt(2, grupoId);
            ps.executeUpdate();
        }
    }

    public List<Map<String, Object>> listarAvisosAdmin() throws SQLException {
        String sql = "SELECT a.id, a.titulo, a.cuerpo, a.tipo, a.created_at, "
                   + "CONCAT(p.nombre,' ',p.apellido) AS profesor, g.codigo_grupo, "
                   + "COALESCE(a.activo,1) AS activo "
                   + "FROM avisos a "
                   + "LEFT JOIN profesores p ON p.id = a.profesor_id "
                   + "LEFT JOIN grupos g ON g.id = a.grupo_id "
                   + "ORDER BY a.created_at DESC";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("titulo", rs.getString("titulo"));
                row.put("cuerpo", rs.getString("cuerpo"));
                row.put("tipo", rs.getString("tipo"));
                row.put("profesor", rs.getString("profesor"));
                row.put("grupo", rs.getString("codigo_grupo"));
                row.put("activo", rs.getInt("activo") == 1);
                Timestamp ts = rs.getTimestamp("created_at");
                row.put("fecha", ts != null ? ts.toString() : "");
                lista.add(row);
            }
        }
        return lista;
    }

    public void desactivarAviso(int avisoId) throws SQLException {
        try {
            try (Connection con = ConexionDB.obtenerConexion();
                 PreparedStatement ps = con.prepareStatement("UPDATE avisos SET activo=0 WHERE id=?")) {
                ps.setInt(1, avisoId);
                ps.executeUpdate();
            }
        } catch (SQLException ex) {
            if (ex.getMessage() != null && ex.getMessage().contains("activo")) {
                throw new SQLException("Columna avisos.activo no existe. Ejecute database/admin_schema.sql");
            }
            throw ex;
        }
    }

    public void eliminarAviso(int avisoId) throws SQLException {
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement("DELETE FROM avisos WHERE id=?")) {
            ps.setInt(1, avisoId);
            ps.executeUpdate();
        }
    }

    public List<Map<String, Object>> reportePromedioMateria() throws SQLException {
        String sql = "SELECT m.nombre, ROUND(AVG(vp.promedio_final),1) AS promedio "
                   + "FROM v_promedios vp "
                   + "JOIN inscripciones i ON i.id = vp.inscripcion_id "
                   + "JOIN grupos g ON g.id = i.grupo_id "
                   + "JOIN materias m ON m.id = g.materia_id "
                   + "GROUP BY m.id ORDER BY promedio DESC";
        return queryList(sql);
    }

    public List<Map<String, Object>> reporteRiesgo() throws SQLException {
        String sql = "SELECT estudiante, materia, promedio_final, estado_academico FROM v_riesgo_academico ORDER BY promedio_final";
        return queryList(sql);
    }

    public List<Map<String, Object>> reporteInscritosMateria() throws SQLException {
        String sql = "SELECT m.nombre, m.codigo, COUNT(i.id) AS inscritos, g.capacidad "
                   + "FROM materias m "
                   + "JOIN grupos g ON g.materia_id = m.id "
                   + "LEFT JOIN inscripciones i ON i.grupo_id = g.id AND i.estado='activo' "
                   + "GROUP BY m.id, g.id ORDER BY inscritos DESC";
        return queryList(sql);
    }

    private List<Map<String, Object>> queryList(String sql) throws SQLException {
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            ResultSetMetaData meta = rs.getMetaData();
            int cols = meta.getColumnCount();
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                for (int c = 1; c <= cols; c++) {
                    row.put(meta.getColumnLabel(c), rs.getObject(c));
                }
                lista.add(row);
            }
        }
        return lista;
    }

    private int scalar(Statement st, String sql) throws SQLException {
        try (ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) return rs.getInt(1);
        }
        return 0;
    }
}

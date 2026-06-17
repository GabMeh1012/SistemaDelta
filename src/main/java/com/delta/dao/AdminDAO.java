package com.delta.dao;

import com.delta.util.ConexionDB;

import java.sql.*;
import java.time.LocalDate;
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
        if (carrera != null && !carrera.isEmpty()) sql += " AND e.carrera LIKE ?";
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
            if (carrera != null && !carrera.isEmpty()) ps.setString(i++, "%" + carrera + "%");
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
        String sql = "SELECT p.id, p.codigo, CONCAT(p.nombre,' ',p.apellido) AS nombre, p.departamento, "
                   + "COUNT(DISTINCT g.id) AS grupos, COALESCE(SUM(m.creditos),0) AS creditos, "
                   + "COALESCE((SELECT SUM(TIME_TO_SEC(TIMEDIFF(h.hora_fin,h.hora_inicio)))/3600 "
                   + "          FROM horarios h JOIN grupos g3 ON g3.id = h.grupo_id "
                   + "          WHERE g3.profesor_id = p.id), 0) AS horas_semanales, "
                   + "GROUP_CONCAT(DISTINCT m.nombre ORDER BY m.nombre SEPARATOR ', ') AS materias_lista "
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
                    row.put("codigo", rs.getString("codigo"));
                    row.put("nombre", rs.getString("nombre"));
                    row.put("departamento", rs.getString("departamento"));
                    row.put("grupos", rs.getInt("grupos"));
                    row.put("creditos", rs.getInt("creditos"));
                    row.put("horasSemanales", rs.getDouble("horas_semanales"));
                    row.put("materiasLista", rs.getString("materias_lista"));
                    lista.add(row);
                }
            }
        }
        return lista;
    }

    public List<Map<String, Object>> listarMaterias() throws SQLException {
        String sql = "SELECT m.id, m.codigo, m.nombre, m.creditos, g.id AS grupo_id, g.capacidad, "
                   + "p.id AS profesor_id, CONCAT(p.nombre,' ',p.apellido) AS profesor, g.codigo_grupo, "
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
                int grupoId = rs.getInt("grupo_id");
                row.put("grupoId", rs.wasNull() ? null : grupoId);
                row.put("capacidad", rs.getInt("capacidad"));
                int profesorId = rs.getInt("profesor_id");
                row.put("profesorId", rs.wasNull() ? null : profesorId);
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

    /** Lista simple de profesores (id + nombre) para el selector de reasignacion. */
    public List<Map<String, Object>> listarProfesoresSimple() throws SQLException {
        String sql = "SELECT p.id, CONCAT(p.nombre,' ',p.apellido) AS nombre FROM profesores p ORDER BY p.apellido, p.nombre";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("nombre", rs.getString("nombre"));
                lista.add(row);
            }
        }
        return lista;
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

    /** Promedio general de notas agrupado por carrera del estudiante. */
    public List<Map<String, Object>> reportePromedioCarrera() throws SQLException {
        String sql = "SELECT e.carrera, ROUND(AVG(vp.promedio_final),1) AS promedio, COUNT(*) AS materias_evaluadas "
                   + "FROM v_promedios vp "
                   + "JOIN estudiantes e ON e.id = vp.estudiante_id "
                   + "WHERE e.carrera IS NOT NULL "
                   + "GROUP BY e.carrera ORDER BY promedio DESC";
        return queryList(sql);
    }

    /**
     * Materias ordenadas por cantidad de aprobados (promedio >= 71) o reprobados
     * (promedio < 61), segun el parametro `orden`.
     */
    public List<Map<String, Object>> reporteAprobadosReprobados(String orden) throws SQLException {
        String orderBy = "reprobados".equals(orden) ? "reprobados DESC" : "aprobados DESC";
        String sql = "SELECT m.nombre, m.codigo, COUNT(*) AS total_evaluados, "
                   + "SUM(CASE WHEN vp.promedio_final >= 71 THEN 1 ELSE 0 END) AS aprobados, "
                   + "SUM(CASE WHEN vp.promedio_final < 61 THEN 1 ELSE 0 END) AS reprobados "
                   + "FROM v_promedios vp "
                   + "JOIN inscripciones i ON i.id = vp.inscripcion_id "
                   + "JOIN grupos g ON g.id = i.grupo_id "
                   + "JOIN materias m ON m.id = g.materia_id "
                   + "GROUP BY m.id ORDER BY " + orderBy;
        return queryList(sql);
    }

    public List<Map<String, Object>> reporteRiesgo() throws SQLException {
        String sql = "SELECT estudiante, materia, promedio_final, estado_academico FROM v_riesgo_academico ORDER BY promedio_final";
        return queryList(sql);
    }

    public List<Map<String, Object>> reporteInscritosMateria() throws SQLException {
        return reporteInscritosMateria("desc");
    }

    /** Materias ordenadas por cantidad de inscritos, ascendente o descendente. */
    public List<Map<String, Object>> reporteInscritosMateria(String orden) throws SQLException {
        String orderBy = "asc".equalsIgnoreCase(orden) ? "inscritos ASC" : "inscritos DESC";
        String sql = "SELECT m.nombre, m.codigo, COUNT(i.id) AS inscritos, g.capacidad "
                   + "FROM materias m "
                   + "JOIN grupos g ON g.materia_id = m.id "
                   + "LEFT JOIN inscripciones i ON i.grupo_id = g.id AND i.estado='activo' "
                   + "GROUP BY m.id, g.id ORDER BY " + orderBy;
        return queryList(sql);
    }

    /** Cupos disponibles (capacidad - inscritos activos) por materia/grupo. */
    public List<Map<String, Object>> reporteCuposDisponibles() throws SQLException {
        String sql = "SELECT m.nombre, m.codigo, g.codigo_grupo, g.capacidad, COUNT(i.id) AS inscritos, "
                   + "(g.capacidad - COUNT(i.id)) AS cupos_disponibles "
                   + "FROM materias m "
                   + "JOIN grupos g ON g.materia_id = m.id "
                   + "LEFT JOIN inscripciones i ON i.grupo_id = g.id AND i.estado='activo' "
                   + "GROUP BY m.id, g.id ORDER BY cupos_disponibles ASC";
        return queryList(sql);
    }

    /** Carga academica de los profesores: grupos asignados, creditos totales y horas semanales. */
    public List<Map<String, Object>> reporteCargaProfesores() throws SQLException {
        String sql = "SELECT CONCAT(p.nombre,' ',p.apellido) AS profesor, p.departamento, "
                   + "COUNT(DISTINCT g.id) AS grupos_asignados, COALESCE(SUM(m.creditos),0) AS creditos_totales, "
                   + "COALESCE((SELECT SUM(TIME_TO_SEC(TIMEDIFF(h.hora_fin,h.hora_inicio)))/3600 "
                   + "          FROM horarios h JOIN grupos g3 ON g3.id = h.grupo_id "
                   + "          WHERE g3.profesor_id = p.id), 0) AS horas_semanales "
                   + "FROM profesores p "
                   + "LEFT JOIN grupos g ON g.profesor_id = p.id "
                   + "LEFT JOIN materias m ON m.id = g.materia_id "
                   + "GROUP BY p.id ORDER BY horas_semanales DESC";
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

    // ============================================================
    // GESTION DE LIMITES DE SOLICITUDES DE MATRICULA
    // ============================================================

    /**
     * Lista todos los estudiantes con inscripciones activas, mostrando por cada
     * (estudiante, grupo) cuantas solicitudes han realizado vs el limite actual.
     * Util para que el admin vea quien se acerca o supero el limite.
     */
    public List<Map<String, Object>> listarLimitesSolicitudes() throws SQLException {
        String sql = "SELECT e.id AS estudiante_id, CONCAT(e.nombre,' ',e.apellido) AS estudiante, "
                   + "m.nombre AS materia, m.codigo AS materia_codigo, g.id AS grupo_id, "
                   + "COALESCE(ls.limite, 2) AS limite, "
                   + "(SELECT COUNT(*) FROM solicitudes_matricula s2 "
                   + " WHERE s2.estudiante_id = e.id AND s2.grupo_id = g.id AND s2.tipo = 'inscripcion') AS sol_inscripcion, "
                   + "(SELECT COUNT(*) FROM solicitudes_matricula s3 "
                   + " WHERE s3.estudiante_id = e.id AND s3.grupo_id = g.id AND s3.tipo = 'retiro') AS sol_retiro "
                   + "FROM estudiantes e "
                   + "JOIN inscripciones i ON i.estudiante_id = e.id AND i.estado = 'activo' "
                   + "JOIN grupos g ON g.id = i.grupo_id "
                   + "JOIN materias m ON m.id = g.materia_id "
                   + "LEFT JOIN limites_solicitudes ls ON ls.estudiante_id = e.id AND ls.grupo_id = g.id "
                   + "ORDER BY e.apellido, e.nombre, m.codigo";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("estudianteId", rs.getInt("estudiante_id"));
                row.put("estudiante",   rs.getString("estudiante"));
                row.put("materia",      rs.getString("materia"));
                row.put("materiaCodigo", rs.getString("materia_codigo"));
                row.put("grupoId",      rs.getInt("grupo_id"));
                row.put("limite",       rs.getInt("limite"));
                row.put("solInscripcion", rs.getInt("sol_inscripcion"));
                row.put("solRetiro",    rs.getInt("sol_retiro"));
                lista.add(row);
            }
        }
        return lista;
    }

    /** Actualiza el limite de solicitudes para un estudiante/grupo especifico. */
    public void actualizarLimiteSolicitud(int estudianteId, int grupoId, int nuevoLimite, int adminUsuarioId) throws SQLException {
        new SolicitudMatriculaDAO().actualizarLimite(estudianteId, grupoId, nuevoLimite, adminUsuarioId);
    }

    // ============================================================
    // SUPERVISION DE CALIFICACIONES
    // ============================================================

    private static final int LIMITE_MODIFICACIONES_NOTAS = 3;

    /**
     * Lista las notas que han sido modificadas al menos una vez, con la cantidad
     * de modificaciones registradas, el limite efectivo (base + autorizaciones)
     * y si ya alcanzaron el limite.
     */
    public List<Map<String, Object>> listarSupervisionCalificaciones() throws SQLException {
        String sql = "SELECT i.id AS inscripcion_id, CONCAT(e.nombre,' ',e.apellido) AS estudiante, "
                   + "m.nombre AS materia, m.codigo AS materia_codigo, g.codigo_grupo, "
                   + "n.componente, n.nota AS nota_actual, "
                   + "COALESCE((SELECT COUNT(*) FROM notas_historial h "
                   + "          WHERE h.inscripcion_id = i.id AND h.componente = n.componente), 0) AS modificaciones, "
                   + "COALESCE((SELECT SUM(cantidad) FROM notas_autorizaciones na "
                   + "          WHERE na.inscripcion_id = i.id AND na.componente = n.componente), 0) AS autorizaciones "
                   + "FROM notas n "
                   + "JOIN inscripciones i ON i.id = n.inscripcion_id "
                   + "JOIN estudiantes e ON e.id = i.estudiante_id "
                   + "JOIN grupos g ON g.id = i.grupo_id "
                   + "JOIN materias m ON m.id = g.materia_id "
                   + "WHERE i.estado = 'activo' "
                   + "ORDER BY e.apellido, e.nombre, n.componente";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("inscripcionId", rs.getInt("inscripcion_id"));
                row.put("estudiante", rs.getString("estudiante"));
                row.put("materia", rs.getString("materia"));
                row.put("materiaCodigo", rs.getString("materia_codigo"));
                row.put("grupo", rs.getString("codigo_grupo"));
                row.put("componente", rs.getString("componente"));
                double notaActual = rs.getDouble("nota_actual");
                row.put("notaActual", rs.wasNull() ? null : notaActual);
                int modificaciones = rs.getInt("modificaciones");
                int autorizaciones = rs.getInt("autorizaciones");
                int limite = LIMITE_MODIFICACIONES_NOTAS + autorizaciones;
                row.put("modificaciones", modificaciones);
                row.put("limite", limite);
                row.put("autorizaciones", autorizaciones);
                row.put("enLimite", modificaciones >= limite);
                lista.add(row);
            }
        }
        return lista;
    }

    /** Otorga +cantidad modificaciones adicionales permitidas para una nota especifica. */
    public void autorizarModificacionNota(int inscripcionId, String componente, int cantidad, int adminUsuarioId) throws SQLException {
        String sql = "INSERT INTO notas_autorizaciones (inscripcion_id, componente, cantidad, admin_usuario_id) VALUES (?,?,?,?)";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, inscripcionId);
            ps.setString(2, componente);
            ps.setInt(3, cantidad);
            ps.setInt(4, adminUsuarioId);
            ps.executeUpdate();
        }
    }

    /**
     * Reinicia el contador de modificaciones de una nota: borra el historial
     * y las autorizaciones previas, dejando la nota como si nunca hubiera
     * sido modificada (el profesor vuelve a tener el limite completo).
     */
    public void reiniciarModificaciones(int inscripcionId, String componente) throws SQLException {
        try (Connection con = ConexionDB.obtenerConexion()) {
            con.setAutoCommit(false);
            try {
                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM notas_historial WHERE inscripcion_id = ? AND componente = ?")) {
                    ps.setInt(1, inscripcionId); ps.setString(2, componente);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM notas_autorizaciones WHERE inscripcion_id = ? AND componente = ?")) {
                    ps.setInt(1, inscripcionId); ps.setString(2, componente);
                    ps.executeUpdate();
                }
                con.commit();
            } catch (SQLException ex) { con.rollback(); throw ex; }
            finally { con.setAutoCommit(true); }
        }
    }

    /** Historial completo de cambios de una nota especifica (para detalle/auditoria). */
    public List<Map<String, Object>> historialNota(int inscripcionId, String componente) throws SQLException {
        String sql = "SELECT nota_anterior, nota_nueva, fecha_cambio FROM notas_historial "
                   + "WHERE inscripcion_id = ? AND componente = ? ORDER BY fecha_cambio ASC";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, inscripcionId);
            ps.setString(2, componente);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    double na = rs.getDouble("nota_anterior");
                    row.put("notaAnterior", rs.wasNull() ? null : na);
                    row.put("notaNueva", rs.getDouble("nota_nueva"));
                    Timestamp ts = rs.getTimestamp("fecha_cambio");
                    row.put("fecha", ts != null ? ts.toString() : "");
                    lista.add(row);
                }
            }
        }
        return lista;
    }

    // ============================================================
    // SUPERVISION DE ASISTENCIA
    // ============================================================

    /**
     * Lista registros de asistencia con filtros opcionales por grupo, estudiante
     * y materia. Si no se pasa ningun filtro, devuelve los registros mas recientes
     * (limitados) para evitar tablas enormes.
     */
    public List<Map<String, Object>> listarSupervisionAsistencia(Integer grupoId, Integer estudianteId, Integer materiaId, String fecha) throws SQLException {
        StringBuilder sql = new StringBuilder(
                "SELECT a.id, a.inscripcion_id, a.fecha, a.estado, a.observacion, "
              + "CONCAT(e.nombre,' ',e.apellido) AS estudiante, e.id AS estudiante_id, "
              + "m.nombre AS materia, m.id AS materia_id, g.codigo_grupo, g.id AS grupo_id "
              + "FROM asistencia a "
              + "JOIN inscripciones i ON i.id = a.inscripcion_id "
              + "JOIN estudiantes e ON e.id = i.estudiante_id "
              + "JOIN grupos g ON g.id = i.grupo_id "
              + "JOIN materias m ON m.id = g.materia_id WHERE 1=1");
        List<Object> params = new ArrayList<>();
        if (grupoId != null)      { sql.append(" AND g.id = ?"); params.add(grupoId); }
        if (estudianteId != null) { sql.append(" AND e.id = ?"); params.add(estudianteId); }
        if (materiaId != null)    { sql.append(" AND m.id = ?"); params.add(materiaId); }
        if (fecha != null && !fecha.isEmpty()) { sql.append(" AND a.fecha = ?"); params.add(fecha); }
        sql.append(" ORDER BY a.fecha DESC, e.apellido LIMIT 300");

        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("inscripcionId", rs.getInt("inscripcion_id"));
                    Date f = rs.getDate("fecha");
                    row.put("fecha", f != null ? f.toString() : "");
                    row.put("estado", AsistenciaDAO.mapEstadoFrontend(rs.getString("estado")));
                    row.put("observacion", rs.getString("observacion"));
                    row.put("estudiante", rs.getString("estudiante"));
                    row.put("estudianteId", rs.getInt("estudiante_id"));
                    row.put("materia", rs.getString("materia"));
                    row.put("materiaId", rs.getInt("materia_id"));
                    row.put("grupo", rs.getString("codigo_grupo"));
                    row.put("grupoId", rs.getInt("grupo_id"));
                    lista.add(row);
                }
            }
        }
        return lista;
    }

    /** Corrige (upsert) un registro de asistencia existente. */
    public void corregirAsistencia(int inscripcionId, String fecha, String estado, String observacion) throws SQLException {
        new AsistenciaDAO().guardar(inscripcionId, LocalDate.parse(fecha), estado, observacion);
    }

    /**
     * Porcentaje de asistencia (presente+tardanza / total) agrupado por estudiante,
     * grupo o materia, segun el parametro `agrupar`.
     */
    public List<Map<String, Object>> reporteAsistenciaPorcentaje(String agrupar) throws SQLException {
        String campoNombre, campoId, groupBy;
        switch (agrupar == null ? "" : agrupar) {
            case "grupo":
                campoNombre = "g.codigo_grupo"; campoId = "g.id"; groupBy = "g.id, g.codigo_grupo";
                break;
            case "materia":
                campoNombre = "m.nombre"; campoId = "m.id"; groupBy = "m.id, m.nombre";
                break;
            default: // estudiante
                campoNombre = "CONCAT(e.nombre,' ',e.apellido)"; campoId = "e.id"; groupBy = "e.id, e.nombre, e.apellido";
        }
        String sql = "SELECT " + campoNombre + " AS nombre, "
                   + "COUNT(*) AS total, "
                   + "SUM(CASE WHEN a.estado IN ('presente','tardanza') THEN 1 ELSE 0 END) AS presentes, "
                   + "ROUND(100 * SUM(CASE WHEN a.estado IN ('presente','tardanza') THEN 1 ELSE 0 END) / COUNT(*), 1) AS porcentaje "
                   + "FROM asistencia a "
                   + "JOIN inscripciones i ON i.id = a.inscripcion_id "
                   + "JOIN estudiantes e ON e.id = i.estudiante_id "
                   + "JOIN grupos g ON g.id = i.grupo_id "
                   + "JOIN materias m ON m.id = g.materia_id "
                   + "GROUP BY " + groupBy + " ORDER BY porcentaje ASC";
        return queryList(sql);
    }
}

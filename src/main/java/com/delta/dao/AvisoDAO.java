package com.delta.dao;
import com.delta.modelo.Aviso;
import com.delta.util.ConexionDB;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Acceso a datos para avisos / anuncios institucionales y de profesores.
 */
public class AvisoDAO {

    /**
     * Lista los avisos ACTIVOS visibles para un estudiante: los institucionales
     * (grupo_id IS NULL, profesor_id IS NULL) más los publicados por
     * profesores dirigidos a "todos sus grupos" (grupo_id IS NULL,
     * profesor_id NOT NULL) o a un grupo específico en el que el
     * estudiante esté inscrito activamente.
     * Solo se devuelven avisos con estado='activo' (o sin estado definido).
     */
    public List<Aviso> listarParaEstudiante(int usuarioId) throws SQLException {
        List<Aviso> lista = new ArrayList<>();
        String sql = "SELECT a.id, a.profesor_id, a.grupo_id, a.titulo, a.cuerpo, a.tipo, a.created_at, "
                   + "CONCAT(p.nombre,' ',p.apellido) AS profesor_nombre, g.codigo_grupo "
                   + "FROM avisos a "
                   + "LEFT JOIN profesores p ON p.id = a.profesor_id "
                   + "LEFT JOIN grupos g ON g.id = a.grupo_id "
                   + "WHERE COALESCE(a.estado,'activo') = 'activo' "
                   + "  AND (a.grupo_id IS NULL "
                   + "   OR a.grupo_id IN ("
                   + "         SELECT i.grupo_id FROM inscripciones i "
                   + "         JOIN estudiantes e ON e.id = i.estudiante_id "
                   + "         WHERE e.usuario_id = ? AND i.estado = 'activo'"
                   + "       )) "
                   + "ORDER BY a.created_at DESC";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    /**
     * Lista los avisos ACTIVOS publicados por un profesor (para mostrarlos en su propio panel).
     * Solo se devuelven avisos con estado='activo' (o sin estado definido).
     */
    public List<Aviso> listarPorProfesor(int profesorId) throws SQLException {
        List<Aviso> lista = new ArrayList<>();
        // Incluye tambien los avisos institucionales (profesor_id NULL,
        // creados por el admin) para que el profesor los vea en su propio
        // panel, ademas de los que el mismo publico.
        String sql = "SELECT a.id, a.profesor_id, a.grupo_id, a.titulo, a.cuerpo, a.tipo, a.created_at, "
                   + "CONCAT(p.nombre,' ',p.apellido) AS profesor_nombre, g.codigo_grupo "
                   + "FROM avisos a "
                   + "LEFT JOIN profesores p ON p.id = a.profesor_id "
                   + "LEFT JOIN grupos g ON g.id = a.grupo_id "
                   + "WHERE (a.profesor_id = ? OR a.profesor_id IS NULL) "
                   + "  AND COALESCE(a.estado,'activo') = 'activo' "
                   + "ORDER BY a.created_at DESC";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, profesorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    /**
     * Crea un nuevo aviso y genera una notificación (tabla notificaciones,
     * tipo='aviso') para cada usuario afectado:
     *  - profesorId == null -> aviso institucional (creado por el admin):
     *                          llega a TODOS los estudiantes y profesores.
     *  - profesorId != null, grupoId == null -> todos los estudiantes con
     *                          inscripción activa en algún grupo del profesor.
     *  - profesorId != null, grupoId != null -> estudiantes con inscripción
     *                          activa en ese grupo.
     * @return el id del aviso generado
     */
    public int crear(Integer profesorId, Integer grupoId, String titulo, String cuerpo, String tipo) throws SQLException {
        String tipoFinal = (tipo == null || tipo.isEmpty()) ? "info" : tipo;
        String sql = "INSERT INTO avisos (profesor_id, grupo_id, titulo, cuerpo, tipo) VALUES (?,?,?,?,?)";
        int avisoId = -1;
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            if (profesorId == null) ps.setNull(1, Types.INTEGER); else ps.setInt(1, profesorId);
            if (grupoId == null) ps.setNull(2, Types.INTEGER); else ps.setInt(2, grupoId);
            ps.setString(3, titulo);
            ps.setString(4, cuerpo);
            ps.setString(5, tipoFinal);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) avisoId = rs.getInt(1);
            }
        }
        if (avisoId != -1) {
            notificarUsuarios(profesorId, grupoId, titulo, cuerpo);
        }
        return avisoId;
    }

    /**
     * Inserta una notificación (tipo='aviso') para cada usuario afectado por
     * el aviso: estudiantes del grupo/profesor, o TODOS los estudiantes y
     * profesores cuando es institucional (profesorId == null).
     */
    private void notificarUsuarios(Integer profesorId, Integer grupoId, String titulo, String cuerpo) throws SQLException {
        String sqlUsuarios;
        if (profesorId == null) {
            sqlUsuarios = "SELECT usuario_id FROM estudiantes UNION SELECT usuario_id FROM profesores";
        } else if (grupoId != null) {
            sqlUsuarios = "SELECT DISTINCT e.usuario_id FROM inscripciones i "
                        + "JOIN estudiantes e ON e.id = i.estudiante_id "
                        + "WHERE i.grupo_id = ? AND i.estado = 'activo'";
        } else {
            sqlUsuarios = "SELECT DISTINCT e.usuario_id FROM inscripciones i "
                        + "JOIN estudiantes e ON e.id = i.estudiante_id "
                        + "JOIN grupos g ON g.id = i.grupo_id "
                        + "WHERE g.profesor_id = ? AND i.estado = 'activo'";
        }
        String resumenCuerpo = cuerpo.length() > 150 ? cuerpo.substring(0, 147) + "..." : cuerpo;
        String sqlNotif = "INSERT INTO notificaciones (usuario_id, tipo, titulo, cuerpo, enlace) "
                        + "VALUES (?, 'aviso', ?, ?, 'avisos')";
        try (Connection con = ConexionDB.obtenerConexion()) {
            con.setAutoCommit(false);
            try {
                java.util.List<Integer> usuarioIds = new ArrayList<>();
                try (PreparedStatement psU = con.prepareStatement(sqlUsuarios)) {
                    if (profesorId != null) psU.setInt(1, grupoId != null ? grupoId : profesorId);
                    try (ResultSet rs = psU.executeQuery()) {
                        while (rs.next()) usuarioIds.add(rs.getInt("usuario_id"));
                    }
                }
                try (PreparedStatement psN = con.prepareStatement(sqlNotif)) {
                    for (int usuarioId : usuarioIds) {
                        psN.setInt(1, usuarioId);
                        psN.setString(2, titulo);
                        psN.setString(3, resumenCuerpo);
                        psN.addBatch();
                    }
                    if (!usuarioIds.isEmpty()) psN.executeBatch();
                }
                con.commit();
            } catch (SQLException ex) {
                con.rollback();
                throw ex;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    private Aviso mapRow(ResultSet rs) throws SQLException {
        Aviso a = new Aviso();
        a.setId(rs.getInt("id"));
        int profesorId = rs.getInt("profesor_id");
        a.setProfesorId(rs.wasNull() ? null : profesorId);
        int grupoId = rs.getInt("grupo_id");
        a.setGrupoId(rs.wasNull() ? null : grupoId);
        a.setTitulo(rs.getString("titulo"));
        a.setCuerpo(rs.getString("cuerpo"));
        a.setTipo(rs.getString("tipo"));
        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) a.setCreatedAt(ts.toLocalDateTime());
        a.setProfesorNombre(rs.getString("profesor_nombre"));
        a.setCodigoGrupo(rs.getString("codigo_grupo"));
        return a;
    }
}
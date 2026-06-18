package com.delta.dao;

import com.delta.modelo.SolicitudMatricula;
import com.delta.util.ConexionDB;
import com.delta.util.MatriculaHelper;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class SolicitudMatriculaDAO {

    /** Limite base de oportunidades por (estudiante, grupo) — combinando inscripcion y retiro. */
    private static final int LIMITE_DEFAULT = 3;

    /** IDs de cédula de los 5 estudiantes autorizados para este módulo. */
    private static final java.util.Set<String> ESTUDIANTES_PERMITIDOS = new java.util.HashSet<>(
        java.util.Arrays.asList(
            "Gabriela Fuentes", "Laura Orellana", "Evelin Pineda",
            "Edgar Sánchez", "Luis King"
        )
    );

    private static final String SELECT_BASE =
            "SELECT s.id, s.estudiante_id, s.grupo_id, s.tipo, s.estado, s.inscripcion_id, "
          + "s.motivo, s.admin_usuario_id, s.fecha_solicitud, s.fecha_resolucion, "
          + "CONCAT(e.nombre,' ',e.apellido) AS estudiante_nombre, "
          + "m.codigo AS materia_codigo, m.nombre AS materia_nombre, g.codigo_grupo "
          + "FROM solicitudes_matricula s "
          + "JOIN estudiantes e ON e.id = s.estudiante_id "
          + "JOIN grupos g ON g.id = s.grupo_id "
          + "JOIN materias m ON m.id = g.materia_id ";

    public int crearInscripcion(int estudianteId, String codigoMateria) throws SQLException {
        verificarEstudiantePermitido(estudianteId);
        int grupoId = obtenerGrupoIdPorCodigo(codigoMateria);
        if (grupoId == -1) throw new SQLException("materia/grupo no encontrado");
        verificarLimite(estudianteId, grupoId);
        if (tienePendiente(estudianteId, grupoId, "inscripcion")) {
            throw new SQLException("Ya existe una solicitud de inscripcion pendiente para esta materia.");
        }
        if (yaInscrito(estudianteId, grupoId)) {
            throw new SQLException("ya inscrito");
        }
        return insertar(estudianteId, grupoId, "inscripcion", null);
    }

    public int crearRetiro(int estudianteId, String codigoMateria) throws SQLException {
        verificarEstudiantePermitido(estudianteId);
        int grupoId = obtenerGrupoIdPorCodigo(codigoMateria);
        if (grupoId == -1) throw new SQLException("materia/grupo no encontrado");
        Integer inscripcionId = obtenerInscripcionActiva(estudianteId, codigoMateria);
        if (inscripcionId == null) throw new SQLException("inscripcion no encontrada");
        verificarLimite(estudianteId, grupoId);
        if (tienePendiente(estudianteId, grupoId, "retiro")) {
            throw new SQLException("Ya existe una solicitud de retiro pendiente para esta materia.");
        }
        return insertar(estudianteId, grupoId, "retiro", inscripcionId);
    }

    public List<SolicitudMatricula> listarPorEstudianteUsuario(int usuarioId, String estado) throws SQLException {
        String sql = SELECT_BASE
                   + "WHERE e.usuario_id = ? "
                   + (estado != null ? "AND s.estado = ? " : "")
                   + "ORDER BY s.fecha_solicitud DESC";
        List<SolicitudMatricula> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, usuarioId);
            if (estado != null) ps.setString(2, estado);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    public List<SolicitudMatricula> listarPendientes(String tipo) throws SQLException {
        String sql = SELECT_BASE + "WHERE s.estado = 'pendiente' "
                   + (tipo != null ? "AND s.tipo = ? " : "")
                   + "ORDER BY s.fecha_solicitud ASC";
        List<SolicitudMatricula> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            if (tipo != null) ps.setString(1, tipo);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    public int contarPendientes(String tipo) throws SQLException {
        String sql = "SELECT COUNT(*) FROM solicitudes_matricula WHERE estado = 'pendiente'"
                   + (tipo != null ? " AND tipo = ?" : "");
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            if (tipo != null) ps.setString(1, tipo);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    public void aprobar(int solicitudId, int adminUsuarioId) throws SQLException {
        SolicitudMatricula sol = obtenerPorId(solicitudId);
        if (sol == null) throw new SQLException("solicitud no encontrada");
        if (!"pendiente".equals(sol.getEstado())) throw new SQLException("solicitud ya resuelta");

        try (Connection con = ConexionDB.obtenerConexion()) {
            con.setAutoCommit(false);
            try {
                if ("inscripcion".equals(sol.getTipo())) {
                    MatriculaHelper.ejecutarInscripcion(con, sol.getEstudianteId(), sol.getMateriaCodigo());
                } else {
                    MatriculaHelper.ejecutarRetiro(con, sol.getEstudianteId(), sol.getMateriaCodigo());
                }
                resolver(con, solicitudId, adminUsuarioId, "aprobada");
                notificarEstudiante(con, sol, true);
                con.commit();
            } catch (SQLException ex) {
                con.rollback();
                throw ex;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    public void rechazar(int solicitudId, int adminUsuarioId, String motivo) throws SQLException {
        SolicitudMatricula sol = obtenerPorId(solicitudId);
        if (sol == null) throw new SQLException("solicitud no encontrada");
        if (!"pendiente".equals(sol.getEstado())) throw new SQLException("solicitud ya resuelta");

        try (Connection con = ConexionDB.obtenerConexion()) {
            con.setAutoCommit(false);
            try {
                resolver(con, solicitudId, adminUsuarioId, "rechazada", motivo);
                notificarEstudiante(con, sol, false);
                con.commit();
            } catch (SQLException ex) {
                con.rollback();
                throw ex;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    private void resolver(Connection con, int id, int adminId, String estado) throws SQLException {
        resolver(con, id, adminId, estado, null);
    }

    private void resolver(Connection con, int id, int adminId, String estado, String motivo) throws SQLException {
        String sql = "UPDATE solicitudes_matricula SET estado=?, admin_usuario_id=?, "
                   + "fecha_resolucion=NOW(), motivo=COALESCE(?, motivo) WHERE id=?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, estado);
            ps.setInt(2, adminId);
            ps.setString(3, motivo);
            ps.setInt(4, id);
            ps.executeUpdate();
        }
    }

    private void notificarEstudiante(Connection con, SolicitudMatricula sol, boolean aprobada) throws SQLException {
        int usuarioId;
        try (PreparedStatement ps = con.prepareStatement("SELECT usuario_id FROM estudiantes WHERE id = ?")) {
            ps.setInt(1, sol.getEstudianteId());
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return;
                usuarioId = rs.getInt(1);
            }
        }
        String accion = "inscripcion".equals(sol.getTipo()) ? "inscripcion" : "retiro";
        String titulo = aprobada
                ? "Solicitud de " + accion + " aprobada"
                : "Solicitud de " + accion + " rechazada";
        String cuerpo = aprobada
                ? "Su solicitud para " + accion + " en " + sol.getMateriaNombre() + " fue aprobada."
                : "Su solicitud para " + accion + " en " + sol.getMateriaNombre() + " fue rechazada.";
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO notificaciones (usuario_id, tipo, titulo, cuerpo, enlace) VALUES (?,?,?,?,?)")) {
            ps.setInt(1, usuarioId);
            ps.setString(2, "matricula");
            ps.setString(3, titulo);
            ps.setString(4, cuerpo);
            ps.setString(5, "inscripcion");
            ps.executeUpdate();
        }
    }

    private SolicitudMatricula obtenerPorId(int id) throws SQLException {
        String sql = SELECT_BASE + "WHERE s.id = ?";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        }
        return null;
    }

    private int insertar(int estudianteId, int grupoId, String tipo, Integer inscripcionId) throws SQLException {
        String sql = "INSERT INTO solicitudes_matricula (estudiante_id, grupo_id, tipo, inscripcion_id) VALUES (?,?,?,?)";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, estudianteId);
            ps.setInt(2, grupoId);
            ps.setString(3, tipo);
            if (inscripcionId == null) ps.setNull(4, Types.INTEGER);
            else ps.setInt(4, inscripcionId);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return -1;
    }

    private boolean tienePendiente(int estudianteId, int grupoId, String tipo) throws SQLException {
        String sql = "SELECT 1 FROM solicitudes_matricula WHERE estudiante_id=? AND grupo_id=? "
                   + "AND tipo=? AND estado='pendiente' LIMIT 1";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, estudianteId);
            ps.setInt(2, grupoId);
            ps.setString(3, tipo);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private boolean yaInscrito(int estudianteId, int grupoId) throws SQLException {
        String sql = "SELECT 1 FROM inscripciones WHERE estudiante_id=? AND grupo_id=? AND estado='activo' LIMIT 1";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, estudianteId);
            ps.setInt(2, grupoId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private Integer obtenerInscripcionActiva(int estudianteId, String codigoMateria) throws SQLException {
        String sql = "SELECT i.id FROM inscripciones i "
                   + "JOIN grupos g ON g.id = i.grupo_id "
                   + "JOIN materias m ON m.id = g.materia_id "
                   + "WHERE i.estudiante_id = ? AND m.codigo = ? AND i.estado = 'activo'";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, estudianteId);
            ps.setString(2, codigoMateria);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return null;
    }

    private int obtenerGrupoIdPorCodigo(String codigoMateria) throws SQLException {
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT g.id FROM grupos g JOIN materias m ON m.id = g.materia_id WHERE m.codigo = ? LIMIT 1")) {
            ps.setString(1, codigoMateria);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return -1;
    }

    private SolicitudMatricula mapRow(ResultSet rs) throws SQLException {
        SolicitudMatricula s = new SolicitudMatricula();
        s.setId(rs.getInt("id"));
        s.setEstudianteId(rs.getInt("estudiante_id"));
        s.setGrupoId(rs.getInt("grupo_id"));
        s.setTipo(rs.getString("tipo"));
        s.setEstado(rs.getString("estado"));
        int inscId = rs.getInt("inscripcion_id");
        s.setInscripcionId(rs.wasNull() ? null : inscId);
        s.setMotivo(rs.getString("motivo"));
        int adminId = rs.getInt("admin_usuario_id");
        s.setAdminUsuarioId(rs.wasNull() ? null : adminId);
        Timestamp ts = rs.getTimestamp("fecha_solicitud");
        if (ts != null) s.setFechaSolicitud(ts.toLocalDateTime());
        Timestamp tr = rs.getTimestamp("fecha_resolucion");
        if (tr != null) s.setFechaResolucion(tr.toLocalDateTime());
        s.setEstudianteNombre(rs.getString("estudiante_nombre"));
        s.setMateriaCodigo(rs.getString("materia_codigo"));
        s.setMateriaNombre(rs.getString("materia_nombre"));
        s.setGrupoCodigo(rs.getString("codigo_grupo"));
        return s;
    }

    // ──────────────────────────────────────────────────────────
    // Control de oportunidades por materia (inscripcion + retiro combinados)
    // ──────────────────────────────────────────────────────────

    /** Verifica que el estudiante sea uno de los 5 permitidos. */
    private void verificarEstudiantePermitido(int estudianteId) throws SQLException {
        String sql = "SELECT CONCAT(nombre,' ',apellido) AS nombre FROM estudiantes WHERE id = ?";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, estudianteId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String nombre = rs.getString("nombre");
                    if (!ESTUDIANTES_PERMITIDOS.contains(nombre)) {
                        throw new SQLException("Este estudiante no esta habilitado para realizar solicitudes academicas.");
                    }
                } else {
                    throw new SQLException("Estudiante no encontrado.");
                }
            }
        }
    }

    /**
     * Verifica que el estudiante no haya superado el limite de oportunidades
     * para este grupo (contando inscripcion + retiro juntos).
     */
    private void verificarLimite(int estudianteId, int grupoId) throws SQLException {
        int usadas = contarOportunidadesUsadas(estudianteId, grupoId);
        int limite = obtenerLimite(estudianteId, grupoId);
        if (usadas >= limite) {
            throw new SQLException(
                "Ha alcanzado el limite de solicitudes permitidas para esta materia. "
                + "Contacte al administrador para obtener autorizacion adicional."
            );
        }
    }

    /** Cuenta TODAS las solicitudes (inscripcion + retiro, cualquier estado) para un (estudiante, grupo). */
    public int contarOportunidadesUsadas(int estudianteId, int grupoId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM solicitudes_matricula "
                   + "WHERE estudiante_id = ? AND grupo_id = ?";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, estudianteId);
            ps.setInt(2, grupoId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    /** Devuelve el limite configurado. Si no hay fila, devuelve LIMITE_DEFAULT (3). */
    public int obtenerLimite(int estudianteId, int grupoId) throws SQLException {
        String sql = "SELECT limite FROM limites_solicitudes WHERE estudiante_id = ? AND grupo_id = ?";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, estudianteId);
            ps.setInt(2, grupoId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return LIMITE_DEFAULT;
    }

    /** Reinicia oportunidades: resetea limite a 3 y borra historial de solicitudes. */
    public void reiniciarOportunidades(int estudianteId, int grupoId, int adminUsuarioId) throws SQLException {
        String upsert = "INSERT INTO limites_solicitudes (estudiante_id, grupo_id, limite, admin_usuario_id) "
                      + "VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE limite=?, admin_usuario_id=VALUES(admin_usuario_id)";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(upsert)) {
            ps.setInt(1, estudianteId); ps.setInt(2, grupoId);
            ps.setInt(3, LIMITE_DEFAULT); ps.setInt(4, adminUsuarioId); ps.setInt(5, LIMITE_DEFAULT);
            ps.executeUpdate();
        }
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(
                     "DELETE FROM solicitudes_matricula WHERE estudiante_id = ? AND grupo_id = ?")) {
            ps.setInt(1, estudianteId); ps.setInt(2, grupoId);
            ps.executeUpdate();
        }
    }

    /** Agrega +1 oportunidad adicional para un (estudiante, grupo). */
    public void autorizarOportunidad(int estudianteId, int grupoId, int adminUsuarioId) throws SQLException {
        int nuevoLimite = obtenerLimite(estudianteId, grupoId) + 1;
        actualizarLimite(estudianteId, grupoId, nuevoLimite, adminUsuarioId);
    }

    /** Actualiza (o crea) el limite de solicitudes para un (estudiante, grupo). */
    public void actualizarLimite(int estudianteId, int grupoId, int nuevoLimite, int adminUsuarioId) throws SQLException {
        String sql = "INSERT INTO limites_solicitudes (estudiante_id, grupo_id, limite, admin_usuario_id) "
                   + "VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE limite=VALUES(limite), admin_usuario_id=VALUES(admin_usuario_id)";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, estudianteId); ps.setInt(2, grupoId);
            ps.setInt(3, nuevoLimite); ps.setInt(4, adminUsuarioId);
            ps.executeUpdate();
        }
    }
}

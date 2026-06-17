package com.delta.dao;

import com.delta.modelo.Mensaje;
import com.delta.modelo.Notificacion;
import com.delta.util.ConexionDB;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Acceso a datos para mensajes y notificaciones.
 */
public class MensajeDAO {

    // ─────────────────────────────────────────
    // MENSAJES
    // ─────────────────────────────────────────

    /** Devuelve todos los mensajes enviados por un usuario (ordenados por fecha desc). */
    public List<Mensaje> listarEnviados(int remitenteId) throws SQLException {
        List<Mensaje> lista = new ArrayList<>();
        String sql = "SELECT m.id, m.destinatario_id, m.asunto, m.cuerpo, m.leido, m.fecha_envio, "
                   + "COALESCE(CONCAT(p.nombre,' ',p.apellido), CONCAT(e.nombre,' ',e.apellido), u.username) AS destinatario_nombre "
                   + "FROM mensajes m "
                   + "JOIN usuarios u ON u.id = m.destinatario_id "
                   + "LEFT JOIN profesores  p ON p.usuario_id = m.destinatario_id "
                   + "LEFT JOIN estudiantes e ON e.usuario_id = m.destinatario_id "
                   + "WHERE m.remitente_id = ? "
                   + "ORDER BY m.fecha_envio DESC";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, remitenteId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Mensaje msg = new Mensaje();
                    msg.setId(rs.getInt("id"));
                    msg.setDestinatarioId(rs.getInt("destinatario_id"));
                    msg.setDestinatarioNombre(rs.getString("destinatario_nombre"));
                    msg.setAsunto(rs.getString("asunto"));
                    msg.setCuerpo(rs.getString("cuerpo"));
                    msg.setLeido(rs.getBoolean("leido"));
                    Timestamp ts = rs.getTimestamp("fecha_envio");
                    if (ts != null) msg.setFechaEnvio(ts.toLocalDateTime());
                    lista.add(msg);
                }
            }
        }
        return lista;
    }

    /** Devuelve todos los mensajes recibidos por un usuario (ordenados por fecha desc). */
    public List<Mensaje> listarRecibidos(int destinatarioId) throws SQLException {
        List<Mensaje> lista = new ArrayList<>();
        String sql = "SELECT m.id, m.remitente_id, m.asunto, m.cuerpo, m.leido, m.fecha_envio, "
                   + "COALESCE(CONCAT(p.nombre,' ',p.apellido), CONCAT(e.nombre,' ',e.apellido), u.username) AS remitente_nombre "
                   + "FROM mensajes m "
                   + "JOIN usuarios u ON u.id = m.remitente_id "
                   + "LEFT JOIN profesores  p ON p.usuario_id = m.remitente_id "
                   + "LEFT JOIN estudiantes e ON e.usuario_id = m.remitente_id "
                   + "WHERE m.destinatario_id = ? "
                   + "ORDER BY m.fecha_envio DESC";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, destinatarioId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Mensaje msg = new Mensaje();
                    msg.setId(rs.getInt("id"));
                    msg.setRemitenteId(rs.getInt("remitente_id"));
                    msg.setRemitenteNombre(rs.getString("remitente_nombre"));
                    msg.setAsunto(rs.getString("asunto"));
                    msg.setCuerpo(rs.getString("cuerpo"));
                    msg.setLeido(rs.getBoolean("leido"));
                    Timestamp ts = rs.getTimestamp("fecha_envio");
                    if (ts != null) msg.setFechaEnvio(ts.toLocalDateTime());
                    lista.add(msg);
                }
            }
        }
        return lista;
    }

    /** Cuenta mensajes no leídos para un usuario. */
    public int contarNoLeidos(int destinatarioId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM mensajes WHERE destinatario_id=? AND leido=0";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, destinatarioId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    /**
     * Marca un mensaje como leído Y actualiza la notificación de tipo 'mensaje'
     * asociada (si existe) en la misma transacción.
     */
    public void marcarLeido(int mensajeId, int destinatarioId) throws SQLException {
        String sqlMsg  = "UPDATE mensajes SET leido=1 WHERE id=? AND destinatario_id=?";
        // Busca notificación de tipo mensaje no leída para este usuario cuyo cuerpo
        // mencione el asunto/remitente y la marca leída también.
        String sqlNotif = "UPDATE notificaciones SET leida=1 "
                        + "WHERE usuario_id=? AND tipo='mensaje' AND leida=0 "
                        + "AND id IN ("
                        + "  SELECT n.id FROM (SELECT id FROM notificaciones "
                        + "    WHERE usuario_id=? AND tipo='mensaje' AND leida=0 LIMIT 1) n)";
        try (Connection con = ConexionDB.obtenerConexion()) {
            con.setAutoCommit(false);
            try (PreparedStatement ps1 = con.prepareStatement(sqlMsg)) {
                ps1.setInt(1, mensajeId);
                ps1.setInt(2, destinatarioId);
                ps1.executeUpdate();
            }
            // Actualizar notificación relacionada
            try (PreparedStatement ps2 = con.prepareStatement(
                    "UPDATE notificaciones SET leida=1 WHERE usuario_id=? AND tipo='mensaje' "
                    + "AND leida=0 AND titulo LIKE (SELECT CONCAT('%',COALESCE("
                    + "(SELECT COALESCE(CONCAT(p.nombre,' ',p.apellido),CONCAT(e.nombre,' ',e.apellido)) "
                    + "FROM mensajes m LEFT JOIN profesores p ON p.usuario_id=m.remitente_id "
                    + "LEFT JOIN estudiantes e ON e.usuario_id=m.remitente_id WHERE m.id=?),''),'%') "
                    + "LIMIT 1")) {
                ps2.setInt(1, destinatarioId);
                ps2.setInt(2, mensajeId);
                ps2.executeUpdate();
            } catch (SQLException ignored) {
                // La subquery compleja puede fallar en algunos motores; ignoramos silenciosamente
            }
            con.commit();
        }
    }

    /** Envía un mensaje nuevo. Devuelve el id generado. */
    public int enviar(int remitenteId, int destinatarioId, String asunto, String cuerpo)
            throws SQLException {
        String sql = "INSERT INTO mensajes (remitente_id, destinatario_id, asunto, cuerpo) VALUES (?,?,?,?)";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, remitenteId);
            ps.setInt(2, destinatarioId);
            ps.setString(3, asunto);
            ps.setString(4, cuerpo);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return -1;
    }

    // ─────────────────────────────────────────
    // NOTIFICACIONES
    // ─────────────────────────────────────────

    /** Lista todas las notificaciones de un usuario, no leídas primero. */
    public List<Notificacion> listarPorUsuario(int usuarioId) throws SQLException {
        List<Notificacion> lista = new ArrayList<>();
        String sql = "SELECT * FROM notificaciones WHERE usuario_id=? "
                   + "ORDER BY leida ASC, created_at DESC LIMIT 50";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Notificacion n = new Notificacion();
                    n.setId(rs.getInt("id"));
                    n.setUsuarioId(rs.getInt("usuario_id"));
                    n.setTipo(rs.getString("tipo"));
                    n.setTitulo(rs.getString("titulo"));
                    n.setCuerpo(rs.getString("cuerpo"));
                    n.setLeida(rs.getBoolean("leida"));
                    n.setEnlace(rs.getString("enlace"));
                    Timestamp ts = rs.getTimestamp("created_at");
                    if (ts != null) n.setCreatedAt(ts.toLocalDateTime());
                    lista.add(n);
                }
            }
        }
        return lista;
    }

    /** Cuenta notificaciones no leídas de un usuario. */
    public int contarNoLeidas(int usuarioId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM notificaciones WHERE usuario_id=? AND leida=0";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    /** Marca una notificación como leída. */
    public void marcarNotifLeida(int notifId, int usuarioId) throws SQLException {
        String sql = "UPDATE notificaciones SET leida=1 WHERE id=? AND usuario_id=?";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, notifId);
            ps.setInt(2, usuarioId);
            ps.executeUpdate();
        }
    }

    /** Marca todas las notificaciones de un usuario como leídas. */
    public void marcarTodasLeidas(int usuarioId) throws SQLException {
        String sql = "UPDATE notificaciones SET leida=1 WHERE usuario_id=?";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, usuarioId);
            ps.executeUpdate();
        }
    }
}

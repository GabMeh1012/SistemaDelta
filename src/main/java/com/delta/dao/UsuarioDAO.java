package com.delta.dao;

import com.delta.modelo.Usuario;
import com.delta.util.ConexionDB;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.*;

/**
 * Acceso a datos de la tabla usuarios.
 */
public class UsuarioDAO {

    /**
     * Autentica al usuario comparando username y la contraseña hasheada con SHA-256.
     * Devuelve el Usuario con su rol, o null si las credenciales son incorrectas.
     */
    public Usuario autenticar(String username, String password) throws SQLException {
        String hashPass = sha256(password);
        String sql = "SELECT id, username, rol, activo FROM usuarios "
                   + "WHERE username = ? AND password = ? AND activo = 1";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, hashPass);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Usuario u = new Usuario();
                    u.setId(rs.getInt("id"));
                    u.setUsername(rs.getString("username"));
                    u.setRol(rs.getString("rol"));
                    u.setActivo(rs.getBoolean("activo"));
                    return u;
                }
            }
        }
        return null;
    }

    /**
     * Devuelve el id del profesor (tabla profesores) asociado a un usuario_id.
     * Retorna -1 si no existe.
     */
    public int obtenerProfesorId(int usuarioId) throws SQLException {
        String sql = "SELECT id, nombre, apellido FROM profesores WHERE usuario_id = ?";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("id");
            }
        }
        return -1;
    }

    /**
     * Devuelve nombre completo del profesor dado su usuario_id.
     */
    public String obtenerNombreProfesor(int usuarioId) throws SQLException {
        String sql = "SELECT CONCAT(nombre,' ',apellido) AS nombre_completo "
                   + "FROM profesores WHERE usuario_id = ?";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("nombre_completo");
            }
        }
        return "Docente";
    }

    /**
     * Devuelve el usuario_id de un estudiante o profesor por su nombre completo.
     * Útil para enviar mensajes seleccionando al destinatario por nombre.
     */
    public Integer buscarUsuarioIdPorNombre(String nombreCompleto) throws SQLException {
        if (nombreCompleto == null || nombreCompleto.trim().isEmpty()) return null;
        String nombre = nombreCompleto.trim();
        // Intentar coincidencia exacta primero
        String[] sqls = {
            "SELECT usuario_id FROM estudiantes WHERE CONCAT(nombre,' ',apellido) = ?",
            "SELECT usuario_id FROM profesores  WHERE CONCAT(nombre,' ',apellido) = ?",
            // Coincidencia parcial (solo primer nombre)
            "SELECT usuario_id FROM estudiantes WHERE nombre = ? OR CONCAT(nombre,' ',apellido) LIKE ?",
            "SELECT usuario_id FROM profesores  WHERE nombre = ? OR CONCAT(nombre,' ',apellido) LIKE ?"
        };
        for (int i = 0; i < sqls.length; i++) {
            try (Connection con = ConexionDB.obtenerConexion();
                 PreparedStatement ps = con.prepareStatement(sqls[i])) {
                ps.setString(1, nombre);
                if (i >= 2) ps.setString(2, nombre + "%");
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) return rs.getInt("usuario_id");
                }
            }
        }
        return null;
    }

    /**
     * Busca usuario por nombre ignorando tildes y mayúsculas.
     */
    public Integer buscarUsuarioIdPorNombreSinTildes(String nombreSinTildes) throws SQLException {
        String[] sqls = {
            "SELECT usuario_id FROM estudiantes WHERE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(CONCAT(nombre,' ',apellido)),'á','a'),'é','e'),'í','i'),'ó','o'),'ú','u'),'ñ','n'),'à','a'),'è','e'),'ì','i'),'ò','o') = LOWER(?)",
            "SELECT usuario_id FROM profesores  WHERE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(CONCAT(nombre,' ',apellido)),'á','a'),'é','e'),'í','i'),'ó','o'),'ú','u'),'ñ','n'),'à','a'),'è','e'),'ì','i'),'ò','o') = LOWER(?)"
        };
        for (String sql : sqls) {
            try (Connection con = ConexionDB.obtenerConexion();
                 PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, nombreSinTildes.toLowerCase());
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) return rs.getInt("usuario_id");
                }
            }
        }
        return null;
    }

    // ── Hash SHA-256 ──
    public static String sha256(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] bytes = md.digest(input.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : bytes) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 no disponible", e);
        }
    }
}

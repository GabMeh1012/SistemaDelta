package com.delta.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Utilidad de conexión JDBC a MySQL (XAMPP).
 * Carga el driver y retorna una Connection lista para usar.
 */
public class ConexionDB {

    // ── Modificar estos valores si cambiaste el puerto o credenciales en XAMPP ──
    private static final String URL      = "jdbc:mysql://localhost:3306/sistema_delta"
                                          + "?useSSL=false&serverTimezone=America/Panama"
                                          + "&characterEncoding=UTF-8";
    private static final String USUARIO  = "root";
    private static final String PASSWORD = "";   // XAMPP no tiene contraseña por defecto

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("Driver MySQL no encontrado. "
                + "Asegúrese de agregar mysql-connector-j-*.jar a WEB-INF/lib", e);
        }
    }

    /**
     * Obtiene una nueva conexión a la BD.
     * Recuerde cerrarla en un bloque finally o try-with-resources.
     */
    public static Connection obtenerConexion() throws SQLException {
        return DriverManager.getConnection(URL, USUARIO, PASSWORD);
    }
}

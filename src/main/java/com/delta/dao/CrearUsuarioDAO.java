package com.delta.dao;

import com.delta.util.ConexionDB;
import java.sql.*;
import java.text.Normalizer;
import java.util.*;

/**
 * DAO para la creación de nuevos usuarios (estudiantes y profesores)
 * desde el Portal Administrador de SistemaDelta.
 *
 * Todas las operaciones de escritura se ejecutan en transacciones
 * atómicas: tabla usuarios + tabla específica en un único commit.
 */
public class CrearUsuarioDAO {

    // ── Normalización ────────────────────────────────────────────────────

    /** Convierte nombre.apellido a username sin tildes, sin espacios, en minúsculas. */
    private String normalizarUsername(String nombre, String apellido) {
        String base = (nombre.trim() + "." + apellido.trim()).toLowerCase();
        base = Normalizer.normalize(base, Normalizer.Form.NFD)
                         .replaceAll("[\\p{InCombiningDiacriticalMarks}]", "");
        base = base.replaceAll("[^a-z0-9.]", "");
        return base;
    }

    /**
     * Genera username único: nombre.apellido; si ya existe añade sufijo
     * numérico creciente (nombre.apellido2, nombre.apellido3, …).
     */
    public String generarUsername(Connection con, String nombre, String apellido)
            throws SQLException {
        String base      = normalizarUsername(nombre, apellido);
        String candidato = base;
        int    sufijo    = 2;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM usuarios WHERE username = ?")) {
            while (true) {
                ps.setString(1, candidato);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    if (rs.getInt(1) == 0) return candidato;
                }
                candidato = base + sufijo++;
            }
        }
    }

    /** Genera el siguiente código de profesor: PROF-009, PROF-010, … */
    public String generarCodigoProfesor(Connection con) throws SQLException {
        String sql = "SELECT IFNULL(MAX(CAST(SUBSTRING(codigo,6) AS UNSIGNED)),0)+1 "
                   + "FROM profesores WHERE codigo LIKE 'PROF-%'";
        try (Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return String.format("PROF-%03d", rs.getInt(1));
        }
    }

    /**
     * Genera ID institucional para extranjero: E-8-0001, E-8-0002, …
     * Consulta ambas tablas para garantizar unicidad global.
     */
    public String generarIdExtranjero(Connection con) throws SQLException {
        String sql = "SELECT IFNULL(MAX(n),0)+1 FROM ("
                   + "  SELECT CAST(SUBSTRING_INDEX(cedula,'-',-1) AS UNSIGNED) AS n"
                   + "    FROM estudiantes WHERE cedula LIKE 'E-8-%'"
                   + "  UNION ALL"
                   + "  SELECT CAST(SUBSTRING_INDEX(codigo,'-',-1) AS UNSIGNED) AS n"
                   + "    FROM profesores WHERE codigo LIKE 'E-8-%'"
                   + ") t";
        try (Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return String.format("E-8-%04d", rs.getInt(1));
        }
    }

    // ── Validaciones ─────────────────────────────────────────────────────

    /** Formato cédula panameña: X-XXXX-XXXX (sólo dígitos y guiones). */
    public boolean validarCedulaPanamena(String cedula) {
        if (cedula == null) return false;
        return cedula.matches("^[1-9][0-9]*-[0-9]+-[0-9]+$");
    }

    /** true si la cédula ya existe en estudiantes. */
    public boolean existeCedula(Connection con, String cedula) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM estudiantes WHERE cedula = ?")) {
            ps.setString(1, cedula);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    /** true si el email ya existe en estudiantes o profesores. */
    public boolean existeEmail(Connection con, String email) throws SQLException {
        String sql = "SELECT COUNT(*) FROM ("
                   + "  SELECT email FROM estudiantes WHERE email = ?"
                   + "  UNION ALL"
                   + "  SELECT email FROM profesores   WHERE email = ?"
                   + ") t";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setString(2, email);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    // ── Lookups de catálogos ──────────────────────────────────────────────

    private int obtenerFacultadId(Connection con) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT id FROM facultades WHERE codigo = 'FSC' LIMIT 1")) {
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
                throw new SQLException(
                    "Facultad FSC no encontrada. Ejecute crear_usuarios_schema.sql");
            }
        }
    }

    private int obtenerCarreraId(Connection con) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT id FROM carreras WHERE codigo = 'ISC' LIMIT 1")) {
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
                throw new SQLException(
                    "Carrera ISC no encontrada. Ejecute crear_usuarios_schema.sql");
            }
        }
    }

    // ── Listados para el formulario ───────────────────────────────────────

    /** Retorna usuarios creados (estudiantes + profesores) ordenados por fecha de creación descendente. */
    public List<Map<String, Object>> listarUsuariosCreados() throws SQLException {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql =
            "SELECT u.id, u.username, u.rol, u.activo, e.nombre, e.apellido, e.email, e.cedula AS documento"
          + "  FROM usuarios u JOIN estudiantes e ON e.usuario_id = u.id"
          + " UNION ALL"
          + " SELECT u.id, u.username, u.rol, u.activo, p.nombre, p.apellido, p.email, p.codigo AS documento"
          + "  FROM usuarios u JOIN profesores p ON p.usuario_id = u.id"
          + " ORDER BY id DESC LIMIT 100";
        try (Connection con = ConexionDB.obtenerConexion();
             Statement st  = con.createStatement();
             ResultSet rs  = st.executeQuery(sql)) {
            while (rs.next()) {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("username",  rs.getString("username"));
                m.put("nombre",    rs.getString("nombre") + " " + rs.getString("apellido"));
                m.put("rol",       rs.getString("rol"));
                m.put("email",     rs.getString("email"));
                m.put("documento", rs.getString("documento"));
                m.put("activo",    rs.getInt("activo") == 1);
                lista.add(m);
            }
        }
        return lista;
    }

    /** Retorna todas las materias ordenadas por nombre. */
    public List<Map<String, Object>> listarMaterias() throws SQLException {
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             Statement st  = con.createStatement();
             ResultSet rs  = st.executeQuery(
                     "SELECT id, codigo, nombre, creditos FROM materias ORDER BY nombre")) {
            while (rs.next()) {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("id",       rs.getInt("id"));
                m.put("codigo",   rs.getString("codigo"));
                m.put("nombre",   rs.getString("nombre"));
                m.put("creditos", rs.getInt("creditos"));
                lista.add(m);
            }
        }
        return lista;
    }

    /** Retorna todos los grupos con el nombre y código de su materia. */
    public List<Map<String, Object>> listarGruposDisponibles() throws SQLException {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql = "SELECT g.id, g.codigo_grupo, m.nombre AS materia, m.codigo AS mat_codigo,"
                   + "       g.semestre, g.aula "
                   + "FROM grupos g JOIN materias m ON m.id = g.materia_id ORDER BY m.nombre";
        try (Connection con = ConexionDB.obtenerConexion();
             Statement st  = con.createStatement();
             ResultSet rs  = st.executeQuery(sql)) {
            while (rs.next()) {
                Map<String, Object> g = new LinkedHashMap<>();
                g.put("id",          rs.getInt("id"));
                g.put("codigoGrupo", rs.getString("codigo_grupo"));
                g.put("materia",     rs.getString("materia"));
                g.put("matCodigo",   rs.getString("mat_codigo"));
                g.put("semestre",    rs.getString("semestre"));
                g.put("aula",        rs.getString("aula"));
                lista.add(g);
            }
        }
        return lista;
    }

    // ── Crear Estudiante ──────────────────────────────────────────────────

    /**
     * Inserta un estudiante en una transacción atómica.
     * Pasos: validación → generar ID → INSERT usuarios → INSERT estudiantes → commit.
     *
     * @return Mapa con ok, username, passwordInicial, idDocumento, tipoId.
     * @throws IllegalArgumentException Si alguna validación falla (capturado como 400 en el servlet).
     * @throws SQLException             Si ocurre error de BD.
     */
    public Map<String, Object> crearEstudiante(
            String nombre,      String apellido, String cedula,
            String email,       String telefono, int    semestre,
            String nacionalidad, boolean esExtranjero) throws SQLException {

        try (Connection con = ConexionDB.obtenerConexion()) {
            con.setAutoCommit(false);
            try {
                // Validaciones
                if (!esExtranjero && !validarCedulaPanamena(cedula)) {
                    throw new IllegalArgumentException(
                        "Formato de cédula panameña inválido. Use: 8-1042-245");
                }
                if (existeEmail(con, email)) {
                    throw new IllegalArgumentException(
                        "El email ya está registrado en el sistema.");
                }

                String idDocumento;
                if (esExtranjero) {
                    idDocumento = generarIdExtranjero(con);
                } else {
                    if (existeCedula(con, cedula))
                        throw new IllegalArgumentException("La cédula ya está registrada.");
                    idDocumento = cedula;
                }

                int    facultadId = obtenerFacultadId(con);
                int    carreraId  = obtenerCarreraId(con);
                String username   = generarUsername(con, nombre, apellido);
                String passHash   = UsuarioDAO.sha256("estudiante123");
                String tipoId     = esExtranjero ? "extranjero" : "cedula";

                // INSERT usuarios
                int usuarioId;
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO usuarios (username, password, rol, activo) VALUES (?,?,'estudiante',1)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, username);
                    ps.setString(2, passHash);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) { rs.next(); usuarioId = rs.getInt(1); }
                }

                // INSERT estudiantes
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO estudiantes "
                      + "(usuario_id, cedula, nombre, apellido, email, telefono, semestre,"
                      + " carrera, carrera_id, facultad_id, nacionalidad, tipo_identificacion)"
                      + " VALUES (?,?,?,?,?,?,?,?,?,?,?,?)")) {
                    ps.setInt(1, usuarioId);
                    ps.setString(2, idDocumento);
                    ps.setString(3, nombre);
                    ps.setString(4, apellido);
                    ps.setString(5, email);
                    ps.setString(6, (telefono != null && !telefono.isEmpty()) ? telefono : null);
                    ps.setInt(7, semestre);
                    ps.setString(8, "Ingeniería en Sistemas Computacionales");
                    ps.setInt(9, carreraId);
                    ps.setInt(10, facultadId);
                    ps.setString(11, (nacionalidad != null) ? nacionalidad : "panameño");
                    ps.setString(12, tipoId);
                    ps.executeUpdate();
                }

                con.commit();

                Map<String, Object> r = new LinkedHashMap<>();
                r.put("ok",             true);
                r.put("username",        username);
                r.put("passwordInicial", "estudiante123");
                r.put("idDocumento",     idDocumento);
                r.put("tipoId",          tipoId);
                return r;

            } catch (Exception ex) {
                con.rollback();
                if (ex instanceof SQLException) throw (SQLException) ex;
                throw new SQLException(ex.getMessage(), ex);
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    // ── Crear Profesor ────────────────────────────────────────────────────

    /**
     * Inserta un profesor en una transacción atómica.
     * Pasos: validación → generar código → INSERT usuarios → INSERT profesores
     *         → INSERT profesor_materias → commit.
     *
     * @return Mapa con ok, username, passwordInicial, codigo, idDocumento, tipoId.
     */
    public Map<String, Object> crearProfesor(
            String nombre,       String apellido,   String cedula,
            String email,        String telefono,   String departamento,
            String nacionalidad, boolean esExtranjero,
            List<Integer> materiaIds) throws SQLException {

        try (Connection con = ConexionDB.obtenerConexion()) {
            con.setAutoCommit(false);
            try {
                // Validaciones
                if (!esExtranjero && cedula != null && !cedula.isEmpty()
                        && !validarCedulaPanamena(cedula)) {
                    throw new IllegalArgumentException("Formato de cédula panameña inválido.");
                }
                if (existeEmail(con, email)) {
                    throw new IllegalArgumentException(
                        "El email ya está registrado en el sistema.");
                }
                if (!esExtranjero && cedula != null && !cedula.isEmpty()) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "SELECT COUNT(*) FROM profesores WHERE codigo = ?")) {
                        ps.setString(1, cedula);
                        try (ResultSet rs = ps.executeQuery()) {
                            rs.next();
                            if (rs.getInt(1) > 0)
                                throw new IllegalArgumentException("La cédula ya está registrada.");
                        }
                    }
                }

                int    facultadId = obtenerFacultadId(con);
                String codigo     = generarCodigoProfesor(con);
                String username   = generarUsername(con, nombre, apellido);
                String passHash   = UsuarioDAO.sha256("profesor123");
                String idDoc      = esExtranjero ? generarIdExtranjero(con)
                                                 : (cedula != null ? cedula : "");
                String tipoId     = esExtranjero ? "extranjero" : "cedula";

                // INSERT usuarios
                int usuarioId;
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO usuarios (username, password, rol, activo) VALUES (?,?,'profesor',1)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, username);
                    ps.setString(2, passHash);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) { rs.next(); usuarioId = rs.getInt(1); }
                }

                // INSERT profesores
                int profesorId;
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO profesores "
                      + "(usuario_id, codigo, nombre, apellido, email, telefono,"
                      + " departamento, facultad_id, nacionalidad, tipo_identificacion)"
                      + " VALUES (?,?,?,?,?,?,?,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, usuarioId);
                    ps.setString(2, codigo);
                    ps.setString(3, nombre);
                    ps.setString(4, apellido);
                    ps.setString(5, email);
                    ps.setString(6, (telefono != null && !telefono.isEmpty()) ? telefono : null);
                    ps.setString(7, (departamento != null) ? departamento : "Sistemas");
                    ps.setInt(8, facultadId);
                    ps.setString(9, (nacionalidad != null) ? nacionalidad : "panameño");
                    ps.setString(10, tipoId);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) { rs.next(); profesorId = rs.getInt(1); }
                }

                // INSERT profesor_materias (batch)
                if (materiaIds != null && !materiaIds.isEmpty()) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "INSERT IGNORE INTO profesor_materias (profesor_id, materia_id) VALUES (?,?)")) {
                        for (int matId : materiaIds) {
                            ps.setInt(1, profesorId);
                            ps.setInt(2, matId);
                            ps.addBatch();
                        }
                        ps.executeBatch();
                    }
                }

                con.commit();

                Map<String, Object> r = new LinkedHashMap<>();
                r.put("ok",             true);
                r.put("username",        username);
                r.put("passwordInicial", "profesor123");
                r.put("codigo",          codigo);
                r.put("idDocumento",     idDoc);
                r.put("tipoId",          tipoId);
                return r;

            } catch (Exception ex) {
                con.rollback();
                if (ex instanceof SQLException) throw (SQLException) ex;
                throw new SQLException(ex.getMessage(), ex);
            } finally {
                con.setAutoCommit(true);
            }
        }
    }
}

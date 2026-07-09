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

    /** Solo letras (incluyendo tildes, ñ, ü) y espacios simples entre palabras. */
    public boolean validarNombreApellido(String valor) {
        if (valor == null || valor.trim().isEmpty()) return false;
        return valor.trim().matches("^[\\p{L} ]+$");
    }

    /** Teléfono panameño: debe empezar con 6, sin letras ni caracteres especiales (guion opcional). */
    public boolean validarTelefono(String telefono) {
        if (telefono == null || telefono.trim().isEmpty()) return false;
        return telefono.trim().matches("^6[0-9]{3}-[0-9]{4}$|^6[0-9]{6,7}$");
    }

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

    private String obtenerNombreCarrera(Connection con, int carreraId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT nombre FROM carreras WHERE id = ?")) {
            ps.setInt(1, carreraId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("nombre");
                throw new SQLException("Carrera con id " + carreraId + " no encontrada.");
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
     * Pasos: validación → generar ID → INSERT usuarios → INSERT estudiantes
     *        → (opcional) matricular en un salón inicial → commit.
     *
     * @param carreraId          Carrera a la que pertenece; si es null, se usa la carrera por defecto (ISC).
     * @param grupoIdsIniciales  Grupos (uno por materia del salón elegido) donde matricularlo de una vez (opcional); valida cupo en cada uno.
     * @return Mapa con ok, username, passwordInicial, idDocumento, tipoId.
     * @throws IllegalArgumentException Si alguna validación falla (capturado como 400 en el servlet).
     * @throws SQLException             Si ocurre error de BD.
     */
    public Map<String, Object> crearEstudiante(
            String nombre,      String apellido, String cedula,
            String email,       String telefono, int    semestre,
            String nacionalidad, boolean esExtranjero,
            Integer carreraId,  List<Integer> grupoIdsIniciales) throws SQLException {

        try (Connection con = ConexionDB.obtenerConexion()) {
            con.setAutoCommit(false);
            try {
                // Validaciones de datos
                if (!validarNombreApellido(nombre))
                    throw new IllegalArgumentException("El nombre solo puede contener letras.");
                if (!validarNombreApellido(apellido))
                    throw new IllegalArgumentException("El apellido solo puede contener letras.");
                if (!validarTelefono(telefono))
                    throw new IllegalArgumentException("El teléfono es obligatorio. Formato: 6123-4567.");
                if (!esExtranjero && !validarCedulaPanamena(cedula))
                    throw new IllegalArgumentException("Formato de cédula panameña inválido. Use: 8-1042-245");

                String idDocumento;
                if (esExtranjero) {
                    idDocumento = generarIdExtranjero(con);
                } else {
                    if (existeCedula(con, cedula))
                        throw new IllegalArgumentException("La cédula ya está registrada.");
                    idDocumento = cedula;
                }

                int    facultadId    = obtenerFacultadId(con);
                int    carreraIdReal = (carreraId != null) ? carreraId : obtenerCarreraId(con);
                String carreraNombre = obtenerNombreCarrera(con, carreraIdReal);
                String username      = generarUsername(con, nombre, apellido);
                // El correo se deriva del username ya-unico (no del valor enviado por el
                // formulario) para que dos personas con el mismo nombre nunca choquen: el
                // campo del formulario es de solo lectura y solo sirve de vista previa.
                String emailReal     = username + "@delta.edu";
                String passHash      = UsuarioDAO.sha256("estudiante123");
                String tipoId        = esExtranjero ? "extranjero" : "cedula";

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
                int estudianteId;
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO estudiantes "
                      + "(usuario_id, cedula, nombre, apellido, email, telefono, semestre,"
                      + " carrera, carrera_id, facultad_id, nacionalidad, tipo_identificacion)"
                      + " VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, usuarioId);
                    ps.setString(2, idDocumento);
                    ps.setString(3, nombre);
                    ps.setString(4, apellido);
                    ps.setString(5, emailReal);
                    ps.setString(6, (telefono != null && !telefono.isEmpty()) ? telefono : null);
                    ps.setInt(7, semestre);
                    ps.setString(8, carreraNombre);
                    ps.setInt(9, carreraIdReal);
                    ps.setInt(10, facultadId);
                    ps.setString(11, (nacionalidad != null) ? nacionalidad : "panameño");
                    ps.setString(12, tipoId);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) { rs.next(); estudianteId = rs.getInt(1); }
                }

                // Matricula inicial opcional en un salon (numero de aula): como el
                // aula es compartida por todas las materias de la carrera, se
                // matricula al estudiante de una vez en el grupo correspondiente
                // de CADA una de esas materias (accion administrativa, no pasa
                // por solicitudes_matricula).
                if (grupoIdsIniciales != null && !grupoIdsIniciales.isEmpty()) {
                    for (int grupoId : grupoIdsIniciales) {
                        int capacidad = 0, ocupados = 0;
                        try (PreparedStatement ps = con.prepareStatement(
                                "SELECT capacidad, (SELECT COUNT(*) FROM inscripciones i "
                              + "WHERE i.grupo_id = g.id AND i.estado='activo') AS ocupados "
                              + "FROM grupos g WHERE g.id = ?")) {
                            ps.setInt(1, grupoId);
                            try (ResultSet rs = ps.executeQuery()) {
                                if (!rs.next()) throw new IllegalArgumentException("Uno de los salones elegidos no fue encontrado.");
                                capacidad = rs.getInt("capacidad");
                                ocupados  = rs.getInt("ocupados");
                            }
                        }
                        if (ocupados >= capacidad)
                            throw new IllegalArgumentException("Ya no hay cupo disponible en uno de los salones elegidos.");

                        try (PreparedStatement ps = con.prepareStatement(
                                "INSERT INTO inscripciones (estudiante_id, grupo_id, estado) VALUES (?,?,'activo')")) {
                            ps.setInt(1, estudianteId);
                            ps.setInt(2, grupoId);
                            ps.executeUpdate();
                        }
                    }
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
            String nacionalidad, boolean esExtranjero) throws SQLException {

        try (Connection con = ConexionDB.obtenerConexion()) {
            con.setAutoCommit(false);
            try {
                // Validaciones
                if (!validarNombreApellido(nombre))
                    throw new IllegalArgumentException("El nombre solo puede contener letras.");
                if (!validarNombreApellido(apellido))
                    throw new IllegalArgumentException("El apellido solo puede contener letras.");
                if (!validarTelefono(telefono))
                    throw new IllegalArgumentException("El teléfono debe empezar con 6 y contener solo números. Formato: 6123-4567.");
                if (!esExtranjero && cedula != null && !cedula.isEmpty()
                        && !validarCedulaPanamena(cedula)) {
                    throw new IllegalArgumentException("Formato de cédula panameña inválido.");
                }
                if (!esExtranjero && cedula != null && !cedula.isEmpty()) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "SELECT COUNT(*) FROM profesores WHERE cedula = ?")) {
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
                // El correo se deriva del username ya-unico (no del valor enviado por el
                // formulario) para que dos profesores con el mismo nombre nunca choquen: el
                // campo del formulario es de solo lectura y solo sirve de vista previa.
                String emailReal  = username + "@delta.edu";
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
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO profesores "
                      + "(usuario_id, codigo, cedula, nombre, apellido, email, telefono,"
                      + " departamento, facultad_id, nacionalidad, tipo_identificacion)"
                      + " VALUES (?,?,?,?,?,?,?,?,?,?,?)")) {
                    ps.setInt(1, usuarioId);
                    ps.setString(2, codigo);
                    ps.setString(3, idDoc);
                    ps.setString(4, nombre);
                    ps.setString(5, apellido);
                    ps.setString(6, emailReal);
                    ps.setString(7, (telefono != null && !telefono.isEmpty()) ? telefono : null);
                    ps.setString(8, (departamento != null) ? departamento : "Sistemas");
                    ps.setInt(9, facultadId);
                    ps.setString(10, (nacionalidad != null) ? nacionalidad : "panameño");
                    ps.setString(11, tipoId);
                    ps.executeUpdate();
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

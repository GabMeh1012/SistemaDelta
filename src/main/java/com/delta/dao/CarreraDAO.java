package com.delta.dao;

import com.delta.util.ConexionDB;

import java.sql.*;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Acceso a datos para carreras, periodos academicos y salones (grupos) con
 * su horario, incluyendo las validaciones de tope de salones, choque de
 * aula y horario dentro de 7:00am-3:00pm.
 */
public class CarreraDAO {

    private static final LocalTime HORA_MIN = LocalTime.of(7, 0);
    private static final LocalTime HORA_MAX = LocalTime.of(15, 0);
    private static final int MAX_SALONES_POR_MATERIA = 3;

    // ============================================================
    // CARRERAS
    // ============================================================

    public List<Map<String, Object>> listarFacultades() throws SQLException {
        String sql = "SELECT id, nombre, codigo FROM facultades ORDER BY nombre";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("nombre", rs.getString("nombre"));
                row.put("codigo", rs.getString("codigo"));
                lista.add(row);
            }
        }
        return lista;
    }

    public List<Map<String, Object>> listarCarreras() throws SQLException {
        String sql = "SELECT c.id, c.nombre, c.codigo, f.nombre AS facultad "
                   + "FROM carreras c JOIN facultades f ON f.id = c.facultad_id "
                   + "ORDER BY c.nombre";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("nombre", rs.getString("nombre"));
                row.put("codigo", rs.getString("codigo"));
                row.put("facultad", rs.getString("facultad"));
                lista.add(row);
            }
        }
        return lista;
    }

    public List<Map<String, Object>> listarMateriasPorCarrera(int carreraId) throws SQLException {
        String sql = "SELECT id, codigo, nombre FROM materias WHERE carrera_id = ? ORDER BY nombre";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, carreraId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("codigo", rs.getString("codigo"));
                    row.put("nombre", rs.getString("nombre"));
                    lista.add(row);
                }
            }
        }
        return lista;
    }

    /** Salones de una materia con su ocupacion, para elegir a cual matricular a un estudiante nuevo. */
    public List<Map<String, Object>> listarSalonesDeMateria(int materiaId) throws SQLException {
        String sql = "SELECT g.id AS grupo_id, g.codigo_grupo, g.aula, g.capacidad, "
                   + "CONCAT(p.nombre,' ',p.apellido) AS profesor, "
                   + "(SELECT COUNT(*) FROM inscripciones i WHERE i.grupo_id = g.id AND i.estado='activo') AS ocupados, "
                   + "(SELECT GROUP_CONCAT(CONCAT(h.dia_semana,' ',TIME_FORMAT(h.hora_inicio,'%h:%i%p'),'-',TIME_FORMAT(h.hora_fin,'%h:%i%p')) SEPARATOR ' / ') "
                   + " FROM horarios h WHERE h.grupo_id = g.id) AS horario "
                   + "FROM grupos g LEFT JOIN profesores p ON p.id = g.profesor_id "
                   + "WHERE g.materia_id = ? ORDER BY g.codigo_grupo";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, materiaId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("grupoId", rs.getInt("grupo_id"));
                    row.put("codigoGrupo", rs.getString("codigo_grupo"));
                    row.put("aula", rs.getString("aula"));
                    row.put("capacidad", rs.getInt("capacidad"));
                    row.put("profesor", rs.getString("profesor"));
                    row.put("ocupados", rs.getInt("ocupados"));
                    row.put("horario", rs.getString("horario"));
                    lista.add(row);
                }
            }
        }
        return lista;
    }

    /**
     * Todos los salones de TODAS las materias de una carrera, en un solo listado
     * (para elegir directamente el salón al crear un estudiante, sin tener que
     * elegir primero la materia).
     */
    /**
     * Lista los "salones" de una carrera agrupados por aula: como el aula de
     * cada numero de salon es compartida por TODAS las materias de la
     * carrera, matricular a un estudiante en un salon significa inscribirlo
     * de una vez en el grupo correspondiente de cada una de las materias que
     * comparten esa aula (no una materia a la vez).
     */
    public List<Map<String, Object>> listarSalonesPorCarrera(int carreraId) throws SQLException {
        String sql = "SELECT g.id AS grupo_id, g.aula, g.capacidad, "
                   + "m.codigo AS materia_codigo, m.nombre AS materia_nombre, "
                   + "(SELECT COUNT(*) FROM inscripciones i WHERE i.grupo_id = g.id AND i.estado='activo') AS ocupados "
                   + "FROM grupos g "
                   + "JOIN materias m ON m.id = g.materia_id "
                   + "WHERE m.carrera_id = ? "
                   + "ORDER BY g.aula, m.codigo";
        Map<String, Map<String, Object>> porAula = new LinkedHashMap<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, carreraId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String aula = rs.getString("aula");
                    Map<String, Object> grupo = porAula.computeIfAbsent(aula, a -> {
                        Map<String, Object> nuevo = new LinkedHashMap<>();
                        nuevo.put("aula", a);
                        nuevo.put("grupoIds", new ArrayList<Integer>());
                        nuevo.put("materias", new ArrayList<String>());
                        nuevo.put("totalMaterias", 0);
                        nuevo.put("cupoMinimo", Integer.MAX_VALUE);
                        return nuevo;
                    });
                    int capacidad = rs.getInt("capacidad");
                    int ocupados = rs.getInt("ocupados");
                    int disponible = capacidad - ocupados;
                    @SuppressWarnings("unchecked")
                    List<Integer> grupoIds = (List<Integer>) grupo.get("grupoIds");
                    grupoIds.add(rs.getInt("grupo_id"));
                    @SuppressWarnings("unchecked")
                    List<String> materias = (List<String>) grupo.get("materias");
                    materias.add(rs.getString("materia_codigo") + " " + rs.getString("materia_nombre"));
                    grupo.put("totalMaterias", (Integer) grupo.get("totalMaterias") + 1);
                    grupo.put("cupoMinimo", Math.min((Integer) grupo.get("cupoMinimo"), disponible));
                }
            }
        }
        return new ArrayList<>(porAula.values());
    }

    /** Materias sin carrera asignada todavia (candidatas para vincular a una carrera nueva). */
    public List<Map<String, Object>> listarMateriasSinCarrera() throws SQLException {
        String sql = "SELECT id, codigo, nombre, creditos FROM materias WHERE carrera_id IS NULL ORDER BY nombre";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("codigo", rs.getString("codigo"));
                row.put("nombre", rs.getString("nombre"));
                row.put("creditos", rs.getInt("creditos"));
                lista.add(row);
            }
        }
        return lista;
    }

    /**
     * Crea una carrera nueva vinculando exactamente 6 materias: una mezcla de
     * materias existentes (por id, deben estar sin carrera) y materias nuevas
     * (definidas inline: codigo, nombre, creditos, nivel). Para cada materia
     * nueva, tambien crea sus salones (1 a 3): el primero con el horario
     * indicado, los siguientes heredandolo y solo con aula propia. Todo en
     * una sola transaccion — si algo falla, no se crea nada.
     *
     * @param salonesPorMateriaNueva mismo tamaño/orden que materiasNuevas; cada entrada trae
     *        "aulas" (List&lt;String&gt;, una por salon) y "horario" (List&lt;Map&gt; bloques del salon 1).
     */
    public int crearCarrera(String nombre, String codigo, int facultadId,
                             List<Integer> materiaIdsExistentes,
                             List<Map<String, Object>> materiasNuevas,
                             List<Map<String, Object>> salonesPorMateriaNueva) throws SQLException {
        if (nombre == null || nombre.trim().isEmpty())
            throw new SQLException("El nombre de la carrera es obligatorio.");
        if (codigo == null || codigo.trim().isEmpty())
            throw new SQLException("El código de la carrera es obligatorio.");

        int totalMaterias = (materiaIdsExistentes == null ? 0 : materiaIdsExistentes.size())
                           + (materiasNuevas == null ? 0 : materiasNuevas.size());
        if (totalMaterias != 6) {
            throw new SQLException("Una carrera debe tener exactamente 6 materias (recibidas: " + totalMaterias + ").");
        }

        try (Connection con = ConexionDB.obtenerConexion()) {
            con.setAutoCommit(false);
            try {
                if (materiaIdsExistentes != null) {
                    for (int materiaId : materiaIdsExistentes) {
                        try (PreparedStatement ps = con.prepareStatement(
                                "SELECT carrera_id FROM materias WHERE id = ?")) {
                            ps.setInt(1, materiaId);
                            try (ResultSet rs = ps.executeQuery()) {
                                if (!rs.next())
                                    throw new SQLException("Materia con id " + materiaId + " no encontrada.");
                                rs.getInt("carrera_id");
                                if (!rs.wasNull())
                                    throw new SQLException("La materia con id " + materiaId + " ya pertenece a otra carrera.");
                            }
                        }
                    }
                }

                int carreraId;
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO carreras (nombre, codigo, facultad_id) VALUES (?,?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, nombre);
                    ps.setString(2, codigo);
                    ps.setInt(3, facultadId);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) { rs.next(); carreraId = rs.getInt(1); }
                }

                if (materiaIdsExistentes != null && !materiaIdsExistentes.isEmpty()) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE materias SET carrera_id=? WHERE id=?")) {
                        for (int materiaId : materiaIdsExistentes) {
                            ps.setInt(1, carreraId);
                            ps.setInt(2, materiaId);
                            ps.addBatch();
                        }
                        ps.executeBatch();
                    }
                }

                if (materiasNuevas != null && !materiasNuevas.isEmpty()) {
                    String periodoActivo = obtenerPeriodoActivo(con);
                    for (int i = 0; i < materiasNuevas.size(); i++) {
                        Map<String, Object> m = materiasNuevas.get(i);
                        String matCodigo = (String) m.get("codigo");
                        int materiaId;
                        try (PreparedStatement ps = con.prepareStatement(
                                "INSERT INTO materias (codigo, nombre, creditos, carrera_id, nivel) VALUES (?,?,?,?,?)",
                                Statement.RETURN_GENERATED_KEYS)) {
                            ps.setString(1, matCodigo);
                            ps.setString(2, (String) m.get("nombre"));
                            Object creditos = m.get("creditos");
                            ps.setInt(3, creditos != null ? (Integer) creditos : 3);
                            ps.setInt(4, carreraId);
                            Object nivel = m.get("nivel");
                            if (nivel != null) ps.setInt(5, (Integer) nivel); else ps.setNull(5, Types.INTEGER);
                            ps.executeUpdate();
                            try (ResultSet rs = ps.getGeneratedKeys()) { rs.next(); materiaId = rs.getInt(1); }
                        }

                        Map<String, Object> salonesInfo = (salonesPorMateriaNueva != null && i < salonesPorMateriaNueva.size())
                                ? salonesPorMateriaNueva.get(i) : null;
                        if (salonesInfo != null) {
                            @SuppressWarnings("unchecked")
                            List<String> aulas = (List<String>) salonesInfo.get("aulas");
                            @SuppressWarnings("unchecked")
                            List<Map<String, Object>> horarioSalon1 = (List<Map<String, Object>>) salonesInfo.get("horario");
                            String[] sufijos = {"A", "B", "C"};
                            for (int s = 0; s < aulas.size(); s++) {
                                String codigoGrupo = "GRP-" + matCodigo + "-" + sufijos[s];
                                crearGrupoTx(con, materiaId, codigoGrupo, aulas.get(s), 30, periodoActivo,
                                        s == 0 ? horarioSalon1 : null);
                            }
                        }
                    }
                }

                con.commit();
                return carreraId;
            } catch (Exception ex) {
                con.rollback();
                if (ex instanceof SQLException) throw (SQLException) ex;
                throw new SQLException(ex.getMessage(), ex);
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    private String obtenerPeriodoActivo(Connection con) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("SELECT codigo FROM periodos WHERE activo = 1 LIMIT 1")) {
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("codigo");
                throw new SQLException("No hay un periodo activo configurado.");
            }
        }
    }

    // ============================================================
    // PERIODOS ACADEMICOS
    // ============================================================

    public List<Map<String, Object>> listarPeriodos() throws SQLException {
        String sql = "SELECT codigo, nombre, activo FROM periodos ORDER BY codigo DESC";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("codigo", rs.getString("codigo"));
                row.put("nombre", rs.getString("nombre"));
                row.put("activo", rs.getBoolean("activo"));
                lista.add(row);
            }
        }
        return lista;
    }

    public void crearPeriodo(String codigo, String nombre, String fechaInicio, String fechaFin) throws SQLException {
        if (codigo == null || codigo.trim().isEmpty())
            throw new SQLException("El código del periodo es obligatorio.");
        String sql = "INSERT INTO periodos (codigo, nombre, fecha_inicio, fecha_fin) VALUES (?,?,?,?)";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, codigo);
            ps.setString(2, nombre);
            if (fechaInicio != null && !fechaInicio.isEmpty()) ps.setDate(3, Date.valueOf(fechaInicio));
            else ps.setNull(3, Types.DATE);
            if (fechaFin != null && !fechaFin.isEmpty()) ps.setDate(4, Date.valueOf(fechaFin));
            else ps.setNull(4, Types.DATE);
            ps.executeUpdate();
        }
    }

    /** Marca un periodo como activo y desactiva cualquier otro. */
    public void activarPeriodo(String codigo) throws SQLException {
        try (Connection con = ConexionDB.obtenerConexion()) {
            con.setAutoCommit(false);
            try {
                try (PreparedStatement ps = con.prepareStatement("UPDATE periodos SET activo = 0")) {
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = con.prepareStatement("UPDATE periodos SET activo = 1 WHERE codigo = ?")) {
                    ps.setString(1, codigo);
                    if (ps.executeUpdate() == 0) throw new SQLException("Periodo no encontrado.");
                }
                con.commit();
            } catch (Exception ex) {
                con.rollback();
                if (ex instanceof SQLException) throw (SQLException) ex;
                throw new SQLException(ex.getMessage(), ex);
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    // ============================================================
    // SALONES (GRUPOS) Y HORARIOS
    // ============================================================

    /**
     * Crea un salon nuevo para una materia. Si es el primer salon de esa
     * materia, exige horarioBloques (cada bloque: dia, horaInicio, horaFin)
     * y valida que caiga entre 7:00am y 3:00pm. Si la materia ya tiene al
     * menos un salon, ignora horarioBloques y clona el horario del primero.
     * En ambos casos valida que ningun otro salon (cualquier materia, mismo
     * periodo) ocupe la misma aula en un horario que se cruce.
     */
    public int crearGrupo(int materiaId, String codigoGrupo, String aula, int capacidad,
                           String periodoCodigo, List<Map<String, Object>> horarioBloques) throws SQLException {
        try (Connection con = ConexionDB.obtenerConexion()) {
            con.setAutoCommit(false);
            try {
                int grupoId = crearGrupoTx(con, materiaId, codigoGrupo, aula, capacidad, periodoCodigo, horarioBloques);
                con.commit();
                return grupoId;
            } catch (Exception ex) {
                con.rollback();
                if (ex instanceof SQLException) throw (SQLException) ex;
                throw new SQLException(ex.getMessage(), ex);
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    /**
     * Version interna de crearGrupo que reutiliza una conexion/transaccion ya
     * abierta por el llamador (usada por crearCarrera para crear carrera +
     * materias + salones de forma atomica).
     */
    private int crearGrupoTx(Connection con, int materiaId, String codigoGrupo, String aula, int capacidad,
                              String periodoCodigo, List<Map<String, Object>> horarioBloques) throws SQLException {
        if (codigoGrupo == null || codigoGrupo.trim().isEmpty())
            throw new SQLException("El código de grupo es obligatorio.");
        if (aula == null || aula.trim().isEmpty())
            throw new SQLException("El aula es obligatoria.");
        if (capacidad <= 0)
            throw new SQLException("La capacidad debe ser mayor a 0.");

        int salonesExistentes = 0;
        Integer grupoBase = null;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) AS n, MIN(id) AS primer_grupo FROM grupos WHERE materia_id = ?")) {
            ps.setInt(1, materiaId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    salonesExistentes = rs.getInt("n");
                    grupoBase = rs.getInt("primer_grupo");
                    if (rs.wasNull()) grupoBase = null;
                }
            }
        }
        if (salonesExistentes >= MAX_SALONES_POR_MATERIA) {
            throw new SQLException("Esta materia ya tiene el máximo de " + MAX_SALONES_POR_MATERIA + " salones.");
        }

        List<String[]> bloques = new ArrayList<>(); // {diaSemana, horaInicio, horaFin}

        if (salonesExistentes == 0) {
            if (horarioBloques == null || horarioBloques.isEmpty())
                throw new SQLException("Debe definir al menos un bloque de horario para el primer salón de esta materia.");
            for (Map<String, Object> b : horarioBloques) {
                String dia = (String) b.get("dia");
                LocalTime hi, hf;
                try {
                    hi = LocalTime.parse((String) b.get("horaInicio"));
                    hf = LocalTime.parse((String) b.get("horaFin"));
                } catch (Exception e) {
                    throw new SQLException("Hora inválida en el horario.");
                }
                if (!hi.isBefore(hf))
                    throw new SQLException("La hora de inicio debe ser antes que la hora de fin.");
                if (hi.isBefore(HORA_MIN) || hf.isAfter(HORA_MAX))
                    throw new SQLException("El horario debe estar entre 7:00am y 3:00pm.");
                bloques.add(new String[]{dia, hi.toString(), hf.toString()});
            }
        } else {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT dia_semana, hora_inicio, hora_fin FROM horarios WHERE grupo_id = ?")) {
                ps.setInt(1, grupoBase);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        bloques.add(new String[]{
                            rs.getString("dia_semana"),
                            rs.getTime("hora_inicio").toLocalTime().toString(),
                            rs.getTime("hora_fin").toLocalTime().toString()
                        });
                    }
                }
            }
            if (bloques.isEmpty())
                throw new SQLException("El salón base de esta materia no tiene horario definido.");
        }

        // Choque de aula: mismo periodo, misma aula, dia con rango que se cruza
        for (String[] bloque : bloques) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT g.codigo_grupo FROM horarios h JOIN grupos g ON g.id = h.grupo_id "
                  + "WHERE g.aula = ? AND g.semestre = ? AND h.dia_semana = ? "
                  + "AND h.hora_inicio < ? AND ? < h.hora_fin")) {
                ps.setString(1, aula);
                ps.setString(2, periodoCodigo);
                ps.setString(3, bloque[0]);
                ps.setString(4, bloque[2]);
                ps.setString(5, bloque[1]);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next())
                        throw new SQLException("El aula '" + aula + "' ya está ocupada el " + bloque[0]
                            + " en ese horario (salón " + rs.getString("codigo_grupo") + ").");
                }
            }
        }

        int grupoId;
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO grupos (codigo_grupo, materia_id, profesor_id, semestre, aula, capacidad) "
              + "VALUES (?,?,NULL,?,?,?)",
                Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, codigoGrupo);
            ps.setInt(2, materiaId);
            ps.setString(3, periodoCodigo);
            ps.setString(4, aula);
            ps.setInt(5, capacidad);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) { rs.next(); grupoId = rs.getInt(1); }
        }

        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO horarios (grupo_id, dia_semana, hora_inicio, hora_fin) VALUES (?,?,?,?)")) {
            for (String[] bloque : bloques) {
                ps.setInt(1, grupoId);
                ps.setString(2, bloque[0]);
                ps.setString(3, bloque[1]);
                ps.setString(4, bloque[2]);
                ps.addBatch();
            }
            ps.executeBatch();
        }
        return grupoId;
    }

    public List<Map<String, Object>> listarHorarios(int grupoId) throws SQLException {
        String sql = "SELECT dia_semana, hora_inicio, hora_fin FROM horarios WHERE grupo_id = ? "
                   + "ORDER BY FIELD(dia_semana,'lunes','martes','miercoles','jueves','viernes','sabado'), hora_inicio";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, grupoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("dia", rs.getString("dia_semana"));
                    row.put("horaInicio", rs.getTime("hora_inicio").toLocalTime().toString());
                    row.put("horaFin", rs.getTime("hora_fin").toLocalTime().toString());
                    lista.add(row);
                }
            }
        }
        return lista;
    }

    public List<Map<String, Object>> listarSalonesSinProfesor(String periodoCodigo) throws SQLException {
        String sql = "SELECT g.id AS grupo_id, g.codigo_grupo, m.codigo AS materia_codigo, m.nombre AS materia_nombre, g.aula "
                   + "FROM grupos g JOIN materias m ON m.id = g.materia_id "
                   + "WHERE g.profesor_id IS NULL AND g.semestre = ? "
                   + "ORDER BY m.codigo, g.codigo_grupo";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, periodoCodigo);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("grupoId", rs.getInt("grupo_id"));
                    row.put("codigoGrupo", rs.getString("codigo_grupo"));
                    row.put("materiaCodigo", rs.getString("materia_codigo"));
                    row.put("materiaNombre", rs.getString("materia_nombre"));
                    row.put("aula", rs.getString("aula"));
                    lista.add(row);
                }
            }
        }
        return lista;
    }

    /** Profesores que ya tienen esta materia marcada en profesor_materias. */
    public List<Map<String, Object>> listarProfesoresPorMateria(int materiaId) throws SQLException {
        String sql = "SELECT p.id, CONCAT(p.nombre,' ',p.apellido) AS nombre "
                   + "FROM profesor_materias pm JOIN profesores p ON p.id = pm.profesor_id "
                   + "WHERE pm.materia_id = ? ORDER BY p.apellido, p.nombre";
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, materiaId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("nombre", rs.getString("nombre"));
                    lista.add(row);
                }
            }
        }
        return lista;
    }

}

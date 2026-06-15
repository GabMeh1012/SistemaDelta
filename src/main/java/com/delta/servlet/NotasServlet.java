package com.delta.servlet;

import com.delta.dao.SolicitudMatriculaDAO;
import com.delta.util.ConexionDB;
import com.delta.util.MatriculaHelper;
import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

/**
 * Gestiona calificaciones e inscripciones de estudiantes.
 *
 * GET  /notas?grupoId=X                  -> JSON lista notas del grupo
 * GET  /notas?accion=misNotas            -> JSON notas del estudiante en sesion
 * POST /notas (accion=inscribir)         -> crea solicitud de inscripcion pendiente
 * POST /notas (accion=desinscribir)      -> crea solicitud de retiro pendiente
 * POST /notas (form: inscripcionId, componente, nota) -> guarda/actualiza una nota
 */
public class NotasServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("usuarioId") == null) {
            resp.setStatus(401);
            resp.getWriter().print("{\"error\":\"no autenticado\"}");
            return;
        }

        String accionGet = req.getParameter("accion");
        PrintWriter out = resp.getWriter();

        // -- Notas del estudiante en sesion --
        if ("misNotas".equals(accionGet)) {
            String sql2 = "SELECT m.nombre AS materia, m.codigo, "
                       + "MAX(CASE WHEN n.componente='parcial1'     THEN n.nota END) AS p1, "
                       + "MAX(CASE WHEN n.componente='parcial2'     THEN n.nota END) AS p2, "
                       + "MAX(CASE WHEN n.componente='proyecto'     THEN n.nota END) AS proy, "
                       + "MAX(CASE WHEN n.componente='examen_final' THEN n.nota END) AS ef "
                       + "FROM inscripciones i "
                       + "JOIN estudiantes e ON e.id = i.estudiante_id "
                       + "JOIN grupos g ON g.id = i.grupo_id "
                       + "JOIN materias m ON m.id = g.materia_id "
                       + "LEFT JOIN notas n ON n.inscripcion_id = i.id "
                       + "WHERE e.usuario_id = ? AND i.estado = 'activo' "
                       + "GROUP BY m.id, m.nombre, m.codigo";
            try (Connection con = ConexionDB.obtenerConexion();
                 PreparedStatement ps2 = con.prepareStatement(sql2)) {
                ps2.setInt(1, (Integer) session.getAttribute("usuarioId"));
                try (ResultSet rs2 = ps2.executeQuery()) {
                    out.print("[");
                    boolean first2 = true;
                    while (rs2.next()) {
                        if (!first2) out.print(",");
                        first2 = false;
                        double p1   = rs2.getDouble("p1");   boolean np1   = rs2.wasNull();
                        double p2   = rs2.getDouble("p2");   boolean np2   = rs2.wasNull();
                        double proy = rs2.getDouble("proy");  boolean nproy = rs2.wasNull();
                        double ef   = rs2.getDouble("ef");   boolean nef   = rs2.wasNull();
                        double nota = 0;
                        if (!np1 || !np2 || !nproy || !nef) {
                            nota = Math.round(((np1?0:p1)*0.25 + (np2?0:p2)*0.25 + (nproy?0:proy)*0.20 + (nef?0:ef)*0.30) * 10.0) / 10.0;
                        }
                        out.print("{\"materia\":" + jStr(rs2.getString("materia"))
                            + ",\"codigo\":" + jStr(rs2.getString("codigo"))
                            + ",\"p1\":" + (np1?"null":p1)
                            + ",\"p2\":" + (np2?"null":p2)
                            + ",\"proy\":" + (nproy?"null":proy)
                            + ",\"ef\":" + (nef?"null":ef)
                            + ",\"nota\":" + nota + "}");
                    }
                    out.print("]");
                }
            } catch (SQLException e) {
                resp.setStatus(500);
                out.print("{\"error\":\"" + e.getMessage() + "\"}");
            }
            return;
        }

        String grupoIdStr = req.getParameter("grupoId");
        if (grupoIdStr == null) {
            resp.setStatus(400);
            out.print("{\"error\":\"grupoId requerido\"}");
            return;
        }

        int grupoId = Integer.parseInt(grupoIdStr);

        String sql = "SELECT e.id, CONCAT(e.nombre,' ',e.apellido) AS estudiante, "
                   + "i.id AS inscripcion_id, "
                   + "MAX(CASE WHEN n.componente='parcial1'     THEN n.nota END) AS p1, "
                   + "MAX(CASE WHEN n.componente='parcial2'     THEN n.nota END) AS p2, "
                   + "MAX(CASE WHEN n.componente='proyecto'     THEN n.nota END) AS proy, "
                   + "MAX(CASE WHEN n.componente='examen_final' THEN n.nota END) AS ef "
                   + "FROM inscripciones i "
                   + "JOIN estudiantes e ON e.id = i.estudiante_id "
                   + "LEFT JOIN notas n ON n.inscripcion_id = i.id "
                   + "WHERE i.grupo_id = ? AND i.estado = 'activo' "
                   + "GROUP BY e.id, i.id "
                   + "ORDER BY e.apellido";

        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, grupoId);
            try (ResultSet rs = ps.executeQuery()) {
                out.print("[");
                boolean first = true;
                while (rs.next()) {
                    if (!first) out.print(",");
                    first = false;
                    out.print("{"
                        + "\"id\":"             + rs.getInt("id")
                        + ",\"estudiante\":"    + jStr(rs.getString("estudiante"))
                        + ",\"inscripcionId\":" + rs.getInt("inscripcion_id")
                        + ",\"p1\":"            + nullableDouble(rs, "p1")
                        + ",\"p2\":"            + nullableDouble(rs, "p2")
                        + ",\"proy\":"          + nullableDouble(rs, "proy")
                        + ",\"ef\":"            + nullableDouble(rs, "ef")
                        + "}");
                }
                out.print("]");
            }
        } catch (SQLException e) {
            resp.setStatus(500);
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json;charset=UTF-8");

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("usuarioId") == null) {
            resp.setStatus(401);
            resp.getWriter().print("{\"error\":\"no autenticado\"}");
            return;
        }
        int usuarioId = (Integer) session.getAttribute("usuarioId");
        PrintWriter out = resp.getWriter();
        String accion = req.getParameter("accion");

        try {
            if ("inscribir".equals(accion)) {
                inscribir(usuarioId, req.getParameter("codigoMateria"), out);
                return;
            }
            if ("desinscribir".equals(accion)) {
                desinscribir(usuarioId, req.getParameter("codigoMateria"), out);
                return;
            }

            // Por defecto: guardar nota individual
            int    inscripcionId = Integer.parseInt(req.getParameter("inscripcionId"));
            String componente    = req.getParameter("componente");
            double nota          = Double.parseDouble(req.getParameter("nota"));

            guardarNota(inscripcionId, componente, nota, out);
        } catch (Exception e) {
            resp.setStatus(500);
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    /** Limite base de modificaciones permitidas por componente de nota, antes de requerir autorizacion. */
    private static final int LIMITE_MODIFICACIONES = 3;

    /**
     * Guarda/actualiza una nota. Si ya existe un valor distinto (es decir, es una
     * MODIFICACION y no el primer registro), valida el limite de modificaciones
     * permitido (LIMITE_MODIFICACIONES + autorizaciones del administrador) y, si
     * esta dentro del limite, registra el cambio en notas_historial.
     */
    private void guardarNota(int inscripcionId, String componente, double nota, PrintWriter out) throws SQLException, IOException {
        try (Connection con = ConexionDB.obtenerConexion()) {
            con.setAutoCommit(false);
            try {
                Double notaAnterior = null;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT nota FROM notas WHERE inscripcion_id=? AND componente=?")) {
                    ps.setInt(1, inscripcionId);
                    ps.setString(2, componente);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && !rs.wasNull()) {
                            double v = rs.getDouble(1);
                            if (!rs.wasNull()) notaAnterior = v;
                        }
                    }
                }

                boolean esModificacion = notaAnterior != null && Math.abs(notaAnterior - nota) > 1e-9;

                if (esModificacion) {
                    int modificaciones = contarModificaciones(con, inscripcionId, componente);
                    int autorizadas = contarAutorizaciones(con, inscripcionId, componente);
                    int limite = LIMITE_MODIFICACIONES + autorizadas;
                    if (modificaciones >= limite) {
                        con.rollback();
                        out.print("{\"error\":\"Ha alcanzado el limite de " + limite
                                + " modificaciones para esta nota. Solicite autorizacion al administrador.\"}");
                        return;
                    }
                }

                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO notas (inscripcion_id, componente, nota) VALUES (?,?,?) "
                      + "ON DUPLICATE KEY UPDATE nota=VALUES(nota)")) {
                    ps.setInt(1, inscripcionId);
                    ps.setString(2, componente);
                    ps.setDouble(3, nota);
                    ps.executeUpdate();
                }

                if (esModificacion) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "INSERT INTO notas_historial (inscripcion_id, componente, nota_anterior, nota_nueva) VALUES (?,?,?,?)")) {
                        ps.setInt(1, inscripcionId);
                        ps.setString(2, componente);
                        ps.setDouble(3, notaAnterior);
                        ps.setDouble(4, nota);
                        ps.executeUpdate();
                    }
                }

                con.commit();
                out.print("{\"ok\":true}");
            } catch (SQLException ex) {
                con.rollback();
                throw ex;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    private int contarModificaciones(Connection con, int inscripcionId, String componente) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM notas_historial WHERE inscripcion_id=? AND componente=?")) {
            ps.setInt(1, inscripcionId);
            ps.setString(2, componente);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    private int contarAutorizaciones(Connection con, int inscripcionId, String componente) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COALESCE(SUM(cantidad),0) FROM notas_autorizaciones WHERE inscripcion_id=? AND componente=?")) {
            ps.setInt(1, inscripcionId);
            ps.setString(2, componente);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    /**
     * Crea solicitud de inscripcion pendiente de aprobacion administrativa.
     */
    private void inscribir(int usuarioId, String codigoMateria, PrintWriter out) throws SQLException, IOException {
        if (codigoMateria == null || codigoMateria.trim().isEmpty()) {
            out.print("{\"error\":\"codigoMateria requerido\"}");
            return;
        }

        try (Connection con = ConexionDB.obtenerConexion()) {
            int estudianteId = MatriculaHelper.obtenerEstudianteId(con, usuarioId);
            if (estudianteId == -1) {
                out.print("{\"error\":\"estudiante no encontrado\"}");
                return;
            }
            int activas = MatriculaHelper.contarInscripcionesActivas(con, estudianteId);
            if (activas >= 6) {
                out.print("{\"error\":\"Ha alcanzado el limite de 6 materias permitidas.\"}");
                return;
            }
        }

        SolicitudMatriculaDAO dao = new SolicitudMatriculaDAO();
        try (Connection con = ConexionDB.obtenerConexion()) {
            int estudianteId = MatriculaHelper.obtenerEstudianteId(con, usuarioId);
            int solicitudId = dao.crearInscripcion(estudianteId, codigoMateria);
            out.print("{\"ok\":true,\"pendiente\":true,\"solicitudId\":" + solicitudId
                    + ",\"mensaje\":\"Su solicitud de inscripcion quedo pendiente de aprobacion.\"}");
        } catch (SQLException e) {
            out.print("{\"error\":\"" + e.getMessage().replace("\"", "'") + "\"}");
        }
    }

    /**
     * Crea solicitud de retiro pendiente de aprobacion administrativa.
     */
    private void desinscribir(int usuarioId, String codigoMateria, PrintWriter out) throws SQLException, IOException {
        if (codigoMateria == null || codigoMateria.trim().isEmpty()) {
            out.print("{\"error\":\"codigoMateria requerido\"}");
            return;
        }

        SolicitudMatriculaDAO dao = new SolicitudMatriculaDAO();
        try (Connection con = ConexionDB.obtenerConexion()) {
            int estudianteId = MatriculaHelper.obtenerEstudianteId(con, usuarioId);
            int solicitudId = dao.crearRetiro(estudianteId, codigoMateria);
            out.print("{\"ok\":true,\"pendiente\":true,\"solicitudId\":" + solicitudId
                    + ",\"mensaje\":\"Su solicitud de retiro quedo pendiente de aprobacion.\"}");
        } catch (SQLException e) {
            out.print("{\"error\":\"" + e.getMessage().replace("\"", "'") + "\"}");
        }
    }

    private int obtenerEstudianteId(Connection con, int usuarioId) throws SQLException {
        return MatriculaHelper.obtenerEstudianteId(con, usuarioId);
    }

    private int contarInscripcionesActivas(Connection con, int estudianteId) throws SQLException {
        return MatriculaHelper.contarInscripcionesActivas(con, estudianteId);
    }

    private String jStr(String s) {
        if (s == null) return "null";
        return "\"" + s.replace("\"", "\\\"") + "\"";
    }

    private String nullableDouble(ResultSet rs, String col) throws SQLException {
        double v = rs.getDouble(col);
        return rs.wasNull() ? "null" : String.valueOf(v);
    }
}

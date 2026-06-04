package com.delta.servlet;

import com.delta.util.ConexionDB;
import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

/**
 * Gestiona calificaciones de estudiantes.
 *
 * GET  /notas?grupoId=X          → JSON lista notas del grupo
 * POST /notas  (form: inscripcionId, componente, nota) → guarda / actualiza nota
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

        // ── Notas del estudiante en sesión ──
        if ("misNotas".equals(accionGet)) {
            String sql2 = "SELECT m.nombre AS materia, m.codigo, "
                       + "MAX(CASE WHEN n.componente='parcial1'     THEN n.nota END) AS p1, "
                       + "MAX(CASE WHEN n.componente='parcial2'     THEN n.nota END) AS p2, "
                       + "MAX(CASE WHEN n.componente='proyecto'     THEN n.nota END) AS proy, "
                       + "MAX(CASE WHEN n.componente='examen_final' THEN n.nota END) AS ef "
                       + "FROM inscripciones i "
                       + "JOIN estudiantes e ON e.usuario_id = ? "
                       + "JOIN grupos g ON g.id = i.grupo_id "
                       + "JOIN materias m ON m.id = g.materia_id "
                       + "LEFT JOIN notas n ON n.inscripcion_id = i.id "
                       + "WHERE i.estudiante_id = e.id AND i.estado = 'activo' "
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

        try {
            int    inscripcionId = Integer.parseInt(req.getParameter("inscripcionId"));
            String componente    = req.getParameter("componente");
            double nota          = Double.parseDouble(req.getParameter("nota"));

            String sql = "INSERT INTO notas (inscripcion_id, componente, nota) VALUES (?,?,?) "
                       + "ON DUPLICATE KEY UPDATE nota=VALUES(nota)";
            try (Connection con = ConexionDB.obtenerConexion();
                 PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, inscripcionId);
                ps.setString(2, componente);
                ps.setDouble(3, nota);
                ps.executeUpdate();
            }
            resp.getWriter().print("{\"ok\":true}");
        } catch (Exception e) {
            resp.setStatus(500);
            resp.getWriter().print("{\"error\":\"" + e.getMessage() + "\"}");
        }
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

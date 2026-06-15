package com.delta.servlet;

import com.delta.dao.AsistenciaDAO;
import com.delta.modelo.Asistencia;
import com.delta.util.ConexionDB;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Control de asistencia para profesores.
 *
 * GET  /asistencia?grupoId=43&desde=2026-06-09&hasta=2026-06-15
 *      -> JSON con la lista de estudiantes inscritos y su asistencia
 *         registrada en el rango de fechas (los dias sin registro no
 *         aparecen; el frontend los trata como "presente" por defecto).
 *
 * POST /asistencia
 *      params: inscripcionId, fecha (yyyy-MM-dd), estado (present|late|absent),
 *              observacion (opcional)
 *      -> crea o actualiza el registro de asistencia (upsert).
 */
public class AsistenciaServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("profesorId") == null) {
            resp.setStatus(401);
            out.print("{\"error\":\"no autenticado\"}");
            return;
        }
        int profesorId = (Integer) session.getAttribute("profesorId");

        Integer grupoId = parseInt(req.getParameter("grupoId"));
        String desdeStr = req.getParameter("desde");
        String hastaStr = req.getParameter("hasta");
        if (grupoId == null || desdeStr == null || hastaStr == null) {
            resp.setStatus(400);
            out.print("{\"error\":\"parametros requeridos: grupoId, desde, hasta\"}");
            return;
        }

        LocalDate desde, hasta;
        try {
            desde = LocalDate.parse(desdeStr);
            hasta = LocalDate.parse(hastaStr);
        } catch (Exception e) {
            resp.setStatus(400);
            out.print("{\"error\":\"formato de fecha invalido (use yyyy-MM-dd)\"}");
            return;
        }

        try {
            if (!grupoPerteneceAProfesor(grupoId, profesorId)) {
                resp.setStatus(403);
                out.print("{\"error\":\"no tiene acceso a este grupo\"}");
                return;
            }

            AsistenciaDAO dao = new AsistenciaDAO();
            List<AsistenciaDAO.EstudianteInscrito> estudiantes = dao.listarEstudiantesPorGrupo(grupoId);
            Map<String, Asistencia> registros = dao.listarAsistenciaSemana(grupoId, desde, hasta);

            StringBuilder sb = new StringBuilder();
            sb.append("{\"estudiantes\":[");
            for (int i = 0; i < estudiantes.size(); i++) {
                AsistenciaDAO.EstudianteInscrito ei = estudiantes.get(i);
                if (i > 0) sb.append(",");
                sb.append("{\"inscripcionId\":").append(ei.inscripcionId)
                  .append(",\"nombre\":").append(jStr(ei.nombre))
                  .append(",\"cedula\":").append(jStr(ei.cedula))
                  .append("}");
            }
            sb.append("],\"asistencia\":{");
            boolean first = true;
            for (Map.Entry<String, Asistencia> entry : registros.entrySet()) {
                Asistencia a = entry.getValue();
                if (!first) sb.append(",");
                first = false;
                sb.append(jStr(a.getInscripcionId() + "-" + a.getFecha()))
                  .append(":{\"estado\":").append(jStr(AsistenciaDAO.mapEstadoFrontend(a.getEstado())))
                  .append(",\"observacion\":").append(jStr(a.getObservacion()))
                  .append("}");
            }
            sb.append("}}");
            out.print(sb.toString());
        } catch (SQLException e) {
            resp.setStatus(500);
            out.print("{\"error\":" + jStr(e.getMessage()) + "}");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("profesorId") == null) {
            resp.setStatus(401);
            out.print("{\"error\":\"no autenticado\"}");
            return;
        }

        Integer inscripcionId = parseInt(req.getParameter("inscripcionId"));
        String fechaStr = req.getParameter("fecha");
        String estado = req.getParameter("estado");
        String observacion = req.getParameter("observacion");

        if (inscripcionId == null || fechaStr == null || estado == null) {
            resp.setStatus(400);
            out.print("{\"error\":\"parametros requeridos: inscripcionId, fecha, estado\"}");
            return;
        }

        LocalDate fecha;
        try {
            fecha = LocalDate.parse(fechaStr);
        } catch (Exception e) {
            resp.setStatus(400);
            out.print("{\"error\":\"formato de fecha invalido (use yyyy-MM-dd)\"}");
            return;
        }

        try {
            AsistenciaDAO dao = new AsistenciaDAO();
            dao.guardar(inscripcionId, fecha, estado, observacion);
            out.print("{\"ok\":true}");
        } catch (SQLException e) {
            resp.setStatus(500);
            out.print("{\"error\":" + jStr(e.getMessage()) + "}");
        }
    }

    /** Verifica que el grupo pertenezca al profesor en sesion. */
    private boolean grupoPerteneceAProfesor(int grupoId, int profesorId) throws SQLException {
        String sql = "SELECT 1 FROM grupos WHERE id = ? AND profesor_id = ?";
        try (Connection con = ConexionDB.obtenerConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, grupoId);
            ps.setInt(2, profesorId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private Integer parseInt(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    private String jStr(String s) {
        if (s == null) return "null";
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"")
                        .replace("\n", "\\n").replace("\r", "\\r") + "\"";
    }
}

package com.delta.servlet;

import com.delta.dao.SolicitudMatriculaDAO;
import com.delta.modelo.SolicitudMatricula;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.util.List;

/**
 * Gestión de solicitudes de matrícula (inscripción / retiro).
 *
 * GET  /matricula?accion=misSolicitudes          → estudiante
 * GET  /matricula?accion=pendientes[&tipo=...]  → admin
 * POST /matricula accion=aprobar|rechazar       → admin
 */
public class MatriculaServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

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

        String accion = req.getParameter("accion");
        String rol = (String) session.getAttribute("usuarioRol");
        PrintWriter out = resp.getWriter();

        try {
            SolicitudMatriculaDAO dao = new SolicitudMatriculaDAO();
            if ("misSolicitudes".equals(accion) && "estudiante".equals(rol)) {
                int usuarioId = (Integer) session.getAttribute("usuarioId");
                List<SolicitudMatricula> lista = dao.listarPorEstudianteUsuario(usuarioId, null);
                out.print(toJsonArray(lista));
                return;
            }
            if ("pendientes".equals(accion) && "admin".equals(rol)) {
                List<SolicitudMatricula> lista = dao.listarPendientes(req.getParameter("tipo"));
                out.print(toJsonArray(lista));
                return;
            }
            resp.setStatus(400);
            out.print("{\"error\":\"accion no valida\"}");
        } catch (SQLException e) {
            resp.setStatus(500);
            out.print("{\"error\":\"" + esc(e.getMessage()) + "\"}");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json;charset=UTF-8");

        HttpSession session = req.getSession(false);
        if (session == null || !"admin".equals(session.getAttribute("usuarioRol"))) {
            resp.setStatus(403);
            resp.getWriter().print("{\"error\":\"acceso denegado\"}");
            return;
        }

        String accion = req.getParameter("accion");
        PrintWriter out = resp.getWriter();
        try {
            int solicitudId = Integer.parseInt(req.getParameter("id"));
            int adminId = (Integer) session.getAttribute("usuarioId");
            SolicitudMatriculaDAO dao = new SolicitudMatriculaDAO();

            if ("aprobar".equals(accion)) {
                dao.aprobar(solicitudId, adminId);
                out.print("{\"ok\":true}");
            } else if ("rechazar".equals(accion)) {
                dao.rechazar(solicitudId, adminId, req.getParameter("motivo"));
                out.print("{\"ok\":true}");
            } else {
                resp.setStatus(400);
                out.print("{\"error\":\"accion no valida\"}");
            }
        } catch (Exception e) {
            resp.setStatus(500);
            out.print("{\"error\":\"" + esc(e.getMessage()) + "\"}");
        }
    }

    private String toJsonArray(List<SolicitudMatricula> lista) {
        StringBuilder sb = new StringBuilder("[");
        boolean first = true;
        for (SolicitudMatricula s : lista) {
            if (!first) sb.append(",");
            first = false;
            sb.append("{")
              .append("\"id\":").append(s.getId())
              .append(",\"tipo\":").append(jStr(s.getTipo()))
              .append(",\"estado\":").append(jStr(s.getEstado()))
              .append(",\"estudiante\":").append(jStr(s.getEstudianteNombre()))
              .append(",\"materiaCodigo\":").append(jStr(s.getMateriaCodigo()))
              .append(",\"materiaNombre\":").append(jStr(s.getMateriaNombre()))
              .append(",\"grupo\":").append(jStr(s.getGrupoCodigo()))
              .append(",\"fecha\":").append(jStr(s.getFechaSolicitud() != null ? s.getFechaSolicitud().toString() : ""))
              .append("}");
        }
        sb.append("]");
        return sb.toString();
    }

    private String jStr(String s) {
        if (s == null) return "null";
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}

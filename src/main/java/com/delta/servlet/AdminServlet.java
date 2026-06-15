package com.delta.servlet;

import com.delta.dao.AdminDAO;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * API administrativa.
 * GET/POST /admin?accion=...
 */
public class AdminServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!esAdmin(req)) {
            resp.setStatus(403);
            resp.getWriter().print("{\"error\":\"acceso denegado\"}");
            return;
        }
        procesar(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        if (!esAdmin(req)) {
            resp.setStatus(403);
            resp.getWriter().print("{\"error\":\"acceso denegado\"}");
            return;
        }
        procesar(req, resp);
    }

    private void procesar(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        String accion = req.getParameter("accion");
        PrintWriter out = resp.getWriter();
        AdminDAO dao = new AdminDAO();

        try {
            switch (accion != null ? accion : "") {
                case "dashboard":
                    out.print(mapToJson(dao.dashboard()));
                    break;
                case "estudiantes":
                    out.print(listToJson(dao.listarEstudiantes(
                            req.getParameter("carrera"), req.getParameter("materia"),
                            req.getParameter("nombre"), req.getParameter("cedula"))));
                    break;
                case "profesores":
                    out.print(listToJson(dao.listarProfesores(
                            req.getParameter("materia"), req.getParameter("departamento"),
                            req.getParameter("nombre"))));
                    break;
                case "materias":
                    out.print(listToJson(dao.listarMaterias()));
                    break;
                case "profesoresSimple":
                    out.print(listToJson(dao.listarProfesoresSimple()));
                    break;
                case "avisos":
                    out.print(listToJson(dao.listarAvisosAdmin()));
                    break;
                case "reportePromedioMateria":
                    out.print(listToJson(dao.reportePromedioMateria()));
                    break;
                case "reporteRiesgo":
                    out.print(listToJson(dao.reporteRiesgo()));
                    break;
                case "reporteInscritos":
                    out.print(listToJson(dao.reporteInscritosMateria()));
                    break;
                case "actualizarCreditos":
                    dao.actualizarCreditos(Integer.parseInt(req.getParameter("materiaId")),
                            Integer.parseInt(req.getParameter("creditos")));
                    out.print("{\"ok\":true}");
                    break;
                case "actualizarCapacidad":
                    dao.actualizarCapacidad(Integer.parseInt(req.getParameter("grupoId")),
                            Integer.parseInt(req.getParameter("capacidad")));
                    out.print("{\"ok\":true}");
                    break;
                case "reasignarProfesor":
                    dao.reasignarProfesor(Integer.parseInt(req.getParameter("grupoId")),
                            Integer.parseInt(req.getParameter("profesorId")));
                    out.print("{\"ok\":true}");
                    break;
                case "supervisionCalificaciones":
                    out.print(listToJson(dao.listarSupervisionCalificaciones()));
                    break;
                case "historialNota":
                    out.print(listToJson(dao.historialNota(
                            Integer.parseInt(req.getParameter("inscripcionId")),
                            req.getParameter("componente"))));
                    break;
                case "autorizarModificacion": {
                    HttpSession s = req.getSession(false);
                    int adminUsuarioId = (Integer) s.getAttribute("usuarioId");
                    int cantidad = req.getParameter("cantidad") != null
                            ? Integer.parseInt(req.getParameter("cantidad")) : 1;
                    dao.autorizarModificacionNota(
                            Integer.parseInt(req.getParameter("inscripcionId")),
                            req.getParameter("componente"), cantidad, adminUsuarioId);
                    out.print("{\"ok\":true}");
                    break;
                }
                case "supervisionAsistencia": {
                    Integer grupoId = parseIntOrNull(req.getParameter("grupoId"));
                    Integer estudianteId = parseIntOrNull(req.getParameter("estudianteId"));
                    Integer materiaId = parseIntOrNull(req.getParameter("materiaId"));
                    out.print(listToJson(dao.listarSupervisionAsistencia(grupoId, estudianteId, materiaId, req.getParameter("fecha"))));
                    break;
                }
                case "corregirAsistencia":
                    dao.corregirAsistencia(Integer.parseInt(req.getParameter("inscripcionId")),
                            req.getParameter("fecha"), req.getParameter("estado"), req.getParameter("observacion"));
                    out.print("{\"ok\":true}");
                    break;
                case "reporteAsistenciaPorcentaje":
                    out.print(listToJson(dao.reporteAsistenciaPorcentaje(req.getParameter("agrupar"))));
                    break;
                case "desactivarAviso":
                    dao.desactivarAviso(Integer.parseInt(req.getParameter("id")));
                    out.print("{\"ok\":true}");
                    break;
                case "eliminarAviso":
                    dao.eliminarAviso(Integer.parseInt(req.getParameter("id")));
                    out.print("{\"ok\":true}");
                    break;
                default:
                    resp.setStatus(400);
                    out.print("{\"error\":\"accion no valida\"}");
            }
        } catch (SQLException e) {
            resp.setStatus(500);
            out.print("{\"error\":\"" + esc(e.getMessage()) + "\"}");
        } catch (Exception e) {
            resp.setStatus(400);
            out.print("{\"error\":\"" + esc(e.getMessage()) + "\"}");
        }
    }

    private boolean esAdmin(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s != null && "admin".equals(s.getAttribute("usuarioRol"));
    }

    private Integer parseIntOrNull(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    private String mapToJson(Map<String, Object> map) {
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (Map.Entry<String, Object> e : map.entrySet()) {
            if (!first) sb.append(",");
            first = false;
            sb.append("\"").append(e.getKey()).append("\":").append(val(e.getValue()));
        }
        sb.append("}");
        return sb.toString();
    }

    private String listToJson(List<Map<String, Object>> lista) {
        StringBuilder sb = new StringBuilder("[");
        boolean first = true;
        for (Map<String, Object> row : lista) {
            if (!first) sb.append(",");
            first = false;
            sb.append(mapToJson(row));
        }
        sb.append("]");
        return sb.toString();
    }

    private String val(Object v) {
        if (v == null) return "null";
        if (v instanceof Number || v instanceof Boolean) return v.toString();
        return "\"" + esc(String.valueOf(v)) + "\"";
    }

    private String esc(String s) {
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}

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

    private static final long serialVersionUID = 1L;

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
                    out.print(listToJson(dao.listarAvisosAdmin(req.getParameter("estado"))));
                    break;
                case "reportePromedioMateria":
                    out.print(listToJson(dao.reportePromedioMateria()));
                    break;
                case "reportePromedioCarrera":
                    out.print(listToJson(dao.reportePromedioCarrera()));
                    break;
                case "reporteRiesgo":
                    out.print(listToJson(dao.reporteRiesgo()));
                    break;
                case "reporteAprobadosReprobados":
                    out.print(listToJson(dao.reporteAprobadosReprobados(req.getParameter("orden"))));
                    break;
                case "reporteInscritos":
                    out.print(listToJson(dao.reporteInscritosMateria(req.getParameter("orden"))));
                    break;
                case "reporteCupos":
                    out.print(listToJson(dao.reporteCuposDisponibles()));
                    break;
                case "reporteCargaProfesores":
                    out.print(listToJson(dao.reporteCargaProfesores()));
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
                case "reasignarProfesor": {
                    HttpSession sProf = req.getSession(false);
                    int adminIdProf = (Integer) sProf.getAttribute("usuarioId");
                    boolean cambiado = dao.reasignarProfesor(
                            Integer.parseInt(req.getParameter("grupoId")),
                            Integer.parseInt(req.getParameter("profesorId")),
                            adminIdProf);
                    if (cambiado) {
                        out.print("{\"ok\":true,\"cambiado\":true}");
                    } else {
                        out.print("{\"ok\":true,\"cambiado\":false,\"msg\":\"El profesor seleccionado ya estaba asignado a este grupo. No se realizaron cambios.\"}");
                    }
                    break;
                }
                case "historialAsignaciones":
                    out.print(listToJson(dao.listarHistorialAsignaciones()));
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
                case "reiniciarModificaciones":
                    dao.reiniciarModificaciones(
                            Integer.parseInt(req.getParameter("inscripcionId")),
                            req.getParameter("componente"));
                    out.print("{\"ok\":true}");
                    break;
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
                case "materiasRetiradas":
                    out.print(listToJson(dao.listarMateriasRetiradas()));
                    break;
                case "desbloquearMateria":
                    dao.desbloquearMateria(
                        Integer.parseInt(req.getParameter("estudianteId")),
                        Integer.parseInt(req.getParameter("grupoId")));
                    out.print("{\"ok\":true}");
                    break;
                // ---- AVISOS ----
                case "archivarAviso":
                    dao.archivarAviso(Integer.parseInt(req.getParameter("id")));
                    out.print("{\"ok\":true}");
                    break;
                case "restaurarAviso":
                    dao.restaurarAviso(Integer.parseInt(req.getParameter("id")));
                    out.print("{\"ok\":true}");
                    break;
                case "actualizarAviso":
                    dao.actualizarAviso(
                        Integer.parseInt(req.getParameter("id")),
                        req.getParameter("titulo"),
                        req.getParameter("cuerpo"),
                        req.getParameter("estado"));
                    out.print("{\"ok\":true}");
                    break;
                // Mantener compatibilidad con codigo anterior
                case "desactivarAviso":
                    dao.archivarAviso(Integer.parseInt(req.getParameter("id")));
                    out.print("{\"ok\":true}");
                    break;
                case "eliminarAviso":
                    dao.archivarAviso(Integer.parseInt(req.getParameter("id")));
                    out.print("{\"ok\":true}");
                    break;
                case "listarUsuariosCreados":
                    out.print(listToJson(new com.delta.dao.CrearUsuarioDAO().listarUsuariosCreados()));
                    break;
                case "listarMaterias":
                    out.print(listToJson(new com.delta.dao.CrearUsuarioDAO().listarMaterias()));
                    break;
                case "listarGruposDisponibles":
                    out.print(listToJson(new com.delta.dao.CrearUsuarioDAO().listarGruposDisponibles()));
                    break;
                case "crearEstudiante": {
                    com.delta.dao.CrearUsuarioDAO cudEst = new com.delta.dao.CrearUsuarioDAO();
                    String nacEst = req.getParameter("nacionalidad");
                    boolean extEst = nacEst != null && !nacEst.isEmpty()
                                     && !"panameño".equalsIgnoreCase(nacEst)
                                     && !"panameno".equalsIgnoreCase(nacEst);
                    int semEst = 1;
                    try { semEst = Integer.parseInt(req.getParameter("semestre")); } catch (Exception ignored) {}
                    java.util.Map<String,Object> resEst = cudEst.crearEstudiante(
                        req.getParameter("nombre"),   req.getParameter("apellido"),
                        req.getParameter("cedula"),   req.getParameter("email"),
                        req.getParameter("telefono"), semEst,
                        nacEst, extEst);
                    out.print(mapToJson(resEst));
                    break;
                }
                case "crearProfesor": {
                    com.delta.dao.CrearUsuarioDAO cudProf = new com.delta.dao.CrearUsuarioDAO();
                    String nacProf = req.getParameter("nacionalidad");
                    boolean extProf = nacProf != null && !nacProf.isEmpty()
                                      && !"panameño".equalsIgnoreCase(nacProf)
                                      && !"panameno".equalsIgnoreCase(nacProf);
                    String matIdsStr = req.getParameter("materiaIds");
                    java.util.List<Integer> mIds = new java.util.ArrayList<>();
                    if (matIdsStr != null && !matIdsStr.isEmpty()) {
                        for (String s : matIdsStr.split(",")) {
                            try { mIds.add(Integer.parseInt(s.trim())); } catch (NumberFormatException ignored) {}
                        }
                    }
                    java.util.Map<String,Object> resProf = cudProf.crearProfesor(
                        req.getParameter("nombre"),       req.getParameter("apellido"),
                        req.getParameter("cedula"),       req.getParameter("email"),
                        req.getParameter("telefono"),     req.getParameter("departamento"),
                        nacProf, extProf, mIds);
                    out.print(mapToJson(resProf));
                    break;
                }
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
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
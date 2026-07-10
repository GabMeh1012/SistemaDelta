package com.delta.servlet;
import com.delta.dao.AdminDAO;
import com.delta.dao.CarreraDAO;
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
        CarreraDAO carreraDao = new CarreraDAO();
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
                case "quitarProfesor": {
                    HttpSession sQuitar = req.getSession(false);
                    int adminIdQuitar = (Integer) sQuitar.getAttribute("usuarioId");
                    dao.quitarProfesor(Integer.parseInt(req.getParameter("grupoId")), adminIdQuitar);
                    out.print("{\"ok\":true}");
                    break;
                }
                case "historialAsignaciones":
                    out.print(listToJson(dao.listarHistorialAsignaciones()));
                    break;
                case "supervisionCalificaciones": {
                    String carreraIdStr = req.getParameter("carreraId");
                    Integer carreraId = (carreraIdStr != null && !carreraIdStr.trim().isEmpty())
                            ? Integer.parseInt(carreraIdStr.trim()) : null;
                    out.print(listToJson(dao.listarSupervisionCalificaciones(carreraId)));
                    break;
                }
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

                // ---- CARRERAS, PERIODOS, SALONES Y HORARIOS ----
                case "listarFacultades":
                    out.print(listToJson(carreraDao.listarFacultades()));
                    break;
                case "listarCarreras":
                    out.print(listToJson(carreraDao.listarCarreras()));
                    break;
                case "materiasSinCarrera":
                    out.print(listToJson(carreraDao.listarMateriasSinCarrera()));
                    break;
                case "salonesPorCarrera":
                    out.print(listToJson(carreraDao.listarSalonesPorCarrera(Integer.parseInt(req.getParameter("carreraId")))));
                    break;
                case "crearCarrera": {
                    List<Integer> matExistentes = parseCsvInt(req.getParameter("materiaIdsExistentes"));
                    List<Map<String,Object>> matNuevas = parseMateriasNuevas(
                        req.getParameter("nuevasCodigos"), req.getParameter("nuevasNombres"),
                        req.getParameter("nuevasCreditos"), req.getParameter("nuevasNiveles"));
                    List<Map<String,Object>> salonesPorMateria = parseSalonesPorMateriaNueva(
                        req.getParameter("nuevasAulas"), req.getParameter("nuevasHorarios"));
                    int carreraId = carreraDao.crearCarrera(
                        req.getParameter("nombre"), req.getParameter("codigo"),
                        Integer.parseInt(req.getParameter("facultadId")),
                        matExistentes, matNuevas, salonesPorMateria);
                    out.print("{\"ok\":true,\"carreraId\":" + carreraId + "}");
                    break;
                }
                case "listarPeriodos":
                    out.print(listToJson(carreraDao.listarPeriodos()));
                    break;
                case "crearPeriodo":
                    carreraDao.crearPeriodo(req.getParameter("codigo"), req.getParameter("nombre"),
                        req.getParameter("fechaInicio"), req.getParameter("fechaFin"));
                    out.print("{\"ok\":true}");
                    break;
                case "activarPeriodo":
                    carreraDao.activarPeriodo(req.getParameter("codigo"));
                    out.print("{\"ok\":true}");
                    break;

                // ---- AVISOS ----
                case "crearAviso": {
                    String tituloAv = req.getParameter("titulo");
                    String cuerpoAv = req.getParameter("cuerpo");
                    String tipoAv   = req.getParameter("tipo");
                    if (tituloAv == null || tituloAv.trim().isEmpty() || cuerpoAv == null || cuerpoAv.trim().isEmpty()) {
                        out.print("{\"ok\":false,\"error\":\"Titulo y contenido son requeridos.\"}");
                        break;
                    }
                    // profesorId y grupoId en null = aviso institucional, visible
                    // para todos los estudiantes y profesores.
                    int avisoId = new com.delta.dao.AvisoDAO().crear(null, null, tituloAv.trim(), cuerpoAv.trim(), tipoAv);
                    out.print("{\"ok\":true,\"id\":" + avisoId + "}");
                    break;
                }
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
                case "listarUsuariosCreados":
                    out.print(listToJson(new com.delta.dao.CrearUsuarioDAO().listarUsuariosCreados()));
                    break;
                case "crearEstudiante": {
                    com.delta.dao.CrearUsuarioDAO cudEst = new com.delta.dao.CrearUsuarioDAO();
                    String nacEst = req.getParameter("nacionalidad");
                    boolean extEst = nacEst != null && !nacEst.isEmpty()
                                     && !"panameño".equalsIgnoreCase(nacEst)
                                     && !"panameno".equalsIgnoreCase(nacEst);
                    // Semestre fijo en 5 (3er año, 1er semestre) - no se lee del request.
                    int semEst = 5;
                    Integer carreraIdEst = parseIntOrNull(req.getParameter("carreraId"));
                    List<Integer> grupoIdsIniciales = parseCsvInt(req.getParameter("grupoIdsIniciales"));
                    java.util.Map<String,Object> resEst = cudEst.crearEstudiante(
                        req.getParameter("nombre"),   req.getParameter("apellido"),
                        req.getParameter("cedula"),   req.getParameter("email"),
                        req.getParameter("telefono"), semEst,
                        nacEst, extEst, carreraIdEst, grupoIdsIniciales);
                    out.print(mapToJson(resEst));
                    break;
                }
                case "crearProfesor": {
                    com.delta.dao.CrearUsuarioDAO cudProf = new com.delta.dao.CrearUsuarioDAO();
                    String nacProf = req.getParameter("nacionalidad");
                    boolean extProf = nacProf != null && !nacProf.isEmpty()
                                      && !"panameño".equalsIgnoreCase(nacProf)
                                      && !"panameno".equalsIgnoreCase(nacProf);
                    java.util.Map<String,Object> resProf = cudProf.crearProfesor(
                        req.getParameter("nombre"),       req.getParameter("apellido"),
                        req.getParameter("cedula"),       req.getParameter("email"),
                        req.getParameter("telefono"),     req.getParameter("departamento"),
                        nacProf, extProf);
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
    private List<Integer> parseCsvInt(String csv) {
        List<Integer> lista = new java.util.ArrayList<>();
        if (csv == null || csv.trim().isEmpty()) return lista;
        for (String s : csv.split(",")) {
            try { lista.add(Integer.parseInt(s.trim())); } catch (NumberFormatException ignored) {}
        }
        return lista;
    }
    /** Arma la lista de materias nuevas a partir de 4 listas paralelas separadas por coma. */
    private List<Map<String,Object>> parseMateriasNuevas(String codigos, String nombres, String creditos, String niveles) {
        List<Map<String,Object>> lista = new java.util.ArrayList<>();
        if (codigos == null || codigos.trim().isEmpty()) return lista;
        String[] aCodigos  = codigos.split(",", -1);
        String[] aNombres  = nombres  != null ? nombres.split(",", -1)  : new String[0];
        String[] aCreditos = creditos != null ? creditos.split(",", -1) : new String[0];
        String[] aNiveles  = niveles  != null ? niveles.split(",", -1)  : new String[0];
        for (int i = 0; i < aCodigos.length; i++) {
            Map<String,Object> m = new java.util.LinkedHashMap<>();
            m.put("codigo", aCodigos[i].trim());
            m.put("nombre", i < aNombres.length ? aNombres[i].trim() : aCodigos[i].trim());
            try { m.put("creditos", i < aCreditos.length ? Integer.parseInt(aCreditos[i].trim()) : 3); }
            catch (NumberFormatException e) { m.put("creditos", 3); }
            try { m.put("nivel", i < aNiveles.length ? Integer.parseInt(aNiveles[i].trim()) : null); }
            catch (NumberFormatException e) { m.put("nivel", null); }
            lista.add(m);
        }
        return lista;
    }
    /** Arma la lista de bloques de horario a partir de 3 listas paralelas separadas por coma. */
    private List<Map<String,Object>> parseHorarioBloques(String dias, String horaInicios, String horaFines) {
        List<Map<String,Object>> lista = new java.util.ArrayList<>();
        if (dias == null || dias.trim().isEmpty()) return lista;
        String[] aDias   = dias.split(",", -1);
        String[] aInicio = horaInicios != null ? horaInicios.split(",", -1) : new String[0];
        String[] aFin    = horaFines   != null ? horaFines.split(",", -1)   : new String[0];
        for (int i = 0; i < aDias.length; i++) {
            Map<String,Object> b = new java.util.LinkedHashMap<>();
            b.put("dia", aDias[i].trim());
            b.put("horaInicio", i < aInicio.length ? aInicio[i].trim() : "");
            b.put("horaFin", i < aFin.length ? aFin[i].trim() : "");
            lista.add(b);
        }
        return lista;
    }
    /**
     * Arma la info de salones por cada materia nueva. Formato de wire:
     * nuevasAulas: por materia, aulas separadas por '|'; materias separadas por ','.
     * nuevasHorarios: por materia, bloques del salon 1 separados por ';' (cada bloque "dia@horaInicio@horaFin"); materias separadas por ','.
     */
    private List<Map<String,Object>> parseSalonesPorMateriaNueva(String aulasCsv, String horariosCsv) {
        List<Map<String,Object>> lista = new java.util.ArrayList<>();
        if (aulasCsv == null || aulasCsv.trim().isEmpty()) return lista;
        String[] porMateriaAulas = aulasCsv.split(",", -1);
        String[] porMateriaHorarios = horariosCsv != null ? horariosCsv.split(",", -1) : new String[0];
        for (int i = 0; i < porMateriaAulas.length; i++) {
            Map<String,Object> entrada = new java.util.LinkedHashMap<>();
            List<String> aulas = new java.util.ArrayList<>();
            for (String a : porMateriaAulas[i].split("\\|", -1)) aulas.add(a.trim());
            entrada.put("aulas", aulas);

            List<Map<String,Object>> bloques = new java.util.ArrayList<>();
            if (i < porMateriaHorarios.length && !porMateriaHorarios[i].isEmpty()) {
                for (String bloqueStr : porMateriaHorarios[i].split(";", -1)) {
                    String[] partes = bloqueStr.split("@", -1);
                    if (partes.length == 3) {
                        Map<String,Object> b = new java.util.LinkedHashMap<>();
                        b.put("dia", partes[0].trim());
                        b.put("horaInicio", partes[1].trim());
                        b.put("horaFin", partes[2].trim());
                        bloques.add(b);
                    }
                }
            }
            entrada.put("horario", bloques);
            lista.add(entrada);
        }
        return lista;
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
    @SuppressWarnings("unchecked")
    private String val(Object v) {
        if (v == null) return "null";
        if (v instanceof Number || v instanceof Boolean) return v.toString();
        if (v instanceof Map) return mapToJson((Map<String, Object>) v);
        if (v instanceof List) {
            StringBuilder sb = new StringBuilder("[");
            boolean first = true;
            for (Object item : (List<Object>) v) {
                if (!first) sb.append(",");
                first = false;
                sb.append(val(item));
            }
            sb.append("]");
            return sb.toString();
        }
        return "\"" + esc(String.valueOf(v)) + "\"";
    }
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
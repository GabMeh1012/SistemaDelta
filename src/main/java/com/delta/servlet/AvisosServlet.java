package com.delta.servlet;

import com.delta.dao.AvisoDAO;
import com.delta.modelo.Aviso;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Avisos / anuncios institucionales y de profesores.
 *
 * GET  /avisos              → JSON con los avisos visibles para el usuario en sesion
 *                              (estudiante: institucionales + los de sus grupos;
 *                               profesor: los que el mismo ha publicado)
 * POST /avisos              → publica un nuevo aviso (solo profesor en sesion)
 *        params: titulo, cuerpo, tipo, grupoId (opcional, vacio/"" = todos)
 */
public class AvisosServlet extends HttpServlet {

    private static final DateTimeFormatter FECHA_FMT =
            DateTimeFormatter.ofPattern("d 'de' MMMM yyyy", new java.util.Locale("es","ES"));

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

        String rol = (String) session.getAttribute("usuarioRol");
        AvisoDAO dao = new AvisoDAO();
        PrintWriter out = resp.getWriter();

        try {
            List<Aviso> lista;
            if ("profesor".equals(rol) && session.getAttribute("profesorId") != null) {
                int profesorId = (Integer) session.getAttribute("profesorId");
                lista = dao.listarPorProfesor(profesorId);
            } else {
                int usuarioId = (Integer) session.getAttribute("usuarioId");
                lista = dao.listarParaEstudiante(usuarioId);
            }

            out.print("[");
            for (int i = 0; i < lista.size(); i++) {
                if (i > 0) out.print(",");
                out.print(toJson(lista.get(i)));
            }
            out.print("]");
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
        PrintWriter out = resp.getWriter();

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("profesorId") == null) {
            resp.setStatus(401);
            out.print("{\"error\":\"no autenticado\"}");
            return;
        }

        int profesorId = (Integer) session.getAttribute("profesorId");
        String titulo = req.getParameter("titulo");
        String cuerpo = req.getParameter("cuerpo");
        String tipo   = req.getParameter("tipo");
        String grupoIdStr = req.getParameter("grupoId");

        if (titulo == null || titulo.trim().isEmpty() || cuerpo == null || cuerpo.trim().isEmpty()) {
            resp.setStatus(400);
            out.print("{\"error\":\"Titulo y contenido son requeridos\"}");
            return;
        }

        Integer grupoId = null;
        if (grupoIdStr != null && !grupoIdStr.trim().isEmpty()) {
            try {
                grupoId = Integer.parseInt(grupoIdStr.trim());
            } catch (NumberFormatException ignored) {
                grupoId = null; // valor invalido -> tratar como "todos"
            }
        }

        try {
            AvisoDAO dao = new AvisoDAO();
            int id = dao.crear(profesorId, grupoId, titulo.trim(), cuerpo.trim(), tipo);
            out.print("{\"ok\":true,\"id\":" + id + "}");
        } catch (SQLException e) {
            resp.setStatus(500);
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    private String toJson(Aviso a) {
        String fecha = a.getCreatedAt() != null ? a.getCreatedAt().format(FECHA_FMT) : "";
        String origen;
        if (a.getProfesorNombre() != null) {
            origen = a.getProfesorNombre() + (a.getCodigoGrupo() != null ? " - " + a.getCodigoGrupo() : " - Todos los grupos");
        } else {
            origen = "Administracion UTP";
        }
        return "{"
            + "\"id\":"      + a.getId()
            + ",\"titulo\":" + jStr(a.getTitulo())
            + ",\"cuerpo\":" + jStr(a.getCuerpo())
            + ",\"tipo\":"   + jStr(a.getTipo())
            + ",\"fecha\":"  + jStr(fecha)
            + ",\"origen\":" + jStr(origen)
            + ",\"grupo\":"  + jStr(a.getCodigoGrupo())
            + "}";
    }

    private String jStr(String s) {
        if (s == null) return "null";
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"")
                        .replace("\n", "\\n").replace("\r", "\\r") + "\"";
    }
}

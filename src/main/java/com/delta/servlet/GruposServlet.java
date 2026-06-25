package com.delta.servlet;

import com.delta.dao.GrupoDAO;
import com.delta.modelo.EstudianteRiesgo;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.util.List;

/**
 * Devuelve datos de grupos y riesgo académico en JSON.
 *
 * GET /grupos?accion=riesgo  → JSON lista EstudianteRiesgo del profesor en sesión
 * GET /grupos?accion=resumen → JSON resumen por grupo (código, materia, total, prom, riesgo)
 */
public class GruposServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("profesorId") == null) {
            resp.setStatus(401);
            resp.getWriter().print("{\"error\":\"no autenticado\"}");
            return;
        }

        int profesorId = (Integer) session.getAttribute("profesorId");
        String accion = req.getParameter("accion");
        GrupoDAO dao = new GrupoDAO();
        PrintWriter out = resp.getWriter();

        try {
            switch (accion == null ? "" : accion) {

                case "riesgo": {
                    List<EstudianteRiesgo> lista = dao.listarRiesgoPorProfesor(profesorId);
                    out.print("[");
                    for (int i = 0; i < lista.size(); i++) {
                        EstudianteRiesgo er = lista.get(i);
                        if (i > 0) out.print(",");
                        out.print("{"
                            + "\"estudianteId\":" + er.getEstudianteId()
                            + ",\"nombre\":"       + jStr(er.getNombre())
                            + ",\"codigoGrupo\":"  + jStr(er.getCodigoGrupo())
                            + ",\"materia\":"      + jStr(er.getMateria())
                            + ",\"promedio\":"     + er.getPromedioFinal()
                            + ",\"estado\":"       + jStr(er.getEstadoAcademico())
                            + "}");
                    }
                    out.print("]");
                    break;
                }

                case "resumen": {
                    List<Object[]> lista = dao.resumenGruposProfesor(profesorId);
                    out.print("[");
                    for (int i = 0; i < lista.size(); i++) {
                        Object[] row = lista.get(i);
                        if (i > 0) out.print(",");
                        out.print("{"
                            + "\"codigoGrupo\":"  + jStr((String)  row[0])
                            + ",\"materia\":"     + jStr((String)  row[1])
                            + ",\"total\":"       + (int)          row[2]
                            + ",\"promedio\":"    + (double)       row[3]
                            + ",\"enRiesgo\":"    + (int)          row[4]
                            + "}");
                    }
                    out.print("]");
                    break;
                }

                default:
                    resp.setStatus(400);
                    out.print("{\"error\":\"accion desconocida\"}");
            }
        } catch (SQLException e) {
            resp.setStatus(500);
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    private String jStr(String s) {
        if (s == null) return "null";
        return "\"" + s.replace("\"", "\\\"") + "\"";
    }
}

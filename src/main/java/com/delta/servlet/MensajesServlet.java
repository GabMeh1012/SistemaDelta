package com.delta.servlet;

import com.delta.dao.MensajeDAO;
import com.delta.dao.UsuarioDAO;
import com.delta.modelo.Mensaje;
import com.delta.modelo.Notificacion;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.util.List;

public class MensajesServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        String accion = req.getParameter("accion");
        Integer usuarioId = getUsuarioId(req, resp);
        if (usuarioId == null) return;

        MensajeDAO dao = new MensajeDAO();
        PrintWriter out = resp.getWriter();

        try {
            switch (accion == null ? "" : accion) {

                case "bandeja": {
                    List<Mensaje> msgs = dao.listarRecibidos(usuarioId);
                    out.print("[");
                    for (int i = 0; i < msgs.size(); i++) {
                        Mensaje m = msgs.get(i);
                        if (i > 0) out.print(",");
                        out.print("{\"id\":" + m.getId()
                            + ",\"remitente\":" + jsonStr(m.getRemitenteNombre())
                            + ",\"asunto\":"   + jsonStr(m.getAsunto())
                            + ",\"cuerpo\":"   + jsonStr(m.getCuerpo())
                            + ",\"leido\":"    + m.isLeido()
                            + ",\"fecha\":"    + jsonStr(m.getFechaEnvio() != null ? m.getFechaEnvio().toString() : "")
                            + "}");
                    }
                    out.print("]");
                    break;
                }

                case "noLeidos": {
                    int cnt  = dao.contarNoLeidos(usuarioId);
                    int cntN = dao.contarNoLeidas(usuarioId);
                    out.print("{\"mensajes\":" + cnt + ",\"notificaciones\":" + cntN + "}");
                    break;
                }

                case "notificaciones": {
                    List<Notificacion> notifs = dao.listarPorUsuario(usuarioId);
                    out.print("[");
                    for (int i = 0; i < notifs.size(); i++) {
                        Notificacion n = notifs.get(i);
                        if (i > 0) out.print(",");
                        out.print("{\"id\":" + n.getId()
                            + ",\"tipo\":"    + jsonStr(n.getTipo())
                            + ",\"titulo\":"  + jsonStr(n.getTitulo())
                            + ",\"cuerpo\":"  + jsonStr(n.getCuerpo())
                            + ",\"leida\":"   + n.isLeida()
                            + ",\"enlace\":"  + jsonStr(n.getEnlace())
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

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json;charset=UTF-8");
        String accion = req.getParameter("accion");
        Integer usuarioId = getUsuarioId(req, resp);
        if (usuarioId == null) return;

        MensajeDAO dao = new MensajeDAO();
        PrintWriter out = resp.getWriter();

        try {
            switch (accion == null ? "" : accion) {

                case "marcarLeido": {
                    int msgId = Integer.parseInt(req.getParameter("id"));
                    dao.marcarLeido(msgId, usuarioId);
                    int noLeidos = dao.contarNoLeidos(usuarioId);
                    int noLeidas = dao.contarNoLeidas(usuarioId);
                    out.print("{\"ok\":true,\"noLeidos\":" + noLeidos + ",\"noLeidas\":" + noLeidas + "}");
                    break;
                }

                case "enviar": {
                    String destNombre = req.getParameter("destinatario");
                    String asunto     = req.getParameter("asunto");
                    String cuerpo     = req.getParameter("cuerpo");

                    if (destNombre == null || destNombre.trim().isEmpty()) {
                        resp.setStatus(400);
                        out.print("{\"error\":\"Destinatario requerido\"}");
                        break;
                    }

                    UsuarioDAO uDao = new UsuarioDAO();
                    Integer destId = uDao.buscarUsuarioIdPorNombre(destNombre.trim());

                    if (destId == null) {
                        String sinTildes = quitarTildes(destNombre.trim());
                        destId = uDao.buscarUsuarioIdPorNombreSinTildes(sinTildes);
                    }

                    if (destId == null) {
                        resp.setStatus(404);
                        out.print("{\"error\":\"Destinatario no encontrado\"}");
                        break;
                    }
                    int msgId = dao.enviar(usuarioId, destId, asunto, cuerpo);
                    out.print("{\"ok\":true,\"msgId\":" + msgId + "}");
                    break;
                }

                case "marcarNotifLeida": {
                    int notifId = Integer.parseInt(req.getParameter("id"));
                    dao.marcarNotifLeida(notifId, usuarioId);
                    int noLeidas = dao.contarNoLeidas(usuarioId);
                    out.print("{\"ok\":true,\"noLeidas\":" + noLeidas + "}");
                    break;
                }

                case "marcarTodasLeidas": {
                    dao.marcarTodasLeidas(usuarioId);
                    out.print("{\"ok\":true,\"noLeidas\":0}");
                    break;
                }

                default:
                    resp.setStatus(400);
                    out.print("{\"error\":\"accion desconocida\"}");
            }
        } catch (SQLException | NumberFormatException e) {
            resp.setStatus(500);
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    private String quitarTildes(String s) {
        return s.replace("\u00e1","a").replace("\u00e9","e")
                .replace("\u00ed","i").replace("\u00f3","o")
                .replace("\u00fa","u").replace("\u00c1","A")
                .replace("\u00c9","E").replace("\u00cd","I")
                .replace("\u00d3","O").replace("\u00da","U")
                .replace("\u00f1","n").replace("\u00d1","N");
    }

    private Integer getUsuarioId(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("usuarioId") == null) {
            resp.setStatus(401);
            resp.getWriter().print("{\"error\":\"no autenticado\"}");
            return null;
        }
        return (Integer) session.getAttribute("usuarioId");
    }

    private String jsonStr(String s) {
        if (s == null) return "null";
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"")
                        .replace("\n", "\\n").replace("\r", "\\r") + "\"";
    }
}

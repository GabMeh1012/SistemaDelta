package com.delta.servlet;

import com.delta.dao.UsuarioDAO;
import com.delta.modelo.Usuario;

import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Maneja el formulario de login tanto para profesores como para estudiantes.
 * POST /login  → autentica y redirige al portal correspondiente
 */
public class LoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String username = req.getParameter("username");
        String password = req.getParameter("password");
        String destino  = req.getParameter("destino"); // 'profesor' | 'estudiante'

        try {
            UsuarioDAO dao = new UsuarioDAO();
            Usuario usuario = dao.autenticar(username, password);

            if (usuario == null) {
                resp.sendRedirect(req.getContextPath() + "/" + paginaError(destino) + "?error=1");
                return;
            }

            // Verificar que el rol coincida con el portal de destino
            boolean rolCorrecto = ("profesor".equals(destino) && usuario.esProfesor())
                               || ("estudiante".equals(destino) && usuario.esEstudiante())
                               || ("admin".equals(destino) && usuario.esAdmin());
            if (!rolCorrecto) {
                String pagina = paginaError(destino);
                resp.sendRedirect(req.getContextPath() + "/" + pagina + "?error=1");
                return;
            }

            // Guardar en sesión
            HttpSession session = req.getSession(true);
            session.setAttribute("usuarioId",       usuario.getId());
            session.setAttribute("usuarioUsername", usuario.getUsername());
            session.setAttribute("usuarioRol",      usuario.getRol());

            if (usuario.esProfesor()) {
                int profId = dao.obtenerProfesorId(usuario.getId());
                String nombre = dao.obtenerNombreProfesor(usuario.getId());
                session.setAttribute("profesorId",     profId);
                session.setAttribute("profesorNombre", nombre);
                resp.sendRedirect(req.getContextPath() + "/portal_profesor.jsp");
            } else if (usuario.esEstudiante()) {
                resp.sendRedirect(req.getContextPath() + "/portal_estudiante.jsp");
            } else if (usuario.esAdmin()) {
                session.setAttribute("adminNombre", usuario.getUsername());
                resp.sendRedirect(req.getContextPath() + "/portal_administrador.jsp");
            } else {
                resp.sendRedirect(req.getContextPath() + "/index.jsp");
            }

        } catch (SQLException e) {
            throw new ServletException("Error de base de datos en login", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Si ya hay sesión activa, redirigir al portal correcto
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("usuarioRol") != null) {
            String rol = (String) session.getAttribute("usuarioRol");
            if ("profesor".equals(rol)) {
                resp.sendRedirect(req.getContextPath() + "/portal_profesor.jsp");
            } else if ("admin".equals(rol)) {
                resp.sendRedirect(req.getContextPath() + "/portal_administrador.jsp");
            } else {
                resp.sendRedirect(req.getContextPath() + "/portal_estudiante.jsp");
            }
        } else {
            resp.sendRedirect(req.getContextPath() + "/index.jsp");
        }
    }

    private String paginaError(String destino) {
        if ("profesor".equals(destino)) return "portal_profesor.jsp";
        if ("admin".equals(destino)) return "portal_administrador.jsp";
        return "portal_estudiante.jsp";
    }
}

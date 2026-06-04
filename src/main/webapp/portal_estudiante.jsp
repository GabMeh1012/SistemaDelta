<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ page import="com.delta.util.ConexionDB, java.sql.*" %>
<%
  Integer est_usuarioId = (Integer) session.getAttribute("usuarioId");
  String  est_rol       = (String)  session.getAttribute("usuarioRol");
  boolean est_hayBD     = (est_usuarioId != null && "estudiante".equals(est_rol));
  boolean est_loginError = "1".equals(request.getParameter("error"));
  // Si la sesión activa es de profesor, redirigir a su portal
  if (est_usuarioId != null && "profesor".equals(est_rol)) {
    response.sendRedirect(request.getContextPath() + "/portal_profesor.jsp");
    return;
  }

  String est_nombre   = "Estudiante";
  String est_apellido = "";
  String est_cedula   = "";
  String est_inicial  = "E";
  String est_semestre = "";
  String est_carrera  = "";

  if (est_hayBD) {
    try (Connection _con = ConexionDB.obtenerConexion();
         PreparedStatement _ps = _con.prepareStatement(
           "SELECT e.nombre, e.apellido, e.cedula, e.semestre, e.carrera " +
           "FROM estudiantes e WHERE e.usuario_id = ?")) {
      _ps.setInt(1, est_usuarioId);
      try (ResultSet _rs = _ps.executeQuery()) {
        if (_rs.next()) {
          est_nombre   = _rs.getString("nombre")   != null ? _rs.getString("nombre")   : "";
          est_apellido = _rs.getString("apellido") != null ? _rs.getString("apellido") : "";
          est_cedula   = _rs.getString("cedula")   != null ? _rs.getString("cedula")   : "";
          est_semestre = _rs.getString("semestre") != null ? String.valueOf(_rs.getInt("semestre")) : "";
          est_carrera  = _rs.getString("carrera")  != null ? _rs.getString("carrera")  : "";
          est_inicial  = est_nombre.length() > 0 ? est_nombre.substring(0,1).toUpperCase() : "E";
        }
      }
    } catch (Exception _e) { /* usar valores demo */ }
  }
  String est_nombreCompleto = (est_nombre + " " + est_apellido).trim();

  // Cargar materias inscritas del estudiante
  StringBuilder est_materiasJsonSb = new StringBuilder("[");
  if (est_hayBD) {
    try (Connection _con2 = ConexionDB.obtenerConexion();
         PreparedStatement _ps2 = _con2.prepareStatement(
           "SELECT m.codigo, m.nombre, " +
           "CONCAT(p.nombre,' ',p.apellido) AS docente, " +
           "g.aula, " +
           "MAX(CASE WHEN n.componente='parcial1'     THEN n.nota END) AS p1, " +
           "MAX(CASE WHEN n.componente='parcial2'     THEN n.nota END) AS p2, " +
           "MAX(CASE WHEN n.componente='proyecto'     THEN n.nota END) AS proy, " +
           "MAX(CASE WHEN n.componente='examen_final' THEN n.nota END) AS ef " +
           "FROM inscripciones i " +
           "JOIN estudiantes e ON e.usuario_id = ? " +
           "JOIN grupos g ON g.id = i.grupo_id " +
           "JOIN materias m ON m.id = g.materia_id " +
           "LEFT JOIN profesores p ON p.id = g.profesor_id " +
           "LEFT JOIN notas n ON n.inscripcion_id = i.id " +
           "WHERE i.estudiante_id = e.id AND i.estado = 'activo' " +
           "GROUP BY m.id, m.codigo, m.nombre, p.nombre, p.apellido, g.aula")) {
      _ps2.setInt(1, est_usuarioId);
      try (ResultSet _rs2 = _ps2.executeQuery()) {
        boolean _first = true;
        while (_rs2.next()) {
          if (!_first) est_materiasJsonSb.append(",");
          _first = false;
          double _p1   = _rs2.getDouble("p1");   boolean _np1   = _rs2.wasNull();
          double _p2   = _rs2.getDouble("p2");   boolean _np2   = _rs2.wasNull();
          double _proy = _rs2.getDouble("proy");  boolean _nproy = _rs2.wasNull();
          double _ef   = _rs2.getDouble("ef");   boolean _nef   = _rs2.wasNull();
          double _nota = Math.round(((_np1?0:_p1)*0.25 + (_np2?0:_p2)*0.25 + (_nproy?0:_proy)*0.20 + (_nef?0:_ef)*0.30)*10.0)/10.0;
          String _docente = _rs2.getString("docente") != null ? _rs2.getString("docente").replace('"', ' ') : "";
          String _aula    = _rs2.getString("aula")    != null ? _rs2.getString("aula").replace('"', ' ')    : "";
          String _codigo  = _rs2.getString("codigo")  != null ? _rs2.getString("codigo").replace('"', ' ')  : "";
          String _mnombre = _rs2.getString("nombre")  != null ? _rs2.getString("nombre").replace('"', ' ')  : "";
          est_materiasJsonSb.append("{")
            .append("\"codigo\":\"").append(_codigo).append("\",")
            .append("\"nombre\":\"").append(_mnombre).append("\",")
            .append("\"creditos\":3,")
            .append("\"horario\":\"\",")
            .append("\"docente\":\"").append(_docente).append("\",")
            .append("\"color\":\"#1a56a0\",")
            .append("\"colorBg\":\"#eff6ff\",")
            .append("\"dias\":{},")
            .append("\"aula\":\"").append(_aula).append("\",")
            .append("\"p1\":").append(_np1?0:_p1).append(",")
            .append("\"p2\":").append(_np2?0:_p2).append(",")
            .append("\"proj\":").append(_nproy?0:_proy).append(",")
            .append("\"exFinal\":").append(_nef?0:_ef).append(",")
            .append("\"nota\":").append(_nota)
            .append("}");
        }
      }
    } catch (Exception _e2) { /* usar demo */ }
  }
  est_materiasJsonSb.append("]");
  String est_materiasJson = est_materiasJsonSb.toString();
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="ctx" content="<%=request.getContextPath()%>">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Portal Estudiantil - Sistema Delta UTP</title>
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;500;600;700;800&family=Merriweather:wght@700&display=swap" rel="stylesheet">
<style>
/* ===== VARIABLES ===== */
:root {
  --bg: #f4f6fb;
  --bg2: #eaf0fb;
  --white: #ffffff;
  --blue: #1a56a0;
  --blue-mid: #2269c4;
  --blue-light: #dbeafe;
  --blue-pale: #eff6ff;
  --green: #15803d;
  --green-bg: #dcfce7;
  --red: #b91c1c;
  --red-bg: #fee2e2;
  --amber: #b45309;
  --amber-bg: #fef3c7;
  --purple: #7c3aed;
  --purple-bg: #f3e8ff;
  --cyan: #0891b2;
  --cyan-bg: #e0f2fe;
  --text: #1e2a3b;
  --text-mid: #3d5068;
  --text-soft: #6b7e96;
  --border: #c8d8ec;
  --shadow: 0 2px 12px rgba(26,86,160,0.10);
  --shadow-lg: 0 6px 28px rgba(26,86,160,0.14);
  --radius: 14px;
  --radius-sm: 9px;
}

/* ===== RESET ===== */
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Nunito', sans-serif; background: var(--bg); color: var(--text); font-size: 16px; min-height: 100vh; }
h1, h2, h3 { font-family: 'Merriweather', serif; }
.hidden { display: none !important; }

/* ===== BUTTONS ===== */
.btn {
  display: inline-flex; align-items: center; justify-content: center;
  gap: 8px; padding: 13px 26px; border-radius: var(--radius-sm);
  border: none; font-family: 'Nunito', sans-serif; font-size: 16px;
  font-weight: 700; cursor: pointer; transition: all 0.2s; text-decoration: none;
}
.btn-primary { background: var(--blue); color: #fff; }
.btn-primary:hover { background: var(--blue-mid); box-shadow: var(--shadow); }
.btn-secondary { background: var(--white); color: var(--blue); border: 2px solid var(--blue); }
.btn-secondary:hover { background: var(--blue-pale); }
.btn-sm { padding: 9px 18px; font-size: 14px; }
.btn-full { width: 100%; }
.btn-danger { background: var(--white); color: var(--red); border: 2px solid var(--red); font-size: 13px; padding: 6px 14px; border-radius: 20px; }
.btn-danger:hover { background: var(--red-bg); }

/* ===== CARD / TAG ===== */
.card { background: var(--white); border: 1.5px solid var(--border); border-radius: var(--radius); padding: 26px; box-shadow: var(--shadow); }
.tag { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 13px; font-weight: 700; }
.tag-green { background: var(--green-bg); color: var(--green); }
.tag-red { background: var(--red-bg); color: var(--red); }
.tag-amber { background: var(--amber-bg); color: var(--amber); }
.tag-blue { background: var(--blue-light); color: var(--blue); }

/* ===== LOGIN ===== */
#page-login {
  min-height: 100vh; display: flex; align-items: center; justify-content: center;
  background: linear-gradient(145deg,#dbeafe 0%,#f4f6fb 60%,#e0f2fe 100%); padding: 24px;
}
.login-box {
  background: var(--white); border: 1.5px solid var(--border); border-radius: 20px;
  box-shadow: var(--shadow-lg); width: 100%; max-width: 420px; padding: 48px 40px;
  animation: popIn 0.4s ease;
}
@keyframes popIn { from { opacity:0; transform:scale(0.96) translateY(10px); } to { opacity:1; transform:scale(1) translateY(0); } }
.login-logo { text-align: center; margin-bottom: 28px; }
.delta-mark {
  display: inline-flex; align-items: center; justify-content: center;
  width: 68px; height: 68px; border-radius: 18px; background: var(--blue);
  color: #fff; font-family: 'Merriweather', serif; font-size: 32px;
  margin-bottom: 12px; box-shadow: 0 4px 16px rgba(26,86,160,0.3);
}
.login-logo h1 { font-size: 22px; color: var(--blue); }
.login-logo p { font-size: 14px; color: var(--text-soft); margin-top: 4px; }
.login-role-banner {
  background: var(--blue-pale); border: 1.5px solid var(--blue-light);
  border-radius: var(--radius-sm); padding: 14px 16px; margin-bottom: 24px;
  display: flex; align-items: center; gap: 12px; font-size: 16px; font-weight: 700; color: var(--blue);
}
.form-group { margin-bottom: 18px; }
.form-group label { display: block; font-size: 15px; font-weight: 700; color: var(--text-mid); margin-bottom: 7px; }
.form-group input {
  width: 100%; padding: 13px 16px; border: 2px solid var(--border);
  border-radius: var(--radius-sm); font-family: 'Nunito', sans-serif;
  font-size: 16px; color: var(--text); background: var(--bg); transition: border-color 0.2s;
}
.form-group input:focus { outline: none; border-color: var(--blue); background: #fff; }
.login-error {
  background: var(--red-bg); color: var(--red); padding: 12px 16px;
  border-radius: var(--radius-sm); font-size: 14px; font-weight: 600;
  margin-bottom: 16px; border: 1px solid #fca5a5; display: none;
}
.login-hint { text-align: center; margin-top: 16px; font-size: 13px; color: var(--text-soft); background: var(--bg2); padding: 11px; border-radius: var(--radius-sm); }
.login-hint strong { color: var(--blue); }
.login-switch { text-align: center; margin-top: 14px; font-size: 13px; color: var(--text-soft); }
.login-switch a { color: var(--blue); font-weight: 700; text-decoration: none; }

/* ===== PORTAL LAYOUT ===== */
.portal { display: flex; min-height: 100vh; }
.sidebar {
  width: 270px; flex-shrink: 0; background: var(--white); border-right: 2px solid var(--border);
  display: flex; flex-direction: column; position: fixed; top: 0; left: 0; bottom: 0;
  z-index: 100; overflow-y: auto; box-shadow: 3px 0 16px rgba(26,86,160,0.07);
}
.sidebar-header { padding: 24px 22px 18px; border-bottom: 2px solid var(--border); background: var(--blue); }
.sidebar-logo { display: flex; align-items: center; gap: 12px; }
.logo-mark {
  width: 46px; height: 46px; border-radius: 12px; background: rgba(255,255,255,0.2);
  display: flex; align-items: center; justify-content: center;
  font-family: 'Merriweather', serif; font-size: 22px; color: #fff; border: 2px solid rgba(255,255,255,0.3);
}
.logo-name { font-family: 'Merriweather', serif; font-size: 20px; color: #fff; }
.logo-sub { font-size: 11px; color: rgba(255,255,255,0.7); text-transform: uppercase; letter-spacing: 1.5px; }
.sidebar-user {
  margin: 16px 16px 0; background: var(--blue-pale); border: 1.5px solid var(--blue-light);
  border-radius: var(--radius-sm); padding: 14px; display: flex; align-items: center; gap: 12px;
}
.user-avatar {
  width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center;
  justify-content: center; font-family: 'Merriweather', serif; font-size: 20px;
  background: var(--blue); color: #fff; flex-shrink: 0;
}
.user-name { font-size: 15px; font-weight: 800; color: var(--text); }
.user-id { font-size: 12px; color: var(--text-soft); margin-top: 2px; }
.user-role-tag { display: inline-block; margin-top: 4px; background: var(--blue); color: #fff; font-size: 11px; font-weight: 700; padding: 2px 9px; border-radius: 20px; }
.nav-section { padding: 16px 12px 8px; }
.nav-label { font-size: 11px; text-transform: uppercase; letter-spacing: 2px; color: var(--text-soft); padding: 4px 10px 10px; font-weight: 700; }
.nav-item {
  display: flex; align-items: center; gap: 12px; padding: 13px 14px;
  border-radius: var(--radius-sm); cursor: pointer; font-size: 16px; font-weight: 600;
  color: var(--text-mid); transition: all 0.18s; margin-bottom: 3px;
  text-decoration: none; border: none; background: none; width: 100%;
  text-align: left; font-family: 'Nunito', sans-serif;
}
.nav-item:hover { background: var(--blue-pale); color: var(--blue); }
.nav-item.active { background: var(--blue-light); color: var(--blue); }
.nav-icon { font-size: 20px; width: 26px; text-align: center; flex-shrink: 0; }
.nav-badge { margin-left: auto; background: var(--blue); color: #fff; font-size: 12px; font-weight: 800; padding: 2px 8px; border-radius: 20px; }
.sidebar-footer { margin-top: auto; padding: 16px 14px; border-top: 2px solid var(--border); }
.logout-btn {
  display: flex; align-items: center; gap: 10px; padding: 12px 14px;
  border-radius: var(--radius-sm); font-size: 15px; font-weight: 700;
  color: var(--red); cursor: pointer; background: var(--red-bg);
  border: 1.5px solid #fca5a5; width: 100%; font-family: 'Nunito', sans-serif; transition: all 0.18s;
}
.logout-btn:hover { background: #fecaca; }
.main-content { margin-left: 270px; flex: 1; padding: 32px 36px; min-height: 100vh; }
.topbar {
  display: flex; align-items: center; justify-content: space-between;
  margin-bottom: 30px; padding-bottom: 24px; border-bottom: 2px solid var(--border);
}
.page-title { font-size: 28px; color: var(--text); }
.page-subtitle { font-size: 15px; color: var(--text-soft); margin-top: 4px; font-family: 'Nunito', sans-serif; }
.topbar-right { display: flex; align-items: center; gap: 12px; }

/* ===== NOTIFICATION BELL ===== */
.notif-btn {
  width: 46px; height: 46px; border-radius: 10px; background: var(--white);
  border: 2px solid var(--border); display: flex; align-items: center;
  justify-content: center; font-size: 20px; cursor: pointer; transition: all 0.18s; position: relative;
}
.notif-btn:hover { border-color: var(--blue); background: var(--blue-pale); }
.notif-dot { position: absolute; top: 8px; right: 8px; width: 9px; height: 9px; background: var(--red); border-radius: 50%; border: 2px solid #fff; }

/* ===== NOTIFICATION PANEL ===== */
.notif-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.18); z-index: 499; }
.notif-panel {
  position: fixed; top: 0; right: 0; width: 370px; height: 100vh;
  background: var(--white); border-left: 2px solid var(--border);
  box-shadow: -6px 0 28px rgba(26,86,160,0.14); z-index: 500;
  display: flex; flex-direction: column; transition: transform 0.3s ease;
}
.notif-panel.notif-cerrado { transform: translateX(100%); }
.notif-panel-header {
  padding: 20px 20px 16px; border-bottom: 2px solid var(--border);
  display: flex; align-items: center; justify-content: space-between; background: var(--blue);
}
.notif-panel-titulo { font-family: 'Merriweather', serif; font-size: 17px; color: #fff; }
.notif-cerrar-btn {
  width: 34px; height: 34px; border-radius: 8px; background: rgba(255,255,255,0.2);
  border: none; color: #fff; font-size: 18px; cursor: pointer;
  display: flex; align-items: center; justify-content: center; font-family: 'Nunito', sans-serif;
}
.notif-panel-body { flex: 1; overflow-y: auto; padding: 14px; }
.notif-card {
  display: flex; gap: 12px; padding: 14px; border-radius: var(--radius-sm);
  margin-bottom: 8px; border: 1.5px solid var(--border);
}
.notif-card.ncard-unread { background: var(--blue-pale); border-color: #93c5fd; }
.notif-card.ncard-read { background: var(--bg2); opacity: 0.8; }
.notif-card-icon { width: 40px; height: 40px; border-radius: 10px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; font-size: 19px; }
.notif-card-titulo { font-size: 14px; font-weight: 800; color: var(--text); }
.notif-card-cuerpo { font-size: 13px; color: var(--text-soft); margin-top: 3px; line-height: 1.4; }
.notif-card-hora { font-size: 12px; color: var(--blue); font-weight: 700; margin-top: 5px; }
.btn-visto {
  margin-top: 8px; padding: 5px 16px; border-radius: 20px; border: none;
  background: var(--blue); color: #fff; font-size: 12px; font-weight: 700;
  cursor: pointer; font-family: 'Nunito', sans-serif; transition: background 0.15s;
}
.btn-visto:hover { background: var(--blue-mid); }
.btn-visto.visto-ok { background: var(--green); cursor: default; }

/* ===== TAB PANELS ===== */
.tab-panel { display: none; animation: fadeIn 0.3s ease; }
.tab-panel.active { display: block; }
@keyframes fadeIn { from { opacity:0; transform:translateY(8px); } to { opacity:1; transform:translateY(0); } }

/* ===== STATS ===== */
.stats-row { display: grid; gap: 18px; margin-bottom: 26px; }
.stats-4 { grid-template-columns: repeat(4, 1fr); }
.stats-3 { grid-template-columns: repeat(3, 1fr); }
.stat-card {
  background: var(--white); border: 1.5px solid var(--border); border-radius: var(--radius);
  padding: 22px 20px; box-shadow: var(--shadow); display: flex; align-items: center;
  gap: 16px; transition: transform 0.18s, box-shadow 0.18s;
}
.stat-card:hover { transform: translateY(-2px); box-shadow: var(--shadow-lg); }
.stat-icon-box { width: 56px; height: 56px; border-radius: 14px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; font-size: 26px; }
.icon-blue { background: var(--blue-light); }
.icon-green { background: var(--green-bg); }
.icon-amber { background: var(--amber-bg); }
.icon-red { background: var(--red-bg); }
.stat-label { font-size: 13px; color: var(--text-soft); font-weight: 600; text-transform: uppercase; letter-spacing: 0.8px; }
.stat-value { font-family: 'Merriweather', serif; font-size: 30px; color: var(--text); line-height: 1.1; margin: 4px 0; }
.stat-sub { font-size: 13px; color: var(--text-soft); }

/* ===== GRIDS ===== */
.grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 22px; margin-bottom: 22px; }
.grid-21 { display: grid; grid-template-columns: 2fr 1fr; gap: 22px; margin-bottom: 22px; }
.card-title {
  font-family: 'Merriweather', serif; font-size: 18px; color: var(--text);
  margin-bottom: 18px; display: flex; align-items: center; justify-content: space-between;
}
.card-link { font-family: 'Nunito', sans-serif; font-size: 13px; color: var(--blue); font-weight: 700; text-decoration: none; cursor: pointer; background: none; border: none; }
.card-link:hover { text-decoration: underline; }

/* ===== SCHEDULE ===== */
.sched-item { display: flex; gap: 14px; padding: 14px 0; border-bottom: 1.5px solid var(--bg2); align-items: flex-start; }
.sched-item:last-child { border-bottom: none; }
.sched-time { font-size: 13px; color: var(--text-soft); font-weight: 700; min-width: 60px; padding-top: 2px; }
.sched-bar { width: 4px; min-height: 44px; border-radius: 4px; flex-shrink: 0; margin-top: 2px; }
.sched-subject { font-size: 16px; font-weight: 800; color: var(--text); }
.sched-prof { font-size: 14px; color: var(--text-soft); margin-top: 3px; }
.sched-room { display: inline-block; margin-top: 6px; font-size: 13px; font-weight: 700; background: var(--bg2); color: var(--text-mid); padding: 3px 10px; border-radius: 6px; }

/* ===== TABLE ===== */
.delta-table { width: 100%; border-collapse: collapse; }
.delta-table th { font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.8px; color: var(--text-soft); padding: 10px 14px; text-align: left; background: var(--bg2); border-bottom: 2px solid var(--border); }
.delta-table td { padding: 12px 14px; font-size: 15px; border-bottom: 1.5px solid var(--bg2); vertical-align: middle; color: var(--text); }
.delta-table tr:last-child td { border-bottom: none; }
.delta-table tr:hover td { background: var(--blue-pale); }

/* ===== PROGRESS BAR ===== */
.prog-wrap { background: var(--bg2); border-radius: 10px; height: 8px; width: 90px; overflow: hidden; }
.prog-fill { height: 100%; border-radius: 10px; }

/* ===== MESSAGES ===== */
.msg-item {
  display: flex; gap: 14px; padding: 14px 10px; border-bottom: 1.5px solid var(--bg2);
  cursor: pointer; transition: background 0.15s; border-radius: var(--radius-sm); margin-left: -10px;
}
.msg-item:hover { background: var(--blue-pale); }
.msg-item:last-child { border-bottom: none; }
.msg-av { width: 42px; height: 42px; border-radius: 12px; background: var(--blue-light); display: flex; align-items: center; justify-content: center; font-size: 20px; flex-shrink: 0; border: 1.5px solid var(--border); }
.msg-from { font-size: 15px; font-weight: 800; }
.msg-from.leido { font-weight: 600; color: var(--text-soft); }
.msg-preview { font-size: 14px; color: var(--text-soft); margin-top: 3px; }
.msg-time { font-size: 13px; color: var(--text-soft); white-space: nowrap; }
.msg-dot-unread { width: 9px; height: 9px; background: var(--blue); border-radius: 50%; margin-top: 5px; flex-shrink: 0; }

/* ===== ANNOUNCEMENTS ===== */
.ann-item { border-left: 4px solid var(--blue); background: var(--blue-pale); border-radius: 0 var(--radius-sm) var(--radius-sm) 0; padding: 14px 16px; margin-bottom: 12px; }
.ann-item:last-child { margin-bottom: 0; }
.ann-item.ann-green { border-color: var(--green); background: var(--green-bg); }
.ann-item.ann-amber { border-color: var(--amber); background: var(--amber-bg); }
.ann-titulo { font-size: 15px; font-weight: 800; color: var(--text); }
.ann-cuerpo { font-size: 14px; color: var(--text-mid); margin-top: 4px; line-height: 1.5; }
.ann-fecha { font-size: 12px; font-weight: 700; color: var(--blue); margin-top: 6px; }

/* ===== COMPOSE ===== */
.compose-wrap { border: 2px solid var(--border); border-radius: var(--radius-sm); overflow: hidden; }
.compose-input { width: 100%; padding: 13px 16px; border: none; border-bottom: 1.5px solid var(--border); font-family: 'Nunito', sans-serif; font-size: 16px; color: var(--text); background: var(--bg); }
.compose-input::placeholder { color: var(--text-soft); }
.compose-input:focus { outline: none; background: #fff; }
.compose-textarea { width: 100%; padding: 14px 16px; border: none; font-family: 'Nunito', sans-serif; font-size: 15px; color: var(--text); background: var(--bg); min-height: 100px; resize: vertical; }
.compose-textarea::placeholder { color: var(--text-soft); }
.compose-textarea:focus { outline: none; background: #fff; }
.compose-footer { padding: 12px 16px; background: var(--bg2); display: flex; justify-content: flex-end; gap: 10px; }

/* ===== HORARIO GRID ===== */
.horario-cell-clase { padding: 8px; border-radius: 8px; font-size: 14px; font-weight: 700; }

/* ===== RESPONSIVE ===== */
@media(max-width: 1100px) { .stats-4 { grid-template-columns: 1fr 1fr; } .grid-2, .grid-21 { grid-template-columns: 1fr; } }
@media(max-width: 760px) { .sidebar { width: 220px; } .main-content { margin-left: 220px; padding: 20px; } .stats-4, .stats-3 { grid-template-columns: 1fr 1fr; } }
</style>
</head>
<body>

<!-- ==================== LOGIN ==================== -->
<div id="page-login">
  <div class="login-box">
    <div class="login-logo">
      <div class="delta-mark">&#916;</div>
      <h1>Sistema Delta</h1>
      <p>Universidad Tecnologica de Panama</p>
    </div>
    <div class="login-role-banner">&#127891;&nbsp; Portal Estudiantil</div>
    <div class="form-group">
      <label for="loginUser">Usuario / Cedula</label>
      <input id="loginUser" type="text" placeholder="Ej: E-8-221893" autocomplete="username">
    </div>
    <div class="form-group">
      <label for="loginPass">Contrasena</label>
      <input id="loginPass" type="password" placeholder="&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;" autocomplete="current-password">
    </div>
    <div class="login-error" id="loginError">Usuario o contrasena incorrectos. Intente nuevamente.</div>
    <button class="btn btn-primary btn-full" onclick="doLogin()">Ingresar al Portal</button>
    <div class="login-hint">Demo: usuario <strong>estudiante</strong> &middot; clave <strong>1234</strong></div>
    <div class="login-switch">Es docente? <a href="index.jsp">Ir al Portal Docente &#8594;</a></div>
  </div>
</div>

<!-- ==================== PANEL NOTIFICACIONES ==================== -->
<div id="notifOverlay" class="notif-overlay hidden" onclick="cerrarNotifPanel()"></div>
<div id="notifPanel" class="notif-panel notif-cerrado">
  <div class="notif-panel-header">
    <span class="notif-panel-titulo">Notificaciones</span>
    <button class="notif-cerrar-btn" onclick="cerrarNotifPanel()">X</button>
  </div>
  <div class="notif-panel-body" id="notifPanelBody"></div>
</div>

<!-- ==================== PORTAL ==================== -->
<div id="page-portal" class="portal hidden">

  <!-- SIDEBAR -->
  <aside class="sidebar">
    <div class="sidebar-header">
      <div class="sidebar-logo">
        <div class="logo-mark">&#916;</div>
        <div>
          <div class="logo-name">Delta</div>
          <div class="logo-sub">Portal Estudiantil</div>
        </div>
      </div>
    </div>
    <div class="sidebar-user">
      <div class="user-avatar"><%= est_inicial %></div>
      <div>
        <div class="user-name"><%= est_nombreCompleto %></div>
        <div class="user-id"><%= est_cedula %></div>
        <div class="user-role-tag">Estudiante</div>
      </div>
    </div>
    <nav class="nav-section">
      <div class="nav-label">Principal</div>
      <button class="nav-item active" id="nav-inicio" onclick="irTab('inicio', this)">
        <span class="nav-icon">&#127968;</span> Inicio
      </button>
      <button class="nav-item" id="nav-inscripcion" onclick="irTab('inscripcion', this)">
        <span class="nav-icon">&#128203;</span> Inscripcion
      </button>
      <button class="nav-item" id="nav-calificaciones" onclick="irTab('calificaciones', this)">
        <span class="nav-icon">&#128202;</span> Calificaciones
      </button>
      <button class="nav-item" id="nav-horario" onclick="irTab('horario', this)">
        <span class="nav-icon">&#128197;</span> Horario
      </button>
      <div class="nav-label">Comunicacion</div>
      <button class="nav-item" id="nav-mensajes" onclick="irTab('mensajes', this)">
        <span class="nav-icon">&#9993;</span> Mensajes
        <span class="nav-badge" id="badgeMsgNav" style="display:none;">0</span>
      </button>
      <button class="nav-item" id="nav-avisos" onclick="irTab('avisos', this)">
        <span class="nav-icon">&#128226;</span> Avisos
      </button>
    </nav>
    <div class="sidebar-footer">
      <button class="logout-btn" onclick="cerrarSesion()">&#128682; Cerrar Sesion</button>
    </div>
  </aside>

  <!-- MAIN -->
  <main class="main-content">

    <!-- ===== INICIO ===== -->
    <div id="tab-inicio" class="tab-panel active">
      <div class="topbar">
        <div>
          <h2 class="page-title">Bienvenido/a, <%= est_nombre %></h2>
          <div class="page-subtitle">Semestre: <%= est_semestre %> &middot; <%= est_carrera %></div>
        </div>
        <div class="topbar-right">
          <div class="notif-btn" onclick="abrirNotifPanel()" style="position:relative;">
            &#128276;
            <div class="notif-dot" id="notifDot" style="display:none;"></div>
            <span id="campanaCount" style="display:none;position:absolute;top:-6px;right:-6px;background:#ef4444;color:#fff;border-radius:50%;width:18px;height:18px;font-size:11px;font-weight:700;display:flex;align-items:center;justify-content:center;"></span>
          </div>
        </div>
      </div>

      <!-- Stats dinamicos -->
      <div class="stats-row stats-4">
        <div class="stat-card">
          <div class="stat-icon-box icon-blue">&#128218;</div>
          <div>
            <div class="stat-label">Materias</div>
            <div class="stat-value" id="statMaterias">5</div>
            <div class="stat-sub">I Semestre 2026</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon-box icon-green">&#11088;</div>
          <div>
            <div class="stat-label">Promedio</div>
            <div class="stat-value" id="statPromedio">87.4</div>
            <div class="stat-sub" id="statPromedioSub">Excelente</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon-box icon-amber">&#127885;</div>
          <div>
            <div class="stat-label">Creditos</div>
            <div class="stat-value" id="statCreditos">15</div>
            <div class="stat-sub">de 180 requeridos</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon-box icon-red">&#128197;</div>
          <div>
            <div class="stat-label">Prox. Examen</div>
            <div class="stat-value" style="font-size:22px">Jun 3</div>
            <div class="stat-sub">Calidad del SW</div>
          </div>
        </div>
      </div>

      <div class="grid-2">
        <!-- Horario de hoy -->
        <div class="card">
          <div class="card-title">
            Horario de Hoy
            <button class="card-link" onclick="irTab('horario', document.getElementById('nav-horario'))">Ver semana &#8594;</button>
          </div>
          <div style="font-size:13px;font-weight:700;color:var(--blue);margin-bottom:12px;text-transform:uppercase;letter-spacing:1px;">
            Martes 27 de mayo
          </div>
          <div id="horarioHoy"></div>
        </div>
        <!-- Calificaciones resumen -->
        <div class="card">
          <div class="card-title">
            Mis Calificaciones
            <button class="card-link" onclick="irTab('calificaciones', document.getElementById('nav-calificaciones'))">Ver todas &#8594;</button>
          </div>
          <table class="delta-table">
            <thead><tr><th>Materia</th><th>Nota</th><th>Progreso</th></tr></thead>
            <tbody id="calResumen"></tbody>
          </table>
        </div>
      </div>

      <div class="grid-2">
        <!-- Mensajes resumen -->
        <div class="card">
          <div class="card-title">
            Mensajes recientes
            <button class="card-link" onclick="irTab('mensajes', document.getElementById('nav-mensajes'))">Ver bandeja &#8594;</button>
          </div>
          <div id="mensajesResumen"></div>
        </div>
        <!-- Avisos resumen -->
        <div class="card">
          <div class="card-title">
            Avisos Institucionales
            <button class="card-link" onclick="irTab('avisos', document.getElementById('nav-avisos'))">Ver todos &#8594;</button>
          </div>
          <div class="ann-item">
            <div class="ann-titulo">Matricula II Semestre 2026</div>
            <div class="ann-cuerpo">El periodo de inscripcion inicia el 2 de junio. Revisa los requisitos.</div>
            <div class="ann-fecha">26 mayo 2026</div>
          </div>
          <div class="ann-item ann-green">
            <div class="ann-titulo">Semana de Ingenieria</div>
            <div class="ann-cuerpo">Actividades del 9 al 13 de junio. Exposicion de proyectos finales.</div>
            <div class="ann-fecha">24 mayo 2026</div>
          </div>
          <div class="ann-item ann-amber">
            <div class="ann-titulo">Examen Parcial BD II</div>
            <div class="ann-cuerpo">Jueves 29 de mayo a las 9:00 AM. Revisar temas de SQL avanzado.</div>
            <div class="ann-fecha">23 mayo 2026</div>
          </div>
        </div>
      </div>
    </div><!-- fin tab-inicio -->

    <!-- ===== INSCRIPCION ===== -->
    <div id="tab-inscripcion" class="tab-panel">
      <div class="topbar">
        <div>
          <h2 class="page-title">Inscripcion de Materias</h2>
          <div class="page-subtitle">I Semestre 2026 &middot; Materias disponibles</div>
        </div>
      </div>
      <div class="stats-row stats-3">
        <div class="stat-card">
          <div class="stat-icon-box icon-blue">&#128218;</div>
          <div>
            <div class="stat-label">Inscritas</div>
            <div class="stat-value" id="inscCant">5</div>
            <div class="stat-sub">de 6 permitidas</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon-box icon-green">&#9989;</div>
          <div>
            <div class="stat-label">Creditos Activos</div>
            <div class="stat-value" id="inscCred">15</div>
            <div class="stat-sub">creditos</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon-box icon-amber">&#9200;</div>
          <div>
            <div class="stat-label">Cierre Matricula</div>
            <div class="stat-value" style="font-size:20px">Jun 6</div>
            <div class="stat-sub">Plazo limite</div>
          </div>
        </div>
      </div>
      <div class="card" style="margin-bottom:22px;">
        <div class="card-title">Materias Actualmente Inscritas</div>
        <div style="overflow-x:auto;">
          <table class="delta-table">
            <thead>
              <tr>
                <th>Codigo</th><th>Materia</th><th>Creditos</th>
                <th>Horario</th><th>Docente</th><th>Estado</th><th>Accion</th>
              </tr>
            </thead>
            <tbody id="tablaInscritas"></tbody>
          </table>
        </div>
      </div>
      <div class="card">
        <div class="card-title">Materias Disponibles para Agregar</div>
        <div style="overflow-x:auto;">
          <table class="delta-table">
            <thead>
              <tr>
                <th>Codigo</th><th>Materia</th><th>Creditos</th>
                <th>Cupos</th><th>Horario</th><th>Accion</th>
              </tr>
            </thead>
            <tbody id="tablaDisponibles"></tbody>
          </table>
        </div>
      </div>
    </div><!-- fin tab-inscripcion -->

    <!-- ===== CALIFICACIONES ===== -->
    <div id="tab-calificaciones" class="tab-panel">
      <div class="topbar">
        <div>
          <h2 class="page-title">Mis Calificaciones</h2>
          <div class="page-subtitle">I Semestre 2026 &middot; Historial academico</div>
        </div>
        <button class="btn btn-secondary" onclick="alert('Descargando reporte PDF...')">Descargar PDF</button>
      </div>
      <div class="stats-row stats-3">
        <div class="stat-card">
          <div class="stat-icon-box icon-green">&#11088;</div>
          <div>
            <div class="stat-label">Promedio General</div>
            <div class="stat-value" id="calProm">87.4</div>
            <div class="stat-sub">Excelente</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon-box icon-green">&#9989;</div>
          <div>
            <div class="stat-label">Materias Aprobadas</div>
            <div class="stat-value" id="calAprobadas">5</div>
            <div class="stat-sub" id="calAprobSub">de 5 activas</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon-box icon-blue">&#127885;</div>
          <div>
            <div class="stat-label">Mejor Nota</div>
            <div class="stat-value" id="calMejor">92</div>
            <div class="stat-sub" id="calMejorSub">Calidad del SW</div>
          </div>
        </div>
      </div>
      <div class="card">
        <div class="card-title">Detalle de Calificaciones por Materia</div>
        <div style="overflow-x:auto;">
          <table class="delta-table">
            <thead>
              <tr>
                <th>Materia</th><th>Parcial 1</th><th>Parcial 2</th>
                <th>Proyecto</th><th>Final</th><th>Nota Final</th><th>Estado</th>
              </tr>
            </thead>
            <tbody id="calDetalle"></tbody>
          </table>
        </div>
      </div>
    </div><!-- fin tab-calificaciones -->

    <!-- ===== HORARIO ===== -->
    <div id="tab-horario" class="tab-panel">
      <div class="topbar">
        <div>
          <h2 class="page-title">Mi Horario Semanal</h2>
          <div class="page-subtitle">I Semestre 2026</div>
        </div>
      </div>
      <div class="card">
        <div class="card-title">Semana del 27 al 31 de Mayo, 2026</div>
        <div style="overflow-x:auto;">
          <table class="delta-table" style="min-width:700px;">
            <thead>
              <tr>
                <th style="width:100px;">Hora</th>
                <th>Lunes</th><th>Martes</th><th>Miercoles</th><th>Jueves</th><th>Viernes</th>
              </tr>
            </thead>
            <tbody id="tablaHorario"></tbody>
          </table>
        </div>
      </div>
    </div><!-- fin tab-horario -->

    <!-- ===== MENSAJES ===== -->
    <div id="tab-mensajes" class="tab-panel">
      <div class="topbar">
        <div>
          <h2 class="page-title">Mensajes</h2>
          <div class="page-subtitle">Comunicacion con docentes y administracion</div>
        </div>
      </div>
      <div class="grid-21">
        <div class="card">
          <div class="card-title">
            Bandeja de Entrada
            <span class="nav-badge" id="badgeInbox" style="display:none;">0</span>
          </div>
          <div id="bandeja"></div>
        </div>
        <div class="card">
          <div class="card-title">Nuevo Mensaje</div>
          <div class="compose-wrap">
            <datalist id="docentesOpciones">
              <option value="María Mosquera">
            </datalist>
            <input class="compose-input" id="msgPara" type="text" list="docentesOpciones" placeholder="Para: María Mosquera..." value="María Mosquera">
            <input class="compose-input" id="msgAsunto" type="text" placeholder="Asunto...">
            <textarea class="compose-textarea" id="msgCuerpo" placeholder="Escribe tu mensaje aqui..."></textarea>
            <div class="compose-footer">
              <button class="btn btn-secondary btn-sm">Adjuntar</button>
              <button class="btn btn-primary btn-sm" onclick="enviarMsg()">Enviar</button>
            </div>
          </div>
        </div>
      </div>
    </div><!-- fin tab-mensajes -->

    <!-- ===== AVISOS ===== -->
    <div id="tab-avisos" class="tab-panel">
      <div class="topbar">
        <div>
          <h2 class="page-title">Avisos Institucionales</h2>
          <div class="page-subtitle">Comunicados oficiales de la universidad</div>
        </div>
      </div>
      <div class="card">
        <div class="ann-item">
          <div class="ann-titulo">Apertura de Matricula - II Semestre 2026</div>
          <div class="ann-cuerpo">El periodo de inscripcion para el II Semestre 2026 iniciara el lunes 2 de junio. Asegurate de no tener deudas academicas o financieras pendientes.</div>
          <div class="ann-fecha">26 mayo 2026 - Registraduria</div>
        </div>
        <div class="ann-item ann-green">
          <div class="ann-titulo">Semana de Ingenieria UTP 2026</div>
          <div class="ann-cuerpo">Del 9 al 13 de junio se realizara la Semana de Ingenieria. Los grupos de la Facultad de Sistemas presentaran sus proyectos finales en exposicion abierta al publico.</div>
          <div class="ann-fecha">24 mayo 2026 - FISC</div>
        </div>
        <div class="ann-item ann-amber">
          <div class="ann-titulo">Mantenimiento del Sistema Delta</div>
          <div class="ann-cuerpo">El sabado 1 de junio de 1:00 AM a 5:00 AM el sistema estara en mantenimiento programado. No habra acceso durante ese periodo.</div>
          <div class="ann-fecha">22 mayo 2026 - DTI</div>
        </div>
        <div class="ann-item">
          <div class="ann-titulo">Actualizacion del Sistema Delta v1.2</div>
          <div class="ann-cuerpo">Se ha implementado la version 1.2 del Portal Delta con mejoras de rendimiento, mayor seguridad y accesibilidad mejorada.</div>
          <div class="ann-fecha">20 mayo 2026 - DTI</div>
        </div>
      </div>
    </div><!-- fin tab-avisos -->

  </main>
</div><!-- fin portal -->

<!-- ==================== JAVASCRIPT ==================== -->
<script type="text/javascript">

// ============================================================
// DATOS CENTRALES
// ============================================================

// Mapa de info estática por código de materia (horarios, colores, días)
var INFO_MATERIAS = {
  'IS-401': { creditos:3, horario:'Mar/Jue 7:00 AM',  color:'#1a56a0', colorBg:'#dbeafe', dias:{mar:'7:00 AM',jue:'7:00 AM'},   aula:'Aula 3B'        },
  'BD-301': { creditos:3, horario:'Mar/Jue 9:00 AM',  color:'#0e7490', colorBg:'#cffafe', dias:{mar:'9:00 AM',jue:'9:00 AM'},   aula:'Lab. Computo 1'  },
  'WD-201': { creditos:3, horario:'Mar/Jue 11:00 AM', color:'#15803d', colorBg:'#dcfce7', dias:{mar:'11:00 AM',jue:'11:00 AM'}, aula:'Lab. Computo 3'  },
  'RC-402': { creditos:3, horario:'Mar 1:00 PM',       color:'#7c3aed', colorBg:'#ede9fe', dias:{mar:'1:00 PM'},                 aula:'Aula 5A'         },
  'SO-301': { creditos:3, horario:'Lun/Mie 7:00 AM',  color:'#b45309', colorBg:'#fef3c7', dias:{lun:'7:00 AM',mie:'7:00 AM'},   aula:'Aula 2A'         },
  'IA-401': { creditos:3, horario:'Vie 7:00 AM',       color:'#dc2626', colorBg:'#fee2e2', dias:{vie:'7:00 AM'},                 aula:'Aula 6B'         },
  'EM-201': { creditos:2, horario:'Mie 1:00 PM',       color:'#0f766e', colorBg:'#ccfbf1', dias:{mie:'1:00 PM'},                 aula:'Aula 4C'         },
  'EC-301': { creditos:2, horario:'Jue 3:00 PM',       color:'#9333ea', colorBg:'#f3e8ff', dias:{jue:'3:00 PM'},                 aula:'Aula 1A'         }
};

// Codigos de materias extras (disponibles para inscribir)
var CODIGOS_EXTRAS = ['IA-401','EM-201','EC-301'];

function enriquecerMateria(m) {
  var info = INFO_MATERIAS[m.codigo] || { creditos:3, horario:'', color:'#1a56a0', colorBg:'#eff6ff', dias:{}, aula:'' };
  return {
    codigo:   m.codigo,
    nombre:   m.nombre,
    creditos: info.creditos,
    horario:  info.horario,
    color:    info.color,
    colorBg:  info.colorBg,
    dias:     info.dias,
    aula:     info.aula,
    docente:  m.docente || 'Por asignar',
    cupos:    '30/30',
    p1:       m.p1   || 0,
    p2:       m.p2   || 0,
    proj:     m.proj || 0,
    exFinal:  m.ef   || 0,
    nota:     m.nota || 0
  };
}

// Separar materias principales de extras desde BD
var _todosBD = [];
try {
  var _jsonBD = '<%= est_materiasJson %>';
  if (_jsonBD && _jsonBD !== '[]') _todosBD = JSON.parse(_jsonBD);
} catch(e) {}

var materiasInscritas    = [];
var materiasDisponibles  = [];

if (_todosBD.length) {
  _todosBD.forEach(function(m) {
    var em = enriquecerMateria(m);
    if (CODIGOS_EXTRAS.indexOf(m.codigo) === -1) {
      materiasInscritas.push(em);   // principales → inscritas
    } else if (m.nota > 0) {
      materiasInscritas.push(em);   // extra ya inscrita con nota
    } else {
      em.cupos = INFO_MATERIAS[m.codigo] ? '30/30' : '30/30';
      materiasDisponibles.push(em); // extra sin nota → disponible
    }
  });
} else {
  // Demo si no hay BD
  materiasInscritas = [
    enriquecerMateria({codigo:'IS-401',nombre:'Calidad del Software',docente:'Mosquera, M.',p1:90,p2:88,proj:95,ef:94,nota:92})
  ];
  materiasDisponibles = [
    enriquecerMateria({codigo:'IA-401',nombre:'Inteligencia Artificial',docente:'Perez, L.',p1:0,p2:0,proj:0,ef:0,nota:0}),
    enriquecerMateria({codigo:'EM-201',nombre:'Emprendimiento Tech',docente:'Quiros, F.',p1:0,p2:0,proj:0,ef:0,nota:0}),
    enriquecerMateria({codigo:'EC-301',nombre:'Etica Computacional',docente:'Nunez, P.',p1:0,p2:0,proj:0,ef:0,nota:0})
  ];
}

// Mensajes: leido = false por defecto
var mensajesData = [
  { id:1, avatar:"P.M", de:"Prof. Maria Mosquera",  preview:"Recordatorio: entrega del Proyecto Delta el viernes 30 de mayo antes de las 11:59 PM.", hora:"Hoy, 9:42 AM",  leido:false },
  { id:2, avatar:"P.R", de:"Prof. Carlos Ramos",    preview:"El laboratorio de manana esta confirmado en sala 1. Traer el proyecto BD.",               hora:"Ayer, 3:15 PM", leido:false },
  { id:3, avatar:"ADM", de:"Administracion UTP",    preview:"El periodo de matricula del II Semestre 2026 inicia el proximo lunes 2 de junio.",         hora:"Lun, 8:00 AM",  leido:false }
];

// Notificaciones ligadas a mensajes (msgId = mensajesData[i].id)
var notifData = [
  { id:1, msgId:1, icon:"P.M", iconBg:"#dbeafe", titulo:"Mensaje de Prof. Mosquera",   cuerpo:"Recordatorio: entrega del Proyecto Delta el viernes 30 de mayo.", hora:"Hace 20 minutos" },
  { id:2, msgId:2, icon:"P.R", iconBg:"#e0f2fe", titulo:"Mensaje de Prof. Ramos",      cuerpo:"Laboratorio de manana confirmado en sala 1. Traer proyecto BD.",   hora:"Ayer, 3:15 PM"  },
  { id:3, msgId:3, icon:"ADM", iconBg:"#fef3c7", titulo:"Aviso de Administracion UTP", cuerpo:"Periodo de matricula del II Semestre inicia el 2 de junio.",       hora:"Lun, 8:00 AM"   }
];

var horasSlots = ["7:00 AM","9:00 AM","11:00 AM","1:00 PM","3:00 PM"];
var diasKeys   = ["lun","mar","mie","jue","vie"];

// ============================================================
// NAVEGACION
// ============================================================
function irTab(id, boton) {
  var paneles = document.querySelectorAll('.tab-panel');
  for (var i = 0; i < paneles.length; i++) paneles[i].classList.remove('active');
  var navItems = document.querySelectorAll('.nav-item');
  for (var i = 0; i < navItems.length; i++) navItems[i].classList.remove('active');

  document.getElementById('tab-' + id).classList.add('active');

  if (boton) {
    boton.classList.add('active');
  } else {
    var navBoton = document.getElementById('nav-' + id);
    if (navBoton) navBoton.classList.add('active');
  }
  window.scrollTo(0, 0);
}

// ============================================================
// LOGIN / LOGOUT
// ============================================================
function doLogin() {
  var user = document.getElementById('loginUser').value.trim();
  var pass = document.getElementById('loginPass').value.trim();
  var err  = document.getElementById('loginError');
  if (!user || !pass) { err.style.display='block'; setTimeout(function(){err.style.display='none';},3500); return; }
  var params = 'username='+encodeURIComponent(user)+'&password='+encodeURIComponent(pass)+'&destino=estudiante';
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/login', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:params, redirect:'follow'})
    .then(function(r) {
      if (r.url && r.url.indexOf('portal_estudiante') !== -1) {
        window.location.href = r.url;
      } else if (r.url && r.url.indexOf('error=1') !== -1) {
        err.style.display='block'; setTimeout(function(){err.style.display='none';},3500);
      } else {
        window.location.reload();
      }
    }).catch(function(){ err.style.display='block'; setTimeout(function(){err.style.display='none';},3500); });
}

document.getElementById('loginPass').addEventListener('keydown', function(e) {
  if (e.key === 'Enter') doLogin();
});

function cerrarSesion() {
  if (confirm('Desea cerrar sesion?')) {
    document.getElementById('page-portal').classList.add('hidden');
    document.getElementById('page-login').classList.remove('hidden');
    document.getElementById('loginUser').value = '';
    document.getElementById('loginPass').value = '';
    cerrarNotifPanel();
  }
}

// ============================================================
// INICIO DEL PORTAL
// ============================================================
function iniciarPortal() {
  renderInscritas();
  renderDisponibles();
  renderCalResumen();
  renderCalDetalle();
  renderHorario();
  renderHorarioHoy();
  renderBandeja();
  renderMensajesResumen();
  actualizarBadges();
}

// ============================================================
// NOTIFICACIONES
// ============================================================
function abrirNotifPanel() {
  document.getElementById('notifOverlay').classList.remove('hidden');
  document.getElementById('notifPanel').classList.remove('notif-cerrado');
  renderNotifPanel();
}

function cerrarNotifPanel() {
  document.getElementById('notifOverlay').classList.add('hidden');
  document.getElementById('notifPanel').classList.add('notif-cerrado');
}

function renderNotifPanel() {
  var body = document.getElementById('notifPanelBody');
  body.innerHTML = '<div style="text-align:center;padding:20px;color:#6b7e96;">Cargando...</div>';
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  // Cargar mensajes no leídos como notificaciones
  fetch(ctx+'/mensajes?accion=bandeja')
    .then(function(r){ return r.json(); })
    .then(function(msgs){
      body.innerHTML = '';
      var noLeidos = msgs.filter(function(m){ return !m.leido; });
      if (msgs.length === 0) {
        body.innerHTML = '<div style="text-align:center;padding:20px;color:#6b7e96;">Sin notificaciones.</div>';
      } else {
        msgs.forEach(function(msg) {
          var initials = msg.remitente ? msg.remitente.split(' ').map(function(p){return p[0];}).join('').substring(0,2).toUpperCase() : '??';
          var div = document.createElement('div');
          div.className = 'notif-card ' + (msg.leido ? 'ncard-read' : 'ncard-unread');
          div.innerHTML =
            '<div class="notif-card-icon" style="background:#dbeafe;">' + initials + '</div>' +
            '<div style="flex:1;">' +
              '<div class="notif-card-titulo">' + (msg.remitente||'Desconocido') + '</div>' +
              '<div class="notif-card-cuerpo">' + (msg.asunto||'') + '</div>' +
              '<div class="notif-card-hora">' + (msg.fecha||'') + '</div>' +
              '<button class="' + (msg.leido?'btn-visto visto-ok':'btn-visto') + '" ' +
                (msg.leido?'disabled':'onclick="marcarVistoMsg('+msg.id+')"') + '>' +
                (msg.leido?'Visto':'Marcar como visto') + '</button>' +
            '</div>';
          body.appendChild(div);
        });
      }
      var footer = document.createElement('div');
      footer.style.cssText = 'margin-top:14px;text-align:center;';
      footer.innerHTML = '<button class="btn btn-secondary btn-sm" onclick="marcarTodosVistoMsg()">Marcar todas como vistas</button>';
      body.appendChild(footer);
      // Actualizar punto rojo y número en campanita
      var noLeidosCount = noLeidos.length;
      var dot        = document.getElementById('notifDot');
      var campanaNum = document.getElementById('campanaCount');
      var badgeNav   = document.getElementById('badgeMsgNav');
      var badgeInbox = document.getElementById('badgeInbox');
      if (dot)        { dot.style.display        = noLeidosCount > 0 ? '' : 'none'; }
      if (campanaNum) { campanaNum.textContent    = noLeidosCount; campanaNum.style.display = noLeidosCount > 0 ? 'flex' : 'none'; }
      if (badgeNav)   { badgeNav.textContent      = noLeidosCount; badgeNav.style.display   = noLeidosCount > 0 ? '' : 'none'; }
      if (badgeInbox) { badgeInbox.textContent    = noLeidosCount; badgeInbox.style.display  = noLeidosCount > 0 ? '' : 'none'; }
    }).catch(function(){
      body.innerHTML = '<div style="text-align:center;padding:20px;color:#6b7e96;">Error al cargar.</div>';
    });
}

function marcarVistoMsg(msgId) {
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/mensajes?accion=marcarLeido', {method:'POST',
    headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'id='+msgId})
    .then(function(r){ return r.json(); })
    .then(function(d){
      renderNotifPanel();
      renderBandeja();
      // Actualizar badge inmediatamente
      var noLeidos = d.noLeidos || 0;
      var campanaNum = document.getElementById('campanaCount');
      var badgeNav   = document.getElementById('badgeMsgNav');
      var dot        = document.getElementById('notifDot');
      if (campanaNum) { campanaNum.textContent = noLeidos; campanaNum.style.display = noLeidos>0 ? 'flex' : 'none'; }
      if (badgeNav)   { badgeNav.textContent = noLeidos;  badgeNav.style.display   = noLeidos>0 ? '' : 'none'; }
      if (dot)        { dot.style.display = noLeidos>0 ? '' : 'none'; }
    });
}

function marcarTodosVistoMsg() {
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/mensajes?accion=marcarTodasLeidas', {method:'POST'})
    .then(function(){
      renderNotifPanel();
      actualizarBadges();
      renderBandeja();
    });
}

function marcarVisto(notifId) {
  var n = getNotifPorId(notifId);
  if (!n) return;
  var msg = getMensajePorId(n.msgId);
  if (msg) msg.leido = true;
  renderNotifPanel();
  actualizarBadges();
  renderBandeja();
  renderMensajesResumen();
}

function marcarTodosVisto() {
  for (var i = 0; i < notifData.length; i++) {
    var msg = getMensajePorId(notifData[i].msgId);
    if (msg) msg.leido = true;
  }
  renderNotifPanel();
  actualizarBadges();
  renderBandeja();
  renderMensajesResumen();
}

function getNotifPorId(id) {
  for (var i = 0; i < notifData.length; i++) {
    if (notifData[i].id === id) return notifData[i];
  }
  return null;
}

function getMensajePorId(id) {
  for (var i = 0; i < mensajesData.length; i++) {
    if (mensajesData[i].id === id) return mensajesData[i];
  }
  return null;
}

// ============================================================
// BADGES
// ============================================================
function actualizarBadges() {
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/mensajes?accion=noLeidos')
    .then(function(r){ return r.json(); })
    .then(function(d){
      var noLeidos = d.mensajes || 0;
      var badgeNav    = document.getElementById('badgeMsgNav');
      var badgeInbox  = document.getElementById('badgeInbox');
      var dot         = document.getElementById('notifDot');
      var campanaNum  = document.getElementById('campanaCount');
      if (badgeNav)   { badgeNav.textContent = noLeidos;   badgeNav.style.display   = noLeidos>0 ? '' : 'none'; }
      if (badgeInbox) { badgeInbox.textContent = noLeidos; badgeInbox.style.display = noLeidos>0 ? '' : 'none'; }
      if (dot)        { dot.style.display = noLeidos>0 ? '' : 'none'; }
      if (campanaNum) { campanaNum.textContent = noLeidos; campanaNum.style.display = noLeidos>0 ? 'flex' : 'none'; }
    }).catch(function(){});
}
function actualizarBadges_legacy() {
  var noLeidos = 0;
  for (var i = 0; i < mensajesData.length; i++) {
    if (!mensajesData[i].leido) noLeidos++;
  }
  var badgeNav   = document.getElementById('badgeMsgNav');
  var badgeInbox = document.getElementById('badgeInbox');
  var dot = document.getElementById('notifDot');

  if (badgeNav)   { badgeNav.textContent   = noLeidos; badgeNav.style.display   = noLeidos > 0 ? 'inline-block' : 'none'; }
  if (badgeInbox) { badgeInbox.textContent = noLeidos; badgeInbox.style.display = noLeidos > 0 ? 'inline-block' : 'none'; }
  if (dot) dot.style.display = noLeidos > 0 ? 'block' : 'none';
}

// ============================================================
// MENSAJES
// ============================================================
function renderBandeja() {
  var cont = document.getElementById('bandeja');
  if (!cont) return;
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  cont.innerHTML = '<div style="text-align:center;padding:20px;color:#6b7e96;">Cargando mensajes...</div>';
  fetch(ctx+'/mensajes?accion=bandeja')
    .then(function(r){ return r.json(); })
    .then(function(msgs){
      cont.innerHTML = '';
      if (msgs.length === 0) {
        cont.innerHTML = '<div style="text-align:center;padding:24px;color:#6b7e96;">No tienes mensajes.</div>';
        return;
      }
      msgs.forEach(function(msg) {
        var div = document.createElement('div');
        div.className = 'msg-item';
        var initials = msg.remitente ? msg.remitente.split(' ').map(function(p){return p[0];}).join('').substring(0,2).toUpperCase() : 'XX';
        var fromClass = msg.leido ? 'msg-from leido' : 'msg-from';
        var dotStyle  = msg.leido ? 'display:none;' : '';
        div.innerHTML =
          '<div class="msg-av">' + initials + '</div>' +
          '<div style="flex:1;min-width:0;">' +
            '<div class="' + fromClass + '">' + (msg.remitente||'Desconocido') + '</div>' +
            '<div class="msg-preview">' + (msg.asunto||'') + ' — ' + (msg.cuerpo||'').substring(0,60) + '</div>' +
            '<div style="font-size:12px;color:var(--text-soft);margin-top:4px;">' + (msg.fecha||'') + '</div>' +
          '</div>' +
          '<div class="msg-dot-unread" style="' + dotStyle + '"></div>';
        div.onclick = function() {
          if (!msg.leido) {
            fetch(ctx+'/mensajes?accion=marcarLeido', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'id='+msg.id});
            msg.leido = true;
            div.querySelector('.msg-dot-unread').style.display='none';
            div.querySelector('.msg-from').className='msg-from leido';
          }
          alert('De: ' + (msg.remitente||'') + '\nAsunto: ' + (msg.asunto||'') + '\n\n' + (msg.cuerpo||''));
        };
        cont.appendChild(div);
      });
    }).catch(function(){
      cont.innerHTML = '<div style="text-align:center;padding:24px;color:#6b7e96;">No se pudo cargar la bandeja.</div>';
    });
}

function renderMensajesResumen() {
  var cont = document.getElementById('mensajesResumen');
  if (!cont) return;
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/mensajes?accion=bandeja')
    .then(function(r){ return r.json(); })
    .then(function(msgs){
      cont.innerHTML = '';
      if (!msgs.length) {
        cont.innerHTML = '<div style="color:var(--text-soft);font-size:14px;padding:8px 0;">No tienes mensajes.</div>';
        return;
      }
      // Mostrar solo los 3 más recientes
      msgs.slice(0,3).forEach(function(msg) {
        var initials = msg.remitente ? msg.remitente.split(' ').map(function(p){return p[0];}).join('').substring(0,2).toUpperCase() : '??';
        var div = document.createElement('div');
        div.className = 'msg-item';
        div.onclick = function(){ irTab('mensajes', document.getElementById('nav-mensajes')); };
        var fromClass = msg.leido ? 'msg-from leido' : 'msg-from';
        var dotStyle  = msg.leido ? 'display:none;' : '';
        div.innerHTML =
          '<div class="msg-av">' + initials + '</div>' +
          '<div style="flex:1;min-width:0;">' +
            '<div class="' + fromClass + '">' + (msg.remitente||'Desconocido') + '</div>' +
            '<div class="msg-preview">' + (msg.asunto||'') + '</div>' +
          '</div>' +
          '<div style="display:flex;flex-direction:column;align-items:flex-end;gap:4px;">' +
            '<div class="msg-dot-unread" style="' + dotStyle + '"></div>' +
          '</div>';
        cont.appendChild(div);
      });
    }).catch(function(){
      cont.innerHTML = '<div style="color:var(--text-soft);font-size:14px;padding:8px 0;">No tienes mensajes.</div>';
    });
}

function enviarMsg() {
  var para   = document.getElementById('msgPara').value.trim();
  var asunto = document.getElementById('msgAsunto').value.trim() || '(Sin asunto)';
  var cuerpo = document.getElementById('msgCuerpo').value.trim();
  if (!para || !cuerpo) { alert('Complete el destinatario y el mensaje.'); return; }
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  var params = 'accion=enviar&destinatario='+encodeURIComponent(para)+'&asunto='+encodeURIComponent(asunto)+'&cuerpo='+encodeURIComponent(cuerpo);
  fetch(ctx+'/mensajes', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:params})
    .then(function(r){ return r.json(); })
    .then(function(d){
      if (d.ok) {
        alert('Mensaje enviado a: ' + para);
        document.getElementById('msgPara').value   = 'María Mosquera';
        document.getElementById('msgAsunto').value = '';
        document.getElementById('msgCuerpo').value = '';
        renderBandeja();
        actualizarBadges();
      } else {
        alert('Error: ' + (d.error || 'No se pudo enviar el mensaje.'));
      }
    }).catch(function(){ alert('Error de conexión al enviar el mensaje.'); });
}

// ============================================================
// INSCRIPCION
// ============================================================
function calcCreditos() {
  var total = 0;
  for (var i = 0; i < materiasInscritas.length; i++) total += materiasInscritas[i].creditos;
  return total;
}

function renderInscritas() {
  var tbody = document.getElementById('tablaInscritas');
  if (!tbody) return;
  tbody.innerHTML = '';
  for (var i = 0; i < materiasInscritas.length; i++) {
    (function(m, idx) {
      var tr = document.createElement('tr');
      tr.innerHTML =
        '<td>' + m.codigo + '</td>' +
        '<td><strong>' + m.nombre + '</strong></td>' +
        '<td>' + m.creditos + '</td>' +
        '<td>' + m.horario + '</td>' +
        '<td>' + m.docente + '</td>' +
        '<td><span class="tag tag-green">Inscrita</span></td>' +
        '<td><button class="btn-danger" onclick="desinscribir(\'' + m.codigo + '\')">Eliminar</button></td>';
      tbody.appendChild(tr);
    })(materiasInscritas[i], i);
  }
  actualizarContadoresInscripcion();
}

function renderDisponibles() {
  var tbody = document.getElementById('tablaDisponibles');
  if (!tbody) return;
  tbody.innerHTML = '';
  if (materiasDisponibles.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text-soft);padding:20px;">No hay mas materias disponibles.</td></tr>';
    return;
  }
  for (var i = 0; i < materiasDisponibles.length; i++) {
    (function(m, idx) {
      var tr = document.createElement('tr');
      tr.innerHTML =
        '<td>' + m.codigo + '</td>' +
        '<td><strong>' + m.nombre + '</strong></td>' +
        '<td>' + m.creditos + '</td>' +
        '<td>' + m.cupos + '</td>' +
        '<td>' + m.horario + '</td>' +
        '<td><button class="btn btn-primary btn-sm" onclick="inscribirMateria(\'' + m.codigo + '\')">Inscribir</button></td>';
      tbody.appendChild(tr);
    })(materiasDisponibles[i], i);
  }
}

function actualizarContadoresInscripcion() {
  var cant = materiasInscritas.length;
  var cred = calcCreditos();
  var aprobadas = 0;
  for (var i = 0; i < materiasInscritas.length; i++) {
    if (materiasInscritas[i].nota >= 71) aprobadas++;
  }

  var elCant = document.getElementById('inscCant');
  var elCred = document.getElementById('inscCred');
  if (elCant) elCant.textContent = cant;
  if (elCred) elCred.textContent = cred;

  var elM = document.getElementById('statMaterias');
  var elC = document.getElementById('statCreditos');
  if (elM) elM.textContent = cant;
  if (elC) elC.textContent = cred;

  var elAp = document.getElementById('calAprobadas');
  var elAs = document.getElementById('calAprobSub');
  if (elAp) elAp.textContent = aprobadas;
  if (elAs) elAs.textContent = 'de ' + cant + ' activas';
}

function inscribirMateria(codigo) {
  var idx = -1;
  for (var i = 0; i < materiasDisponibles.length; i++) {
    if (materiasDisponibles[i].codigo === codigo) { idx = i; break; }
  }
  if (idx === -1) return;
  var m = materiasDisponibles[idx];
  if (materiasInscritas.length >= 6) {
    alert('Ha alcanzado el limite de 6 materias permitidas.');
    return;
  }
  if (!confirm('Desea inscribir la materia: ' + m.nombre + '?')) return;
  materiasInscritas.push(m);
  materiasDisponibles.splice(idx, 1);
  renderInscritas();
  renderDisponibles();
  renderCalResumen();
  renderCalDetalle();
  renderHorario();
  renderHorarioHoy();
  actualizarContadoresInscripcion();
}

function desinscribir(codigo) {
  var idx = -1;
  for (var i = 0; i < materiasInscritas.length; i++) {
    if (materiasInscritas[i].codigo === codigo) { idx = i; break; }
  }
  if (idx === -1) return;
  var m = materiasInscritas[idx];
  if (!confirm('Desea eliminar la inscripcion de: ' + m.nombre + '?')) return;
  materiasInscritas.splice(idx, 1);
  materiasDisponibles.push(m);
  renderInscritas();
  renderDisponibles();
  renderCalResumen();
  renderCalDetalle();
  renderHorario();
  renderHorarioHoy();
  actualizarContadoresInscripcion();
}

// ============================================================
// CALIFICACIONES
// ============================================================
function getTagClass(nota) {
  if (nota >= 90) return 'tag-green';
  if (nota >= 80) return 'tag-blue';
  if (nota >= 70) return 'tag-amber';
  return 'tag-red';
}

function getBarColor(nota) {
  if (nota >= 90) return 'var(--green)';
  if (nota >= 80) return 'var(--blue)';
  if (nota >= 70) return 'var(--amber)';
  return 'var(--red)';
}

function renderCalResumen() {
  var tbody = document.getElementById('calResumen');
  if (!tbody) return;
  tbody.innerHTML = '';
  if (!materiasInscritas.length) {
    tbody.innerHTML = '<tr><td colspan="3" style="text-align:center;padding:16px;color:#6b7e96;">Sin materias inscritas.</td></tr>';
    return;
  }
  materiasInscritas.forEach(function(m) {
    var nota = m.nota || 0;
    var tr = document.createElement('tr');
    tr.innerHTML =
      '<td><strong>' + m.nombre + '</strong></td>' +
      '<td><span class="tag ' + getTagClass(nota) + '">' + nota + '</span></td>' +
      '<td><div class="prog-wrap"><div class="prog-fill" style="width:' + Math.min(nota,100) + '%;background:' + getBarColor(nota) + ';"></div></div></td>';
    tbody.appendChild(tr);
  });
  actualizarStatsCalificaciones();
  renderCalDetalle();
  actualizarContadoresInscripcion();
}

function renderCalDetalle() {
  var tbody = document.getElementById('calDetalle');
  if (!tbody) return;
  tbody.innerHTML = '';
  materiasInscritas.forEach(function(m) {
    var nota = m.nota || 0;
    var estado = nota >= 71
      ? '<span class="tag tag-green">Aprobado</span>'
      : (nota > 0 ? (nota >= 61 ? '<span class="tag tag-amber">En proceso</span>' : '<span class="tag tag-red">Reprobado</span>') : '<span class="tag tag-gray">Sin notas</span>');
    var tr = document.createElement('tr');
    tr.innerHTML =
      '<td><strong>' + m.nombre + '</strong></td>' +
      '<td>' + (m.p1   > 0 ? m.p1   : '-') + '</td>' +
      '<td>' + (m.p2   > 0 ? m.p2   : '-') + '</td>' +
      '<td>' + (m.proj > 0 ? m.proj : '-') + '</td>' +
      '<td>' + (m.exFinal > 0 ? m.exFinal : '-') + '</td>' +
      '<td><span class="tag ' + getTagClass(nota) + '" style="font-size:16px;padding:6px 14px;">' + (nota>0?nota:'-') + '</span></td>' +
      '<td>' + estado + '</td>';
    tbody.appendChild(tr);
  });
}

function actualizarStatsCalificaciones() {
  if (!materiasInscritas.length) return;
  var suma = 0; var mejor = 0; var mejorNombre = ''; var conNotas = 0;
  materiasInscritas.forEach(function(m) {
    var n = m.nota || 0;
    if (n > 0) { suma += n; conNotas++; if (n > mejor) { mejor = n; mejorNombre = m.nombre; } }
  });
  var prom = conNotas > 0 ? Math.round((suma/conNotas)*10)/10 : 0;
  var elProm=document.getElementById('calProm'), elMejor=document.getElementById('calMejor'),
      elMejorS=document.getElementById('calMejorSub'), elPromI=document.getElementById('statPromedio');
  if(elProm)   elProm.textContent = prom;
  if(elMejor)  elMejor.textContent = mejor > 0 ? mejor : '-';
  if(elMejorS) elMejorS.textContent = mejorNombre || '-';
  if(elPromI)  elPromI.textContent = prom;
}

function actualizarStatsCalificaciones() {
  if (materiasInscritas.length === 0) return;
  var suma = 0;
  var mejor = 0;
  var mejorNombre = '';
  for (var i = 0; i < materiasInscritas.length; i++) {
    var n = materiasInscritas[i].nota;
    suma += n;
    if (n > mejor) { mejor = n; mejorNombre = materiasInscritas[i].nombre; }
  }
  var prom = Math.round((suma / materiasInscritas.length) * 10) / 10;
  var elProm   = document.getElementById('calProm');
  var elMejor  = document.getElementById('calMejor');
  var elMejorS = document.getElementById('calMejorSub');
  var elPromI  = document.getElementById('statPromedio');
  if (elProm)   elProm.textContent   = prom;
  if (elMejor)  elMejor.textContent  = mejor;
  if (elMejorS) elMejorS.textContent = mejorNombre;
  if (elPromI)  elPromI.textContent  = prom;
}

// ============================================================
// HORARIO
// ============================================================
function renderHorario() {
  var tbody = document.getElementById('tablaHorario');
  if (!tbody) return;
  tbody.innerHTML = '';

  // Construir grid: { hora: { dia: materia } }
  var grid = {};
  for (var h = 0; h < horasSlots.length; h++) {
    grid[horasSlots[h]] = {};
    for (var d = 0; d < diasKeys.length; d++) grid[horasSlots[h]][diasKeys[d]] = null;
  }
  for (var i = 0; i < materiasInscritas.length; i++) {
    var m = materiasInscritas[i];
    if (!m.dias) continue;
    var dKeys = Object.keys(m.dias);
    for (var k = 0; k < dKeys.length; k++) {
      var dia  = dKeys[k];
      var hora = m.dias[dia];
      if (grid[hora]) grid[hora][dia] = m;
    }
  }

  for (var h = 0; h < horasSlots.length; h++) {
    var hora = horasSlots[h];
    var tr = document.createElement('tr');
    var html = '<td style="font-weight:800;color:var(--blue);">' + hora + '</td>';
    for (var d = 0; d < diasKeys.length; d++) {
      var mat = grid[hora][diasKeys[d]];
      if (mat) {
        html += '<td><div class="horario-cell-clase" style="background:' + mat.colorBg + ';color:' + mat.color + ';">' +
                mat.nombre + '<br><small style="font-weight:400;">' + mat.aula + '</small></div></td>';
      } else {
        html += '<td style="color:var(--text-soft);text-align:center;">-</td>';
      }
    }
    tr.innerHTML = html;
    tbody.appendChild(tr);
  }
}

function renderHorarioHoy() {
  var cont = document.getElementById('horarioHoy');
  if (!cont) return;
  cont.innerHTML = '';

  var diasMap = ['dom','lun','mar','mie','jue','vie','sab'];
  var diaHoy  = diasMap[new Date().getDay()];

  var hoy = [];
  for (var i = 0; i < materiasInscritas.length; i++) {
    var m = materiasInscritas[i];
    if (m.dias && m.dias[diaHoy]) hoy.push({m:m, hora:m.dias[diaHoy]});
  }

  hoy.sort(function(a, b) {
    function toMin(h) {
      var parts = h.replace(' AM','').replace(' PM','').split(':');
      var hh = parseInt(parts[0]), mm = parseInt(parts[1]||0);
      if (h.indexOf('PM')>-1 && hh!==12) hh+=12;
      if (h.indexOf('AM')>-1 && hh===12) hh=0;
      return hh*60+mm;
    }
    return toMin(a.hora) - toMin(b.hora);
  });

  if (hoy.length === 0) {
    cont.innerHTML = '<div style="color:var(--text-soft);font-size:14px;padding:12px 0;">No hay clases hoy.</div>';
    return;
  }

  for (var i = 0; i < hoy.length; i++) {
    var m = hoy[i].m;
    var hora = hoy[i].hora;
    var div = document.createElement('div');
    div.className = 'sched-item';
    div.innerHTML =
      '<div class="sched-time">' + hora + '</div>' +
      '<div class="sched-bar" style="background:' + m.color + ';"></div>' +
      '<div>' +
        '<div class="sched-subject">' + m.nombre + '</div>' +
        '<div class="sched-prof">Prof. ' + m.docente.split(',')[0] + '</div>' +
        '<div class="sched-room">' + m.aula + '</div>' +
      '</div>';
    cont.appendChild(div);
  }
}

</script>
<script>
(function() {
  var hayBD = '<%= est_hayBD %>' === 'true';
  if (hayBD) {
    document.getElementById('page-login').classList.add('hidden');
    document.getElementById('page-portal').classList.remove('hidden');
    iniciarPortal();
    window.scrollTo(0,0);
  }
})();
</script>
</body>
</html>

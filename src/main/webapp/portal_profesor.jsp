<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ page import="com.delta.dao.MensajeDAO, com.delta.dao.GrupoDAO, com.delta.util.ConexionDB, java.sql.*" %>
<%
  // ── Verificar sesión ──
  Integer usuarioId_pg  = (Integer) session.getAttribute("usuarioId");
  Integer profesorId_pg = (Integer) session.getAttribute("profesorId");
  String  profNombre_pg = (String)  session.getAttribute("profesorNombre");
  String  rolPg         = (String)  session.getAttribute("usuarioRol");
  boolean hayBD = (usuarioId_pg != null && "profesor".equals(rolPg));
  // Si la sesión activa es de estudiante o admin, redirigir a su portal
  if (usuarioId_pg != null && "estudiante".equals(rolPg)) {
    response.sendRedirect(request.getContextPath() + "/portal_estudiante.jsp");
    return;
  }
  if (usuarioId_pg != null && "admin".equals(rolPg)) {
    response.sendRedirect(request.getContextPath() + "/portal_administrador.jsp");
    return;
  }
  // Si hay error de login, mostrar mensaje
  boolean loginError = "1".equals(request.getParameter("error"));

  int    noLeidosMsgs  = 0;
  int    noLeidasNotif = 0;
  int    enRiesgo      = 0;
  // Mapa nombre→{iid, cedula, notas} para el grupo IS-401
  StringBuilder inscripcionesJson = new StringBuilder("{");
  if (hayBD) {
    try {
      MensajeDAO mDao = new MensajeDAO();
      noLeidosMsgs  = mDao.contarNoLeidos(usuarioId_pg);
      noLeidasNotif = mDao.contarNoLeidas(usuarioId_pg);
      GrupoDAO gDao = new GrupoDAO();
      enRiesgo      = gDao.contarRiesgoPorProfesor(profesorId_pg);
    } catch (Exception e) { /* BD no conectada */ }
    try (Connection _c = ConexionDB.obtenerConexion();
         PreparedStatement _p = _c.prepareStatement(
           "SELECT CONCAT(e.nombre,' ',e.apellido) AS nom, i.id AS iid, e.cedula, " +
           "MAX(CASE WHEN n.componente='parcial1'     THEN n.nota END) AS p1, " +
           "MAX(CASE WHEN n.componente='parcial2'     THEN n.nota END) AS p2, " +
           "MAX(CASE WHEN n.componente='proyecto'     THEN n.nota END) AS proy, " +
           "MAX(CASE WHEN n.componente='examen_final' THEN n.nota END) AS ef " +
           "FROM inscripciones i JOIN estudiantes e ON e.id=i.estudiante_id " +
           "JOIN grupos g ON g.id=i.grupo_id JOIN materias m ON m.id=g.materia_id " +
           "LEFT JOIN notas n ON n.inscripcion_id=i.id " +
           "WHERE m.codigo='IS-401' AND i.estado='activo' " +
           "GROUP BY e.id, i.id, e.nombre, e.apellido, e.cedula")) {
      ResultSet _r = _p.executeQuery();
      boolean _f = true;
      while (_r.next()) {
        if (!_f) inscripcionesJson.append(",");
        _f = false;
        String _nom = _r.getString("nom") != null ? _r.getString("nom").replace('"', ' ') : "";
        double _p1   = _r.getDouble("p1");   boolean _np1   = _r.wasNull();
        double _p2   = _r.getDouble("p2");   boolean _np2   = _r.wasNull();
        double _proy = _r.getDouble("proy"); boolean _nproy = _r.wasNull();
        double _ef   = _r.getDouble("ef");   boolean _nef   = _r.wasNull();
        inscripcionesJson.append("\"").append(_nom).append("\":{")
          .append("\"iid\":").append(_r.getInt("iid"))
          .append(",\"cedula\":\"").append(_r.getString("cedula")).append("\"")
          .append(",\"p1\":").append(_np1   ? 0 : _p1)
          .append(",\"p2\":").append(_np2   ? 0 : _p2)
          .append(",\"proj\":").append(_nproy ? 0 : _proy)
          .append(",\"final\":").append(_nef  ? 0 : _ef)
          .append("}");
      }
    } catch (Exception _e2) {}
  } else {
    noLeidosMsgs  = 2;
    noLeidasNotif = 2;
    enRiesgo      = 4;
    profNombre_pg = "Prof. María Mosquera";
  }
  inscripcionesJson.append("}");

  // ── Grupos del profesor (para "Dirigido a" en Publicar Aviso y "Clases de Hoy") ──
  StringBuilder misGruposJsonSb = new StringBuilder("[");
  if (hayBD) {
    try (Connection _cg = ConexionDB.obtenerConexion();
         PreparedStatement _pg = _cg.prepareStatement(
           "SELECT g.id AS grupo_id, g.codigo_grupo, g.aula, m.nombre AS materia, " +
           "  (SELECT COUNT(*) FROM inscripciones i WHERE i.grupo_id = g.id AND i.estado = 'activo') AS num_est " +
           "FROM grupos g JOIN materias m ON m.id = g.materia_id " +
           "WHERE g.profesor_id = ? ORDER BY g.codigo_grupo")) {
      _pg.setInt(1, profesorId_pg);
      try (ResultSet _rg = _pg.executeQuery()) {
        boolean _fg = true;
        while (_rg.next()) {
          if (!_fg) misGruposJsonSb.append(",");
          _fg = false;
          int _gid = _rg.getInt("grupo_id");
          String _cod = _rg.getString("codigo_grupo") != null ? _rg.getString("codigo_grupo").replace('"',' ') : "";
          String _mat = _rg.getString("materia")      != null ? _rg.getString("materia").replace('"',' ')      : "";
          String _aula = _rg.getString("aula")        != null ? _rg.getString("aula").replace('"',' ')         : "";
          int _numEst = _rg.getInt("num_est");

          // Horarios de este grupo
          StringBuilder _horSb = new StringBuilder("[");
          try (PreparedStatement _ph = _cg.prepareStatement(
                 "SELECT dia_semana, hora_inicio, hora_fin FROM horarios WHERE grupo_id = ? ORDER BY dia_semana, hora_inicio")) {
            _ph.setInt(1, _gid);
            try (ResultSet _rh = _ph.executeQuery()) {
              boolean _fh = true;
              while (_rh.next()) {
                if (!_fh) _horSb.append(",");
                _fh = false;
                _horSb.append("{\"dia\":\"").append(_rh.getString("dia_semana")).append("\"")
                  .append(",\"horaInicio\":\"").append(_rh.getString("hora_inicio")).append("\"")
                  .append(",\"horaFin\":\"").append(_rh.getString("hora_fin")).append("\"}");
              }
            }
          } catch (Exception _eh) { /* sin horarios */ }
          _horSb.append("]");

          misGruposJsonSb.append("{\"grupoId\":").append(_gid)
            .append(",\"codigo\":\"").append(_cod).append("\"")
            .append(",\"materia\":\"").append(_mat).append("\"")
            .append(",\"aula\":\"").append(_aula).append("\"")
            .append(",\"numEstudiantes\":").append(_numEst)
            .append(",\"horarios\":").append(_horSb)
            .append("}");
        }
      }
    } catch (Exception _eg) { /* sin grupos */ }
  }
  misGruposJsonSb.append("]");
  String misGruposJson = misGruposJsonSb.toString();
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Portal Docente — Sistema Delta UTP</title>
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;500;600;700;800&family=Merriweather:wght@700&display=swap" rel="stylesheet">
<style>
:root {
  --bg:#f4f6fb; --bg2:#eaf0fb; --white:#ffffff;
  --blue:#1a56a0; --blue-mid:#2269c4; --blue-light:#dbeafe; --blue-pale:#eff6ff;
  --green:#15803d; --green-bg:#dcfce7;
  --red:#b91c1c; --red-bg:#fee2e2;
  --amber:#b45309; --amber-bg:#fef3c7;
  --purple:#7c3aed; --purple-bg:#ede9fe;
  --text:#1e2a3b; --text-mid:#3d5068; --text-soft:#6b7e96;
  --border:#c8d8ec;
  --shadow:0 2px 12px rgba(26,86,160,0.10);
  --shadow-lg:0 6px 28px rgba(26,86,160,0.14);
  --radius:14px; --radius-sm:9px;
}
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Nunito',sans-serif;background:var(--bg);color:var(--text);font-size:16px;min-height:100vh;}
.hidden{display:none!important;}
h1,h2,h3{font-family:'Merriweather',serif;}
.btn{display:inline-flex;align-items:center;justify-content:center;gap:8px;padding:13px 26px;border-radius:var(--radius-sm);border:none;font-family:'Nunito',sans-serif;font-size:16px;font-weight:700;cursor:pointer;transition:all 0.2s;text-decoration:none;}
.btn-primary{background:var(--blue);color:#fff;} .btn-primary:hover{background:var(--blue-mid);box-shadow:var(--shadow);}
.btn-secondary{background:var(--white);color:var(--blue);border:2px solid var(--blue);} .btn-secondary:hover{background:var(--blue-pale);}
.btn-sm{padding:9px 18px;font-size:14px;} .btn-full{width:100%;}
.card{background:var(--white);border:1.5px solid var(--border);border-radius:var(--radius);padding:26px;box-shadow:var(--shadow);}
.tag{display:inline-block;padding:4px 12px;border-radius:20px;font-size:13px;font-weight:700;}
.tag-green{background:var(--green-bg);color:var(--green);}
.tag-red{background:var(--red-bg);color:var(--red);}
.tag-amber{background:var(--amber-bg);color:var(--amber);}
.tag-blue{background:var(--blue-light);color:var(--blue);}

/* LOGIN */
#page-login{min-height:100vh;display:flex;align-items:center;justify-content:center;background:linear-gradient(145deg,#dbeafe 0%,#f4f6fb 60%,#e0f2fe 100%);padding:24px;}
.login-box{background:var(--white);border:1.5px solid var(--border);border-radius:20px;box-shadow:var(--shadow-lg);width:100%;max-width:420px;padding:48px 40px;animation:popIn 0.4s ease;}
@keyframes popIn{from{opacity:0;transform:scale(0.96) translateY(10px);}to{opacity:1;transform:scale(1) translateY(0);}}
.login-logo{text-align:center;margin-bottom:28px;}
.delta-mark{display:inline-flex;align-items:center;justify-content:center;width:68px;height:68px;border-radius:18px;background:var(--blue);color:#fff;font-family:'Merriweather',serif;font-size:32px;margin-bottom:12px;box-shadow:0 4px 16px rgba(26,86,160,0.3);}
.login-logo h1{font-size:22px;color:var(--blue);}
.login-logo p{font-size:14px;color:var(--text-soft);margin-top:4px;}
.login-role-banner{background:#fef3c7;border:1.5px solid #fcd34d;border-radius:var(--radius-sm);padding:14px 16px;margin-bottom:24px;display:flex;align-items:center;gap:12px;font-size:16px;font-weight:700;color:#92400e;}
.form-group{margin-bottom:18px;}
.form-group label{display:block;font-size:15px;font-weight:700;color:var(--text-mid);margin-bottom:7px;}
.form-group input{width:100%;padding:13px 16px;border:2px solid var(--border);border-radius:var(--radius-sm);font-family:'Nunito',sans-serif;font-size:16px;color:var(--text);background:var(--bg);transition:border-color 0.2s;}
.form-group input:focus{outline:none;border-color:var(--blue);background:#fff;}
.password-wrap{position:relative;}
.password-wrap input{padding-right:46px;}
.password-toggle{position:absolute;right:6px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;font-size:18px;color:var(--text-soft);padding:6px 8px;line-height:1;}
.password-toggle:hover{color:var(--blue);}
.login-error{background:var(--red-bg);color:var(--red);padding:12px 16px;border-radius:var(--radius-sm);font-size:14px;font-weight:600;margin-bottom:16px;border:1px solid #fca5a5;display:none;}
.login-hint{text-align:center;margin-top:16px;font-size:13px;color:var(--text-soft);background:var(--bg2);padding:11px;border-radius:var(--radius-sm);}
.login-hint strong{color:var(--blue);}
.login-switch{text-align:center;margin-top:14px;font-size:13px;color:var(--text-soft);}
.login-switch a{color:var(--blue);font-weight:700;text-decoration:none;}

/* PORTAL LAYOUT */
.portal{display:flex;min-height:100vh;}
.sidebar{width:270px;flex-shrink:0;background:var(--white);border-right:2px solid var(--border);display:flex;flex-direction:column;position:fixed;top:0;left:0;bottom:0;z-index:100;overflow-y:auto;box-shadow:3px 0 16px rgba(26,86,160,0.07);}
.sidebar-header{padding:24px 22px 18px;border-bottom:2px solid var(--border);background:#92400e;}
.sidebar-logo{display:flex;align-items:center;gap:12px;}
.logo-mark{width:46px;height:46px;border-radius:12px;background:rgba(255,255,255,0.2);display:flex;align-items:center;justify-content:center;font-family:'Merriweather',serif;font-size:22px;color:#fff;border:2px solid rgba(255,255,255,0.3);}
.logo-name{font-family:'Merriweather',serif;font-size:20px;color:#fff;}
.logo-sub{font-size:11px;color:rgba(255,255,255,0.7);text-transform:uppercase;letter-spacing:1.5px;}
.sidebar-user{margin:16px 16px 0;background:#fef3c7;border:1.5px solid #fcd34d;border-radius:var(--radius-sm);padding:14px;display:flex;align-items:center;gap:12px;}
.user-avatar{width:48px;height:48px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-family:'Merriweather',serif;font-size:20px;background:#92400e;color:#fff;flex-shrink:0;}
.user-name{font-size:15px;font-weight:800;color:var(--text);}
.user-id{font-size:12px;color:var(--text-soft);margin-top:2px;}
.user-role-tag{display:inline-block;margin-top:4px;background:#92400e;color:#fff;font-size:11px;font-weight:700;padding:2px 9px;border-radius:20px;}
.nav-section{padding:16px 12px 8px;}
.nav-label{font-size:11px;text-transform:uppercase;letter-spacing:2px;color:var(--text-soft);padding:4px 10px 10px;font-weight:700;}
.nav-item{display:flex;align-items:center;gap:12px;padding:13px 14px;border-radius:var(--radius-sm);cursor:pointer;font-size:16px;font-weight:600;color:var(--text-mid);transition:all 0.18s;margin-bottom:3px;text-decoration:none;border:none;background:none;width:100%;text-align:left;font-family:'Nunito',sans-serif;}
.nav-item:hover{background:var(--amber-bg);color:#92400e;}
.nav-item.active{background:#fef3c7;color:#92400e;}
.nav-icon{font-size:20px;width:26px;text-align:center;flex-shrink:0;}
.nav-badge{margin-left:auto;background:#92400e;color:#fff;font-size:12px;font-weight:800;padding:2px 8px;border-radius:20px;}
.sidebar-footer{margin-top:auto;padding:16px 14px;}
.logout-btn{display:flex;align-items:center;gap:10px;padding:12px 14px;border-radius:var(--radius-sm);font-size:15px;font-weight:700;color:var(--red);cursor:pointer;background:var(--red-bg);border:1.5px solid #fca5a5;width:100%;font-family:'Nunito',sans-serif;transition:all 0.18s;}
.logout-btn:hover{background:#fecaca;}
.main-content{margin-left:270px;flex:1;padding:32px 36px;min-height:100vh;}
.topbar{display:flex;align-items:center;justify-content:space-between;margin-bottom:30px;padding-bottom:24px;border-bottom:2px solid var(--border);}
.page-title{font-size:28px;color:var(--text);}
.page-subtitle{font-size:15px;color:var(--text-soft);margin-top:4px;font-family:'Nunito',sans-serif;}
.topbar-right{display:flex;align-items:center;gap:12px;}

/* NOTIFICATION BELL */
.notif-btn{width:46px;height:46px;border-radius:10px;background:var(--white);border:2px solid var(--border);display:flex;align-items:center;justify-content:center;font-size:20px;cursor:pointer;position:relative;transition:all 0.18s;}
.notif-btn:hover{background:var(--blue-pale);border-color:var(--blue);}
.notif-dot{position:absolute;top:8px;right:8px;width:9px;height:9px;background:var(--red);border-radius:50%;border:2px solid #fff;}

/* NOTIFICATION PANEL */
.notif-panel{position:fixed;top:0;right:0;width:380px;height:100vh;background:var(--white);border-left:2px solid var(--border);box-shadow:-6px 0 28px rgba(26,86,160,0.14);z-index:500;display:flex;flex-direction:column;transition:transform 0.3s ease;}
.notif-panel.hidden-panel{transform:translateX(100%);}
.notif-panel-header{padding:22px 22px 18px;border-bottom:2px solid var(--border);display:flex;align-items:center;justify-content:space-between;background:var(--blue);}
.notif-panel-title{font-family:'Merriweather',serif;font-size:18px;color:#fff;}
.notif-close-btn{width:36px;height:36px;border-radius:8px;background:rgba(255,255,255,0.2);border:none;color:#fff;font-size:20px;cursor:pointer;display:flex;align-items:center;justify-content:center;}
.notif-panel-body{flex:1;overflow-y:auto;padding:16px;}
.notif-panel-item{display:flex;gap:14px;padding:14px;border-radius:var(--radius-sm);margin-bottom:8px;border:1.5px solid var(--border);transition:background 0.15s;cursor:pointer;}
.notif-panel-item:hover{background:var(--bg2);}
.notif-panel-item.unread{background:var(--blue-pale);border-color:#93c5fd;}
.notif-panel-item .npi-icon{width:42px;height:42px;border-radius:10px;flex-shrink:0;display:flex;align-items:center;justify-content:center;font-size:20px;}
.notif-panel-item .npi-title{font-size:14px;font-weight:800;color:var(--text);}
.notif-panel-item .npi-body{font-size:13px;color:var(--text-soft);margin-top:3px;line-height:1.4;}
.notif-panel-item .npi-time{font-size:12px;color:var(--blue);font-weight:700;margin-top:5px;}
.notif-panel-item .npi-unread-dot{width:8px;height:8px;background:var(--blue);border-radius:50%;margin-top:5px;flex-shrink:0;}
.notif-overlay{position:fixed;inset:0;background:rgba(0,0,0,0.15);z-index:499;}

.tab-panel{display:none;animation:fadeIn 0.3s ease;}
.tab-panel.active{display:block;}
@keyframes fadeIn{from{opacity:0;transform:translateY(8px);}to{opacity:1;transform:translateY(0);}}
.stats-row{display:grid;gap:18px;margin-bottom:26px;}
.stats-4{grid-template-columns:repeat(4,1fr);}
.stats-3{grid-template-columns:repeat(3,1fr);}
.stat-card{background:var(--white);border:1.5px solid var(--border);border-radius:var(--radius);padding:22px 20px;box-shadow:var(--shadow);display:flex;align-items:center;gap:16px;transition:transform 0.18s,box-shadow 0.18s;}
.stat-card:hover{transform:translateY(-2px);box-shadow:var(--shadow-lg);}
.stat-icon-box{width:56px;height:56px;border-radius:14px;flex-shrink:0;display:flex;align-items:center;justify-content:center;font-size:26px;}
.icon-blue{background:var(--blue-light);} .icon-green{background:var(--green-bg);} .icon-amber{background:var(--amber-bg);} .icon-red{background:var(--red-bg);}
.stat-label{font-size:13px;color:var(--text-soft);font-weight:600;text-transform:uppercase;letter-spacing:0.8px;}
.stat-value{font-family:'Merriweather',serif;font-size:30px;color:var(--text);line-height:1.1;margin:4px 0;}
.stat-sub{font-size:13px;color:var(--text-soft);}
.grid-2{display:grid;grid-template-columns:1fr 1fr;gap:22px;margin-bottom:22px;}
.grid-21{display:grid;grid-template-columns:2fr 1fr;gap:22px;margin-bottom:22px;}
.card-title{font-family:'Merriweather',serif;font-size:18px;color:var(--text);margin-bottom:18px;display:flex;align-items:center;justify-content:space-between;}
.card-title a{font-family:'Nunito',sans-serif;font-size:13px;color:var(--blue);font-weight:700;text-decoration:none;cursor:pointer;}
.sched-item{display:flex;gap:14px;padding:14px 0;border-bottom:1.5px solid var(--bg2);align-items:flex-start;}
.sched-item:last-child{border-bottom:none;}
.sched-time{font-size:13px;color:var(--text-soft);font-weight:700;min-width:56px;padding-top:2px;}
.sched-bar{width:4px;min-height:44px;border-radius:4px;flex-shrink:0;margin-top:2px;}
.sched-subject{font-size:16px;font-weight:800;color:var(--text);}
.sched-prof{font-size:14px;color:var(--text-soft);margin-top:3px;}
.sched-room{display:inline-block;margin-top:6px;font-size:13px;font-weight:700;background:var(--bg2);color:var(--text-mid);padding:3px 10px;border-radius:6px;}
.delta-table{width:100%;border-collapse:collapse;}
.delta-table th{font-size:13px;font-weight:800;text-transform:uppercase;letter-spacing:0.8px;color:var(--text-soft);padding:10px 14px;text-align:left;background:var(--bg2);border-bottom:2px solid var(--border);}
.delta-table td{padding:13px 14px;font-size:15px;border-bottom:1.5px solid var(--bg2);vertical-align:middle;color:var(--text);}
.delta-table tr:last-child td{border-bottom:none;}
.delta-table tr:hover td{background:var(--blue-pale);}
.grade-input{width:70px;text-align:center;padding:8px;border-radius:var(--radius-sm);border:2px solid var(--border);background:var(--bg);font-family:'Nunito',sans-serif;font-size:16px;font-weight:800;color:var(--text);transition:border-color 0.18s;}
.grade-input:focus{outline:none;border-color:var(--blue);background:#fff;}
.class-row{display:flex;align-items:center;gap:14px;padding:14px 12px;border-radius:var(--radius-sm);transition:background 0.15s;margin-bottom:6px;border:1.5px solid var(--border);background:var(--bg);}
.class-row:hover{background:var(--amber-bg);border-color:#d97706;}
.class-bar{width:5px;height:40px;border-radius:4px;flex-shrink:0;}
.class-name{font-size:16px;font-weight:800;}
.class-meta{font-size:13px;color:var(--text-soft);margin-top:3px;}
.class-right{margin-left:auto;text-align:right;}
.class-count{font-size:16px;font-weight:800;color:var(--blue);}
.class-avg{font-size:13px;color:var(--text-soft);}
.att-btn{width:44px;height:44px;border-radius:9px;border:2px solid var(--border);background:var(--bg);cursor:pointer;font-size:18px;display:flex;align-items:center;justify-content:center;transition:all 0.15s;font-family:'Nunito',sans-serif;}
.att-btn.present{background:var(--green-bg);border-color:#86efac;color:var(--green);}
.att-btn.absent{background:var(--red-bg);border-color:#fca5a5;color:var(--red);}
.att-btn.late{background:var(--amber-bg);border-color:#fcd34d;color:var(--amber);}
.notif-item{display:flex;gap:14px;padding:14px 0;border-bottom:1.5px solid var(--bg2);align-items:flex-start;}
.notif-item:last-child{border-bottom:none;}
.notif-icon-box{width:42px;height:42px;border-radius:12px;flex-shrink:0;display:flex;align-items:center;justify-content:center;font-size:20px;}
.notif-title{font-size:15px;font-weight:800;}
.notif-body{font-size:14px;color:var(--text-soft);margin-top:3px;}
.notif-time{font-size:12px;color:var(--text-soft);margin-top:5px;}

/* MESSAGES */
.msg-item{display:flex;gap:14px;padding:14px 0;border-bottom:1.5px solid var(--bg2);cursor:pointer;transition:background 0.15s;border-radius:var(--radius-sm);padding-left:10px;margin-left:-10px;}
.msg-item:hover{background:var(--amber-bg);}
.msg-item:last-child{border-bottom:none;}
.msg-av{width:42px;height:42px;border-radius:12px;background:var(--blue-light);display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0;border:1.5px solid var(--border);}
.msg-from{font-size:15px;font-weight:800;}
.msg-preview{font-size:14px;color:var(--text-soft);margin-top:3px;}
.msg-unread{width:9px;height:9px;background:#92400e;border-radius:50%;margin-top:7px;flex-shrink:0;}
.msg-read .msg-unread{display:none;}
.msg-read .msg-from{font-weight:600;color:var(--text-soft);}

/* MESSAGE MODAL */
.msg-modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,0.35);z-index:600;display:flex;align-items:center;justify-content:center;padding:24px;}
.msg-modal{background:var(--white);border-radius:var(--radius);box-shadow:var(--shadow-lg);max-width:560px;width:100%;animation:popIn 0.25s ease;}
.msg-modal-header{padding:22px 24px 18px;border-bottom:2px solid var(--border);display:flex;justify-content:space-between;align-items:flex-start;}
.msg-modal-from{font-size:18px;font-weight:800;color:var(--text);}
.msg-modal-sub{font-size:13px;color:var(--text-soft);margin-top:3px;}
.msg-modal-close{width:34px;height:34px;border-radius:8px;border:2px solid var(--border);background:var(--bg);cursor:pointer;font-size:18px;display:flex;align-items:center;justify-content:center;}
.msg-modal-body{padding:22px 24px;font-size:15px;color:var(--text-mid);line-height:1.7;}
.msg-modal-footer{padding:16px 24px;border-top:2px solid var(--border);display:flex;justify-content:flex-end;gap:10px;}

.ann-item{border-left:4px solid var(--blue);background:var(--blue-pale);border-radius:0 var(--radius-sm) var(--radius-sm) 0;padding:14px 16px;margin-bottom:12px;}
.ann-item:last-child{margin-bottom:0;}
.ann-item.amber{border-color:var(--amber);background:var(--amber-bg);}
.ann-title{font-size:15px;font-weight:800;color:var(--text);}
.ann-body{font-size:14px;color:var(--text-mid);margin-top:4px;line-height:1.5;}
.ann-date{font-size:12px;font-weight:700;color:var(--blue);margin-top:6px;}
.compose-wrap{border:2px solid var(--border);border-radius:var(--radius-sm);overflow:hidden;}
.compose-input{width:100%;padding:13px 16px;border:none;border-bottom:1.5px solid var(--border);font-family:'Nunito',sans-serif;font-size:16px;color:var(--text);background:var(--bg);}
.compose-input::placeholder{color:var(--text-soft);}
.compose-input:focus{outline:none;background:#fff;}
.compose-textarea{width:100%;padding:14px 16px;border:none;font-family:'Nunito',sans-serif;font-size:15px;color:var(--text);background:var(--bg);min-height:100px;resize:vertical;}
.compose-textarea::placeholder{color:var(--text-soft);}
.compose-textarea:focus{outline:none;background:#fff;}
.compose-footer{padding:12px 16px;background:var(--bg2);display:flex;justify-content:flex-end;gap:10px;}
.report-row{display:flex;align-items:center;gap:14px;padding:14px 16px;border:1.5px solid var(--border);border-radius:var(--radius-sm);background:var(--bg);margin-bottom:10px;cursor:pointer;transition:all 0.18s;}
.report-row:hover{border-color:#d97706;background:var(--amber-bg);}
.report-icon{font-size:28px;}
.report-name{font-size:15px;font-weight:800;}
.report-desc{font-size:13px;color:var(--text-soft);margin-top:2px;}
.report-btn{margin-left:auto;}
.save-toast{position:fixed;bottom:28px;right:32px;background:var(--blue);color:#fff;border-radius:12px;padding:14px 24px;font-size:16px;font-weight:700;cursor:pointer;display:none;align-items:center;gap:10px;box-shadow:0 6px 24px rgba(26,86,160,0.35);z-index:999;}
.save-toast.show{display:flex;}

/* HORARIO */
.horario-grid{display:grid;grid-template-columns:80px repeat(5,1fr);gap:2px;border-radius:var(--radius-sm);overflow:hidden;background:var(--border);}
.horario-cell{background:var(--white);padding:10px 8px;font-size:13px;text-align:center;}
.horario-header{background:var(--blue);color:#fff;font-weight:800;font-size:13px;text-align:center;padding:12px 8px;}
.horario-time{background:var(--bg2);font-size:12px;font-weight:700;color:var(--text-soft);text-align:center;display:flex;align-items:center;justify-content:center;}
.horario-class{border-radius:8px;padding:10px 8px;font-size:12px;font-weight:700;color:#fff;text-align:center;line-height:1.4;cursor:default;transition:transform 0.15s;}
.horario-class:hover{transform:scale(1.02);}
.horario-empty{background:var(--bg);border-radius:8px;}

/* SEMESTER ATTENDANCE */
.sem-att-grid{display:grid;grid-template-columns:repeat(7,1fr);gap:4px;margin-top:12px;}
.sem-day-label{font-size:11px;font-weight:800;color:var(--text-soft);text-align:center;padding:4px 0;}
.sem-day-cell{aspect-ratio:1;border-radius:5px;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;cursor:default;transition:transform 0.15s;}
.sem-day-cell:hover{transform:scale(1.1);}
.sem-day-cell.present{background:var(--green-bg);color:var(--green);border:1.5px solid #86efac;}
.sem-day-cell.absent{background:var(--red-bg);color:var(--red);border:1.5px solid #fca5a5;}
.sem-day-cell.late{background:var(--amber-bg);color:var(--amber);border:1.5px solid #fcd34d;}
.sem-day-cell.no-class{background:var(--bg2);color:var(--text-soft);border:1.5px solid var(--border);}
.sem-day-cell.future{background:var(--bg);color:var(--border);border:1.5px dashed var(--border);}

/* ===== TOASTS Y MODAL DE CONFIRMACION ===== */
.toast-container{position:fixed;top:20px;right:20px;z-index:9999;display:flex;flex-direction:column;gap:10px;max-width:360px;}
.toast{display:flex;align-items:flex-start;gap:10px;padding:14px 16px;border-radius:var(--radius-sm);background:#fff;box-shadow:0 8px 24px rgba(0,0,0,.12);border-left:5px solid var(--blue);font-size:14px;color:var(--text);animation:toast-in 0.25s ease-out;line-height:1.4;}
.toast.toast-success{border-left-color:var(--green);}
.toast.toast-error{border-left-color:var(--red);}
.toast.toast-info{border-left-color:var(--blue);}
.toast-icon{font-size:18px;flex-shrink:0;line-height:1.4;}
.toast-msg{flex:1;white-space:pre-line;}
.toast-close{cursor:pointer;color:var(--text-soft);font-size:16px;line-height:1;flex-shrink:0;background:none;border:none;padding:0;}
.toast-close:hover{color:var(--text);}
.toast.toast-out{animation:toast-out 0.2s ease-in forwards;}
@keyframes toast-in{from{opacity:0;transform:translateX(30px);}to{opacity:1;transform:translateX(0);}}
@keyframes toast-out{from{opacity:1;transform:translateX(0);}to{opacity:0;transform:translateX(30px);}}

.modal-overlay{position:fixed;inset:0;background:rgba(30,42,59,.45);z-index:10000;display:flex;align-items:center;justify-content:center;padding:20px;animation:modal-fade-in 0.15s ease-out;}
.modal-overlay.hidden{display:none;}
.modal-box{background:#fff;border-radius:var(--radius-sm);max-width:420px;width:100%;padding:24px;box-shadow:0 12px 40px rgba(0,0,0,.2);}
.modal-box p{font-size:15px;color:var(--text);line-height:1.5;margin-bottom:20px;white-space:pre-line;}
.modal-actions{display:flex;justify-content:flex-end;gap:10px;}
@keyframes modal-fade-in{from{opacity:0;}to{opacity:1;}}


@media(max-width:1100px){.stats-4{grid-template-columns:1fr 1fr;}.grid-2,.grid-21{grid-template-columns:1fr;}}
@media(max-width:760px){.sidebar{width:220px;}.main-content{margin-left:220px;padding:20px;}}
</style>
</head>
<body>

<!-- ==================== TOASTS Y MODAL DE CONFIRMACION ==================== -->
<div class="toast-container" id="toastContainer"></div>
<div class="modal-overlay hidden" id="confirmOverlay">
  <div class="modal-box">
    <p id="confirmMsg"></p>
    <div class="modal-actions">
      <button class="btn btn-secondary" id="confirmCancelBtn">Cancelar</button>
      <button class="btn btn-primary" id="confirmOkBtn">Aceptar</button>
    </div>
  </div>
</div>
<div class="modal-overlay hidden" id="infoModalOverlay">
  <div class="modal-box">
    <div id="infoModalTitle" style="font-weight:800;font-size:17px;margin-bottom:8px;color:var(--text);"></div>
    <p id="infoModalMsg"></p>
    <div class="modal-actions">
      <button class="btn btn-primary" id="infoModalCloseBtn">Cerrar</button>
    </div>
  </div>
</div>

<!-- LOGIN DOCENTE -->
<div id="page-login">
  <div class="login-box">
    <div class="login-logo">
      <div class="delta-mark">∆</div>
      <h1>Sistema Delta</h1>
      <p>Universidad Tecnológica de Panamá</p>
    </div>
    <div class="login-role-banner">
      👩‍🏫 &nbsp;Portal Docente
    </div>
    <div class="form-group">
      <label for="loginUser">Usuario / ID Docente</label>
      <input id="loginUser" type="text" placeholder="Ej: DOC-0142" autocomplete="username">
    </div>
    <div class="form-group">
      <label for="loginPass">Contraseña</label>
      <div class="password-wrap">
        <input id="loginPass" type="password" placeholder="••••••••" autocomplete="current-password">
        <button type="button" class="password-toggle" id="togglePass" onclick="togglePasswordVisibility()" aria-label="Mostrar contraseña" title="Mostrar contraseña">👁</button>
      </div>
    </div>
    <div class="login-error" id="loginError">Usuario o contraseña incorrecto.</div>
    <script>if(<%= loginError %>) document.getElementById("loginError").style.display="block";</script>
    <button class="btn btn-primary btn-full" onclick="doLogin()">Ingresar al Portal</button>
    <div class="login-hint">Demo: usuario <strong>profesor</strong> · clave <strong>1234</strong></div>
    <div class="login-switch">¿Es estudiante? <a href="index.jsp">Ir al Portal Estudiantil →</a></div>
  </div>
</div>

<!-- NOTIFICATION PANEL -->
<div id="notifOverlay" class="notif-overlay hidden" onclick="closeNotifPanel()"></div>
<div id="notifPanel" class="notif-panel hidden-panel">
  <div class="notif-panel-header">
    <span class="notif-panel-title">🔔 Notificaciones</span>
    <button class="notif-close-btn" onclick="closeNotifPanel()">✕</button>
  </div>
  <div class="notif-panel-body" id="notifPanelBody">
    <div class="notif-panel-item unread" id="notif-1" onclick="markNotifRead(1)">
      <div class="npi-icon" style="background:var(--blue-light);">📩</div>
      <div style="flex:1;">
        <div class="npi-title">Mensaje de Laura Orellana</div>
        <div class="npi-body">Consulta sobre el Proyecto Delta — Unidad I, entrega del viernes.</div>
        <div class="npi-time">Hace 20 minutos</div>
      </div>
      <div class="npi-unread-dot"></div>
    </div>
    <div class="notif-panel-item unread" id="notif-2" onclick="markNotifRead(2)">
      <div class="npi-icon" style="background:var(--amber-bg);">⚠️</div>
      <div style="flex:1;">
        <div class="npi-title">4 estudiantes en riesgo académico</div>
        <div class="npi-body">Grupo 1SF133 — Promedio menor a 60. Se recomienda intervención.</div>
        <div class="npi-time">Hace 1 hora</div>
      </div>
      <div class="npi-unread-dot"></div>
    </div>
    <div class="notif-panel-item" id="notif-3" onclick="markNotifRead(3)">
      <div class="npi-icon" style="background:var(--green-bg);">✅</div>
      <div style="flex:1;">
        <div class="npi-title">Sistema Delta actualizado</div>
        <div class="npi-body">Versión 1.2 implementada. Nuevas funciones de reporte disponibles.</div>
        <div class="npi-time">Ayer, 3:00 PM</div>
      </div>
    </div>
    <div class="notif-panel-item" id="notif-4" onclick="markNotifRead(4)">
      <div class="npi-icon" style="background:var(--red-bg);">📝</div>
      <div style="flex:1;">
        <div class="npi-title">12 parciales pendientes de calificar</div>
        <div class="npi-body">Recuerde registrar las notas antes del viernes 30 de mayo.</div>
        <div class="npi-time">Hoy, 7:00 AM</div>
      </div>
    </div>
    <div style="margin-top:16px;text-align:center;">
      <button class="btn btn-secondary btn-sm" onclick="markAllNotifRead()">✓ Marcar todas como leídas</button>
    </div>
  </div>
</div>

<!-- MESSAGE MODAL -->
<div id="msgModal" class="msg-modal-overlay hidden" onclick="closeMsgModal(event)">
  <div class="msg-modal" onclick="event.stopPropagation()">
    <div class="msg-modal-header">
      <div>
        <div class="msg-modal-from" id="msgModalFrom">Remitente</div>
        <div class="msg-modal-sub" id="msgModalTime">Fecha</div>
      </div>
      <button class="msg-modal-close" onclick="closeMsgModalBtn()">✕</button>
    </div>
    <div class="msg-modal-body" id="msgModalBody">Contenido del mensaje.</div>
    <div class="msg-modal-footer">
      <button class="btn btn-secondary btn-sm" onclick="closeMsgModalBtn()">Cerrar</button>
      <button class="btn btn-primary btn-sm" onclick="replyToMsg()">↩ Responder</button>
    </div>
  </div>
</div>

<!-- PORTAL DOCENTE -->
<div id="page-portal" class="portal hidden">
  <aside class="sidebar">
    <div class="sidebar-header">
      <div class="sidebar-logo">
        <div class="logo-mark">∆</div>
        <div>
          <div class="logo-name">Delta</div>
          <div class="logo-sub">Portal Docente</div>
        </div>
      </div>
    </div>
    <div class="sidebar-user">
      <div class="user-avatar">M</div>
      <div>
        <div class="user-name">Prof. María Mosquera</div>
        <div class="user-id">ID: DOC-0142</div>
        <div class="user-role-tag">Docente</div>
      </div>
    </div>
    <nav class="nav-section">
      <div class="nav-label">Principal</div>
      <button class="nav-item active" onclick="goTab('inicio',this)"><span class="nav-icon">🏠</span> Inicio</button>
      <button class="nav-item" onclick="goTab('grupos',this)"><span class="nav-icon">👥</span> Mis Grupos</button>
      <button class="nav-item" onclick="goTab('calificaciones',this)"><span class="nav-icon">📊</span> Calificaciones</button>
      <button class="nav-item" onclick="goTab('asistencia',this)"><span class="nav-icon">✅</span> Asistencia</button>
      <button class="nav-item" onclick="goTab('horario',this)"><span class="nav-icon">🗓️</span> Horario</button>
      <div class="nav-label">Comunicación</div>
      <button class="nav-item" id="navMensajes" onclick="goTab('mensajes',this)"><span class="nav-icon">✉️</span> Mensajes<span class="nav-badge" id="msgBadge" style="<%= (noLeidosMsgs > 0) ? "" : "display:none;" %>"><%= noLeidosMsgs %></span></button>
      <button class="nav-item" onclick="goTab('avisos',this)"><span class="nav-icon">📢</span> Publicar Aviso</button>
      <div class="nav-label">Administración</div>
      <button class="nav-item" onclick="goTab('reportes',this)"><span class="nav-icon">📋</span> Reportes</button>
    </nav>
    <div class="sidebar-footer">
      <a href="<%= request.getContextPath() %>/logout" class="logout-btn">🚪 Cerrar Sesión</a>
    </div>
  </aside>

  <main class="main-content">

    <!-- INICIO -->
    <div id="tab-inicio" class="tab-panel active">
      <div class="topbar">
        <div>
          <h2 class="page-title">Bienvenida, Profesora Mosquera </h2>
          <div class="page-subtitle" id="fechaHoyProf">Cargando...</div>
        </div>
        <div class="topbar-right">
          <div class="notif-btn" id="notifBellBtn" onclick="openNotifPanel()" style="position:relative;">🔔<div class="notif-dot" id="notifDot" style="<%= (noLeidosMsgs > 0) ? "" : "display:none;" %>"></div><span id="campanaCountProf" style="<%= (noLeidosMsgs > 0) ? "" : "display:none;" %>;position:absolute;top:-6px;right:-6px;background:#ef4444;color:#fff;border-radius:50%;width:18px;height:18px;font-size:11px;font-weight:700;display:<%= (noLeidosMsgs > 0) ? "flex" : "none" %>;align-items:center;justify-content:center;"><%= noLeidosMsgs %></span></div>
        </div>
      </div>
      <div class="stats-row stats-4">
        <div class="stat-card"><div class="stat-icon-box icon-blue">👥</div><div><div class="stat-label">Grupos Activos</div><div class="stat-value">3</div><div class="stat-sub"><span id="inicioTotalEst">12</span> estudiantes total</div></div></div>
        <div class="stat-card"><div class="stat-icon-box icon-green">✅</div><div><div class="stat-label">Asistencia Hoy</div><div class="stat-value" id="statAsistenciaHoy">--</div><div class="stat-sub" id="statAsistenciaHoySub">Cargando...</div></div></div>
        <div class="stat-card"><div class="stat-icon-box icon-amber">⚠️</div><div><div class="stat-label">En Riesgo</div><div class="stat-value" id="statEnRiesgo"><%= enRiesgo %></div><div class="stat-sub">Nota menor a 70</div></div></div>
        <div class="stat-card"><div class="stat-icon-box icon-red">📝</div><div><div class="stat-label">Por Calificar</div><div class="stat-value">12</div><div class="stat-sub">Parciales pendientes</div></div></div>
      </div>
      <div class="grid-2">
        <div class="card">
          <div class="card-title">Clases de Hoy <a onclick="goTab('grupos',null)">Ver grupos →</a></div>
          <div id="clasesHoyContainer">
            <div style="color:var(--text-soft);font-size:14px;padding:12px 0;">Cargando...</div>
          </div>
          <div style="margin-top:16px;">
            <button class="btn btn-primary" onclick="goTab('asistencia',null)">📋 Registrar Asistencia</button>
          </div>
        </div>
        <div class="card">
          <div class="card-title">Notificaciones Recientes</div>
          <div class="notif-item"><div class="notif-icon-box" style="background:var(--amber-bg);">⚠️</div><div><div class="notif-title" id="riesgoNotifTitle"><%= enRiesgo %> estudiantes en riesgo académico</div><div class="notif-body">Grupo 1SF133 — Promedio menor a 70.</div><div class="notif-time">Actualizado</div></div></div>
          <div class="notif-item"><div class="notif-icon-box" style="background:var(--green-bg);">✅</div><div><div class="notif-title">Sistema Delta</div><div class="notif-body">Versión 1.2 implementada. Nuevas funciones disponibles.</div><div class="notif-time">Ayer, 3:00 PM</div></div></div>
          <div id="inicioMsgList"></div>
        </div>
      </div>
    </div>

    <!-- GRUPOS -->
    <div id="tab-grupos" class="tab-panel">
      <div class="topbar"><div><h2 class="page-title">👥 Mis Grupos</h2><div class="page-subtitle">I Semestre 2026 · Grupos asignados</div></div></div>
      <div class="stats-row stats-3">
        <div class="stat-card"><div class="stat-icon-box icon-blue">👥</div><div><div class="stat-label">Total Estudiantes</div><div class="stat-value" id="totalEstStat">87</div><div class="stat-sub">en 3 grupos</div></div></div>
        <div class="stat-card"><div class="stat-icon-box icon-green">⭐</div><div><div class="stat-label">Promedio General</div><div class="stat-value" id="promGeneralStat">--</div><div class="stat-sub">todos los grupos</div></div></div>
        <div class="stat-card"><div class="stat-icon-box icon-amber">⚠️</div><div><div class="stat-label">Riesgo Académico</div><div class="stat-value" id="statRiesgoInicio"><%= enRiesgo %></div><div class="stat-sub">necesitan atención</div></div></div>
      </div>
      <div class="card">
        <div class="card-title">Grupos Activos</div>
        <!-- Grupo 1SF133: 5 estudiantes -->
        <div class="class-row">
          <div class="class-bar" style="background:var(--blue);"></div>
          <div style="flex:1;"><div class="class-name">Calidad del Software</div><div class="class-meta">Grupo 1SF133 · Mar y Jue · 7:00 AM · Aula 3B</div></div>
          <div class="class-right"><div class="class-count" id="cnt1SF133">5 est.</div><div class="class-avg">Prom: <span id="prom1SF133">--</span></div></div>
          <button class="btn btn-secondary btn-sm" onclick="openGrupoGrades('1SF133')">Ver Notas</button>
        </div>
        <!-- Grupo 1SF131: 4 estudiantes -->
        <div class="class-row">
          <div class="class-bar" style="background:var(--green);"></div>
          <div style="flex:1;"><div class="class-name">Ingeniería de Software I</div><div class="class-meta">Grupo 1SF131 · Lun y Mié · 9:00 AM · Aula 4A</div></div>
          <div class="class-right"><div class="class-count" id="cnt1SF131">4 est.</div><div class="class-avg">Prom: <span id="prom1SF131">--</span></div></div>
          <button class="btn btn-secondary btn-sm" onclick="openGrupoGrades('1SF131')">Ver Notas</button>
        </div>
        <!-- Grupo 2SF241: 3 estudiantes -->
        <div class="class-row">
          <div class="class-bar" style="background:var(--purple);"></div>
          <div style="flex:1;"><div class="class-name">Pruebas de Software</div><div class="class-meta">Grupo 2SF241 · Vie · 11:00 AM · Lab 2</div></div>
          <div class="class-right"><div class="class-count" id="cnt2SF241">3 est.</div><div class="class-avg">Prom: <span id="prom2SF241">--</span></div></div>
          <button class="btn btn-secondary btn-sm" onclick="openGrupoGrades('2SF241')">Ver Notas</button>
        </div>
      </div>

      <!-- RIESGO ACADÉMICO — vinculado desde Mis Grupos -->
      <div class="card" style="margin-top:22px;border-color:#fca5a5;">
        <div class="card-title" style="color:var(--red);">
          ⚠️ Estudiantes en Riesgo Académico
          <span id="riesgoBadge" style="background:var(--red);color:#fff;font-size:13px;font-weight:800;padding:3px 10px;border-radius:20px;font-family:'Nunito',sans-serif;"><%= enRiesgo %></span>
        </div>
        <div id="riesgoContainer">
          <!-- Cargado dinámicamente vía AJAX desde /grupos?accion=riesgo -->
          <div style="text-align:center;padding:24px;color:var(--text-soft);font-size:14px;" id="riesgoLoading">
            ⏳ Cargando estudiantes en riesgo…
          </div>
        </div>
      </div>

      <!-- GRADES per group (shown inline below) -->
      <div id="grupoGradesSection" class="hidden">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-top:22px;margin-bottom:14px;">
          <h3 style="font-family:'Merriweather',serif;font-size:20px;" id="grupoGradesTitle">Calificaciones — Grupo</h3>
          <button class="btn btn-secondary btn-sm" onclick="closeGrupoGrades()">✕ Cerrar</button>
        </div>
        <div class="card">
          <table class="delta-table">
            <thead><tr><th>#</th><th>Estudiante</th><th>Cédula</th><th>Parcial 1</th><th>Parcial 2</th><th>Proyecto</th><th>Final</th><th>Nota Final</th><th>Estado</th></tr></thead>
            <tbody id="grupoGradesBody"></tbody>
          </table>
          <div style="margin-top:18px;display:flex;gap:12px;flex-wrap:wrap;">
            <button class="btn btn-primary" onclick="saveGrupoGrades()">💾 Guardar Calificaciones</button>
          </div>
        </div>
      </div>
    </div>

    <!-- CALIFICACIONES (Grupo 1SF133 default) -->
    <div id="tab-calificaciones" class="tab-panel">
      <div class="topbar">
        <div>
          <h2 class="page-title">📊 Registro de Calificaciones</h2>
          <div class="page-subtitle">Grupo 1SF133 — Calidad del Software</div>
        </div>
        <div style="display:flex;gap:10px;align-items:center;">
          <select id="calGrupoSelect" style="padding:10px 14px;border:2px solid var(--border);border-radius:var(--radius-sm);font-family:'Nunito',sans-serif;font-size:15px;font-weight:700;color:var(--text);background:var(--bg);" onchange="renderCalificaciones()">
            <option value="1SF133">1SF133 — Calidad del Software</option>
            <option value="1SF131">1SF131 — Ingeniería de Software I</option>
            <option value="2SF241">2SF241 — Pruebas de Software</option>
          </select>
          <button class="btn btn-secondary" onclick="exportarCalificacionesExcel()">📥 Exportar a Excel</button>
        </div>
      </div>
      <div class="card">
        <div class="card-title" id="calCardTitle">Lista de Estudiantes — 1SF133</div>
        <table class="delta-table">
          <thead><tr><th>Estudiante</th><th>Cédula</th><th>Parcial 1</th><th>Parcial 2</th><th>Proyecto</th><th>Final</th><th>Nota Final</th><th>Estado</th></tr></thead>
          <tbody id="calTableBody"></tbody>
        </table>
        <div style="margin-top:18px;display:flex;gap:12px;flex-wrap:wrap;">
          <button class="btn btn-primary" onclick="saveCalificaciones()">💾 Guardar Calificaciones</button>
        </div>
      </div>
    </div>

    <!-- ASISTENCIA -->
    <div id="tab-asistencia" class="tab-panel">
      <div class="topbar">
        <div>
          <h2 class="page-title">✅ Control de Asistencia</h2>
          <div class="page-subtitle" id="attSubtitle">I Semestre 2026</div>
        </div>
        <div style="display:flex;gap:10px;align-items:center;">
          <select id="attGrupoSelect" style="padding:10px 14px;border:2px solid var(--border);border-radius:var(--radius-sm);font-family:'Nunito',sans-serif;font-size:15px;font-weight:700;color:var(--text);background:var(--bg);" onchange="renderAttendance()">
            <option value="1SF133">1SF133 — Calidad del Software</option>
            <option value="1SF131">1SF131 — Ingeniería de Software I</option>
            <option value="2SF241">2SF241 — Pruebas de Software</option>
          </select>
        </div>
      </div>

      <!-- ASISTENCIA DEL DÍA -->
      <div class="card" style="margin-bottom:22px;">
        <div class="card-title" id="attDayTitle">📅 Asistencia del Día — 27 Mayo 2026</div>
        <div id="attNoClassMsg" style="display:none;color:var(--text-soft);font-size:14px;padding:18px 0;text-align:center;">Este grupo no tiene clase hoy.</div>
        <div id="attDayContent">
        <div style="display:flex;align-items:center;gap:20px;margin-bottom:20px;flex-wrap:wrap;padding:14px;background:var(--bg2);border-radius:var(--radius-sm);">
          <div style="font-size:15px;font-weight:800;color:var(--text-mid);">Leyenda:</div>
          <div style="display:flex;align-items:center;gap:8px;font-size:16px;font-weight:700;"><button class="att-btn present" style="pointer-events:none;">✓</button> Presente</div>
          <div style="display:flex;align-items:center;gap:8px;font-size:16px;font-weight:700;"><button class="att-btn late" style="pointer-events:none;">⏱</button> Tardanza</div>
          <div style="display:flex;align-items:center;gap:8px;font-size:16px;font-weight:700;"><button class="att-btn absent" style="pointer-events:none;">✗</button> Ausente</div>
          <div style="font-size:14px;color:var(--text-soft);margin-left:auto;">Haga clic en el botón para cambiar el estado</div>
        </div>
        <!-- LIST VIEW -->
        <div id="attDayList" style="display:flex;flex-direction:column;gap:8px;"></div>
        <div style="margin-top:18px;display:flex;gap:12px;flex-wrap:wrap;align-items:center;">
          <div id="attSummary" style="font-size:15px;color:var(--text-mid);font-weight:600;"></div>
          <button class="btn btn-primary" style="margin-left:auto;" onclick="saveAttendance()">💾 Guardar Asistencia</button>
        </div>
        </div>
      </div>

      <!-- ASISTENCIA DE LA SEMANA -->
      <div class="card">
        <div class="card-title">
          📊 Asistencia de la Semana
          <span style="font-size:13px;font-family:'Nunito',sans-serif;color:var(--text-soft);font-weight:600;" id="attSemGrupoLabel">Grupo 1SF133 · Martes y Jueves</span>
        </div>
        <div style="display:flex;gap:18px;margin-bottom:22px;flex-wrap:wrap;">
          <div style="background:var(--green-bg);border:1.5px solid #86efac;border-radius:var(--radius-sm);padding:14px 20px;flex:1;min-width:110px;text-align:center;">
            <div style="font-size:28px;font-weight:800;font-family:'Merriweather',serif;color:var(--green);" id="semPresente">--</div>
            <div style="font-size:13px;color:var(--green);font-weight:700;margin-top:2px;">Clases Esta Semana</div>
          </div>
          <div style="background:var(--red-bg);border:1.5px solid #fca5a5;border-radius:var(--radius-sm);padding:14px 20px;flex:1;min-width:110px;text-align:center;">
            <div style="font-size:28px;font-weight:800;font-family:'Merriweather',serif;color:var(--red);" id="semAusente">--</div>
            <div style="font-size:13px;color:var(--red);font-weight:700;margin-top:2px;">Ausencias</div>
          </div>
          <div style="background:var(--amber-bg);border:1.5px solid #fcd34d;border-radius:var(--radius-sm);padding:14px 20px;flex:1;min-width:110px;text-align:center;">
            <div style="font-size:28px;font-weight:800;font-family:'Merriweather',serif;color:var(--amber);" id="semTardanza">--</div>
            <div style="font-size:13px;color:var(--amber);font-weight:700;margin-top:2px;">Tardanzas</div>
          </div>
          <div style="background:var(--blue-light);border:1.5px solid #93c5fd;border-radius:var(--radius-sm);padding:14px 20px;flex:1;min-width:110px;text-align:center;">
            <div style="font-size:28px;font-weight:800;font-family:'Merriweather',serif;color:var(--blue);" id="semPorcentaje">--</div>
            <div style="font-size:13px;color:var(--blue);font-weight:700;margin-top:2px;">% Asistencia</div>
          </div>
        </div>
        <!-- WEEKLY LIST: one row per class-day, students as columns -->
        <div id="semAttList"></div>
        <div style="display:flex;gap:14px;margin-top:14px;flex-wrap:wrap;align-items:center;">
          <div style="display:flex;align-items:center;gap:6px;font-size:13px;font-weight:700;"><span style="display:inline-block;width:22px;height:22px;border-radius:5px;background:var(--green-bg);border:1.5px solid #86efac;text-align:center;line-height:22px;font-size:13px;">✓</span> Presente</div>
          <div style="display:flex;align-items:center;gap:6px;font-size:13px;font-weight:700;"><span style="display:inline-block;width:22px;height:22px;border-radius:5px;background:var(--red-bg);border:1.5px solid #fca5a5;text-align:center;line-height:22px;font-size:13px;">✗</span> Ausente</div>
          <div style="display:flex;align-items:center;gap:6px;font-size:13px;font-weight:700;"><span style="display:inline-block;width:22px;height:22px;border-radius:5px;background:var(--amber-bg);border:1.5px solid #fcd34d;text-align:center;line-height:22px;font-size:13px;">⏱</span> Tardanza</div>
          <button class="btn btn-secondary btn-sm" style="margin-left:auto;" onclick="exportarAsistenciaExcel()">📥 Exportar a Excel</button>
        </div>
      </div>
    </div>

    <!-- HORARIO -->
    <div id="tab-horario" class="tab-panel">
      <div class="topbar"><div><h2 class="page-title">🗓️ Mi Horario</h2><div class="page-subtitle">I Semestre 2026 — Prof. María Mosquera</div></div></div>
      <div class="card" style="margin-bottom:22px;">
        <div class="card-title">Horario Semanal del Semestre</div>
        <div style="overflow-x:auto;">
          <div class="horario-grid" style="min-width:600px;">
            <!-- Headers -->
            <div class="horario-header">Hora</div>
            <div class="horario-header">Lunes</div>
            <div class="horario-header">Martes</div>
            <div class="horario-header">Miércoles</div>
            <div class="horario-header">Jueves</div>
            <div class="horario-header">Viernes</div>
            <!-- 7:00 AM -->
            <div class="horario-cell horario-time">7:00<br>8:00</div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-class" style="background:#dbeafe;color:#1a56a0;border:1.5px solid #93c5fd;">Calidad del Software<br><small>1SF133 · Aula 3B</small></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-class" style="background:#dbeafe;color:#1a56a0;border:1.5px solid #93c5fd;">Calidad del Software<br><small>1SF133 · Aula 3B</small></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <!-- 8:00 AM -->
            <div class="horario-cell horario-time">8:00<br>9:00</div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-class" style="background:#dbeafe;color:#1a56a0;border:1.5px solid #93c5fd;">Calidad del Software<br><small>1SF133 · Aula 3B</small></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-class" style="background:#dbeafe;color:#1a56a0;border:1.5px solid #93c5fd;">Calidad del Software<br><small>1SF133 · Aula 3B</small></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <!-- 9:00 AM -->
            <div class="horario-cell horario-time">9:00<br>10:00</div>
            <div class="horario-cell"><div class="horario-class" style="background:#bbf7d0;color:#14532d;border:1.5px solid #86efac;">Ingeniería de Software I<br><small>1SF131 · Aula 4A</small></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-class" style="background:#bbf7d0;color:#14532d;border:1.5px solid #86efac;">Ingeniería de Software I<br><small>1SF131 · Aula 4A</small></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <!-- 10:00 AM -->
            <div class="horario-cell horario-time">10:00<br>11:00</div>
            <div class="horario-cell"><div class="horario-class" style="background:#bbf7d0;color:#14532d;border:1.5px solid #86efac;">Ingeniería de Software I<br><small>1SF131 · Aula 4A</small></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-class" style="background:#bbf7d0;color:#14532d;border:1.5px solid #86efac;">Ingeniería de Software I<br><small>1SF131 · Aula 4A</small></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <!-- 11:00 AM -->
            <div class="horario-cell horario-time">11:00<br>12:00</div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-class" style="background:#ede9fe;color:#5b21b6;border:1.5px solid #c4b5fd;">Pruebas de Software<br><small>2SF241 · Lab 2</small></div></div>
            <!-- 12:00 PM -->
            <div class="horario-cell horario-time">12:00<br>1:00</div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-empty" style="padding:10px;border-radius:8px;height:100%;"></div></div>
            <div class="horario-cell"><div class="horario-class" style="background:#ede9fe;color:#5b21b6;border:1.5px solid #c4b5fd;">Pruebas de Software<br><small>2SF241 · Lab 2</small></div></div>
          </div>
        </div>
        <div style="display:flex;gap:16px;margin-top:18px;flex-wrap:wrap;">
          <div style="display:flex;align-items:center;gap:8px;font-size:13px;font-weight:700;"><div style="width:16px;height:16px;border-radius:4px;background:#1a56a0;"></div> Calidad del Software (1SF133)</div>
          <div style="display:flex;align-items:center;gap:8px;font-size:13px;font-weight:700;"><div style="width:16px;height:16px;border-radius:4px;background:#bbf7d0;border:1.5px solid #86efac;"></div> Ingeniería de Software I (1SF131)</div>
          <div style="display:flex;align-items:center;gap:8px;font-size:13px;font-weight:700;"><div style="width:16px;height:16px;border-radius:4px;background:#ede9fe;border:1.5px solid #c4b5fd;"></div> Pruebas de Software (2SF241)</div>
        </div>
      </div>
      <div class="grid-2">
        <div class="card">
          <div class="card-title">Detalle de Grupos</div>
          <table class="delta-table">
            <thead><tr><th>Grupo</th><th>Materia</th><th>Días</th><th>Aula</th><th>Estudiantes</th></tr></thead>
            <tbody>
              <tr><td><strong>1SF133</strong></td><td>Calidad del Software</td><td>Mar · Jue</td><td>Aula 3B P2</td><td><span class="tag tag-blue">5</span></td></tr>
              <tr><td><strong>1SF131</strong></td><td>Ingeniería de Software I</td><td>Lun · Mié</td><td>Aula 4A P2</td><td><span class="tag tag-blue">4</span></td></tr>
              <tr><td><strong>2SF241</strong></td><td>Pruebas de Software</td><td>Viernes</td><td>Lab 2</td><td><span class="tag tag-blue">3</span></td></tr>
            </tbody>
          </table>
        </div>
        <div class="card">
          <div class="card-title">Horas Semanales</div>
          <div style="display:flex;flex-direction:column;gap:12px;">
            <div style="display:flex;justify-content:space-between;align-items:center;padding:12px 14px;background:var(--blue-pale);border-radius:var(--radius-sm);border:1.5px solid var(--blue-light);">
              <span style="font-weight:800;color:var(--blue);">Calidad del Software</span>
              <span class="tag tag-blue">4 h/sem</span>
            </div>
            <div style="display:flex;justify-content:space-between;align-items:center;padding:12px 14px;background:var(--green-bg);border-radius:var(--radius-sm);border:1.5px solid #86efac;">
              <span style="font-weight:800;color:var(--green);">Ingeniería de Software I</span>
              <span class="tag tag-green">4 h/sem</span>
            </div>
            <div style="display:flex;justify-content:space-between;align-items:center;padding:12px 14px;background:var(--purple-bg);border-radius:var(--radius-sm);border:1.5px solid #c4b5fd;">
              <span style="font-weight:800;color:var(--purple);">Pruebas de Software</span>
              <span style="display:inline-block;padding:4px 12px;border-radius:20px;font-size:13px;font-weight:700;background:var(--purple-bg);color:var(--purple);border:1.5px solid #c4b5fd;">2 h/sem</span>
            </div>
            <div style="display:flex;justify-content:space-between;align-items:center;padding:12px 14px;background:var(--bg2);border-radius:var(--radius-sm);border:1.5px solid var(--border);font-weight:800;">
              <span>Total semanal</span>
              <span>10 horas</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- MENSAJES -->
    <div id="tab-mensajes" class="tab-panel">
      <div class="topbar"><div><h2 class="page-title">✉️ Mensajes</h2><div class="page-subtitle">Comunicación con estudiantes y administración</div></div></div>
      <div class="grid-2">
        <div class="card">
          <div class="card-title">Bandeja de Entrada <span class="nav-badge" style="font-size:14px;<%= (noLeidosMsgs > 0) ? "" : "display:none;" %>" id="inboxBadgeCount"><%= noLeidosMsgs %></span></div>
          <div id="profInbox"><div style="text-align:center;padding:20px;color:var(--text-soft);">Cargando mensajes...</div></div>
        </div>
        <div class="card">
          <div class="card-title">Nuevo Mensaje</div>
          <div class="compose-wrap">
            <datalist id="estudiantesOpciones">
              <option value="Laura Orellana">
              <option value="Edgar Sánchez">
              <option value="Evelin Pineda">
              <option value="Luis King">
              <option value="Gabriela Fuentes">
            </datalist>
            <input class="compose-input" id="profMsgTo" type="text" list="estudiantesOpciones" placeholder="Para: selecciona un estudiante...">
            <input class="compose-input" id="profMsgSubj" type="text" placeholder="Asunto...">
            <textarea class="compose-textarea" id="profMsgBody" placeholder="Escribe tu mensaje aquí..."></textarea>
            <div class="compose-footer">
              <button class="btn btn-secondary btn-sm">📎 Adjuntar</button>
              <button class="btn btn-primary btn-sm" onclick="sendProfMsg()">✉ Enviar Mensaje</button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- AVISOS -->
    <div id="tab-avisos" class="tab-panel">
      <div class="topbar"><div><h2 class="page-title">📢 Publicar Aviso</h2><div class="page-subtitle">Comunicados para los estudiantes del grupo</div></div></div>
      <div class="grid-2">
        <div class="card">
          <div class="card-title">Crear Nuevo Aviso</div>
          <div style="display:flex;flex-direction:column;gap:16px;">
            <div><label style="font-size:15px;font-weight:700;color:var(--text-mid);display:block;margin-bottom:7px;">Título del aviso</label><input id="avisoTitle" type="text" style="width:100%;padding:12px 14px;border:2px solid var(--border);border-radius:var(--radius-sm);font-family:'Nunito',sans-serif;font-size:16px;color:var(--text);background:var(--bg);" placeholder="Ej: Recordatorio de entrega..."></div>
            <div><label style="font-size:15px;font-weight:700;color:var(--text-mid);display:block;margin-bottom:7px;">Dirigido a</label>
              <select id="avisoGrupo" style="width:100%;padding:12px 14px;border:2px solid var(--border);border-radius:var(--radius-sm);font-family:'Nunito',sans-serif;font-size:16px;color:var(--text);background:var(--bg);">
                <option value="">Todos mis grupos</option>
              </select>
            </div>
            <div><label style="font-size:15px;font-weight:700;color:var(--text-mid);display:block;margin-bottom:7px;">Tipo</label>
              <select id="avisoTipo" style="width:100%;padding:12px 14px;border:2px solid var(--border);border-radius:var(--radius-sm);font-family:'Nunito',sans-serif;font-size:16px;color:var(--text);background:var(--bg);">
                <option value="info">📘 Informativo</option>
                <option value="urgente">⚠️ Urgente</option>
                <option value="recordatorio">📅 Recordatorio de fecha</option>
                <option value="exito">✅ Resultado / Nota</option>
              </select>
            </div>
            <div><label style="font-size:15px;font-weight:700;color:var(--text-mid);display:block;margin-bottom:7px;">Contenido</label><textarea id="avisoBody" style="width:100%;padding:12px 14px;border:2px solid var(--border);border-radius:var(--radius-sm);font-family:'Nunito',sans-serif;font-size:15px;color:var(--text);background:var(--bg);min-height:120px;resize:vertical;" placeholder="Redacte el aviso aquí..."></textarea></div>
            <button class="btn btn-primary" onclick="publicarAviso()">📢 Publicar Aviso</button>
          </div>
        </div>
        <div class="card">
          <div class="card-title">Avisos Publicados</div>
          <div id="avisosPublicados">
            <div style="color:var(--text-soft);font-size:14px;padding:12px 0;">Cargando avisos...</div>
          </div>
        </div>
      </div>
    </div>


    <!-- REPORTES -->
    <div id="tab-reportes" class="tab-panel">
      <div class="topbar"><div><h2 class="page-title">📋 Reportes y Auditoría</h2><div class="page-subtitle">Documentación trazable — Ley 6 de 2002 · Contraloría General</div></div></div>
      <div class="card">
        <div class="card-title">Reportes Disponibles</div>
        <div class="report-row">
          <div class="report-icon">📊</div>
          <div><div class="report-name">Calificaciones — 1SF133</div><div class="report-desc">Notas parciales y finales de todos los estudiantes</div></div>
          <button class="btn btn-primary btn-sm report-btn" onclick="exportarCalificacionesExcel('1SF133')">📊 Exportar a Excel</button>
        </div>
        <div class="report-row">
          <div class="report-icon">✅</div>
          <div><div class="report-name">Asistencia Semanal — 1SF133</div><div class="report-desc">Registro de asistencia de la semana actual</div></div>
          <button class="btn btn-primary btn-sm report-btn" onclick="exportarAsistenciaExcel('1SF133')">📊 Exportar a Excel</button>
        </div>
        <div class="report-row">
          <div class="report-icon">⚠️</div>
          <div><div class="report-name">Estudiante en Riesgo Académico</div><div class="report-desc">Lista con promedio inferior a 60 puntos</div></div>
          <button class="btn btn-primary btn-sm report-btn" onclick="exportarRiesgoExcel()">📊 Exportar a Excel</button>
        </div>
      </div>
    </div>

  </main>
</div>

<!-- Save Toast -->
<div class="save-toast" id="saveToast" onclick="confirmSaveGrades()">💾 Guardar cambios pendientes</div>

<!-- Grupos del profesor, para el selector de "Publicar Aviso" -->
<script type="application/json" id="mis-grupos-json"><%= misGruposJson %></script>

<script>
// ============================================================
// TOASTS Y MODALES (reemplazo de alert/confirm nativos)
// ============================================================
function showToast(mensaje, tipo) {
  tipo = tipo || 'info';
  var iconos = { success: '✅', error: '❌', info: 'ℹ️' };
  var container = document.getElementById('toastContainer');
  if (!container) { window.alert(mensaje); return; }
  var toast = document.createElement('div');
  toast.className = 'toast toast-' + tipo;
  toast.innerHTML =
    '<span class="toast-icon">' + (iconos[tipo] || iconos.info) + '</span>' +
    '<span class="toast-msg"></span>' +
    '<button class="toast-close" aria-label="Cerrar">&times;</button>';
  toast.querySelector('.toast-msg').textContent = mensaje;
  var quitar = function() {
    toast.classList.add('toast-out');
    setTimeout(function(){ if (toast.parentNode) toast.parentNode.removeChild(toast); }, 200);
  };
  toast.querySelector('.toast-close').addEventListener('click', quitar);
  container.appendChild(toast);
  setTimeout(quitar, 4000);
}

function showConfirm(mensaje, onConfirm) {
  var overlay = document.getElementById('confirmOverlay');
  var msgEl   = document.getElementById('confirmMsg');
  var okBtn   = document.getElementById('confirmOkBtn');
  var cancelBtn = document.getElementById('confirmCancelBtn');
  if (!overlay) { if (window.confirm(mensaje)) onConfirm(); return; }
  msgEl.textContent = mensaje;
  overlay.classList.remove('hidden');
  function cerrar() { overlay.classList.add('hidden'); okBtn.onclick = null; cancelBtn.onclick = null; }
  okBtn.onclick = function(){ cerrar(); onConfirm(); };
  cancelBtn.onclick = cerrar;
}

function showInfoModal(titulo, mensaje) {
  var overlay = document.getElementById('infoModalOverlay');
  var titleEl = document.getElementById('infoModalTitle');
  var msgEl   = document.getElementById('infoModalMsg');
  var closeBtn = document.getElementById('infoModalCloseBtn');
  if (!overlay) { window.alert(titulo + '\n\n' + mensaje); return; }
  titleEl.textContent = titulo;
  msgEl.textContent = mensaje;
  overlay.classList.remove('hidden');
  closeBtn.onclick = function(){ overlay.classList.add('hidden'); };
}

// ============================================================
// CONFIGURACIÓN DINÁMICA (generada por JSP)
// ============================================================
const CTX = '<%= request.getContextPath() %>';
const ATT_HAY_BD = '<%= hayBD %>' === 'true';
// ID del grupo IS-401 desde BD para cargar notas reales
window._grupoIS401Id = (function(){
  try {
    var ids = <%
      int _gid = 0;
      if (hayBD) {
        try (Connection _gc = ConexionDB.obtenerConexion();
             PreparedStatement _gp = _gc.prepareStatement(
               "SELECT g.id FROM grupos g JOIN materias m ON m.id=g.materia_id WHERE m.codigo='IS-401' LIMIT 1")) {
          ResultSet _gr = _gp.executeQuery();
          if (_gr.next()) _gid = _gr.getInt(1);
        } catch(Exception _ge){}
      }
    %><%= _gid %>;
    return ids;
  } catch(e){ return 0; }
})();
const MODO_BD = <%= hayBD %>;

// ─────────────────────────────────────────────────────────────
// CAMPANA ↔ MENSAJES: sincronización
// ─────────────────────────────────────────────────────────────
function sincronizarBadges(noLeidos, noLeidas) {
  const msgBadge    = document.getElementById('msgBadge');
  const notifDot    = document.getElementById('notifDot');
  const inboxBadge  = document.getElementById('inboxBadgeCount');
  const campanaNum  = document.getElementById('campanaCountProf');
  if (msgBadge)   { msgBadge.textContent   = noLeidos; msgBadge.style.display   = noLeidos > 0 ? 'inline-block':'none'; }
  if (inboxBadge) { inboxBadge.textContent = noLeidos; inboxBadge.style.display = noLeidos > 0 ? 'inline-block':'none'; }
  if (notifDot)   { notifDot.style.display = noLeidos > 0 ? 'block':'none'; }
  if (campanaNum) { campanaNum.textContent = noLeidos; campanaNum.style.display = noLeidos > 0 ? 'flex':'none'; }
}

function refreshBadgesFromBD() {
  if (!MODO_BD) return;
  fetch(CTX + '/mensajes?accion=noLeidos').then(r=>r.json()).then(d=>sincronizarBadges(d.mensajes,d.notificaciones)).catch(()=>{});
}

// Notificaciones desde BD — muestra mensajes no leídos
function cargarNotificaciones() {
  const body = document.getElementById('notifPanelBody');
  if (!body) return;
  fetch(CTX + '/mensajes?accion=bandeja').then(r=>r.json()).then(function(msgs) {
    body.innerHTML = '';
    if (!msgs.length) {
      body.innerHTML = '<div style="text-align:center;padding:20px;color:var(--text-soft);">Sin notificaciones.</div>';
    } else {
      msgs.forEach(function(msg) {
        var initials = msg.remitente ? msg.remitente.split(' ').map(function(p){return p[0];}).join('').substring(0,2).toUpperCase() : '??';
        var div = document.createElement('div');
        div.className = 'notif-panel-item ' + (msg.leido ? '' : 'unread');
        div.style.cursor = 'pointer';
        div.innerHTML =
          '<div class="npi-icon" style="background:var(--blue-light);">🎓</div>' +
          '<div style="flex:1;">' +
            '<div class="npi-title" style="font-weight:' + (msg.leido?'400':'700') + ';">' + (msg.remitente||'') + '</div>' +
            '<div class="npi-body">' + (msg.asunto||'') + '</div>' +
            '<div class="npi-body" style="font-size:11px;color:var(--text-soft);">' + formatFechaProf(msg.fecha) + '</div>' +
          '</div>' +
          (!msg.leido ? '<div class="npi-unread-dot"></div>' : '');
        div.onclick = function() {
          if (!msg.leido) {
            fetch(CTX+'/mensajes?accion=marcarLeido', {method:'POST',
              headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'id='+msg.id})
              .then(r=>r.json()).then(function(d){
                msg.leido = true;
                div.classList.remove('unread');
                div.querySelector('.npi-title').style.fontWeight = '400';
                var dot2 = div.querySelector('.npi-unread-dot');
                if (dot2) dot2.remove();
                sincronizarBadges(d.noLeidos||0, d.noLeidas||0);
                cargarInbox();
              });
          }
          goTab('mensajes', document.getElementById('navMensajes'));
          closeNotifPanel();
        };
        body.appendChild(div);
      });
    }
    var footer = document.createElement('div');
    footer.style.cssText = 'margin-top:16px;text-align:center;';
    footer.innerHTML = '<button class="btn btn-secondary btn-sm" onclick="marcarTodasLeidasProf()">✓ Marcar todas como leídas</button>';
    body.appendChild(footer);
    // Actualizar badge campana
    var noLeidos = msgs.filter(function(m){ return !m.leido; }).length;
    sincronizarBadges(noLeidos, noLeidos);
  }).catch(function(){
    body.innerHTML = '<div style="text-align:center;padding:20px;color:var(--text-soft);">Error al cargar.</div>';
  });
}

function formatFechaProf(f) {
  if (!f) return '';
  try {
    var d = new Date(f);
    var now = new Date();
    var diff = Math.floor((now - d) / 60000);
    if (diff < 1)  return 'Ahora';
    if (diff < 60) return 'Hace ' + diff + ' min';
    if (diff < 1440) return 'Hace ' + Math.floor(diff/60) + ' h';
    return d.toLocaleDateString('es-PA', {day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'});
  } catch(e){ return f.substring(0,16); }
}

function marcarTodasLeidasProf() {
  fetch(CTX+'/mensajes?accion=marcarTodasLeidas', {method:'POST'})
    .then(function(){ cargarNotificaciones(); cargarInbox(); sincronizarBadges(0,0); });
}

function marcarNotifLeidaBD(id, enlace) {
  fetch(CTX+'/mensajes?accion=marcarNotifLeida',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'id='+id})
    .then(r=>r.json()).then(data=>{
      const el=document.getElementById('notif-'+id);
      if(el){el.classList.remove('unread');const d=el.querySelector('.npi-unread-dot');if(d)d.remove();}
      if(data.noLeidas!==undefined){const dot=document.getElementById('notifDot');if(dot)dot.style.display=data.noLeidas>0?'block':'none';}
      if(enlace){closeNotifPanel();goTab(enlace,null);}
    }).catch(()=>markNotifRead(id));
}

function marcarTodasLeidasBD() {
  if(!MODO_BD){markAllNotifRead();return;}
  fetch(CTX+'/mensajes?accion=marcarTodasLeidas',{method:'POST'}).then(()=>markAllNotifRead()).catch(()=>markAllNotifRead());
}

// Abrir mensaje y marcar leído en BD
function openMsgBD(id) {
  openMsg(id);
  if(MODO_BD){
    fetch(CTX+'/mensajes?accion=marcarLeido',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'id='+id})
      .then(r=>r.json()).then(d=>{if(d.noLeidos!==undefined)sincronizarBadges(d.noLeidos,d.noLeidas);}).catch(()=>{});
  }
}

// Cargar riesgo académico en Mis Grupos
function cargarRiesgoAcademico() {
  const container = document.getElementById('riesgoContainer');
  if(!container) return;
  if(!MODO_BD){renderRiesgoDemo(container);return;}
  fetch(CTX+'/grupos?accion=riesgo').then(r=>r.json()).then(lista=>renderRiesgoTabla(container,lista)).catch(()=>renderRiesgoDemo(container));
}

function renderRiesgoTabla(container, lista) {
  if(lista.length===0){container.innerHTML='<div style="text-align:center;padding:24px;color:var(--green);font-weight:700;">✅ Ningún estudiante en riesgo académico actualmente.</div>';document.getElementById('riesgoBadge').textContent='0';return;}
  document.getElementById('riesgoBadge').textContent=lista.length;
  let html='<table class="delta-table"><thead><tr><th>Estudiante</th><th>Grupo</th><th>Materia</th><th>Promedio</th><th>Estado</th><th>Acción</th></tr></thead><tbody>';
  lista.forEach(er=>{
    const esR=er.estado==='RIESGO';
    const tag=esR?'<span class="tag tag-red">🚨 Riesgo</span>':'<span class="tag tag-amber">⚠️ Alerta</span>';
    html+=`<tr><td><strong>${escHtml(er.nombre)}</strong></td>
      <td><span class="tag tag-blue">${escHtml(er.codigoGrupo)}</span></td>
      <td>${escHtml(er.materia)}</td>
      <td><span class="tag ${esR?'tag-red':'tag-amber'}">${er.promedio}</span></td>
      <td>${tag}</td>
      <td><button class="btn btn-secondary btn-sm" onclick="enviarMsgRiesgo('${escHtml(er.nombre)}')">✉ Contactar</button></td></tr>`;
  });
  html+='</tbody></table>';
  container.innerHTML=html;
}

function renderRiesgoDemo(container) {
  // Calcular riesgo real desde gruposData['1SF133']
  var lista = [];
  gruposData['1SF133'].estudiantes.forEach(function(est) {
    var nota = calcNotaFinal(est.p1, est.p2, est.proj, est.final);
    if (nota < 70) {
      lista.push({
        nombre: est.name,
        codigoGrupo: '1SF133',
        materia: 'Calidad del Software',
        promedio: nota,
        estado: nota < 60 ? 'RIESGO' : 'ALERTA'
      });
    }
  });
  if (lista.length) {
    renderRiesgoTabla(container, lista);
  } else {
    container.innerHTML = '<div style="text-align:center;padding:24px;color:var(--green);font-weight:700;">✅ Ningún estudiante en riesgo académico actualmente.</div>';
    document.getElementById('riesgoBadge').textContent = '0';
  }
}

function enviarMsgRiesgo(nombre) {
  goTab('mensajes',null);
  setTimeout(()=>{
    const to=document.getElementById('profMsgTo'); if(to)to.value=nombre;
    const body=document.getElementById('profMsgBody');
    if(body){body.value='Estimado/a '+nombre+',\n\nMe comunico para hablar sobre su situación académica actual...';body.focus();}
  },300);
}

function escHtml(s){if(!s)return '';return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');}

// ==================== DATA ====================
// Mapa de inscripciones desde BD: {nombre: {iid, cedula}}
const inscripcionesBD = (function(){
  try { return JSON.parse('<%= inscripcionesJson %>'); } catch(e){ return {}; }
})();

const gruposData = {
  '1SF133': {
    nombre: 'Calidad del Software',
    estudiantes: (function(){
      // Si hay datos de BD, usarlos directamente con nombres y notas reales
      const bdKeys = Object.keys(inscripcionesBD);
      if (bdKeys.length > 0) {
        return bdKeys.map(function(nom) {
          var bd = inscripcionesBD[nom];
          return {
            name: nom,
            id: bd.cedula || '',
            inscripcionId: bd.iid,
            p1:    bd.p1    || 0,
            p2:    bd.p2    || 0,
            proj:  bd.proj  || 0,
            final: bd.final || 0
          };
        });
      }
      // Demo si no hay BD
      return [
        {name:'Laura Orellana',     id:'8-123-456',  p1:90, p2:88, proj:95, final:94},
        {name:'Edgar Sanchez',   id:'8-234-567',  p1:72, p2:68, proj:75, final:70},
        {name:'Evelin Pineda', id:'8-345-678',  p1:91, p2:93, proj:95, final:92},
        {name:'Luis King',       id:'8-456-789',  p1:65, p2:58, proj:62, final:60},
        {name:'Gabriela Fuentes',   id:'8-567-890',  p1:78, p2:82, proj:80, final:79},
      ];
    })()
  },
  '1SF131': {
    nombre: 'Ingeniería de Software I',
    estudiantes: [
      {name:'Ana Cedeño',        id:'8-1028-441',   p1:88, p2:84, proj:90, final:86},
      {name:'Roberto Flores',    id:'8-1035-772',   p1:76, p2:73, proj:80, final:77},
      {name:'María Ríos',        id:'8-1041-559',   p1:95, p2:93, proj:97, final:96},
      {name:'Carlos Mendoza',    id:'8-1019-334',   p1:62, p2:58, proj:64, final:61},
    ]
  },
  '2SF241': {
    nombre: 'Pruebas de Software',
    estudiantes: [
      {name:'Daniela Vega',      id:'8-1038-992',   p1:90, p2:92, proj:88, final:91},
      {name:'Fernando Castro',   id:'8-1044-117',   p1:78, p2:82, proj:79, final:80},
      {name:'Silvia Núñez',      id:'8-1027-663',   p1:85, p2:88, proj:86, final:87},
    ]
  }
};

// ==================== LOGIN ====================
function togglePasswordVisibility() {
  const input = document.getElementById('loginPass');
  const btn   = document.getElementById('togglePass');
  if (input.type === 'password') {
    input.type = 'text';
    btn.textContent = '🙈';
    btn.title = 'Ocultar contraseña';
    btn.setAttribute('aria-label', 'Ocultar contraseña');
  } else {
    input.type = 'password';
    btn.textContent = '👁';
    btn.title = 'Mostrar contraseña';
    btn.setAttribute('aria-label', 'Mostrar contraseña');
  }
}

function doLogin() {
  const user = document.getElementById('loginUser').value.trim();
  const pass = document.getElementById('loginPass').value.trim();
  const err  = document.getElementById('loginError');
  if (!user || !pass) { err.style.display='block'; setTimeout(()=>err.style.display='none',3500); return; }
  const form = document.createElement('form');
  form.method = 'POST';
  form.action = CTX + '/login';
  const fields = {username: user, password: pass, destino: 'profesor'};
  Object.keys(fields).forEach(function(k) {
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = k;
    input.value = fields[k];
    form.appendChild(input);
  });
  document.body.appendChild(form);
  form.submit();
}
document.getElementById('loginPass').addEventListener('keydown', e => { if(e.key==='Enter') doLogin(); });

function logout() {
  showConfirm('¿Desea cerrar sesión?', function() {
    document.getElementById('page-portal').classList.add('hidden');
    document.getElementById('page-login').classList.remove('hidden');
    document.getElementById('loginUser').value = '';
    document.getElementById('loginPass').value = '';
    document.getElementById('saveToast').classList.remove('show');
    closeNotifPanel();
  });
}

function goTab(id, btn) {
  document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(b => b.classList.remove('active'));
  document.getElementById('tab-' + id).classList.add('active');
  if (btn) btn.classList.add('active');
  window.scrollTo(0,0);
  // Cargar datos dinámicos según la pestaña
  if (id === 'grupos')   cargarRiesgoAcademico();
  if (id === 'mensajes') cargarInbox();
}

// ==================== GROUP COUNTS + AVERAGES ====================
function calcGrupoPromedio(grupo) {
  const ests = gruposData[grupo].estudiantes;
  if (!ests.length) return 0;
  const sum = ests.reduce((acc, e) => acc + calcNotaFinal(e.p1, e.p2, e.proj, e.final), 0);
  return Math.round((sum / ests.length) * 10) / 10;
}

function updateGroupCounts() {
  let totalEst = 0;
  let sumAllNotas = 0;
  let countAllEst = 0;
  Object.keys(gruposData).forEach(g => {
    const cnt = gruposData[g].estudiantes.length;
    totalEst += cnt;
    const elCnt = document.getElementById('cnt' + g);
    if (elCnt) elCnt.textContent = cnt + ' est.';
    const prom = calcGrupoPromedio(g);
    sumAllNotas += prom * cnt;
    countAllEst += cnt;
    const elProm = document.getElementById('prom' + g);
    if (elProm) elProm.textContent = prom;
  });
  const elTotal = document.getElementById('totalEstStat');
  if (elTotal) elTotal.textContent = totalEst;
  const elInicio = document.getElementById('inicioTotalEst');
  if (elInicio) elInicio.textContent = totalEst;
  const promGen = countAllEst > 0 ? Math.round((sumAllNotas / countAllEst) * 10) / 10 : 0;
  const elPromGen = document.getElementById('promGeneralStat');
  if (elPromGen) elPromGen.textContent = promGen;
}

// ==================== CALIFICACIONES ====================
function calcNotaFinal(p1, p2, proj, fin) {
  const v = [p1, p2, proj, fin].map(x => Math.min(100, Math.max(0, parseFloat(x) || 0)));
  return Math.round((v[0]*0.25 + v[1]*0.25 + v[2]*0.20 + v[3]*0.30) * 10) / 10;
}

function getEstado(nota) {
  if (nota >= 71) return '<span class="tag tag-green">✓ Aprobado</span>';
  if (nota >= 61) return '<span class="tag tag-amber">⚠ Riesgo</span>';
  return '<span class="tag tag-red">✗ Reprobado</span>';
}

function getEstadoTexto(nota) {
  if (nota >= 71) return 'Aprobado';
  if (nota >= 61) return 'Riesgo';
  return 'Reprobado';
}

function exportarCalificacionesExcel(grupoParam) {
  const grupo = grupoParam || document.getElementById('calGrupoSelect')?.value || '1SF133';
  const g = gruposData[grupo];
  if (!g) { showToast('No hay datos para exportar.', 'error'); return; }

  const encabezados = ['Estudiante','Cedula','Parcial 1','Parcial 2','Proyecto','Examen Final','Nota Final','Estado'];
  const filas = [encabezados];

  g.estudiantes.forEach(function(est) {
    const nota = calcNotaFinal(est.p1, est.p2, est.proj, est.final);
    filas.push([est.name, est.id, est.p1, est.p2, est.proj, est.final, nota, getEstadoTexto(nota)]);
  });

  const csv = filas.map(function(fila) {
    return fila.map(function(celda) {
      var val = String(celda).replace(/"/g, '""');
      if (val.indexOf(',') !== -1 || val.indexOf('"') !== -1 || val.indexOf('\n') !== -1) {
        val = '"' + val + '"';
      }
      return val;
    }).join(',');
  }).join('\r\n');

  // BOM para que Excel detecte UTF-8 y muestre tildes correctamente
  const blob = new Blob(['\uFEFF' + csv], {type: 'text/csv;charset=utf-8;'});
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = 'Calificaciones_' + grupo + '_' + g.nombre.replace(/\s+/g,'_') + '.csv';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);

  showToast('Archivo de calificaciones descargado.', 'success');
}

function exportarRiesgoExcel() {
  const grupo = '1SF133';
  const g = gruposData[grupo];
  if (!g) { showToast('No hay datos para exportar.', 'error'); return; }

  const encabezados = ['Estudiante','Cedula','Parcial 1','Parcial 2','Proyecto','Examen Final','Nota Final','Estado'];
  const filas = [encabezados];

  g.estudiantes.forEach(function(est) {
    const nota = calcNotaFinal(est.p1, est.p2, est.proj, est.final);
    if (nota < 70) {
      filas.push([est.name, est.id, est.p1, est.p2, est.proj, est.final, nota, getEstadoTexto(nota)]);
    }
  });

  if (filas.length === 1) {
    showToast('No hay estudiantes en riesgo en este grupo.', 'info');
    return;
  }

  const csv = filas.map(function(fila) {
    return fila.map(function(celda) {
      var val = String(celda).replace(/"/g, '""');
      if (val.indexOf(',') !== -1 || val.indexOf('"') !== -1 || val.indexOf('\n') !== -1) {
        val = '"' + val + '"';
      }
      return val;
    }).join(',');
  }).join('\r\n');

  const blob = new Blob(['\uFEFF' + csv], {type: 'text/csv;charset=utf-8;'});
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = 'Estudiantes_Riesgo_' + grupo + '.csv';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);

  showToast('Archivo de estudiantes en riesgo descargado.', 'success');
}

function exportarAsistenciaExcel(grupoParam) {
  const grupo = grupoParam || document.getElementById('attGrupoSelect')?.value || '1SF133';
  const g = gruposData[grupo];
  if (!g) { showToast('No hay datos de asistencia para exportar.', 'error'); return; }
  initAttSemStates(grupo);

  const dates = buildWeekDates(grupo);
  if (!dates.length) { showToast('Este grupo no tiene clases programadas esta semana.', 'info'); return; }

  const dayNames = ['Domingo','Lunes','Martes','Miercoles','Jueves','Viernes','Sabado'];
  const stateLabel = {present:'Presente', absent:'Ausente', late:'Tardanza'};

  const encabezados = ['Fecha','Dia','Estudiante','Cedula','Estado'];
  const filas = [encabezados];

  dates.forEach(function(d) {
    const key = d.toISOString().slice(0,10);
    g.estudiantes.forEach(function(s, si) {
      const st = attSemStates[grupo][key]?.[si] || 'present';
      filas.push([key, dayNames[d.getDay()], s.name, s.id, stateLabel[st]]);
    });
  });

  const csv = filas.map(function(fila) {
    return fila.map(function(celda) {
      var val = String(celda).replace(/"/g, '""');
      if (val.indexOf(',') !== -1 || val.indexOf('"') !== -1 || val.indexOf('\n') !== -1) {
        val = '"' + val + '"';
      }
      return val;
    }).join(',');
  }).join('\r\n');

  const blob = new Blob(['\uFEFF' + csv], {type: 'text/csv;charset=utf-8;'});
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = 'Asistencia_Semana_' + grupo + '.csv';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);

  showToast('Archivo de asistencia descargado.', 'success');
}

function getNotaTag(nota) {
  const cls = nota >= 71 ? 'tag-green' : nota >= 61 ? 'tag-amber' : 'tag-red';
  return `<span class="tag ${cls}" style="font-size:15px;padding:5px 12px;">${nota}</span>`;
}

function clampGrade(input) {
  let v = parseFloat(input.value);
  if (isNaN(v)) v = 0;
  if (v < 0) v = 0;
  if (v > 100) v = 100;
  input.value = v;
}

function renderGradesTable(tbodyId, grupo, editable, onchange) {
  const tbody = document.getElementById(tbodyId);
  if (!tbody) return;
  tbody.innerHTML = '';
  const g = gruposData[grupo];
  const LIMITE = 3; // debe coincidir con NotasServlet.LIMITE_MODIFICACIONES
  g.estudiantes.forEach((est, i) => {
    const nota = calcNotaFinal(est.p1, est.p2, est.proj, est.final);
    const tr = document.createElement('tr');
    const rowId = tbodyId + '_' + i;
    if (editable) {
      const inputCell = (modCount, val, id) => {
        const mods = modCount || 0;
        const enLimite = mods >= LIMITE;
        const restantes = LIMITE - mods;
        if (enLimite) {
          // Bloqueado — límite alcanzado
          return `<input class="grade-input" type="number" value="${val}" id="${id}" disabled
            title="Limite alcanzado (${mods}/${LIMITE} modificaciones). Solicita autorizacion al administrador."
            style="opacity:0.55;cursor:not-allowed;background:#fee2e2;border-color:#fca5a5;">`;
        } else if (mods > 0) {
          // Editable pero ya tiene modificaciones — mostrar aviso suave
          return `<input class="grade-input" type="number" min="0" max="100" value="${val}" id="${id}"
            oninput="clampGrade(this);updateRowFinal('${tbodyId}','${grupo}',${i})"
            onchange="showSaveToast()"
            title="${mods}/${LIMITE} modificaciones usadas. Quedan ${restantes}."
            style="border-color:#fbbf24;">`;
        } else {
          // Sin modificaciones — input normal
          return `<input class="grade-input" type="number" min="0" max="100" value="${val}" id="${id}"
            oninput="clampGrade(this);updateRowFinal('${tbodyId}','${grupo}',${i})"
            onchange="showSaveToast()">`;
        }
      };
      tr.innerHTML = `
        <td><strong>${est.name}</strong></td>
        <td style="color:var(--text-soft);font-size:14px;">${est.id}</td>
        <td>${inputCell(est.modP1,   est.p1,    rowId+'_p1')}</td>
        <td>${inputCell(est.modP2,   est.p2,    rowId+'_p2')}</td>
        <td>${inputCell(est.modProy, est.proj,  rowId+'_proj')}</td>
        <td>${inputCell(est.modEf,   est.final, rowId+'_fin')}</td>
        <td id="${rowId}_notafinal">${getNotaTag(nota)}</td>
        <td id="${rowId}_estado">${getEstado(nota)}</td>`;
      if (tbodyId === 'grupoGradesBody') {
        tr.innerHTML = `<td style="font-weight:800;color:var(--text-soft);">${i+1}</td>` + tr.innerHTML;
      }
    } else {
      tr.innerHTML = `<td><strong>${est.name}</strong></td><td style="color:var(--text-soft);">${est.id}</td><td>${est.p1}</td><td>${est.p2}</td><td>${est.proj}</td><td>${est.final}</td><td>${getNotaTag(nota)}</td><td>${getEstado(nota)}</td>`;
    }
    tbody.appendChild(tr);
  });
}

function updateRowFinal(tbodyId, grupo, i) {
  const rowId = tbodyId + '_' + i;
  const p1   = parseFloat(document.getElementById(rowId+'_p1')?.value) || 0;
  const p2   = parseFloat(document.getElementById(rowId+'_p2')?.value) || 0;
  const proj = parseFloat(document.getElementById(rowId+'_proj')?.value) || 0;
  const fin  = parseFloat(document.getElementById(rowId+'_fin')?.value) || 0;
  const nota = calcNotaFinal(p1, p2, proj, fin);
  const nfEl = document.getElementById(rowId+'_notafinal');
  const esEl = document.getElementById(rowId+'_estado');
  if (nfEl) nfEl.innerHTML = getNotaTag(nota);
  if (esEl) esEl.innerHTML = getEstado(nota);
  // Update stored data
  if (gruposData[grupo] && gruposData[grupo].estudiantes[i]) {
    gruposData[grupo].estudiantes[i].p1    = p1;
    gruposData[grupo].estudiantes[i].p2    = p2;
    gruposData[grupo].estudiantes[i].proj  = proj;
    gruposData[grupo].estudiantes[i].final = fin;
  }
  // Refresh averages in Grupos, riesgo y "Necesitan atención"
  updateGroupCounts();
  // Recalcular riesgo académico
  const riesgoContainer = document.getElementById('riesgoContainer');
  if (riesgoContainer) {
    if (!MODO_BD) {
      renderRiesgoDemo(riesgoContainer);
    } else {
      renderRiesgoDemo(riesgoContainer);
    }
  }
  // Actualizar badge de riesgo en inicio
  const totalRiesgo = gruposData['1SF133'].estudiantes.filter(function(e){
    return calcNotaFinal(e.p1,e.p2,e.proj,e.final) < 70;
  }).length;
  const rb = document.getElementById('riesgoBadge');
  if (rb) rb.textContent = totalRiesgo;
  const sr = document.getElementById('statEnRiesgo');
  if (sr) sr.textContent = totalRiesgo;
  const si = document.getElementById('statRiesgoInicio');
  if (si) si.textContent = totalRiesgo;
}

function guardarNotasEnBD(tbodyId, grupo) {
  const g = gruposData[grupo];
  if (!g) return;
  // Solo guardar si es grupo 1SF133 (vinculado a BD)
  if (grupo !== '1SF133') {
    document.getElementById('saveToast').classList.remove('show');
    showToast('Calificaciones guardadas correctamente.', 'success');
    return;
  }
  let pendientes = g.estudiantes.length * 4;
  let errores = 0;
  let primerError = null;
  g.estudiantes.forEach(function(est) {
    if (!est.inscripcionId) { pendientes -= 4; return; }
    const comps = [
      {comp:'parcial1',     val: est.p1},
      {comp:'parcial2',     val: est.p2},
      {comp:'proyecto',     val: est.proj},
      {comp:'examen_final', val: est.final}
    ];
    comps.forEach(function(c) {
      const params = 'inscripcionId=' + est.inscripcionId +
                     '&componente=' + encodeURIComponent(c.comp) +
                     '&nota=' + c.val;
      fetch(CTX+'/notas', {method:'POST',
        headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:params})
        .then(r=>r.json())
        .then(d=>{ pendientes--; if (!d.ok) { errores++; if (!primerError) primerError = d.error; } if (pendientes===0) {
          document.getElementById('saveToast').classList.remove('show');
          if (errores===0) {
            showToast('Calificaciones guardadas correctamente.', 'success');
            // Re-fetch para actualizar conteos de modificaciones y re-renderizar
            recargarNotasBD();
          } else {
            showToast((primerError ? primerError : 'Algunas notas no se pudieron guardar.') + (errores > 1 ? ' (' + errores + ' notas afectadas)' : ''), 'error');
            recargarNotasBD(); // Recargar igual para reflejar qué sí se guardó
          }
        }}).catch(()=>{ pendientes--; errores++; });
    });
  });
}

function renderCalificaciones() {
  const grupo = document.getElementById('calGrupoSelect')?.value || '1SF133';
  const g = gruposData[grupo];
  const titleEl = document.getElementById('calCardTitle');
  if (titleEl) titleEl.textContent = `Lista de Estudiantes — ${grupo}`;
  renderGradesTable('calTableBody', grupo, true, true);
}

/** Re-fetch notas desde BD para actualizar conteos de modificaciones y re-renderizar. */
function recargarNotasBD() {
  if (!window._grupoIS401Id) return;
  fetch(CTX + '/notas?grupoId=' + window._grupoIS401Id)
    .then(r => r.json())
    .then(function(lista) {
      if (!Array.isArray(lista)) return;
      lista.forEach(function(row) {
        var est = gruposData['1SF133'].estudiantes.find(function(e){ return e.inscripcionId === row.inscripcionId; });
        if (est) {
          if (row.p1   !== null) est.p1    = row.p1;
          if (row.p2   !== null) est.p2    = row.p2;
          if (row.proy !== null) est.proj  = row.proy;
          if (row.ef   !== null) est.final = row.ef;
          est.modP1   = row.modP1   || 0;
          est.modP2   = row.modP2   || 0;
          est.modProy = row.modProy || 0;
          est.modEf   = row.modEf   || 0;
        }
      });
      renderCalificaciones();
      updateGroupCounts();
    })
    .catch(function(){});
}

function showSaveToast() { document.getElementById('saveToast').classList.add('show'); }

function confirmSaveGrades() {
  document.getElementById('saveToast').classList.remove('show');
  saveCalificaciones();
}

function saveCalificaciones() {
  const grupo = document.getElementById('calGrupoSelect')?.value || '1SF133';
  guardarNotasEnBD('calTableBody', grupo);
  // Si es 1SF133, sincronizar con la tabla de Mis Grupos
  if (grupo === '1SF133') {
    sincronizarTablas('calTableBody', 'grupoGradesBody');
  }
}

// ==================== GRUPO GRADES ====================
let currentGrupoGrades = null;
function openGrupoGrades(grupo) {
  currentGrupoGrades = grupo;
  const section = document.getElementById('grupoGradesSection');
  const titleEl = document.getElementById('grupoGradesTitle');
  const g = gruposData[grupo];
  titleEl.textContent = `Calificaciones — Grupo ${grupo} · ${g.nombre}`;
  section.classList.remove('hidden');
  renderGradesTable('grupoGradesBody', grupo, true, true);
  section.scrollIntoView({behavior:'smooth', block:'start'});
}
function closeGrupoGrades() {
  document.getElementById('grupoGradesSection').classList.add('hidden');
  currentGrupoGrades = null;
}
function saveGrupoGrades() {
  if (currentGrupoGrades) {
    guardarNotasEnBD('grupoGradesBody', currentGrupoGrades);
    // Si es 1SF133, sincronizar con la tabla de Calificaciones
    if (currentGrupoGrades === '1SF133') {
      sincronizarTablas('grupoGradesBody', 'calTableBody');
    }
  }
}

function sincronizarTablas(origen, destino) {
  // Copiar notas desde una tabla hacia gruposData y re-renderizar la otra
  const rows = document.querySelectorAll('#' + origen + ' tr');
  rows.forEach(function(row) {
    const inputs = row.querySelectorAll('input[type="number"]');
    if (inputs.length < 4) return;
    const nameCell = row.querySelector('td strong');
    if (!nameCell) return;
    const name = nameCell.textContent.trim();
    const est = gruposData['1SF133'].estudiantes.find(function(e){ return e.name === name; });
    if (est) {
      est.p1    = parseFloat(inputs[0].value) || 0;
      est.p2    = parseFloat(inputs[1].value) || 0;
      est.proj  = parseFloat(inputs[2].value) || 0;
      est.final = parseFloat(inputs[3].value) || 0;
    }
  });
  // Re-renderizar tabla destino
  if (destino === 'calTableBody') {
    const sel = document.getElementById('calGrupoSelect');
    if (sel) sel.value = '1SF133';
    renderCalificaciones();
  } else {
    renderGradesTable(destino, '1SF133', true, true);
  }
}

// ==================== ATTENDANCE ====================
// Per-group semester class-day config
const gruposAttConfig = {
  '1SF133': {
    label: 'Grupo 1SF133 · Martes y Jueves',
    classDays: [2, 4], // Tue=2, Thu=4
    startDate: new Date(2026, 2, 3),
    color: '#1a56a0'
  },
  '1SF131': {
    label: 'Grupo 1SF131 · Lunes y Miércoles',
    classDays: [1, 3], // Mon=1, Wed=3
    startDate: new Date(2026, 2, 2),
    color: '#15803d'
  },
  '2SF241': {
    label: 'Grupo 2SF241 · Viernes',
    classDays: [5], // Fri=5
    startDate: new Date(2026, 2, 6),
    color: '#7c3aed'
  }
};

// Day-attendance state per group per student: attDayStates[grupo][studentIdx] = 'present'|'late'|'absent'
const attDayStates = {};

// Semester attendance per group per student per class-date: attSemStates[grupo][dateKey][studentIdx]
const attSemStates = {};

const cycle = ['present','late','absent'];
const symbols = {present:'✓', late:'⏱', absent:'✗'};

// Build this week's class dates (Mon-Sun) for a group, based on real "today"
function buildWeekDates(grupo) {
  const cfg = gruposAttConfig[grupo];
  const today = new Date();
  today.setHours(0,0,0,0);
  // Find Monday of current week
  const dow = today.getDay(); // 0=Sun..6=Sat
  const diffToMonday = (dow === 0) ? -6 : (1 - dow);
  const monday = new Date(today);
  monday.setDate(today.getDate() + diffToMonday);

  const result = [];
  for (let i = 0; i < 7; i++) {
    const d = new Date(monday);
    d.setDate(monday.getDate() + i);
    if (cfg.classDays.includes(d.getDay())) {
      result.push(d);
    }
  }
  return result;
}

// Seed initial semester attendance data for a group
const semInitPatterns = {
  '1SF133': {
    0: ['present','present','late','present','absent','present','present','present','late','present','present','present','absent','present','present','present','present','present'],
    1: ['present','present','present','late','present','present','absent','present','present','present','present','late','present','present','present','present','present','present'],
    2: ['present','late','present','present','present','absent','present','present','present','present','present','present','present','absent','present','present','present','present'],
    3: ['present','present','present','present','late','present','present','present','present','absent','present','present','present','present','present','present','present','late'],
    4: ['absent','present','present','present','present','late','present','absent','present','present','present','present','present','present','late','present','present','present'],
  },
  '1SF131': {
    0: ['present','present','present','present','late','present','present','present','absent','present','present','present','present','present','present','present'],
    1: ['present','late','present','present','present','absent','present','present','present','present','late','present','present','present','present','present'],
    2: ['present','present','present','late','present','present','present','present','present','present','present','absent','present','present','present','present'],
    3: ['late','present','absent','present','present','present','present','late','present','present','present','present','absent','present','present','present'],
  },
  '2SF241': {
    0: ['present','present','late','present','present','present','present','present','absent','present','present','present','present','present','present'],
    1: ['present','late','present','present','absent','present','present','present','present','present','late','present','present','present','present'],
    2: ['present','present','present','present','present','late','absent','present','present','present','present','present','present','late','present'],
  }
};

function initAttSemStates(grupo) {
  if (attSemStates[grupo]) return;
  attSemStates[grupo] = {};
  const dates = buildWeekDates(grupo);
  const today = new Date();
  today.setHours(0,0,0,0);
  const students = gruposData[grupo].estudiantes;
  dates.forEach((d, di) => {
    const key = d.toISOString().slice(0,10);
    attSemStates[grupo][key] = {};
    students.forEach((s, si) => {
      const pattern = semInitPatterns[grupo]?.[si] || [];
      const isPast = d < today;
      // Si ya pasó y hay un patron de demo, usarlo; si no, o si es hoy/futuro, "presente" por defecto
      attSemStates[grupo][key][si] = isPast && pattern[di] ? pattern[di] : 'present';
    });
  });

  // Si es un grupo vinculado a BD, cargar la asistencia real (sobrescribe lo anterior al llegar)
  if (ATT_HAY_BD && obtenerGrupoIdBD(grupo) !== null) {
    cargarAsistenciaBD(grupo);
  }
}

function initAttDayStates(grupo) {
  if (!attDayStates[grupo]) {
    attDayStates[grupo] = {};
    gruposData[grupo].estudiantes.forEach((s, i) => {
      const defaults = {
        '1SF133': ['present','present','late','present','absent'],
        '1SF131': ['present','present','present','late'],
        '2SF241': ['present','late','present']
      };
      attDayStates[grupo][i] = (defaults[grupo] || [])[i] || 'present';
    });
  }
}

// ==================== ASISTENCIA EN BASE DE DATOS (1SF133 / GRP-IS-401) ====================

// Carga la asistencia real de la semana desde el servidor y actualiza
// attSemStates / attDayStates para el grupo indicado, luego re-renderiza.
function cargarAsistenciaBD(grupo) {
  const grupoId = obtenerGrupoIdBD(grupo);
  if (grupoId === null) return;

  const dates = buildWeekDates(grupo);
  if (!dates.length) return;
  const desde = dates[0].toISOString().slice(0,10);
  const hasta = dates[dates.length-1].toISOString().slice(0,10);
  const today = new Date();
  today.setHours(0,0,0,0);
  const todayKey = today.toISOString().slice(0,10);

  fetch(CTX + '/asistencia?grupoId=' + grupoId + '&desde=' + desde + '&hasta=' + hasta)
    .then(function(r){ return r.json(); })
    .then(function(d){
      if (!d || !d.estudiantes) return;
      const students = gruposData[grupo].estudiantes;
      // Mapear inscripcionId -> indice del estudiante en gruposData
      const idxPorInscripcion = {};
      students.forEach(function(s, si){ if (s.inscripcionId) idxPorInscripcion[s.inscripcionId] = si; });

      dates.forEach(function(dt){
        const key = dt.toISOString().slice(0,10);
        if (!attSemStates[grupo][key]) attSemStates[grupo][key] = {};
        students.forEach(function(s, si){
          attSemStates[grupo][key][si] = 'present'; // valor por defecto
        });
      });

      Object.keys(d.asistencia || {}).forEach(function(k){
        // k = "inscripcionId-yyyy-MM-dd"
        const sepIdx = k.indexOf('-');
        const inscripcionId = parseInt(k.substring(0, sepIdx), 10);
        const fecha = k.substring(sepIdx+1);
        const si = idxPorInscripcion[inscripcionId];
        if (si === undefined) return;
        if (!attSemStates[grupo][fecha]) attSemStates[grupo][fecha] = {};
        attSemStates[grupo][fecha][si] = d.asistencia[k].estado;
      });

      // Sincronizar attDayStates (vista de hoy) con lo cargado de BD
      if (attSemStates[grupo][todayKey]) {
        students.forEach(function(s, si){
          attDayStates[grupo][si] = attSemStates[grupo][todayKey][si] || 'present';
        });
      }

      renderAttendance();
    })
    .catch(function(){ /* si falla, se mantiene la vista en memoria */ });
}

// Guarda en BD la asistencia de un estudiante en una fecha (1SF133 / GRP-IS-401)
function guardarAsistenciaBD(grupo, inscripcionId, fechaKey, estadoFrontend) {
  if (!ATT_HAY_BD || obtenerGrupoIdBD(grupo) === null || !inscripcionId) return Promise.resolve();
  const params = 'inscripcionId=' + encodeURIComponent(inscripcionId)
    + '&fecha=' + encodeURIComponent(fechaKey)
    + '&estado=' + encodeURIComponent(estadoFrontend);
  return fetch(CTX + '/asistencia', {
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: params
  }).then(function(r){ return r.json(); });
}

function renderAttendance() {
  const grupo = document.getElementById('attGrupoSelect')?.value || '1SF133';
  const cfg = gruposAttConfig[grupo];
  const g = gruposData[grupo];
  const today = new Date();
  const dayNames = ['Domingo','Lunes','Martes','Miercoles','Jueves','Viernes','Sabado'];
  const monthNames = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];

  initAttDayStates(grupo);
  initAttSemStates(grupo);

  // Update subtitle and labels
  const subtitleEl = document.getElementById('attSubtitle');
  if (subtitleEl) subtitleEl.textContent = `${g.nombre} — ${cfg.label}`;
  const dayTitleEl = document.getElementById('attDayTitle');
  if (dayTitleEl) dayTitleEl.textContent = `📅 Asistencia del Día — ${dayNames[today.getDay()]} ${today.getDate()} de ${monthNames[today.getMonth()]} ${today.getFullYear()} · ${g.nombre}`;
  const semLabelEl = document.getElementById('attSemGrupoLabel');
  if (semLabelEl) semLabelEl.textContent = cfg.label;

  // ---- ¿Hay clase hoy para este grupo? ----
  const hayClaseHoy = cfg.classDays.includes(today.getDay());
  const noClassMsg = document.getElementById('attNoClassMsg');
  const dayContent = document.getElementById('attDayContent');
  if (noClassMsg && dayContent) {
    if (hayClaseHoy) {
      noClassMsg.style.display = 'none';
      dayContent.style.display = '';
    } else {
      noClassMsg.style.display = 'block';
      dayContent.style.display = 'none';
    }
  }

  // ---- DAY LIST ----
  const dayList = document.getElementById('attDayList');
  dayList.innerHTML = '';
  g.estudiantes.forEach((s, i) => {
    const state = attDayStates[grupo][i];
    const row = document.createElement('div');
    row.style.cssText = 'display:flex;align-items:center;gap:14px;padding:12px 16px;border:1.5px solid var(--border);border-radius:var(--radius-sm);background:var(--bg);transition:background 0.15s;';
    row.innerHTML = `
      <div style="font-weight:800;color:var(--text-soft);min-width:24px;text-align:center;">${i+1}</div>
      <div style="flex:1;">
        <div style="font-weight:800;font-size:15px;">${s.name}</div>
        <div style="font-size:13px;color:var(--text-soft);">${s.id}</div>
      </div>
      <div id="attDayStateTag_${grupo}_${i}"></div>
      <button class="att-btn ${state}" id="attDayBtn_${grupo}_${i}" onclick="cycleAttDay('${grupo}',${i})">${symbols[state]}</button>
      <input type="text" placeholder="Observación..." style="border:2px solid var(--border);border-radius:8px;padding:8px 12px;font-family:'Nunito',sans-serif;font-size:13px;width:180px;background:var(--bg);color:var(--text);">
    `;
    dayList.appendChild(row);
    renderDayStateTag(grupo, i);
  });
  updateAttSummary(grupo);

  // ---- WEEKLY LIST ----
  renderSemesterList(grupo);
}

function renderDayStateTag(grupo, i) {
  const state = attDayStates[grupo][i];
  const el = document.getElementById(`attDayStateTag_${grupo}_${i}`);
  if (!el) return;
  const labels = {present:'<span class="tag tag-green">✓ Presente</span>', late:'<span class="tag tag-amber">⏱ Tardanza</span>', absent:'<span class="tag tag-red">✗ Ausente</span>'};
  el.innerHTML = labels[state] || '';
}

function cycleAttDay(grupo, i) {
  const cur = attDayStates[grupo][i];
  const idx = (cycle.indexOf(cur) + 1) % 3;
  attDayStates[grupo][i] = cycle[idx];
  const newState = attDayStates[grupo][i];
  // Reflejar el cambio del dia de hoy en la tabla semanal
  const todayKey = new Date().toISOString().slice(0,10);
  if (attSemStates[grupo] && attSemStates[grupo][todayKey] !== undefined) {
    attSemStates[grupo][todayKey][i] = newState;
    renderSemesterList(grupo);
  }
  const btn = document.getElementById(`attDayBtn_${grupo}_${i}`);
  if (btn) { btn.className = 'att-btn ' + newState; btn.textContent = symbols[newState]; }
  renderDayStateTag(grupo, i);
  updateAttSummary(grupo);
}

function updateAttSummary(grupo) {
  const vals = Object.values(attDayStates[grupo] || {});
  const p = vals.filter(v=>v==='present').length;
  const l = vals.filter(v=>v==='late').length;
  const a = vals.filter(v=>v==='absent').length;
  const el = document.getElementById('attSummary');
  if (el) el.innerHTML = `<span class="tag tag-green">✓ ${p} Presentes</span>&nbsp;<span class="tag tag-amber">⏱ ${l} Tardanza</span>&nbsp;<span class="tag tag-red">✗ ${a} Ausentes</span>`;
  // Actualizar también el stat de asistencia hoy en el Dashboard
  actualizarStatAsistenciaHoy();
}

/**
 * Actualiza el stat card "Asistencia Hoy" en el Dashboard de inicio
 * basándose en attDayStates del grupo que tiene clase hoy (1SF133 por defecto).
 */
function actualizarStatAsistenciaHoy() {
  var elVal = document.getElementById('statAsistenciaHoy');
  var elSub = document.getElementById('statAsistenciaHoySub');
  if (!elVal || !elSub) return;

  // Buscar el grupo que tiene clase hoy
  var diaHoy = DIA_SEMANA_MAP[new Date().getDay()];
  var grupoHoy = null;
  misGruposBD.forEach(function(g) {
    if (!grupoHoy && (g.horarios||[]).some(function(h){ return h.dia === diaHoy; })) {
      // Mapear codigo BD al codigo frontend
      if (g.codigo === 'GRP-IS-401') grupoHoy = '1SF133';
    }
  });

  if (!grupoHoy || !attDayStates[grupoHoy]) {
    elVal.textContent = '--';
    elSub.textContent = 'Sin clase hoy';
    return;
  }

  var vals = Object.values(attDayStates[grupoHoy]);
  var total = vals.length;
  if (total === 0) { elVal.textContent = '--'; elSub.textContent = 'Sin datos'; return; }
  var presentes = vals.filter(function(v){ return v === 'present'; }).length;
  var tardanzas = vals.filter(function(v){ return v === 'late'; }).length;
  var ausentes  = vals.filter(function(v){ return v === 'absent'; }).length;
  var pct = Math.round(((presentes + tardanzas) / total) * 100);
  elVal.textContent = pct + '%';
  elSub.textContent = presentes + ' presentes · ' + tardanzas + ' tardanzas · ' + ausentes + ' ausentes';
}

function renderSemesterList(grupo) {
  const container = document.getElementById('semAttList');
  if (!container) return;
  container.innerHTML = '';

  const g = gruposData[grupo];
  const dates = buildWeekDates(grupo);
  const today = new Date();
  today.setHours(0,0,0,0);
  const dayNames = ['Dom','Lun','Mar','Mié','Jue','Vie','Sáb'];
  const monthNames = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];

  // Compute totals (toda la semana, incluyendo dias futuros que por defecto son "presente")
  let totalClases = dates.length, totalAusencias = 0, totalTardanzas = 0;
  dates.forEach(d => {
    const key = d.toISOString().slice(0,10);
    g.estudiantes.forEach((s, si) => {
      const st = attSemStates[grupo][key]?.[si];
      if (st === 'absent') totalAusencias++;
      if (st === 'late') totalTardanzas++;
    });
  });
  const pct = totalClases > 0 && g.estudiantes.length > 0
    ? Math.round(((totalClases * g.estudiantes.length - totalAusencias - totalTardanzas * 0.5) / (totalClases * g.estudiantes.length)) * 100)
    : 100;

  document.getElementById('semPresente').textContent = totalClases;
  document.getElementById('semAusente').textContent = totalAusencias;
  document.getElementById('semTardanza').textContent = totalTardanzas;
  document.getElementById('semPorcentaje').textContent = pct + '%';

  // Build table: rows = class dates (esta semana), columns = students
  const table = document.createElement('table');
  table.className = 'delta-table';
  table.style.cssText = 'font-size:13px;';

  // Header
  const thead = document.createElement('thead');
  let thHTML = '<tr><th>Fecha</th><th>Día</th>';
  g.estudiantes.forEach(s => { thHTML += `<th style="text-align:center;min-width:90px;">${s.name.split(' ')[0]}<br><span style="font-weight:600;font-size:11px;color:var(--text-soft);">${s.name.split(' ')[1] || ''}</span></th>`; });
  thHTML += '</tr>';
  thead.innerHTML = thHTML;
  table.appendChild(thead);

  // Body
  const tbody = document.createElement('tbody');
  const stateStyle = {
    present: 'background:var(--green-bg);color:var(--green);border:1.5px solid #86efac;',
    absent:  'background:var(--red-bg);color:var(--red);border:1.5px solid #fca5a5;',
    late:    'background:var(--amber-bg);color:var(--amber);border:1.5px solid #fcd34d;'
  };
  const stateSymbol = {present:'✓', absent:'✗', late:'⏱'};
  const stateLabel  = {present:'Presente', absent:'Ausente', late:'Tardanza'};

  if (dates.length === 0) {
    container.innerHTML = '<div style="color:var(--text-soft);font-size:14px;padding:12px 0;">Este grupo no tiene clases programadas esta semana.</div>';
    return;
  }

  dates.forEach((d) => {
    const key = d.toISOString().slice(0,10);
    const esHoy = d.getTime() === today.getTime();
    const tr = document.createElement('tr');
    const dateStr = `${d.getDate()} ${monthNames[d.getMonth()]}`;
    let tdHTML = `<td style="font-weight:700;white-space:nowrap;">${dateStr}</td>`;
    tdHTML += `<td style="color:var(--text-soft);font-size:12px;">${dayNames[d.getDay()]}</td>`;
    g.estudiantes.forEach((s, si) => {
      const st = attSemStates[grupo][key]?.[si] || 'present';
      tdHTML += `<td style="text-align:center;padding:8px;">
        <span style="display:inline-block;width:68px;padding:4px 6px;border-radius:7px;font-size:12px;font-weight:700;${stateStyle[st]}" title="${s.name} — ${stateLabel[st]}">
          ${stateSymbol[st]} ${stateLabel[st]}
        </span>
      </td>`;
    });
    tr.innerHTML = tdHTML;
    if (esHoy) tr.style.background = 'var(--bg2)';
    tbody.appendChild(tr);
  });
  table.appendChild(tbody);
  container.appendChild(table);
}

function saveAttendance() {
  const grupo = document.getElementById('attGrupoSelect')?.value || '1SF133';
  const todayKey = new Date().toISOString().slice(0,10);
  const g = gruposData[grupo];

  if (attSemStates[grupo] && attSemStates[grupo][todayKey]) {
    g.estudiantes.forEach((s, i) => {
      attSemStates[grupo][todayKey][i] = attDayStates[grupo][i];
    });
    renderSemesterList(grupo);
  }

  // Persistir en BD si es un grupo vinculado (1SF133 / GRP-IS-401)
  if (ATT_HAY_BD && obtenerGrupoIdBD(grupo) !== null) {
    const promesas = [];
    g.estudiantes.forEach(function(s, i){
      if (s.inscripcionId) {
        promesas.push(guardarAsistenciaBD(grupo, s.inscripcionId, todayKey, attDayStates[grupo][i]));
      }
    });
    Promise.all(promesas)
      .then(function(){ showToast('Asistencia guardada correctamente.', 'success'); })
      .catch(function(){ showToast('Error al guardar algunos registros de asistencia.', 'error'); });
  } else {
    showToast('Asistencia guardada correctamente.', 'success');
  }
}

// ==================== SEMESTER ATTENDANCE (legacy stub — replaced by renderAttendance) ====================
function buildAttTable() { renderAttendance(); }
function buildSemesterAttendance() { /* handled in renderAttendance */ }

// ==================== NOTIFICATIONS ====================
let unreadNotifs = <%= noLeidasNotif %>;

function openNotifPanel() {
  document.getElementById('notifPanel').classList.remove('hidden-panel');
  cargarNotificaciones();
  document.getElementById('notifOverlay').classList.remove('hidden');
  cargarNotificaciones(); // recarga desde BD si está disponible
}
function closeNotifPanel() {
  document.getElementById('notifPanel').classList.add('hidden-panel');
  document.getElementById('notifOverlay').classList.add('hidden');
}
function markNotifRead(id) {
  const item = document.getElementById('notif-' + id);
  if (item && item.classList.contains('unread')) {
    item.classList.remove('unread');
    const dot = item.querySelector('.npi-unread-dot');
    if (dot) dot.remove();
    unreadNotifs = Math.max(0, unreadNotifs - 1);
    updateNotifBadge();
  }
}
function markAllNotifRead() {
  document.querySelectorAll('.notif-panel-item.unread').forEach(item => {
    item.classList.remove('unread');
    const dot = item.querySelector('.npi-unread-dot');
    if (dot) dot.remove();
  });
  unreadNotifs = 0;
  updateNotifBadge();
}
function updateNotifBadge() {
  const dot = document.getElementById('notifDot');
  if (unreadNotifs === 0) {
    if (dot) dot.style.display = 'none';
  } else {
    if (dot) dot.style.display = 'block';
  }
}

// ==================== MESSAGES ====================
const messagesData = {
  1: {
    from: 'Laura Orellana',
    time: 'Hoy, 8:15 AM',
    body: 'Profesora, tengo una duda sobre la rúbrica del Proyecto Delta. ¿El apartado de pruebas incluye pruebas de caja blanca? Estamos preparando el informe y no queremos omitir ningún requerimiento. Muchas gracias por su tiempo.'
  },
  2: {
    from: 'Edgar Sánchez',
    time: 'Ayer, 5:00 PM',
    body: 'Profesora, quisiera pedir una cita para hablar sobre mi situación académica. Tengo preguntas sobre cómo puedo mejorar mi promedio antes del cierre del semestre. Estoy disponible cualquier día esta semana. Gracias.'
  }
};
const msgRead = {1: false, 2: false};

function openMsg(id) {
  const msg = messagesData[id];
  document.getElementById('msgModalFrom').textContent = '✉️ ' + msg.from;
  document.getElementById('msgModalTime').textContent = msg.time;
  document.getElementById('msgModalBody').textContent = msg.body;
  document.getElementById('msgModal').classList.remove('hidden');
  document.body.style.overflow = 'hidden';
  // Mark as read
  if (!msgRead[id]) {
    msgRead[id] = true;
    const dotEl = document.getElementById('msgDot' + id);
    if (dotEl) dotEl.style.display = 'none';
    const itemEl = document.getElementById('msgItem' + id);
    if (itemEl) {
      const fromEl = itemEl.querySelector('.msg-from');
      if (fromEl) { fromEl.style.fontWeight = '600'; fromEl.style.color = 'var(--text-soft)'; }
    }
    updateInboxBadge();
  }
}

function updateInboxBadge() {
  const unread = Object.values(msgRead).filter(v => !v).length;
  const badge = document.getElementById('inboxBadgeCount');
  const navBadge = document.getElementById('msgBadge');
  if (badge) {
    badge.textContent = unread;
    badge.style.display = unread > 0 ? 'inline-block' : 'none';
  }
  if (navBadge) {
    navBadge.textContent = unread;
    navBadge.style.display = unread > 0 ? 'inline-block' : 'none';
  }
}

function closeMsgModal(event) {
  if (event.target.id === 'msgModal') {
    closeMsgModalBtn();
  }
}
function closeMsgModalBtn() {
  document.getElementById('msgModal').classList.add('hidden');
  document.body.style.overflow = '';
}
function replyToMsg() {
  const from = document.getElementById('msgModalFrom').textContent.replace('✉️ ', '');
  closeMsgModalBtn();
  goTab('mensajes', null);
  setTimeout(() => {
    const toInput = document.getElementById('profMsgTo');
    if (toInput) toInput.value = from;
    document.getElementById('profMsgBody').focus();
  }, 300);
}

// ==================== MESSAGES / ANNOUNCE ====================
function formatFecha(f) {
  if (!f) return '';
  try {
    var d = new Date(f);
    var now = new Date();
    var diff = Math.floor((now - d) / 60000);
    if (diff < 1)  return 'Ahora';
    if (diff < 60) return 'Hace ' + diff + ' min';
    if (diff < 1440) return 'Hace ' + Math.floor(diff/60) + ' h';
    return d.toLocaleDateString('es-PA', {day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'});
  } catch(e){ return f.substring(0,16); }
}

function cargarInbox() {
  const cont = document.getElementById('profInbox');
  if (!cont) return;
  fetch(CTX+'/mensajes?accion=bandeja')
    .then(r=>r.json())
    .then(function(msgs) {
      cont.innerHTML = '';
      if (!msgs.length) {
        cont.innerHTML = '<div style="text-align:center;padding:20px;color:var(--text-soft);">No hay mensajes.</div>';
        actualizarInicioMsgs([]);
        return;
      }
      msgs.forEach(function(msg) {
        var div = document.createElement('div');
        div.className = 'msg-item';
        div.style.cursor = 'pointer';
        var fontW = msg.leido ? '400' : '700';
        div.innerHTML =
          '<div class="msg-av">🎓</div>' +
          '<div style="flex:1;min-width:0;">' +
            '<div class="msg-from" style="font-weight:'+fontW+';">' + (msg.remitente||'Desconocido') + '</div>' +
            '<div class="msg-preview">' + (msg.asunto||'') + '</div>' +
            '<div style="font-size:12px;color:var(--text-soft);margin-top:4px;">' + formatFecha(msg.fecha) + '</div>' +
          '</div>' +
          '<div class="msg-unread" id="dot-'+msg.id+'" style="' + (msg.leido?'display:none;':'') + '"></div>';
        div.onclick = function() {
          if (!msg.leido) {
            fetch(CTX+'/mensajes?accion=marcarLeido', {method:'POST',
              headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'id='+msg.id})
              .then(r=>r.json()).then(function(d){
                sincronizarBadges(d.noLeidos, d.noLeidas);
                var dot = document.getElementById('dot-'+msg.id);
                if (dot) dot.style.display='none';
                div.querySelector('.msg-from').style.fontWeight='400';
                msg.leido = true;
                var badge = document.getElementById('inboxBadgeCount');
                var noLeidos = msgs.filter(function(m){return !m.leido;}).length;
                if (badge) { badge.textContent=noLeidos; badge.style.display=noLeidos>0?'inline-block':'none'; }
              });
          }
          showInfoModal('De: ' + (msg.remitente||'') + ' — ' + (msg.asunto||''), msg.cuerpo||'');
        };
        cont.appendChild(div);
      });
      // Actualizar badges
      var noLeidos = msgs.filter(function(m){return !m.leido;}).length;
      var badge = document.getElementById('inboxBadgeCount');
      if (badge) { badge.textContent=noLeidos; badge.style.display=noLeidos>0?'inline-block':'none'; }
      sincronizarBadges(noLeidos, 0);
      actualizarInicioMsgs(msgs);
    }).catch(function(){
      cont.innerHTML = '<div style="text-align:center;padding:20px;color:var(--text-soft);">Error al cargar mensajes.</div>';
    });
}

function actualizarInicioMsgs(msgs) {
  var cont = document.getElementById('inicioMsgList');
  if (!cont) return;
  if (!msgs.length) {
    cont.innerHTML = '<div style="color:var(--text-soft);font-size:13px;padding:8px 0;">No hay mensajes recientes.</div>';
    return;
  }
  cont.innerHTML = '';
  msgs.slice(0,3).forEach(function(msg) {
    var div = document.createElement('div');
    div.className = 'notif-item';
    div.style.cursor = 'pointer';
    div.innerHTML = '<div class="notif-icon-box" style="background:var(--blue-light);">📩</div>' +
      '<div><div class="notif-title" style="font-weight:'+(msg.leido?'400':'700')+';">' + (msg.remitente||'') + '</div>' +
      '<div class="notif-body">' + (msg.asunto||'') + '</div>' +
      '<div class="notif-time">' + formatFecha(msg.fecha) + '</div></div>';
    div.onclick = function(){ goTab('mensajes', null); };
    cont.appendChild(div);
  });
}

function sendProfMsg() {
  const to    = document.getElementById('profMsgTo').value.trim();
  const subj  = document.getElementById('profMsgSubj').value.trim() || '(Sin asunto)';
  const body  = document.getElementById('profMsgBody').value.trim();
  if (!to || !body) { showToast('Complete el destinatario y el mensaje.', 'error'); return; }
  const params = 'accion=enviar&destinatario='+encodeURIComponent(to)+'&asunto='+encodeURIComponent(subj)+'&cuerpo='+encodeURIComponent(body);
  fetch(CTX+'/mensajes', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:params})
    .then(r=>r.json())
    .then(d=>{
      if(d.ok){
        showToast('Mensaje enviado a: ' + to, 'success');
        document.getElementById('profMsgTo').value='';
        document.getElementById('profMsgSubj').value='';
        document.getElementById('profMsgBody').value='';
        cargarInbox();
      } else {
        showToast('Error: ' + (d.error||'No se pudo enviar. Verifica el nombre del destinatario.'), 'error');
      }
    }).catch(()=>showToast('Error de conexion al enviar el mensaje.', 'error'));
}

// ==================== AVISOS ====================
const misGruposBD = (function(){
  try {
    var tag = document.getElementById('mis-grupos-json');
    var json = tag ? tag.textContent : '[]';
    return JSON.parse(json || '[]');
  } catch(e) { return []; }
})();

// Mapa de codigo de grupo (frontend) -> codigo_grupo real en BD, para Asistencia
const ATT_CODIGO_BD = { '1SF133': 'GRP-IS-401' };

// Devuelve el grupoId real de BD para un codigo de grupo del frontend, o null
function obtenerGrupoIdBD(grupo) {
  const codigoBD = ATT_CODIGO_BD[grupo];
  if (!codigoBD) return null;
  const match = misGruposBD.find(function(g){ return g.codigo === codigoBD; });
  return match ? match.grupoId : null;
}

function poblarSelectGruposAviso() {
  var sel = document.getElementById('avisoGrupo');
  if (!sel) return;
  misGruposBD.forEach(function(g) {
    var opt = document.createElement('option');
    opt.value = g.grupoId;
    opt.textContent = 'Grupo ' + g.codigo + ' — ' + g.materia;
    sel.appendChild(opt);
  });
}

// ==================== INICIO: FECHA Y CLASES DE HOY ====================
var DIA_SEMANA_MAP = ['domingo','lunes','martes','miercoles','jueves','viernes','sabado'];
var MESES_ES = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
var DIAS_ES  = ['Domingo','Lunes','Martes','Miercoles','Jueves','Viernes','Sabado'];
var SCHED_COLORES = [
  {bg:'#dbeafe', text:'#1a56a0', border:'#93c5fd'},  // azul pastel
  {bg:'#bbf7d0', text:'#14532d', border:'#86efac'},  // verde pastel
  {bg:'#ede9fe', text:'#5b21b6', border:'#c4b5fd'},  // púrpura pastel
  {bg:'#fef3c7', text:'#92400e', border:'#fcd34d'},  // ámbar pastel
  {bg:'#fee2e2', text:'#991b1b', border:'#fca5a5'},  // rojo pastel
  {bg:'#cffafe', text:'#164e63', border:'#67e8f9'},  // cyan pastel
];

function formatHora12(horaStr) {
  // horaStr viene como "HH:MM:SS"
  var partes = horaStr.split(':');
  var hh = parseInt(partes[0], 10);
  var mm = partes[1];
  var sufijo = hh >= 12 ? 'PM' : 'AM';
  var hh12 = hh % 12; if (hh12 === 0) hh12 = 12;
  return hh12 + ':' + mm + ' ' + sufijo;
}

function renderFechaHoyProf() {
  var el = document.getElementById('fechaHoyProf');
  if (!el) return;
  var hoy = new Date();
  var fechaStr = DIAS_ES[hoy.getDay()] + ' ' + hoy.getDate() + ' de ' + MESES_ES[hoy.getMonth()] + ', ' + hoy.getFullYear();

  // Construir lista de materias con clase hoy desde misGruposBD
  var diaHoy = DIA_SEMANA_MAP[hoy.getDay()];
  var materiasHoy = [];
  misGruposBD.forEach(function(g) {
    var tieneClase = (g.horarios || []).some(function(h){ return h.dia === diaHoy; });
    if (tieneClase) materiasHoy.push(g.materia || g.codigo);
  });

  var sufijo = materiasHoy.length > 0
    ? ' · ' + materiasHoy.join(' · ')
    : ' · Sin clases hoy';

  el.textContent = fechaStr + ' · I Semestre 2026' + sufijo;
}

function renderClasesHoy() {
  var cont = document.getElementById('clasesHoyContainer');
  if (!cont) return;

  var diaHoy = DIA_SEMANA_MAP[new Date().getDay()];
  var clases = [];

  misGruposBD.forEach(function(g, idx) {
    (g.horarios || []).forEach(function(h) {
      if (h.dia === diaHoy) {
        clases.push({
          hora: h.horaInicio,
          materia: g.materia,
          codigo: g.codigo,
          numEstudiantes: g.numEstudiantes,
          aula: g.aula,
          colores: SCHED_COLORES[idx % SCHED_COLORES.length]
        });
      }
    });
  });

  if (clases.length === 0) {
    cont.innerHTML = '<div style="color:var(--text-soft);font-size:14px;padding:12px 0;">No hay clases hoy.</div>';
    actualizarStatAsistenciaHoy();
    return;
  }

  clases.sort(function(a,b){ return a.hora.localeCompare(b.hora); });

  var html = '';
  clases.forEach(function(c) {
    var col = c.colores;
    html +=
      '<div class="sched-item">' +
        '<div class="sched-time">' + formatHora12(c.hora) + '</div>' +
        '<div class="sched-bar" style="background:' + col.bg + ';border:2px solid ' + col.border + ';"></div>' +
        '<div>' +
          '<div class="sched-subject" style="color:' + col.text + ';">' + escHtml(c.materia) + ' — ' + escHtml(c.codigo) + '</div>' +
          '<div class="sched-prof">' + (c.numEstudiantes||0) + ' estudiantes inscritos</div>' +
          '<div class="sched-room">🏫 ' + escHtml(c.aula||'Sin asignar') + '</div>' +
        '</div>' +
      '</div>';
  });
  cont.innerHTML = html;
  actualizarStatAsistenciaHoy();
}

const AVISO_ICONOS = { info:'📘', urgente:'⚠️', recordatorio:'📅', exito:'✅' };
const AVISO_CLASES = { info:'', urgente:'amber', recordatorio:'', exito:'green' };

function renderAvisosPublicados(lista) {
  const container = document.getElementById('avisosPublicados');
  if (!container) return;
  if (!lista || !lista.length) {
    container.innerHTML = '<div style="color:var(--text-soft);font-size:14px;padding:12px 0;">Aun no ha publicado avisos.</div>';
    return;
  }
  container.innerHTML = '';
  lista.forEach(function(a) {
    const div = document.createElement('div');
    const clase = AVISO_CLASES[a.tipo] || '';
    div.className = 'ann-item' + (clase ? ' ' + clase : '');
    const icono = AVISO_ICONOS[a.tipo] || '📘';
    const destino = a.grupo ? ('Grupo ' + a.grupo) : 'Todos mis grupos';
    div.innerHTML = '<div class="ann-title">' + icono + ' ' + escHtml(a.titulo) + '</div>'
      + '<div class="ann-body">' + escHtml(a.cuerpo) + '</div>'
      + '<div class="ann-date">' + escHtml(a.fecha) + ' · ' + escHtml(destino) + '</div>';
    container.appendChild(div);
  });
}

function cargarAvisosPublicados() {
  fetch(CTX + '/avisos')
    .then(function(r){ return r.json(); })
    .then(function(d){ renderAvisosPublicados(Array.isArray(d) ? d : []); })
    .catch(function(){
      document.getElementById('avisosPublicados').innerHTML =
        '<div style="color:var(--text-soft);font-size:14px;padding:12px 0;">No se pudieron cargar los avisos.</div>';
    });
}

function publicarAviso() {
  const title = document.getElementById('avisoTitle').value.trim();
  const body  = document.getElementById('avisoBody').value.trim();
  const grupoId = document.getElementById('avisoGrupo').value;
  const tipo  = document.getElementById('avisoTipo').value;
  if (!title || !body) { showToast('Complete el título y el contenido del aviso.', 'error'); return; }

  const params = 'titulo=' + encodeURIComponent(title)
    + '&cuerpo=' + encodeURIComponent(body)
    + '&tipo=' + encodeURIComponent(tipo)
    + '&grupoId=' + encodeURIComponent(grupoId);

  fetch(CTX + '/avisos', {
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: params
  })
  .then(function(r){ return r.json(); })
  .then(function(d) {
    if (!d.ok) {
      showToast('Error: ' + (d.error || 'No se pudo publicar el aviso.'), 'error');
      return;
    }
    document.getElementById('avisoTitle').value = '';
    document.getElementById('avisoBody').value  = '';
    cargarAvisosPublicados();
    showToast('Aviso publicado correctamente.', 'success');
  })
  .catch(function(){ showToast('Error de conexion al publicar el aviso.', 'error'); });
}

// ==================== INIT ====================
window.addEventListener('DOMContentLoaded', function() {
  cargarInbox();
  // Cargar notas reales de BD para grupo 1SF133
  if (typeof CTX !== 'undefined') {
    fetch(CTX+'/notas?grupoId=' + (window._grupoIS401Id||0))
      .then(r=>r.json())
      .then(function(lista){
        if (!Array.isArray(lista) || !lista.length) return;
        lista.forEach(function(row) {
          var est = gruposData['1SF133'].estudiantes.find(function(e){ return e.inscripcionId === row.inscripcionId; });
          if (est) {
            if (row.p1   !== null) est.p1    = row.p1;
            if (row.p2   !== null) est.p2    = row.p2;
            if (row.proy !== null) est.proj  = row.proy;
            if (row.ef   !== null) est.final = row.ef;
            // Conteo de modificaciones por componente (para bloquear inputs al limite)
            est.modP1   = row.modP1   || 0;
            est.modP2   = row.modP2   || 0;
            est.modProy = row.modProy || 0;
            est.modEf   = row.modEf   || 0;
          }
        });
        updateGroupCounts();
        renderCalificaciones();
      }).catch(function(){ updateGroupCounts(); renderCalificaciones(); });
  } else {
    updateGroupCounts();
    renderCalificaciones();
  }
  renderAttendance();
  // Sincronizar badges al cargar
  refreshBadgesFromBD();
  // Avisos
  poblarSelectGruposAviso();
  cargarAvisosPublicados();
  // Inicio: fecha y clases de hoy
  renderFechaHoyProf();
  renderClasesHoy();
});
</script>
<script>
(function() {
  var hayBD = '<%= hayBD %>' === 'true';
  if (hayBD) {
    document.getElementById('page-login').classList.add('hidden');
    document.getElementById('page-portal').classList.remove('hidden');
    if (typeof buildAttTable === 'function') buildAttTable();
    if (typeof renderCalificaciones === 'function') renderCalificaciones();
    if (typeof updateGroupCounts === 'function') updateGroupCounts();
    window.scrollTo(0,0);
  }
})();
</script>
</body>
</html>
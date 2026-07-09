<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ page import="com.delta.util.ConexionDB, java.sql.*" %>
<%
  response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
  response.setHeader("Pragma", "no-cache");
  response.setDateHeader("Expires", 0);

  Integer est_usuarioId = (Integer) session.getAttribute("usuarioId");
  String  est_rol       = (String)  session.getAttribute("usuarioRol");
  boolean est_hayBD     = (est_usuarioId != null && "estudiante".equals(est_rol));
  boolean est_loginError = "1".equals(request.getParameter("error"));
  if (est_usuarioId != null && "profesor".equals(est_rol)) {
    response.sendRedirect(request.getContextPath() + "/portal_profesor.jsp");
    return;
  }
  if (est_usuarioId != null && "admin".equals(est_rol)) {
    response.sendRedirect(request.getContextPath() + "/portal_administrador.jsp");
    return;
  }

  String est_nombre   = "Estudiante";
  String est_apellido = "";
  String est_cedula   = "";
  String est_inicial  = "E";
  String est_semestre = "";
  String est_carrera  = "";
  int    est_estudianteId = -1;
  Integer est_carreraId = null;

  if (est_hayBD) {
    try (Connection _con = ConexionDB.obtenerConexion();
         PreparedStatement _ps = _con.prepareStatement(
           "SELECT e.id, e.nombre, e.apellido, e.cedula, e.semestre, e.carrera, e.carrera_id " +
           "FROM estudiantes e WHERE e.usuario_id = ?")) {
      _ps.setInt(1, est_usuarioId);
      try (ResultSet _rs = _ps.executeQuery()) {
        if (_rs.next()) {
          est_estudianteId = _rs.getInt("id");
          est_nombre   = _rs.getString("nombre")   != null ? _rs.getString("nombre")   : "";
          est_apellido = _rs.getString("apellido") != null ? _rs.getString("apellido") : "";
          est_cedula   = _rs.getString("cedula")   != null ? _rs.getString("cedula")   : "";
          est_semestre = _rs.getString("semestre") != null ? String.valueOf(_rs.getInt("semestre")) : "";
          est_carrera  = _rs.getString("carrera")  != null ? _rs.getString("carrera")  : "";
          int _carreraIdTmp = _rs.getInt("carrera_id");
          est_carreraId = _rs.wasNull() ? null : _carreraIdTmp;
          est_inicial  = est_nombre.length() > 0 ? est_nombre.substring(0,1).toUpperCase() : "E";
        }
      }
    } catch (Exception _e) { }
  }
  String est_nombreCompleto = (est_nombre + " " + est_apellido).trim();

  StringBuilder est_materiasJsonSb = new StringBuilder("[");
  StringBuilder est_disponiblesJsonSb = new StringBuilder("[");
  if (est_hayBD) {
    try (Connection _con2 = ConexionDB.obtenerConexion()) {

      String[][] _paleta = {
        {"#1a56a0","#dbeafe"}, {"#0e7490","#cffafe"}, {"#15803d","#dcfce7"},
        {"#7c3aed","#ede9fe"}, {"#b45309","#fef3c7"}, {"#dc2626","#fee2e2"},
        {"#0f766e","#ccfbf1"}, {"#9333ea","#f3e8ff"}
      };
      java.util.Map<String,String> _diaMap = new java.util.HashMap<>();
      _diaMap.put("lunes","lun");     _diaMap.put("martes","mar");
      _diaMap.put("miercoles","mie"); _diaMap.put("jueves","jue");
      _diaMap.put("viernes","vie");   _diaMap.put("sabado","sab");

      java.util.Map<Integer, java.util.List<String[]>> _horariosPorGrupo = new java.util.HashMap<>();
      try (PreparedStatement _psH = _con2.prepareStatement(
             "SELECT grupo_id, dia_semana, hora_inicio FROM horarios ORDER BY grupo_id, hora_inicio");
           ResultSet _rsH = _psH.executeQuery()) {
        while (_rsH.next()) {
          int _gid = _rsH.getInt("grupo_id");
          java.time.LocalTime _lt = _rsH.getTime("hora_inicio").toLocalTime();
          String _horaFmt = _lt.format(java.time.format.DateTimeFormatter.ofPattern("h:mm a", java.util.Locale.US));
          String _diaEnum = _rsH.getString("dia_semana");
          _horariosPorGrupo.computeIfAbsent(_gid, k -> new java.util.ArrayList<>())
                           .add(new String[]{ _diaEnum, _horaFmt });
        }
      }

      java.util.Set<String> _codigosInscritos = new java.util.HashSet<>();
      try (PreparedStatement _psC = _con2.prepareStatement(
             "SELECT m.codigo FROM inscripciones i " +
             "JOIN estudiantes e ON e.id = i.estudiante_id " +
             "JOIN grupos g ON g.id = i.grupo_id " +
             "JOIN materias m ON m.id = g.materia_id " +
             "WHERE e.usuario_id = ? AND i.estado = 'activo'")) {
        _psC.setInt(1, est_usuarioId);
        try (ResultSet _rsC = _psC.executeQuery()) {
          while (_rsC.next()) _codigosInscritos.add(_rsC.getString("codigo"));
        }
      }

      // Materias retiradas previamente: quedan bloqueadas para re-inscripcion.
      java.util.Set<Integer> _gruposBloqueados = new java.util.HashSet<>();
      try (PreparedStatement _psB = _con2.prepareStatement(
             "SELECT grupo_id FROM materias_bloqueadas WHERE estudiante_id = ?")) {
        _psB.setInt(1, est_estudianteId);
        try (ResultSet _rsB = _psB.executeQuery()) {
          while (_rsB.next()) _gruposBloqueados.add(_rsB.getInt("grupo_id"));
        }
      }

      // FIX: agregado m.creditos al SELECT
      try (PreparedStatement _ps2 = _con2.prepareStatement(
             "SELECT g.id AS grupo_id, m.codigo, m.nombre, m.creditos, " +
             "CONCAT(p.nombre,' ',p.apellido) AS docente, " +
             "g.aula, " +
             "MAX(CASE WHEN n.componente='parcial1'     THEN n.nota END) AS p1, " +
             "MAX(CASE WHEN n.componente='parcial2'     THEN n.nota END) AS p2, " +
             "MAX(CASE WHEN n.componente='proyecto'     THEN n.nota END) AS proy, " +
             "MAX(CASE WHEN n.componente='examen_final' THEN n.nota END) AS ef " +
             "FROM inscripciones i " +
             "JOIN estudiantes e ON e.id = i.estudiante_id " +
             "JOIN grupos g ON g.id = i.grupo_id " +
             "JOIN materias m ON m.id = g.materia_id " +
             "LEFT JOIN profesores p ON p.id = g.profesor_id " +
             "LEFT JOIN notas n ON n.inscripcion_id = i.id " +
             "WHERE e.usuario_id = ? AND i.estado = 'activo' " +
             "GROUP BY g.id, m.id, m.codigo, m.nombre, m.creditos, p.nombre, p.apellido, g.aula")) {
        _ps2.setInt(1, est_usuarioId);
        try (ResultSet _rs2 = _ps2.executeQuery()) {
          boolean _first = true;
          int _colorIdx = 0;
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
            int    _creditos = _rs2.getInt("creditos"); // FIX: leer creditos de BD
            int    _grupoId = _rs2.getInt("grupo_id");

            StringBuilder _diasSb = new StringBuilder("{");
            StringBuilder _diasAbrev = new StringBuilder();
            String _horaInicioTexto = "";
            java.util.List<String[]> _bloques = _horariosPorGrupo.get(_grupoId);
            if (_bloques != null) {
              boolean _firstDia = true;
              for (String[] _bloque : _bloques) {
                String _diaEnum = _bloque[0];
                String _horaFmt = _bloque[1];
                String _diaKey  = _diaMap.getOrDefault(_diaEnum, "lun");

                if (!_firstDia) { _diasSb.append(","); _diasAbrev.append("/"); }
                _firstDia = false;
                _diasSb.append("\"").append(_diaKey).append("\":\"").append(_horaFmt).append("\"");
                _diasAbrev.append(_diaKey.substring(0,1).toUpperCase()).append(_diaKey.substring(1));
                if (_horaInicioTexto.isEmpty()) _horaInicioTexto = _horaFmt;
              }
            }
            _diasSb.append("}");
            String _horarioTexto = (_diasAbrev.length() > 0) ? (_diasAbrev + " " + _horaInicioTexto) : "";

            String _color   = _paleta[_colorIdx % _paleta.length][0];
            String _colorBg = _paleta[_colorIdx % _paleta.length][1];
            _colorIdx++;

            est_materiasJsonSb.append("{")
              .append("\"codigo\":\"").append(_codigo).append("\",")
              .append("\"nombre\":\"").append(_mnombre).append("\",")
              .append("\"creditos\":").append(_creditos).append(",") // FIX: valor real de BD
              .append("\"horario\":\"").append(_horarioTexto).append("\",")
              .append("\"docente\":\"").append(_docente).append("\",")
              .append("\"color\":\"").append(_color).append("\",")
              .append("\"colorBg\":\"").append(_colorBg).append("\",")
              .append("\"dias\":").append(_diasSb.toString()).append(",")
              .append("\"aula\":\"").append(_aula).append("\",")
              .append("\"p1\":").append(_np1?0:_p1).append(",")
              .append("\"p2\":").append(_np2?0:_p2).append(",")
              .append("\"proj\":").append(_nproy?0:_proy).append(",")
              .append("\"exFinal\":").append(_nef?0:_ef).append(",")
              .append("\"nota\":").append(_nota)
              .append("}");
          }
        }
      }

      // FIX: agregado m.creditos al SELECT de disponibles
      // EXCLUIR: IS-301 (Ingeniería de Software I) y PS-301 (Pruebas de Software) siempre,
      // cualquier materia con mas de 1 salon (el autoservicio no soporta elegir entre varios;
      // esas se matriculan solo desde el admin al crear al estudiante), y cualquier materia
      // que no pertenezca a la carrera del estudiante (si no tiene carrera asignada, no ve nada).
      try (PreparedStatement _ps3 = _con2.prepareStatement(
             "SELECT g.id AS grupo_id, m.codigo, m.nombre, m.creditos, g.aula, g.capacidad, " +
             "(SELECT COUNT(*) FROM inscripciones i2 WHERE i2.grupo_id = g.id AND i2.estado='activo') AS ocupados " +
             "FROM grupos g JOIN materias m ON m.id = g.materia_id " +
             "WHERE m.codigo NOT IN ('IS-301', 'PS-301') " +
             "AND (SELECT COUNT(*) FROM grupos g3 WHERE g3.materia_id = m.id) = 1 " +
             "AND m.carrera_id = ?")) {
        _ps3.setObject(1, est_carreraId);
        try (ResultSet _rs3 = _ps3.executeQuery()) {
          boolean _firstD = true;
          while (_rs3.next()) {
            String _codigo = _rs3.getString("codigo");
            if (_codigosInscritos.contains(_codigo)) continue;

            int _grupoId    = _rs3.getInt("grupo_id");
            String _mnombre = _rs3.getString("nombre")  != null ? _rs3.getString("nombre").replace('"', ' ')  : "";
            String _aula    = _rs3.getString("aula")    != null ? _rs3.getString("aula").replace('"', ' ')    : "";
            int _capacidad  = _rs3.getInt("capacidad");
            int _ocupados   = _rs3.getInt("ocupados");
            int _creditos   = _rs3.getInt("creditos"); // FIX: leer creditos de BD

            StringBuilder _diasAbrev = new StringBuilder();
            String _horaInicioTexto = "";
            java.util.List<String[]> _bloques = _horariosPorGrupo.get(_grupoId);
            if (_bloques != null) {
              boolean _firstDia = true;
              for (String[] _bloque : _bloques) {
                String _diaEnum = _bloque[0];
                String _horaFmt = _bloque[1];
                String _diaKey  = _diaMap.getOrDefault(_diaEnum, "lun");
                if (!_firstDia) _diasAbrev.append("/");
                _firstDia = false;
                _diasAbrev.append(_diaKey.substring(0,1).toUpperCase()).append(_diaKey.substring(1));
                if (_horaInicioTexto.isEmpty()) _horaInicioTexto = _horaFmt;
              }
            }
            String _horarioTexto = (_diasAbrev.length() > 0) ? (_diasAbrev + " " + _horaInicioTexto) : "";

            if (!_firstD) est_disponiblesJsonSb.append(",");
            _firstD = false;
            est_disponiblesJsonSb.append("{")
              .append("\"codigo\":\"").append(_codigo.replace('"',' ')).append("\",")
              .append("\"nombre\":\"").append(_mnombre).append("\",")
              .append("\"creditos\":").append(_creditos).append(",") // FIX: valor real de BD
              .append("\"horario\":\"").append(_horarioTexto).append("\",")
              .append("\"aula\":\"").append(_aula).append("\",")
              .append("\"cupos\":\"").append(_ocupados).append("/").append(_capacidad).append("\",")
              .append("\"bloqueada\":").append(_gruposBloqueados.contains(_grupoId))
              .append("}");
          }
        }
      }

    } catch (Exception _e2) {
      est_materiasJsonSb = new StringBuilder("[");
      est_disponiblesJsonSb = new StringBuilder("[");
    }
  }
  est_materiasJsonSb.append("]");
  est_disponiblesJsonSb.append("]");
  String est_materiasJson    = est_materiasJsonSb.toString();
  String est_disponiblesJson = est_disponiblesJsonSb.toString();
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
:root {
  --bg: #f4f6fb; --bg2: #eaf0fb; --white: #ffffff; --blue: #1a56a0;
  --blue-mid: #2269c4; --blue-light: #dbeafe; --blue-pale: #eff6ff;
  --green: #15803d; --green-bg: #dcfce7; --red: #b91c1c; --red-bg: #fee2e2;
  --amber: #b45309; --amber-bg: #fef3c7; --purple: #7c3aed; --purple-bg: #f3e8ff;
  --cyan: #0891b2; --cyan-bg: #e0f2fe; --text: #1e2a3b; --text-mid: #3d5068;
  --text-soft: #6b7e96; --border: #c8d8ec; --shadow: 0 2px 12px rgba(26,86,160,0.10);
  --shadow-lg: 0 6px 28px rgba(26,86,160,0.14); --radius: 14px; --radius-sm: 9px;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Nunito', sans-serif; background: var(--bg); color: var(--text); font-size: 16px; min-height: 100vh; }
h1, h2, h3 { font-family: 'Merriweather', serif; }
.hidden { display: none !important; }
.btn { display: inline-flex; align-items: center; justify-content: center; gap: 8px; padding: 13px 26px; border-radius: var(--radius-sm); border: none; font-family: 'Nunito', sans-serif; font-size: 16px; font-weight: 700; cursor: pointer; transition: all 0.2s; text-decoration: none; }
.btn-primary { background: var(--blue); color: #fff; }
.btn-primary:hover { background: var(--blue-mid); box-shadow: var(--shadow); }
.btn-secondary { background: var(--white); color: var(--blue); border: 2px solid var(--blue); }
.btn-secondary:hover { background: var(--blue-pale); }
.btn-sm { padding: 9px 18px; font-size: 14px; }
.btn-full { width: 100%; }
.btn-danger { background: var(--white); color: var(--red); border: 2px solid var(--red); font-size: 13px; padding: 6px 14px; border-radius: 20px; }
.btn-danger:hover { background: var(--red-bg); }
.card { background: var(--white); border: 1.5px solid var(--border); border-radius: var(--radius); padding: 26px; box-shadow: var(--shadow); }
.tag { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 13px; font-weight: 700; }
.tag-green { background: var(--green-bg); color: var(--green); }
.tag-red { background: var(--red-bg); color: var(--red); }
.tag-amber { background: var(--amber-bg); color: var(--amber); }
.tag-blue { background: var(--blue-light); color: var(--blue); }
#page-login { min-height: 100vh; display: flex; align-items: center; justify-content: center; background: linear-gradient(145deg,#dbeafe 0%,#f4f6fb 60%,#e0f2fe 100%); padding: 24px; }
.login-box { background: var(--white); border: 1.5px solid var(--border); border-radius: 20px; box-shadow: var(--shadow-lg); width: 100%; max-width: 420px; padding: 48px 40px; animation: popIn 0.4s ease; }
@keyframes popIn { from { opacity:0; transform:scale(0.96) translateY(10px); } to { opacity:1; transform:scale(1) translateY(0); } }
.login-logo { text-align: center; margin-bottom: 28px; }
.delta-mark { display: inline-flex; align-items: center; justify-content: center; width: 68px; height: 68px; border-radius: 18px; background: var(--blue); color: #fff; font-family: 'Merriweather', serif; font-size: 32px; margin-bottom: 12px; box-shadow: 0 4px 16px rgba(26,86,160,0.3); }
.login-logo h1 { font-size: 22px; color: var(--blue); }
.login-logo p { font-size: 14px; color: var(--text-soft); margin-top: 4px; }
.login-role-banner { background: var(--blue-pale); border: 1.5px solid var(--blue-light); border-radius: var(--radius-sm); padding: 14px 16px; margin-bottom: 24px; display: flex; align-items: center; gap: 12px; font-size: 16px; font-weight: 700; color: var(--blue); }
.form-group { margin-bottom: 18px; }
.form-group label { display: block; font-size: 15px; font-weight: 700; color: var(--text-mid); margin-bottom: 7px; }
.form-group input { width: 100%; padding: 13px 16px; border: 2px solid var(--border); border-radius: var(--radius-sm); font-family: 'Nunito', sans-serif; font-size: 16px; color: var(--text); background: var(--bg); transition: border-color 0.2s; }
.form-group input:focus { outline: none; border-color: var(--blue); background: #fff; }
.password-wrap { position: relative; }
.password-wrap input { padding-right: 46px; }
.password-toggle { position: absolute; right: 6px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; font-size: 18px; color: var(--text-soft); padding: 6px 8px; line-height: 1; }
.password-toggle:hover { color: var(--blue); }
.login-error { background: var(--red-bg); color: var(--red); padding: 12px 16px; border-radius: var(--radius-sm); font-size: 14px; font-weight: 600; margin-bottom: 16px; border: 1px solid #fca5a5; display: none; }
.login-hint { text-align: center; margin-top: 16px; font-size: 13px; color: var(--text-soft); background: var(--bg2); padding: 11px; border-radius: var(--radius-sm); }
.login-hint strong { color: var(--blue); }
.login-switch { text-align: center; margin-top: 14px; font-size: 13px; color: var(--text-soft); }
.login-switch a { color: var(--blue); font-weight: 700; text-decoration: none; }
.portal { display: flex; min-height: 100vh; }
.sidebar { width: 270px; flex-shrink: 0; background: var(--white); border-right: 2px solid var(--border); display: flex; flex-direction: column; position: fixed; top: 0; left: 0; bottom: 0; z-index: 100; overflow-y: auto; box-shadow: 3px 0 16px rgba(26,86,160,0.07); }
.sidebar-header { padding: 24px 22px 18px; border-bottom: 2px solid var(--border); background: var(--blue); }
.sidebar-logo { display: flex; align-items: center; gap: 12px; }
.logo-mark { width: 46px; height: 46px; border-radius: 12px; background: rgba(255,255,255,0.2); display: flex; align-items: center; justify-content: center; font-family: 'Merriweather', serif; font-size: 22px; color: #fff; border: 2px solid rgba(255,255,255,0.3); }
.logo-name { font-family: 'Merriweather', serif; font-size: 20px; color: #fff; }
.logo-sub { font-size: 11px; color: rgba(255,255,255,0.7); text-transform: uppercase; letter-spacing: 1.5px; }
.sidebar-user { margin: 16px 16px 0; background: var(--blue-pale); border: 1.5px solid var(--blue-light); border-radius: var(--radius-sm); padding: 14px; display: flex; align-items: center; gap: 12px; }
.user-avatar { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-family: 'Merriweather', serif; font-size: 20px; background: var(--blue); color: #fff; flex-shrink: 0; }
.user-name { font-size: 15px; font-weight: 800; color: var(--text); }
.user-id { font-size: 12px; color: var(--text-soft); margin-top: 2px; }
.user-role-tag { display: inline-block; margin-top: 4px; background: var(--blue); color: #fff; font-size: 11px; font-weight: 700; padding: 2px 9px; border-radius: 20px; }
.nav-section { padding: 16px 12px 8px; }
.nav-label { font-size: 11px; text-transform: uppercase; letter-spacing: 2px; color: var(--text-soft); padding: 4px 10px 10px; font-weight: 700; }
.nav-item { display: flex; align-items: center; gap: 12px; padding: 13px 14px; border-radius: var(--radius-sm); cursor: pointer; font-size: 16px; font-weight: 600; color: var(--text-mid); transition: all 0.18s; margin-bottom: 3px; text-decoration: none; border: none; background: none; width: 100%; text-align: left; font-family: 'Nunito', sans-serif; }
.nav-item:hover { background: var(--blue-pale); color: var(--blue); }
.nav-item.active { background: var(--blue-light); color: var(--blue); }
.nav-icon { font-size: 20px; width: 26px; text-align: center; flex-shrink: 0; }
.nav-badge { margin-left: auto; background: var(--blue); color: #fff; font-size: 12px; font-weight: 800; padding: 2px 8px; border-radius: 20px; }
.sidebar-footer { margin-top: auto; padding: 16px 14px; border-top: 2px solid var(--border); }
.logout-btn { display: flex; align-items: center; gap: 10px; padding: 12px 14px; border-radius: var(--radius-sm); font-size: 15px; font-weight: 700; color: var(--red); cursor: pointer; background: var(--red-bg); border: 1.5px solid #fca5a5; width: 100%; font-family: 'Nunito', sans-serif; transition: all 0.18s; }
.logout-btn:hover { background: #fecaca; }
.main-content { margin-left: 270px; flex: 1; padding: 32px 36px; min-height: 100vh; }
.topbar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 30px; padding-bottom: 24px; border-bottom: 2px solid var(--border); }
.page-title { font-size: 28px; color: var(--text); }
.page-subtitle { font-size: 15px; color: var(--text-soft); margin-top: 4px; font-family: 'Nunito', sans-serif; }
.topbar-right { display: flex; align-items: center; gap: 12px; }
.notif-btn { width: 46px; height: 46px; border-radius: 10px; background: var(--white); border: 2px solid var(--border); display: flex; align-items: center; justify-content: center; font-size: 20px; cursor: pointer; transition: all 0.18s; position: relative; }
.notif-btn:hover { border-color: var(--blue); background: var(--blue-pale); }
.notif-dot { position: absolute; top: 8px; right: 8px; width: 9px; height: 9px; background: var(--red); border-radius: 50%; border: 2px solid #fff; }
.notif-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.18); z-index: 499; }
.notif-panel { position: fixed; top: 0; right: 0; width: 370px; height: 100vh; background: var(--white); border-left: 2px solid var(--border); box-shadow: -6px 0 28px rgba(26,86,160,0.14); z-index: 500; display: flex; flex-direction: column; transition: transform 0.3s ease; }
.notif-panel.notif-cerrado { transform: translateX(100%); }
.notif-panel-header { padding: 20px 20px 16px; border-bottom: 2px solid var(--border); display: flex; align-items: center; justify-content: space-between; background: var(--blue); }
.notif-panel-titulo { font-family: 'Merriweather', serif; font-size: 17px; color: #fff; }
.notif-cerrar-btn { width: 34px; height: 34px; border-radius: 8px; background: rgba(255,255,255,0.2); border: none; color: #fff; font-size: 18px; cursor: pointer; display: flex; align-items: center; justify-content: center; font-family: 'Nunito', sans-serif; }
.notif-panel-body { flex: 1; overflow-y: auto; padding: 14px; }
.notif-card { display: flex; gap: 12px; padding: 14px; border-radius: var(--radius-sm); margin-bottom: 8px; border: 1.5px solid var(--border); }
.notif-card.ncard-unread { background: var(--blue-pale); border-color: #93c5fd; }
.notif-card.ncard-read { background: var(--bg2); opacity: 0.8; }
.notif-card-icon { width: 40px; height: 40px; border-radius: 10px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; font-size: 19px; }
.notif-card-titulo { font-size: 14px; font-weight: 800; color: var(--text); }
.notif-card-cuerpo { font-size: 13px; color: var(--text-soft); margin-top: 3px; line-height: 1.4; }
.notif-card-hora { font-size: 12px; color: var(--blue); font-weight: 700; margin-top: 5px; }
.btn-visto { margin-top: 8px; padding: 5px 16px; border-radius: 20px; border: none; background: var(--blue); color: #fff; font-size: 12px; font-weight: 700; cursor: pointer; font-family: 'Nunito', sans-serif; transition: background 0.15s; }
.btn-visto:hover { background: var(--blue-mid); }
.btn-visto.visto-ok { background: var(--green); cursor: default; }
.tab-panel { display: none; animation: fadeIn 0.3s ease; }
.tab-panel.active { display: block; }
@keyframes fadeIn { from { opacity:0; transform:translateY(8px); } to { opacity:1; transform:translateY(0); } }
.stats-row { display: grid; gap: 18px; margin-bottom: 26px; }
.stats-4 { grid-template-columns: repeat(4, 1fr); }
.stats-3 { grid-template-columns: repeat(3, 1fr); }
.stat-card { background: var(--white); border: 1.5px solid var(--border); border-radius: var(--radius); padding: 22px 20px; box-shadow: var(--shadow); display: flex; align-items: center; gap: 16px; transition: transform 0.18s, box-shadow 0.18s; }
.stat-card:hover { transform: translateY(-2px); box-shadow: var(--shadow-lg); }
.stat-icon-box { width: 56px; height: 56px; border-radius: 14px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; font-size: 26px; }
.icon-blue { background: var(--blue-light); } .icon-green { background: var(--green-bg); }
.icon-amber { background: var(--amber-bg); } .icon-red { background: var(--red-bg); }
.stat-label { font-size: 13px; color: var(--text-soft); font-weight: 600; text-transform: uppercase; letter-spacing: 0.8px; }
.stat-value { font-family: 'Merriweather', serif; font-size: 30px; color: var(--text); line-height: 1.1; margin: 4px 0; }
.stat-sub { font-size: 13px; color: var(--text-soft); }
.grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 22px; margin-bottom: 22px; }
.grid-21 { display: grid; grid-template-columns: 2fr 1fr; gap: 22px; margin-bottom: 22px; }
.card-title { font-family: 'Merriweather', serif; font-size: 18px; color: var(--text); margin-bottom: 18px; display: flex; align-items: center; justify-content: space-between; }
.card-link { font-family: 'Nunito', sans-serif; font-size: 13px; color: var(--blue); font-weight: 700; text-decoration: none; cursor: pointer; background: none; border: none; }
.card-link:hover { text-decoration: underline; }
.sched-item { display: flex; gap: 14px; padding: 14px 0; border-bottom: 1.5px solid var(--bg2); align-items: flex-start; }
.sched-item:last-child { border-bottom: none; }
.sched-time { font-size: 13px; color: var(--text-soft); font-weight: 700; min-width: 60px; padding-top: 2px; }
.sched-bar { width: 4px; min-height: 44px; border-radius: 4px; flex-shrink: 0; margin-top: 2px; }
.sched-subject { font-size: 16px; font-weight: 800; color: var(--text); }
.sched-prof { font-size: 14px; color: var(--text-soft); margin-top: 3px; }
.sched-room { display: inline-block; margin-top: 6px; font-size: 13px; font-weight: 700; background: var(--bg2); color: var(--text-mid); padding: 3px 10px; border-radius: 6px; }
.delta-table { width: 100%; border-collapse: collapse; }
.delta-table th { font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.8px; color: var(--text-soft); padding: 10px 14px; text-align: left; background: var(--bg2); border-bottom: 2px solid var(--border); }
.delta-table td { padding: 12px 14px; font-size: 15px; border-bottom: 1.5px solid var(--bg2); vertical-align: middle; color: var(--text); }
.delta-table tr:last-child td { border-bottom: none; }
.delta-table tr:hover td { background: var(--blue-pale); }
.prog-wrap { background: var(--bg2); border-radius: 10px; height: 8px; width: 90px; overflow: hidden; }
.prog-fill { height: 100%; border-radius: 10px; }
.msg-item { display: flex; gap: 14px; padding: 14px 10px; border-bottom: 1.5px solid var(--bg2); cursor: pointer; transition: background 0.15s; border-radius: var(--radius-sm); margin-left: -10px; }
.msg-item:hover { background: var(--blue-pale); }
.msg-item:last-child { border-bottom: none; }
.msg-av { width: 42px; height: 42px; border-radius: 12px; background: var(--blue-light); display: flex; align-items: center; justify-content: center; font-size: 20px; flex-shrink: 0; border: 1.5px solid var(--border); }
.msg-from { font-size: 15px; font-weight: 800; }
.msg-from.leido { font-weight: 600; color: var(--text-soft); }
.msg-preview { font-size: 14px; color: var(--text-soft); margin-top: 3px; }
.msg-time { font-size: 13px; color: var(--text-soft); white-space: nowrap; }
.msg-dot-unread { width: 9px; height: 9px; background: var(--blue); border-radius: 50%; margin-top: 5px; flex-shrink: 0; }
.ann-item { border-left: 4px solid var(--blue); background: var(--blue-pale); border-radius: 0 var(--radius-sm) var(--radius-sm) 0; padding: 14px 16px; margin-bottom: 12px; }
.ann-item:last-child { margin-bottom: 0; }
.ann-item.ann-green { border-color: var(--green); background: var(--green-bg); }
.ann-item.ann-amber { border-color: var(--amber); background: var(--amber-bg); }
.ann-titulo { font-size: 15px; font-weight: 800; color: var(--text); }
.ann-cuerpo { font-size: 14px; color: var(--text-mid); margin-top: 4px; line-height: 1.5; }
.ann-fecha { font-size: 12px; font-weight: 700; color: var(--blue); margin-top: 6px; }
.compose-wrap { border: 2px solid var(--border); border-radius: var(--radius-sm); overflow: hidden; }
.compose-input { width: 100%; padding: 13px 16px; border: none; border-bottom: 1.5px solid var(--border); font-family: 'Nunito', sans-serif; font-size: 16px; color: var(--text); background: var(--bg); }
.compose-input::placeholder { color: var(--text-soft); }
.compose-input:focus { outline: none; background: #fff; }
.compose-textarea { width: 100%; padding: 14px 16px; border: none; font-family: 'Nunito', sans-serif; font-size: 15px; color: var(--text); background: var(--bg); min-height: 100px; resize: vertical; }
.compose-textarea::placeholder { color: var(--text-soft); }
.compose-textarea:focus { outline: none; background: #fff; }
.compose-footer { padding: 12px 16px; background: var(--bg2); display: flex; justify-content: flex-end; gap: 10px; }
.horario-cell-clase { padding: 8px; border-radius: 8px; font-size: 14px; font-weight: 700; }
.toast-container { position: fixed; top: 24px; right: 24px; z-index: 9999; display: flex; flex-direction: column; gap: 12px; max-width: 380px; pointer-events: none; }
.toast { display: flex; align-items: flex-start; gap: 12px; padding: 16px 18px; border-radius: 12px; background: #fff; box-shadow: 0 8px 32px rgba(0,0,0,.15), 0 2px 8px rgba(0,0,0,.08); border-left: 5px solid var(--blue); font-size: 14px; color: var(--text); animation: toast-in 0.3s cubic-bezier(.34,1.56,.64,1); line-height: 1.5; pointer-events: all; position: relative; overflow: hidden; min-width: 280px; }
.toast.toast-success { border-left-color: var(--green); } .toast.toast-error { border-left-color: var(--red); }
.toast.toast-warning { border-left-color: var(--amber); } .toast.toast-info { border-left-color: var(--blue); }
.toast-icon-box { width: 36px; height: 36px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 18px; flex-shrink: 0; }
.toast-success .toast-icon-box { background: var(--green-bg); } .toast-error .toast-icon-box { background: var(--red-bg); }
.toast-warning .toast-icon-box { background: var(--amber-bg); } .toast-info .toast-icon-box { background: var(--blue-light); }
.toast-content { flex: 1; min-width: 0; }
.toast-title { font-weight: 800; font-size: 14px; margin-bottom: 2px; }
.toast-success .toast-title { color: var(--green); } .toast-error .toast-title { color: var(--red); }
.toast-warning .toast-title { color: var(--amber); } .toast-info .toast-title { color: var(--blue); }
.toast-msg { font-size: 13px; color: var(--text-mid); white-space: pre-line; line-height: 1.4; }
.toast-close { cursor: pointer; color: var(--text-soft); font-size: 18px; line-height: 1; flex-shrink: 0; background: none; border: none; padding: 0 0 0 4px; margin-top: -2px; }
.toast-close:hover { color: var(--text); }
.toast-progress { position: absolute; bottom: 0; left: 0; height: 3px; }
.toast-success .toast-progress { background: var(--green); } .toast-error .toast-progress { background: var(--red); }
.toast-warning .toast-progress { background: var(--amber); } .toast-info .toast-progress { background: var(--blue); }
.toast.toast-out { animation: toast-out 0.25s ease-in forwards; }
@keyframes toast-in { from { opacity: 0; transform: translateX(40px) scale(0.95); } to { opacity: 1; transform: translateX(0) scale(1); } }
@keyframes toast-out { from { opacity: 1; transform: translateX(0); } to { opacity: 0; transform: translateX(40px); } }
.modal-overlay { position: fixed; inset: 0; background: rgba(30,42,59,.45); z-index: 10000; display: flex; align-items: center; justify-content: center; padding: 20px; animation: modal-fade-in 0.15s ease-out; }
.modal-overlay.hidden { display: none; }
.modal-box { background: #fff; border-radius: var(--radius-sm); max-width: 420px; width: 100%; padding: 24px; box-shadow: 0 12px 40px rgba(0,0,0,.2); }
.modal-box p { font-size: 15px; color: var(--text); line-height: 1.5; margin-bottom: 20px; white-space: pre-line; }
.modal-actions { display: flex; justify-content: flex-end; gap: 10px; }
@keyframes modal-fade-in { from { opacity: 0; } to { opacity: 1; } }
@media(max-width: 1100px) { .stats-4 { grid-template-columns: 1fr 1fr; } .grid-2, .grid-21 { grid-template-columns: 1fr; } }
@media(max-width: 760px) { .sidebar { width: 220px; } .main-content { margin-left: 220px; padding: 20px; } .stats-4, .stats-3 { grid-template-columns: 1fr 1fr; } }
</style>
</head>
<body>
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

<!-- LOGIN -->
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
      <div class="password-wrap">
        <input id="loginPass" type="password" placeholder="&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;" autocomplete="current-password">
        <button type="button" class="password-toggle" id="togglePass" onclick="togglePasswordVisibility()" aria-label="Mostrar contrasena">&#128065;</button>
      </div>
    </div>
    <div class="login-error" id="loginError" style="display:none;">Usuario o contrasena incorrecto.</div>
    <% if (est_loginError) { %>
    <script>window.addEventListener('DOMContentLoaded',function(){ showToast('Usuario o contrasena incorrecto.','error'); });</script>
    <% } %>
    <button class="btn btn-primary btn-full" onclick="doLogin()">Ingresar al Portal</button>
    <div class="login-hint">Demo: usuario <strong>estudiante</strong> &middot; clave <strong>1234</strong></div>
    <div class="login-switch">Es docente? <a href="index.jsp">Ir al Portal Docente &#8594;</a></div>
  </div>
</div>

<!-- NOTIFICACIONES -->
<div id="notifOverlay" class="notif-overlay hidden" onclick="cerrarNotifPanel()"></div>
<div id="notifPanel" class="notif-panel notif-cerrado">
  <div class="notif-panel-header">
    <span class="notif-panel-titulo">Notificaciones</span>
    <button class="notif-cerrar-btn" onclick="cerrarNotifPanel()">X</button>
  </div>
  <div class="notif-panel-body" id="notifPanelBody"></div>
</div>

<!-- PORTAL -->
<div id="page-portal" class="portal hidden">
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
      <button class="nav-item active" id="nav-inicio" onclick="irTab('inicio', this)"><span class="nav-icon">&#127968;</span> Inicio</button>
      <button class="nav-item" id="nav-inscripcion" onclick="irTab('inscripcion', this)"><span class="nav-icon">&#128203;</span> Inscripcion</button>
      <button class="nav-item" id="nav-calificaciones" onclick="irTab('calificaciones', this)"><span class="nav-icon">&#128202;</span> Calificaciones</button>
      <button class="nav-item" id="nav-horario" onclick="irTab('horario', this)"><span class="nav-icon">&#128197;</span> Horario</button>
      <div class="nav-label">Comunicacion</div>
      <button class="nav-item" id="nav-mensajes" onclick="irTab('mensajes', this)">
        <span class="nav-icon">&#9993;</span> Mensajes
        <span class="nav-badge" id="badgeMsgNav" style="display:none;">0</span>
      </button>
      <button class="nav-item" id="nav-avisos" onclick="irTab('avisos', this)">
        <span class="nav-icon">&#128226;</span> Avisos
        <span class="nav-badge" id="badgeAvisosNav" style="display:none;">0</span>
      </button>
    </nav>
    <div class="sidebar-footer">
      <button class="logout-btn" onclick="cerrarSesion()">&#128682; Cerrar Sesion</button>
    </div>
  </aside>

  <main class="main-content">
    <!-- INICIO -->
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
      <div class="stats-row stats-4">
        <div class="stat-card"><div class="stat-icon-box icon-blue">&#128218;</div><div><div class="stat-label">Materias</div><div class="stat-value" id="statMaterias">0</div><div class="stat-sub">I Semestre 2026</div></div></div>
        <div class="stat-card"><div class="stat-icon-box icon-green">&#11088;</div><div><div class="stat-label">Promedio</div><div class="stat-value" id="statPromedio">-</div><div class="stat-sub" id="statPromedioSub">Sin notas</div></div></div>
        <div class="stat-card"><div class="stat-icon-box icon-amber">&#127885;</div><div><div class="stat-label">Creditos</div><div class="stat-value" id="statCreditos">0</div><div class="stat-sub">de 180 requeridos</div></div></div>
        <div class="stat-card"><div class="stat-icon-box icon-red">&#128197;</div><div><div class="stat-label">Prox. Examen</div><div class="stat-value" style="font-size:22px">Jun 3</div><div class="stat-sub">Calidad del SW</div></div></div>
      </div>
      <div class="grid-2">
        <div class="card">
          <div class="card-title">Horario de Hoy <button class="card-link" onclick="irTab('horario', document.getElementById('nav-horario'))">Ver semana &#8594;</button></div>
          <div id="fechaHoy" style="font-size:13px;font-weight:700;color:var(--blue);margin-bottom:12px;text-transform:uppercase;letter-spacing:1px;"></div>
          <div id="horarioHoy"></div>
        </div>
        <div class="card">
          <div class="card-title">Mis Calificaciones <button class="card-link" onclick="irTab('calificaciones', document.getElementById('nav-calificaciones'))">Ver todas &#8594;</button></div>
          <table class="delta-table"><thead><tr><th>Materia</th><th>Nota</th><th>Progreso</th></tr></thead><tbody id="calResumen"></tbody></table>
        </div>
      </div>
      <div class="grid-2">
        <div class="card">
          <div class="card-title">Mensajes recientes <button class="card-link" onclick="irTab('mensajes', document.getElementById('nav-mensajes'))">Ver bandeja &#8594;</button></div>
          <div id="mensajesResumen"></div>
        </div>
        <div class="card">
          <div class="card-title">Avisos Institucionales <button class="card-link" onclick="irTab('avisos', document.getElementById('nav-avisos'))">Ver todos &#8594;</button></div>
          <div id="avisosResumen"><div style="color:var(--text-soft);font-size:14px;padding:12px 0;">Cargando avisos...</div></div>
        </div>
      </div>
    </div>

    <!-- INSCRIPCION -->
    <div id="tab-inscripcion" class="tab-panel">
      <div class="topbar"><div><h2 class="page-title">Inscripcion de Materias</h2><div class="page-subtitle">I Semestre 2026 &middot; Materias disponibles</div></div></div>
      <div class="stats-row stats-3">
        <div class="stat-card"><div class="stat-icon-box icon-blue">&#128218;</div><div><div class="stat-label">Inscritas</div><div class="stat-value" id="inscCant">0</div><div class="stat-sub">de 6 permitidas</div></div></div>
        <div class="stat-card"><div class="stat-icon-box icon-green">&#9989;</div><div><div class="stat-label">Creditos Activos</div><div class="stat-value" id="inscCred">0</div><div class="stat-sub">creditos</div></div></div>
        <div class="stat-card"><div class="stat-icon-box icon-amber">&#9200;</div><div><div class="stat-label">Cierre Matricula</div><div class="stat-value" style="font-size:20px">Jun 6</div><div class="stat-sub">Plazo limite</div></div></div>
      </div>
      <div class="card" style="margin-bottom:22px;" id="cardSolicitudesPendientes">
        <div class="card-title">Solicitudes Pendientes de Aprobacion</div>
        <div style="overflow-x:auto;"><table class="delta-table"><thead><tr><th>Tipo</th><th>Materia</th><th>Codigo</th><th>Estado</th><th>Fecha</th></tr></thead><tbody id="tablaSolicitudes"></tbody></table></div>
      </div>
      <div class="card" style="margin-bottom:22px;">
        <div class="card-title">Materias Actualmente Inscritas</div>
        <div style="overflow-x:auto;"><table class="delta-table"><thead><tr><th>Codigo</th><th>Materia</th><th>Creditos</th><th>Horario</th><th>Docente</th><th>Estado</th><th>Accion</th></tr></thead><tbody id="tablaInscritas"></tbody></table></div>
      </div>
      <div class="card">
        <div class="card-title">Materias Disponibles para Agregar</div>
        <div style="overflow-x:auto;"><table class="delta-table"><thead><tr><th>Codigo</th><th>Materia</th><th>Creditos</th><th>Cupos</th><th>Horario</th><th>Accion</th></tr></thead><tbody id="tablaDisponibles"></tbody></table></div>
      </div>
    </div>

    <!-- CALIFICACIONES -->
    <div id="tab-calificaciones" class="tab-panel">
      <div class="topbar">
        <div><h2 class="page-title">Mis Calificaciones</h2><div class="page-subtitle">I Semestre 2026 &middot; Historial academico</div></div>
        <button class="btn btn-secondary" onclick="showToast('Descargando reporte PDF...', 'info')">Descargar PDF</button>
      </div>
      <div class="stats-row stats-3">
        <div class="stat-card"><div class="stat-icon-box icon-green">&#11088;</div><div><div class="stat-label">Promedio General</div><div class="stat-value" id="calProm">-</div><div class="stat-sub">-</div></div></div>
        <div class="stat-card"><div class="stat-icon-box icon-green">&#9989;</div><div><div class="stat-label">Materias Aprobadas</div><div class="stat-value" id="calAprobadas">0</div><div class="stat-sub" id="calAprobSub">de 0 activas</div></div></div>
        <div class="stat-card"><div class="stat-icon-box icon-blue">&#127885;</div><div><div class="stat-label">Mejor Nota</div><div class="stat-value" id="calMejor">-</div><div class="stat-sub" id="calMejorSub">-</div></div></div>
      </div>
      <div class="card">
        <div class="card-title">Detalle de Calificaciones por Materia</div>
        <div style="overflow-x:auto;"><table class="delta-table"><thead><tr><th>Materia</th><th>Parcial 1</th><th>Parcial 2</th><th>Proyecto</th><th>Final</th><th>Nota Final</th><th>Estado</th></tr></thead><tbody id="calDetalle"></tbody></table></div>
      </div>
    </div>

    <!-- HORARIO -->
    <div id="tab-horario" class="tab-panel">
      <div class="topbar"><div><h2 class="page-title">Mi Horario Semanal</h2><div class="page-subtitle">I Semestre 2026</div></div></div>
      <div class="card">
        <div class="card-title">Horario Semanal - 2026</div>
        <div style="overflow-x:auto;"><table class="delta-table" style="min-width:700px;"><thead><tr><th style="width:100px;">Hora</th><th>Lunes</th><th>Martes</th><th>Miercoles</th><th>Jueves</th><th>Viernes</th></tr></thead><tbody id="tablaHorario"></tbody></table></div>
      </div>
    </div>

    <!-- MENSAJES -->
    <div id="tab-mensajes" class="tab-panel">
      <div class="topbar"><div><h2 class="page-title">Mensajes</h2><div class="page-subtitle">Comunicacion con docentes y administracion</div></div></div>
      <div style="display:flex;gap:10px;margin-bottom:18px;">
        <button id="btnBandeja" class="btn btn-primary btn-sm" onclick="mostrarBandeja()">📥 Recibidos <span id="badgeInbox" class="nav-badge" style="display:none;margin-left:4px;">0</span></button>
        <button id="btnEnviados" class="btn btn-secondary btn-sm" onclick="mostrarEnviados()">📤 Enviados</button>
      </div>
      <div class="grid-21">
        <div class="card">
          <div id="panelBandeja"><div class="card-title">Bandeja de Entrada</div><div id="bandeja"></div></div>
          <div id="panelEnviados" style="display:none;"><div class="card-title">Mensajes Enviados</div><div id="enviados"></div></div>
        </div>
        <div class="card">
          <div class="card-title">Nuevo Mensaje</div>
          <div class="compose-wrap">
            <datalist id="docentesOpciones"><option value="María Mosquera"></datalist>
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
    </div>

    <!-- AVISOS -->
    <div id="tab-avisos" class="tab-panel">
      <div class="topbar"><div><h2 class="page-title">Avisos Institucionales</h2><div class="page-subtitle">Comunicados oficiales de la universidad</div></div></div>
      <div class="card" id="avisosLista"><div style="color:var(--text-soft);font-size:14px;padding:12px 0;">Cargando avisos...</div></div>
    </div>
  </main>
</div>

<script type="application/json" id="est-materias-json"><%= est_materiasJson %></script>
<script type="application/json" id="est-disponibles-json"><%= est_disponiblesJson %></script>
<script type="text/javascript">
function showToast(mensaje, tipo) {
  tipo = tipo || 'info';
  var config = { success:{titulo:'Exito',icono:'✅',duracion:4000}, error:{titulo:'Error',icono:'❌',duracion:6000}, warning:{titulo:'Advertencia',icono:'⚠️',duracion:5000}, info:{titulo:'Informacion',icono:'ℹ️',duracion:4000} };
  var cfg = config[tipo] || config.info;
  var container = document.getElementById('toastContainer');
  if (!container) { window.alert(mensaje); return; }
  var toast = document.createElement('div');
  toast.className = 'toast toast-' + tipo;
  toast.innerHTML = '<div class="toast-icon-box">' + cfg.icono + '</div><div class="toast-content"><div class="toast-title">' + cfg.titulo + '</div><div class="toast-msg"></div></div><button class="toast-close">&times;</button><div class="toast-progress" style="width:100%;"></div>';
  toast.querySelector('.toast-msg').textContent = mensaje;
  var quitar = function() { if (toast._removed) return; toast._removed = true; toast.classList.add('toast-out'); setTimeout(function(){ if (toast.parentNode) toast.parentNode.removeChild(toast); }, 250); };
  toast.querySelector('.toast-close').addEventListener('click', quitar);
  container.appendChild(toast);
  var bar = toast.querySelector('.toast-progress');
  bar.style.transition = 'width ' + cfg.duracion + 'ms linear';
  requestAnimationFrame(function(){ requestAnimationFrame(function(){ bar.style.width = '0%'; }); });
  var timer = setTimeout(quitar, cfg.duracion);
  toast.addEventListener('mouseenter', function(){ clearTimeout(timer); bar.style.transition = 'none'; });
  toast.addEventListener('mouseleave', function(){ var remaining = parseFloat(bar.style.width) / 100 * cfg.duracion; bar.style.transition = 'width ' + remaining + 'ms linear'; bar.style.width = '0%'; timer = setTimeout(quitar, remaining); });
}

function showConfirm(mensaje, onConfirm) {
  var overlay = document.getElementById('confirmOverlay');
  var msgEl = document.getElementById('confirmMsg');
  var okBtn = document.getElementById('confirmOkBtn');
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
  var msgEl = document.getElementById('infoModalMsg');
  var closeBtn = document.getElementById('infoModalCloseBtn');
  if (!overlay) { window.alert(titulo + '\n\n' + mensaje); return; }
  titleEl.textContent = titulo;
  msgEl.textContent = mensaje;
  overlay.classList.remove('hidden');
  closeBtn.onclick = function(){ overlay.classList.add('hidden'); };
}

var _todosBD = [];
var _dispBD  = [];
try { var _jsonTag = document.getElementById('est-materias-json'); var _jsonBD = _jsonTag ? _jsonTag.textContent : '[]'; if (_jsonBD && _jsonBD.trim() !== '[]') _todosBD = JSON.parse(_jsonBD); } catch(e) {}
try { var _jsonTagD = document.getElementById('est-disponibles-json'); var _jsonDisp = _jsonTagD ? _jsonTagD.textContent : '[]'; if (_jsonDisp && _jsonDisp.trim() !== '[]') _dispBD = JSON.parse(_jsonDisp); } catch(e) {}

function enriquecerMateria(m) {
  return {
    codigo:   m.codigo   || '',
    nombre:   m.nombre   || '',
    creditos: (m.creditos != null && m.creditos !== undefined) ? m.creditos : 3,
    horario:  m.horario  || '',
    color:    m.color    || '#1a56a0',
    colorBg:  m.colorBg  || '#eff6ff',
    dias:     (m.dias && Object.keys(m.dias).length) ? m.dias : {},
    aula:     m.aula     || '',
    docente:  m.docente  || 'Por asignar',
    cupos:    m.cupos    || '30/30',
    bloqueada: !!m.bloqueada,
    p1:       m.p1   || 0,
    p2:       m.p2   || 0,
    proj:     m.proj || 0,
    exFinal:  m.exFinal || m.ef || 0,
    nota:     m.nota || 0
  };
}

var materiasInscritas = [];
var solicitudesPendientes = [];
var materiasDisponibles = [];

if (_todosBD.length || _dispBD.length) {
  _todosBD.forEach(function(m){ materiasInscritas.push(enriquecerMateria(m)); });
  _dispBD.forEach(function(m){ materiasDisponibles.push(enriquecerMateria(m)); });
} else {
  materiasInscritas = [enriquecerMateria({codigo:'IS-401',nombre:'Calidad del Software',creditos:3,docente:'Mosquera, M.',p1:90,p2:88,proj:95,exFinal:94,nota:92})];
  materiasDisponibles = [
    enriquecerMateria({codigo:'IA-401',nombre:'Inteligencia Artificial',creditos:3}),
    enriquecerMateria({codigo:'EC-301',nombre:'Etica Computacional',creditos:4})
  ];
}

var horasSlots = ["7:00 AM","9:00 AM","11:00 AM","1:00 PM","3:00 PM"];
var diasKeys   = ["lun","mar","mie","jue","vie"];

function irTab(id, boton) {
  var paneles = document.querySelectorAll('.tab-panel');
  for (var i = 0; i < paneles.length; i++) paneles[i].classList.remove('active');
  var navItems = document.querySelectorAll('.nav-item');
  for (var i = 0; i < navItems.length; i++) navItems[i].classList.remove('active');
  document.getElementById('tab-' + id).classList.add('active');
  if (boton) { boton.classList.add('active'); } else { var nb = document.getElementById('nav-' + id); if (nb) nb.classList.add('active'); }
  if (id === 'avisos') marcarAvisosVistos();
  window.scrollTo(0, 0);
}

function togglePasswordVisibility() {
  var input = document.getElementById('loginPass');
  var btn = document.getElementById('togglePass');
  if (input.type === 'password') { input.type = 'text'; btn.innerHTML = '&#128064;'; btn.title = 'Ocultar contrasena'; }
  else { input.type = 'password'; btn.innerHTML = '&#128065;'; btn.title = 'Mostrar contrasena'; }
}

function doLogin() {
  var user = document.getElementById('loginUser').value.trim();
  var pass = document.getElementById('loginPass').value.trim();
  var err = document.getElementById('loginError');
  if (!user || !pass) { err.style.display='block'; setTimeout(function(){err.style.display='none';},3500); return; }
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  var form = document.createElement('form');
  form.method = 'POST'; form.action = ctx + '/login';
  var fields = {username: user, password: pass, destino: 'estudiante'};
  Object.keys(fields).forEach(function(k){ var inp = document.createElement('input'); inp.type='hidden'; inp.name=k; inp.value=fields[k]; form.appendChild(inp); });
  document.body.appendChild(form); form.submit();
}

document.getElementById('loginPass').addEventListener('keydown', function(e){ if (e.key === 'Enter') doLogin(); });

function cerrarSesion() {
  showConfirm('Desea cerrar sesion?', function() {
    var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
    fetch(ctx + '/logout', {method:'GET', redirect:'follow'}).catch(function(){}).finally(function(){ window.location.href = ctx + '/index.jsp'; });
    setTimeout(function(){ window.location.href = ctx + '/index.jsp'; }, 300);
  });
}

function iniciarPortal() {
  renderInscritas(); renderDisponibles(); renderCalResumen(); renderCalDetalle();
  renderHorario(); renderHorarioHoy(); renderFechaHoy(); renderBandeja();
  renderMensajesResumen(); actualizarBadges(); actualizarBadgeAvisos();
  actualizarContadoresInscripcion(); cargarAvisos(); cargarSolicitudesPendientes();
}

function abrirNotifPanel() { document.getElementById('notifOverlay').classList.remove('hidden'); document.getElementById('notifPanel').classList.remove('notif-cerrado'); renderNotifPanel(); }
function cerrarNotifPanel() { document.getElementById('notifOverlay').classList.add('hidden'); document.getElementById('notifPanel').classList.add('notif-cerrado'); }

function renderNotifPanel() {
  var body = document.getElementById('notifPanelBody');
  body.innerHTML = '<div style="text-align:center;padding:20px;color:#6b7e96;">Cargando...</div>';
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/mensajes?accion=bandeja')
    .then(function(r){ return r.json(); })
    .then(function(msgs){
      body.innerHTML = '';
      var noLeidos = msgs.filter(function(m){ return !m.leido; }).length;
      if (msgs.length === 0) { body.innerHTML = '<div style="text-align:center;padding:20px;color:#6b7e96;">Sin notificaciones.</div>'; }
      else {
        msgs.forEach(function(msg) {
          var initials = msg.remitente ? msg.remitente.split(' ').map(function(p){return p[0];}).join('').substring(0,2).toUpperCase() : '??';
          var div = document.createElement('div');
          div.className = 'notif-card ' + (msg.leido ? 'ncard-read' : 'ncard-unread');
          div.innerHTML = '<div class="notif-card-icon" style="background:#dbeafe;">' + initials + '</div><div style="flex:1;"><div class="notif-card-titulo">' + (msg.remitente||'Desconocido') + '</div><div class="notif-card-cuerpo">' + (msg.asunto||'') + '</div><div class="notif-card-hora">' + (msg.fecha||'') + '</div>' + (msg.leido ? '<button class="btn-visto visto-ok" disabled>Visto</button>' : '<button class="btn-visto" onclick="marcarVistoMsg('+msg.id+')">Marcar como visto</button>') + '</div>';
          body.appendChild(div);
        });
      }
      var footer = document.createElement('div');
      footer.style.cssText = 'margin-top:14px;text-align:center;';
      footer.innerHTML = '<button class="btn btn-secondary btn-sm" onclick="marcarTodosVistoMsg()">Marcar todas como vistas</button>';
      body.appendChild(footer);
      actualizarContadoresBadge(noLeidos);
    }).catch(function(){ body.innerHTML = '<div style="text-align:center;padding:20px;color:#6b7e96;">Error al cargar.</div>'; });
}

function actualizarContadoresBadge(noLeidos) {
  var dot = document.getElementById('notifDot');
  var campanaNum = document.getElementById('campanaCount');
  var badgeNav = document.getElementById('badgeMsgNav');
  var badgeInbox = document.getElementById('badgeInbox');
  if (dot)        { dot.style.display = noLeidos > 0 ? '' : 'none'; }
  if (campanaNum) { campanaNum.textContent = noLeidos; campanaNum.style.display = noLeidos > 0 ? 'flex' : 'none'; }
  if (badgeNav)   { badgeNav.textContent = noLeidos;  badgeNav.style.display   = noLeidos > 0 ? '' : 'none'; }
  if (badgeInbox) { badgeInbox.textContent = noLeidos; badgeInbox.style.display = noLeidos > 0 ? '' : 'none'; }
}

function marcarVistoMsg(msgId) {
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/mensajes?accion=marcarLeido', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'id='+msgId})
    .then(function(r){ return r.json(); })
    .then(function(d){ renderNotifPanel(); renderBandeja(); actualizarContadoresBadge(d.noLeidos || 0); });
}

function marcarTodosVistoMsg() {
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/mensajes?accion=marcarTodasLeidas', {method:'POST'}).then(function(){ renderNotifPanel(); actualizarBadges(); renderBandeja(); });
}

function actualizarBadges() {
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/mensajes?accion=noLeidos')
    .then(function(r){ return r.json(); })
    .then(function(d){ actualizarContadoresBadge(d.mensajes || 0); }).catch(function(){});
}

function actualizarBadgeAvisos() {
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/mensajes?accion=notificaciones')
    .then(function(r){ return r.json(); })
    .then(function(lista){
      var noLeidos = (lista || []).filter(function(n){ return n.tipo === 'aviso' && !n.leida; }).length;
      var badge = document.getElementById('badgeAvisosNav');
      if (badge) { badge.textContent = noLeidos; badge.style.display = noLeidos > 0 ? '' : 'none'; }
    }).catch(function(){});
}

function marcarAvisosVistos() {
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/mensajes?accion=notificaciones')
    .then(function(r){ return r.json(); })
    .then(function(lista){
      var pendientes = (lista || []).filter(function(n){ return n.tipo === 'aviso' && !n.leida; });
      if (!pendientes.length) return;
      Promise.all(pendientes.map(function(n){ return fetch(ctx+'/mensajes?accion=marcarNotifLeida', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'id='+n.id}); }))
        .then(function(){ actualizarBadgeAvisos(); });
    }).catch(function(){});
}

function mostrarBandeja() {
  document.getElementById('panelBandeja').style.display = '';
  document.getElementById('panelEnviados').style.display = 'none';
  document.getElementById('btnBandeja').className = 'btn btn-primary btn-sm';
  document.getElementById('btnEnviados').className = 'btn btn-secondary btn-sm';
  renderBandeja();
}

function mostrarEnviados() {
  document.getElementById('panelBandeja').style.display = 'none';
  document.getElementById('panelEnviados').style.display = '';
  document.getElementById('btnBandeja').className = 'btn btn-secondary btn-sm';
  document.getElementById('btnEnviados').className = 'btn btn-primary btn-sm';
  renderEnviados();
}

function renderEnviados() {
  var cont = document.getElementById('enviados');
  if (!cont) return;
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  cont.innerHTML = '<div style="text-align:center;padding:20px;color:#6b7e96;">Cargando...</div>';
  fetch(ctx+'/mensajes?accion=enviados')
    .then(function(r){ return r.json(); })
    .then(function(msgs){
      if (!msgs.length) { cont.innerHTML = '<div style="text-align:center;padding:24px;color:#6b7e96;">No has enviado ningun mensaje.</div>'; return; }
      var html = '<table class="delta-table" style="font-size:14px;"><thead><tr><th>Para</th><th>Asunto</th><th>Fecha</th><th>Estado</th></tr></thead><tbody>';
      msgs.forEach(function(msg) {
        var fecha = msg.fecha ? msg.fecha.substring(0, 16).replace('T', ' ') : '';
        var estado = msg.leido ? '<span class="tag tag-green">Leido</span>' : '<span class="tag tag-amber">Sin leer</span>';
        html += '<tr style="cursor:pointer;" onclick="showInfoModal(\'Para: ' + (msg.destinatario||'').replace(/'/g,"\\'") + ' — ' + (msg.asunto||'').replace(/'/g,"\\'") + '\', \'' + (msg.cuerpo||'').replace(/'/g,"\\'").replace(/\n/g,'\\n') + '\')"><td><strong>' + (msg.destinatario||'') + '</strong></td><td>' + (msg.asunto||'') + '</td><td style="color:var(--text-soft);font-size:12px;">' + fecha + '</td><td>' + estado + '</td></tr>';
      });
      html += '</tbody></table>';
      cont.innerHTML = html;
    }).catch(function(){ cont.innerHTML = '<div style="text-align:center;padding:24px;color:#6b7e96;">Error al cargar.</div>'; });
}

function renderBandeja() {
  var cont = document.getElementById('bandeja');
  if (!cont) return;
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  cont.innerHTML = '<div style="text-align:center;padding:20px;color:#6b7e96;">Cargando mensajes...</div>';
  fetch(ctx+'/mensajes?accion=bandeja')
    .then(function(r){ return r.json(); })
    .then(function(msgs){
      cont.innerHTML = '';
      if (msgs.length === 0) { cont.innerHTML = '<div style="text-align:center;padding:24px;color:#6b7e96;">No tienes mensajes.</div>'; return; }
      msgs.forEach(function(msg) {
        var div = document.createElement('div');
        div.className = 'msg-item';
        var initials = msg.remitente ? msg.remitente.split(' ').map(function(p){return p[0];}).join('').substring(0,2).toUpperCase() : 'XX';
        div.innerHTML = '<div class="msg-av">' + initials + '</div><div style="flex:1;min-width:0;"><div class="' + (msg.leido ? 'msg-from leido' : 'msg-from') + '">' + (msg.remitente||'Desconocido') + '</div><div class="msg-preview">' + (msg.asunto||'') + ' — ' + (msg.cuerpo||'').substring(0,60) + '</div><div style="font-size:12px;color:var(--text-soft);margin-top:4px;">' + (msg.fecha||'') + '</div></div><div class="msg-dot-unread" style="' + (msg.leido?'display:none;':'') + '"></div>';
        div.onclick = function() {
          if (!msg.leido) {
            fetch(ctx+'/mensajes?accion=marcarLeido', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'id='+msg.id})
              .then(function(r){ return r.json(); })
              .then(function(d){ msg.leido = true; div.querySelector('.msg-dot-unread').style.display='none'; div.querySelector('[class^="msg-from"]').className='msg-from leido'; actualizarContadoresBadge(d.noLeidos||0); renderMensajesResumen(); })
              .catch(function(){ msg.leido=true; div.querySelector('.msg-dot-unread').style.display='none'; actualizarBadges(); });
          }
          showInfoModal('De: '+(msg.remitente||'')+' — '+(msg.asunto||''), msg.cuerpo||'');
        };
        cont.appendChild(div);
      });
    }).catch(function(){ cont.innerHTML = '<div style="text-align:center;padding:24px;color:#6b7e96;">No se pudo cargar la bandeja.</div>'; });
}

function renderMensajesResumen() {
  var cont = document.getElementById('mensajesResumen');
  if (!cont) return;
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/mensajes?accion=bandeja')
    .then(function(r){ return r.json(); })
    .then(function(msgs){
      cont.innerHTML = '';
      if (!msgs.length) { cont.innerHTML = '<div style="color:var(--text-soft);font-size:14px;padding:8px 0;">No tienes mensajes.</div>'; return; }
      msgs.slice(0,3).forEach(function(msg) {
        var initials = msg.remitente ? msg.remitente.split(' ').map(function(p){return p[0];}).join('').substring(0,2).toUpperCase() : '??';
        var div = document.createElement('div');
        div.className = 'msg-item';
        div.onclick = function(){ irTab('mensajes', document.getElementById('nav-mensajes')); };
        div.innerHTML = '<div class="msg-av">' + initials + '</div><div style="flex:1;min-width:0;"><div class="' + (msg.leido?'msg-from leido':'msg-from') + '">' + (msg.remitente||'Desconocido') + '</div><div class="msg-preview">' + (msg.asunto||'') + '</div></div><div class="msg-dot-unread" style="' + (msg.leido?'display:none;':'') + '"></div>';
        cont.appendChild(div);
      });
    }).catch(function(){ cont.innerHTML = '<div style="color:var(--text-soft);font-size:14px;padding:8px 0;">No tienes mensajes.</div>'; });
}

function enviarMsg() {
  var para = document.getElementById('msgPara').value.trim();
  var asunto = document.getElementById('msgAsunto').value.trim() || '(Sin asunto)';
  var cuerpo = document.getElementById('msgCuerpo').value.trim();
  if (!para || !cuerpo) { showToast('Complete el destinatario y el mensaje.', 'error'); return; }
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/mensajes', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'accion=enviar&destinatario='+encodeURIComponent(para)+'&asunto='+encodeURIComponent(asunto)+'&cuerpo='+encodeURIComponent(cuerpo)})
    .then(function(r){ return r.json(); })
    .then(function(d){
      if (d.ok) { showToast('Mensaje enviado a: '+para, 'success'); document.getElementById('msgPara').value='María Mosquera'; document.getElementById('msgAsunto').value=''; document.getElementById('msgCuerpo').value=''; renderBandeja(); actualizarBadges(); }
      else { showToast('Error: '+(d.error||'No se pudo enviar.'), 'error'); }
    }).catch(function(){ showToast('Error de conexion.', 'error'); });
}

function calcCreditos() { var t=0; for(var i=0;i<materiasInscritas.length;i++) t+=materiasInscritas[i].creditos; return t; }
function tieneSolicitudPendiente(codigo, tipo) { for(var i=0;i<solicitudesPendientes.length;i++){ var s=solicitudesPendientes[i]; if(s.materiaCodigo===codigo&&s.estado==='pendiente'&&s.tipo===tipo) return true; } return false; }

function cargarSolicitudesPendientes() {
  if (!<%= est_hayBD %>) return;
  var ctx = document.querySelector('meta[name="ctx"]') ? document.querySelector('meta[name="ctx"]').content : '';
  fetch(ctx+'/matricula?accion=misSolicitudes')
    .then(function(r){ return r.json(); })
    .then(function(data){ solicitudesPendientes = Array.isArray(data)?data:[]; renderSolicitudes(); renderInscritas(); renderDisponibles(); })
    .catch(function(){ solicitudesPendientes=[]; renderSolicitudes(); });
}

function renderSolicitudes() {
  var tbody = document.getElementById('tablaSolicitudes');
  var card = document.getElementById('cardSolicitudesPendientes');
  if (!tbody) return;
  var pendientes = solicitudesPendientes.filter(function(s){ return s.estado==='pendiente'; });
  if (!pendientes.length) { if(card) card.style.display='none'; tbody.innerHTML=''; return; }
  if(card) card.style.display='';
  tbody.innerHTML='';
  pendientes.forEach(function(s){
    var tr=document.createElement('tr');
    tr.innerHTML='<td><span class="tag tag-amber">'+(s.tipo==='inscripcion'?'Inscripcion':'Retiro')+'</span></td><td><strong>'+(s.materiaNombre||'')+'</strong></td><td>'+(s.materiaCodigo||'')+'</td><td><span class="tag tag-amber">Pendiente</span></td><td>'+(s.fecha||'')+'</td>';
    tbody.appendChild(tr);
  });
}

function renderInscritas() {
  var tbody = document.getElementById('tablaInscritas');
  if (!tbody) return;
  tbody.innerHTML='';
  for(var i=0;i<materiasInscritas.length;i++){
    (function(m){
      var retiroPend = tieneSolicitudPendiente(m.codigo,'retiro');
      var tr=document.createElement('tr');
      tr.innerHTML='<td>'+m.codigo+'</td><td><strong>'+m.nombre+'</strong></td><td>'+m.creditos+'</td><td>'+m.horario+'</td><td>'+m.docente+'</td><td>'+(retiroPend?'<span class="tag tag-amber">Retiro pendiente</span>':'<span class="tag tag-green">Inscrita</span>')+'</td><td>'+(retiroPend?'<span style="color:var(--text-soft);font-size:13px;">En revision</span>':'<button class="btn-danger" onclick="desinscribir(\''+m.codigo+'\')">Retirar Materia</button>')+'</td>';
      tbody.appendChild(tr);
    })(materiasInscritas[i]);
  }
  actualizarContadoresInscripcion();
}

function renderDisponibles() {
  var tbody = document.getElementById('tablaDisponibles');
  if (!tbody) return;
  tbody.innerHTML='';
  if(!materiasDisponibles.length){ tbody.innerHTML='<tr><td colspan="6" style="text-align:center;color:var(--text-soft);padding:20px;">No hay mas materias disponibles.</td></tr>'; return; }
  for(var i=0;i<materiasDisponibles.length;i++){
    (function(m){
      var inscPend=tieneSolicitudPendiente(m.codigo,'inscripcion');
      var accionHtml;
      if (m.bloqueada) {
        accionHtml = '<button class="btn btn-sm" disabled title="Esta materia fue retirada y no puede volver a inscribirse." style="background:#cbd5e1;color:#64748b;cursor:not-allowed;">Agregar</button>';
      } else if (inscPend) {
        accionHtml = '<span class="tag tag-amber">Pendiente</span>';
      } else {
        accionHtml = '<button class="btn btn-primary btn-sm" onclick="inscribirMateria(\''+m.codigo+'\')">Agregar</button>';
      }
      var tr=document.createElement('tr');
      tr.innerHTML='<td>'+m.codigo+'</td><td><strong>'+m.nombre+'</strong></td><td>'+m.creditos+'</td><td>'+m.cupos+'</td><td>'+m.horario+'</td><td>'+accionHtml+'</td>';
      tbody.appendChild(tr);
    })(materiasDisponibles[i]);
  }
}

function actualizarContadoresInscripcion() {
  var cant=materiasInscritas.length; var cred=calcCreditos();
  var aprobadas=0; for(var i=0;i<materiasInscritas.length;i++){ if(materiasInscritas[i].nota>=71) aprobadas++; }
  var els={inscCant:cant,inscCred:cred,statMaterias:cant,statCreditos:cred,calAprobadas:aprobadas};
  Object.keys(els).forEach(function(id){ var el=document.getElementById(id); if(el) el.textContent=els[id]; });
  var elAs=document.getElementById('calAprobSub'); if(elAs) elAs.textContent='de '+cant+' activas';
}

function inscribirMateria(codigo) {
  var idx=-1; for(var i=0;i<materiasDisponibles.length;i++){ if(materiasDisponibles[i].codigo===codigo){idx=i;break;} }
  if(idx===-1) return;
  var m=materiasDisponibles[idx];
  if(m.bloqueada){ showToast('Esta materia fue retirada y no puede volver a inscribirse.','error'); return; }
  if(materiasInscritas.length>=6){ showToast('Ha alcanzado el limite de 6 materias.','error'); return; }
  showConfirm('Desea solicitar la inscripcion de: '+m.nombre+'?', function(){
    var ctx=document.querySelector('meta[name="ctx"]')?document.querySelector('meta[name="ctx"]').content:'';
    fetch(ctx+'/notas',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'accion=inscribir&codigoMateria='+encodeURIComponent(codigo)})
      .then(function(r){return r.json();})
      .then(function(d){ if(!d.ok){showToast('Error: '+(d.error||'No se pudo enviar.'), 'error');return;} showToast(d.mensaje||'Solicitud pendiente de aprobacion.','info'); cargarSolicitudesPendientes(); })
      .catch(function(){showToast('Error de conexion.','error');});
  });
}

function desinscribir(codigo) {
  var idx=-1; for(var i=0;i<materiasInscritas.length;i++){ if(materiasInscritas[i].codigo===codigo){idx=i;break;} }
  if(idx===-1) return;
  showConfirm('¿Desea retirar la materia: '+materiasInscritas[idx].nombre+'?', function(){
    var ctx=document.querySelector('meta[name="ctx"]')?document.querySelector('meta[name="ctx"]').content:'';
    fetch(ctx+'/notas',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'accion=desinscribir&codigoMateria='+encodeURIComponent(codigo)})
      .then(function(r){return r.json();})
      .then(function(d){ if(!d.ok){showToast('Error: '+(d.error||'No se pudo enviar.'), 'error');return;} showToast(d.mensaje||'Retiro pendiente de aprobacion.','info'); cargarSolicitudesPendientes(); })
      .catch(function(){showToast('Error de conexion.','error');});
  });
}

function getTagClass(n){ if(n>=90) return 'tag-green'; if(n>=80) return 'tag-blue'; if(n>=70) return 'tag-amber'; return 'tag-red'; }
function getBarColor(n){ if(n>=90) return 'var(--green)'; if(n>=80) return 'var(--blue)'; if(n>=70) return 'var(--amber)'; return 'var(--red)'; }

function renderCalResumen() {
  var tbody=document.getElementById('calResumen');
  if(!tbody) return;
  tbody.innerHTML='';
  if(!materiasInscritas.length){ tbody.innerHTML='<tr><td colspan="3" style="text-align:center;padding:16px;color:#6b7e96;">Sin materias inscritas.</td></tr>'; return; }
  materiasInscritas.forEach(function(m){
    var nota=m.nota||0;
    var tr=document.createElement('tr');
    tr.innerHTML='<td><strong>'+m.nombre+'</strong></td><td><span class="tag '+getTagClass(nota)+'">'+nota+'</span></td><td><div class="prog-wrap"><div class="prog-fill" style="width:'+Math.min(nota,100)+'%;background:'+getBarColor(nota)+';"></div></div></td>';
    tbody.appendChild(tr);
  });
  actualizarStatsCalificaciones(); renderCalDetalle(); actualizarContadoresInscripcion();
}

function renderCalDetalle() {
  var tbody=document.getElementById('calDetalle');
  if(!tbody) return;
  tbody.innerHTML='';
  materiasInscritas.forEach(function(m){
    var nota=m.nota||0;
    var estado=nota>=71?'<span class="tag tag-green">Aprobado</span>':(nota>0?(nota>=61?'<span class="tag tag-amber">En proceso</span>':'<span class="tag tag-red">Reprobado</span>'):'<span class="tag tag-blue">Sin notas</span>');
    var tr=document.createElement('tr');
    tr.innerHTML='<td><strong>'+m.nombre+'</strong></td><td>'+(m.p1>0?m.p1:'-')+'</td><td>'+(m.p2>0?m.p2:'-')+'</td><td>'+(m.proj>0?m.proj:'-')+'</td><td>'+(m.exFinal>0?m.exFinal:'-')+'</td><td><span class="tag '+getTagClass(nota)+'" style="font-size:16px;padding:6px 14px;">'+(nota>0?nota:'-')+'</span></td><td>'+estado+'</td>';
    tbody.appendChild(tr);
  });
}

function actualizarStatsCalificaciones() {
  var suma=0,mejor=0,mejorNombre='',conNotas=0;
  materiasInscritas.forEach(function(m){ var n=m.nota||0; if(n>0){suma+=n;conNotas++;if(n>mejor){mejor=n;mejorNombre=m.nombre;}} });
  var prom=conNotas>0?Math.round((suma/conNotas)*10)/10:0;
  var ids={calProm:prom,calMejor:mejor>0?mejor:'-',calMejorSub:mejorNombre||'-',statPromedio:prom};
  Object.keys(ids).forEach(function(id){ var el=document.getElementById(id); if(el) el.textContent=ids[id]; });
  var elSub=document.getElementById('statPromedioSub');
  if(elSub){ var etq='Sin notas'; if(conNotas>0){if(prom>=90)etq='Excelente';else if(prom>=80)etq='Muy bueno';else if(prom>=70)etq='Bueno';else if(prom>=60)etq='Regular';else etq='En riesgo';} elSub.textContent=etq; }
}

function renderHorario() {
  var tbody=document.getElementById('tablaHorario');
  if(!tbody) return;
  tbody.innerHTML='';
  var grid={};
  for(var h=0;h<horasSlots.length;h++){ grid[horasSlots[h]]={};for(var d=0;d<diasKeys.length;d++) grid[horasSlots[h]][diasKeys[d]]=null; }
  for(var i=0;i<materiasInscritas.length;i++){ var m=materiasInscritas[i]; if(!m.dias) continue; var dks=Object.keys(m.dias); for(var k=0;k<dks.length;k++){ var dia=dks[k]; var hora=m.dias[dia]; if(grid[hora]) grid[hora][dia]=m; } }
  for(var h=0;h<horasSlots.length;h++){
    var hora=horasSlots[h];
    var tr=document.createElement('tr');
    var html='<td style="font-weight:800;color:var(--blue);">'+hora+'</td>';
    for(var d=0;d<diasKeys.length;d++){
      var mat=grid[hora][diasKeys[d]];
      html+=mat?'<td><div class="horario-cell-clase" style="background:'+mat.colorBg+';color:'+mat.color+';">'+mat.nombre+'<br><small style="font-weight:400;">'+mat.aula+'</small></div></td>':'<td style="color:var(--text-soft);text-align:center;">-</td>';
    }
    tr.innerHTML=html; tbody.appendChild(tr);
  }
}

function renderFechaHoy() {
  var el=document.getElementById('fechaHoy');
  if(!el) return;
  var dias=['Domingo','Lunes','Martes','Miercoles','Jueves','Viernes','Sabado'];
  var meses=['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
  var hoy=new Date();
  el.textContent=dias[hoy.getDay()]+' '+hoy.getDate()+' de '+meses[hoy.getMonth()];
}

function escHtml(s){ if(!s) return ''; return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
var AVISO_CLASES={info:'',urgente:'ann-amber',recordatorio:'',exito:'ann-green'};

function renderAvisos(lista) {
  var resumen=document.getElementById('avisosResumen');
  var listaEl=document.getElementById('avisosLista');
  if(!lista||!lista.length){ var v='<div style="color:var(--text-soft);font-size:14px;padding:12px 0;">No hay avisos.</div>'; if(resumen) resumen.innerHTML=v; if(listaEl) listaEl.innerHTML=v; return; }
  var htmlC='';
  lista.forEach(function(a){ var c=AVISO_CLASES[a.tipo]||''; htmlC+='<div class="ann-item'+(c?' '+c:'')+'"><div class="ann-titulo">'+escHtml(a.titulo)+'</div><div class="ann-cuerpo">'+escHtml(a.cuerpo)+'</div><div class="ann-fecha">'+escHtml(a.fecha)+' - '+escHtml(a.origen)+'</div></div>'; });
  if(listaEl) listaEl.innerHTML=htmlC;
  if(resumen){ var htmlR=''; lista.slice(0,3).forEach(function(a){ var c=AVISO_CLASES[a.tipo]||''; htmlR+='<div class="ann-item'+(c?' '+c:'')+'"><div class="ann-titulo">'+escHtml(a.titulo)+'</div><div class="ann-cuerpo">'+escHtml(a.cuerpo)+'</div><div class="ann-fecha">'+escHtml(a.fecha)+'</div></div>'; }); resumen.innerHTML=htmlR; }
}

function cargarAvisos() {
  var ctx=document.querySelector('meta[name="ctx"]')?document.querySelector('meta[name="ctx"]').content:'';
  fetch(ctx+'/avisos').then(function(r){return r.json();}).then(function(d){renderAvisos(Array.isArray(d)?d:[]);}).catch(function(){ var msg='<div style="color:var(--text-soft);font-size:14px;padding:12px 0;">No se pudieron cargar los avisos.</div>'; var r=document.getElementById('avisosResumen'),l=document.getElementById('avisosLista'); if(r)r.innerHTML=msg; if(l)l.innerHTML=msg; });
}

function renderHorarioHoy() {
  var cont=document.getElementById('horarioHoy');
  if(!cont) return;
  cont.innerHTML='';
  var diasMap=['dom','lun','mar','mie','jue','vie','sab'];
  var diaHoy=diasMap[new Date().getDay()];
  var hoy=[];
  for(var i=0;i<materiasInscritas.length;i++){ var m=materiasInscritas[i]; if(m.dias&&m.dias[diaHoy]) hoy.push({m:m,hora:m.dias[diaHoy]}); }
  hoy.sort(function(a,b){ function toMin(h){ var p=h.replace(' AM','').replace(' PM','').split(':'); var hh=parseInt(p[0]),mm=parseInt(p[1]||0); if(h.indexOf('PM')>-1&&hh!==12)hh+=12; if(h.indexOf('AM')>-1&&hh===12)hh=0; return hh*60+mm; } return toMin(a.hora)-toMin(b.hora); });
  if(!hoy.length){ cont.innerHTML='<div style="color:var(--text-soft);font-size:14px;padding:12px 0;">No hay clases hoy.</div>'; return; }
  for(var i=0;i<hoy.length;i++){
    var m=hoy[i].m, hora=hoy[i].hora;
    var div=document.createElement('div'); div.className='sched-item';
    div.innerHTML='<div class="sched-time">'+hora+'</div><div class="sched-bar" style="background:'+m.color+';"></div><div><div class="sched-subject">'+m.nombre+'</div><div class="sched-prof">Prof. '+m.docente.split(',')[0]+'</div><div class="sched-room">'+m.aula+'</div></div>';
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

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
  Integer adm_usuarioId = (Integer) session.getAttribute("usuarioId");
  String  adm_rol       = (String)  session.getAttribute("usuarioRol");
  String  adm_nombre    = (String)  session.getAttribute("adminNombre");
  boolean adm_hayBD     = (adm_usuarioId != null && "admin".equals(adm_rol));
  boolean adm_loginError = "1".equals(request.getParameter("error"));

  if (adm_usuarioId != null && "profesor".equals(adm_rol)) {
    response.sendRedirect(request.getContextPath() + "/portal_profesor.jsp");
    return;
  }
  if (adm_usuarioId != null && "estudiante".equals(adm_rol)) {
    response.sendRedirect(request.getContextPath() + "/portal_estudiante.jsp");
    return;
  }
  if (adm_nombre == null) adm_nombre = "Administrador";
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="ctx" content="<%= request.getContextPath() %>">
<title>Sistema Delta — Portal Administrativo</title>
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&family=Merriweather:wght@700&display=swap" rel="stylesheet">
<style>
:root {
  --purple:#5b21b6; --purple-light:#ede9fe; --purple-dark:#4c1d95;
  --blue:#1a56a0; --green:#15803d; --amber:#b45309; --red:#dc2626;
  --bg:#f4f6fb; --text:#1e2a3b; --text-soft:#6b7e96;
  --radius:14px; --radius-sm:10px;
  --sidebar-w:260px;
}
* { margin:0; padding:0; box-sizing:border-box; }
body { font-family:'Nunito',sans-serif; background:var(--bg); color:var(--text); min-height:100vh; }
.hidden { display:none !important; }

/* LOGIN */
#page-login { min-height:100vh; display:flex; align-items:center; justify-content:center;
  background:linear-gradient(145deg,#ede9fe 0%,#f4f6fb 55%,#dbeafe 100%); padding:24px; }
.login-box { background:#fff; border-radius:20px; padding:40px 36px; width:100%; max-width:400px;
  box-shadow:0 8px 40px rgba(91,33,182,.15); border:2px solid #c4b5fd; }
.login-logo { text-align:center; margin-bottom:24px; }
.delta-mark { display:inline-flex; width:64px; height:64px; border-radius:16px;
  background:var(--purple); color:#fff; font-family:'Merriweather',serif; font-size:32px;
  align-items:center; justify-content:center; margin-bottom:12px; }
.login-logo h1 { font-family:'Merriweather',serif; font-size:22px; }
.login-logo p { font-size:13px; color:var(--text-soft); margin-top:4px; }
.login-role-banner { background:var(--purple-light); color:var(--purple-dark); font-weight:700;
  text-align:center; padding:10px; border-radius:10px; margin-bottom:20px; font-size:14px; }
.form-group { margin-bottom:16px; }
.form-group label { display:block; font-size:13px; font-weight:700; margin-bottom:6px; color:var(--text-soft); }
.form-group input { width:100%; padding:11px 14px; border:2px solid #e2e8f0; border-radius:10px;
  font-family:inherit; font-size:15px; outline:none; }
.form-group input:focus { border-color:var(--purple); }
.login-error { display:none; background:#fee2e2; color:#991b1b; padding:10px; border-radius:8px;
  font-size:13px; margin-bottom:14px; }
.btn { border:none; border-radius:10px; padding:10px 18px; font-family:inherit; font-weight:700;
  font-size:14px; cursor:pointer; transition:all .15s; }
.btn-primary { background:var(--purple); color:#fff; }
.btn-primary:hover { background:var(--purple-dark); }
.btn-secondary { background:#e2e8f0; color:var(--text); }
.btn-success { background:var(--green); color:#fff; }
.btn-danger { background:var(--red); color:#fff; }
.btn-sm { padding:6px 12px; font-size:12px; }
.btn-full { width:100%; padding:13px; font-size:15px; }
.login-hint { text-align:center; font-size:12px; color:var(--text-soft); margin-top:14px; }
.login-switch { text-align:center; font-size:13px; margin-top:16px; color:var(--text-soft); }
.login-switch a { color:var(--purple); font-weight:700; text-decoration:none; }

/* PORTAL */
.portal { display:flex; min-height:100vh; }
.sidebar { width:var(--sidebar-w); background:#fff; border-right:2px solid #e8edf5;
  position:fixed; top:0; left:0; height:100vh; overflow-y:auto; z-index:100; }
.sidebar-header { padding:22px 20px 16px; border-bottom:2px solid #f0f4fa; }
.sidebar-logo { display:flex; align-items:center; gap:12px; }
.logo-mark { width:42px; height:42px; border-radius:12px; background:var(--purple); color:#fff;
  font-family:'Merriweather',serif; font-size:22px; display:flex; align-items:center; justify-content:center; }
.logo-name { font-weight:800; font-size:17px; }
.logo-sub { font-size:12px; color:var(--text-soft); }
.sidebar-user { padding:16px 20px; border-bottom:2px solid #f0f4fa; display:flex; gap:12px; align-items:center; }
.user-avatar { width:40px; height:40px; border-radius:50%; background:var(--purple-light);
  color:var(--purple); font-weight:800; display:flex; align-items:center; justify-content:center; }
.user-name { font-weight:700; font-size:14px; }
.user-role-tag { font-size:11px; background:var(--purple-light); color:var(--purple);
  padding:2px 8px; border-radius:20px; font-weight:700; display:inline-block; margin-top:2px; }
.nav-section { padding:12px 10px; }
.nav-label { font-size:11px; font-weight:800; color:var(--text-soft); text-transform:uppercase;
  letter-spacing:.06em; padding:8px 12px 4px; }
.nav-item { display:flex; align-items:center; gap:10px; width:100%; padding:10px 14px;
  border:none; background:none; border-radius:10px; font-family:inherit; font-size:14px;
  font-weight:600; color:var(--text-soft); cursor:pointer; text-align:left; }
.nav-item:hover { background:#f8f9fc; color:var(--text); }
.nav-item.active { background:var(--purple-light); color:var(--purple); font-weight:800; }
.nav-icon { font-size:16px; width:22px; text-align:center; }
.main-content { margin-left:var(--sidebar-w); flex:1; padding:28px 32px; }
.topbar { margin-bottom:24px; }
.page-title { font-family:'Merriweather',serif; font-size:24px; }
.page-subtitle { font-size:14px; color:var(--text-soft); margin-top:4px; }
.tab-panel { display:none; }
.tab-panel.active { display:block; }
.stats-row { display:grid; gap:16px; margin-bottom:24px; }
.stats-4 { grid-template-columns:repeat(4,1fr); }
.stat-card { background:#fff; border:2px solid #e8edf5; border-radius:var(--radius);
  padding:20px; display:flex; gap:14px; align-items:center; }
.stat-icon { font-size:28px; }
.stat-label { font-size:12px; color:var(--text-soft); font-weight:700; }
.stat-value { font-size:28px; font-weight:800; line-height:1.1; }
.card { background:#fff; border:2px solid #e8edf5; border-radius:var(--radius); padding:22px; margin-bottom:20px; }
.card-title { font-weight:800; font-size:16px; margin-bottom:16px; }
.delta-table { width:100%; border-collapse:collapse; font-size:14px; }
.delta-table th { text-align:left; padding:10px 12px; background:#f8f9fc; font-size:12px;
  color:var(--text-soft); font-weight:800; border-bottom:2px solid #e8edf5; }
.delta-table td { padding:11px 12px; border-bottom:1px solid #f0f4fa; vertical-align:middle; }
.tag { display:inline-block; padding:3px 10px; border-radius:20px; font-size:12px; font-weight:700; }
.tag-green { background:#dcfce7; color:#15803d; }
.tag-amber { background:#fef3c7; color:#b45309; }
.tag-red { background:#fee2e2; color:#dc2626; }
.tag-gray { background:#f1f5f9; color:#64748b; }
.filter-row { display:flex; gap:10px; flex-wrap:wrap; margin-bottom:16px; }
.filter-row input, .filter-row select { padding:9px 12px; border:2px solid #e2e8f0;
  border-radius:8px; font-family:inherit; font-size:14px; }
.sub-nav { display:flex; gap:8px; margin-bottom:16px; }
.sub-nav button { padding:8px 16px; border:2px solid #e2e8f0; background:#fff;
  border-radius:8px; font-family:inherit; font-weight:700; cursor:pointer; font-size:13px; }
.sub-nav button.active { border-color:var(--purple); background:var(--purple-light); color:var(--purple); }
@media(max-width:900px) { .stats-4 { grid-template-columns:1fr 1fr; } .main-content { padding:20px; } }

/* TOASTS Y MODAL */
.toast-container{position:fixed;top:20px;right:20px;z-index:9999;display:flex;flex-direction:column;gap:10px;max-width:360px;}
.toast{display:flex;align-items:flex-start;gap:10px;padding:14px 16px;border-radius:10px;background:#fff;box-shadow:0 8px 24px rgba(0,0,0,.12);border-left:5px solid var(--purple);font-size:14px;color:var(--text);animation:toast-in 0.25s ease-out;line-height:1.4;}
.toast.toast-success{border-left-color:var(--green);}
.toast.toast-error{border-left-color:var(--red);}
.toast.toast-info{border-left-color:var(--purple);}
.toast-icon{font-size:18px;flex-shrink:0;line-height:1.4;}
.toast-msg{flex:1;white-space:pre-line;}
.toast-close{cursor:pointer;color:var(--text-soft);font-size:16px;line-height:1;flex-shrink:0;background:none;border:none;padding:0;}
.toast-close:hover{color:var(--text);}
.toast.toast-out{animation:toast-out 0.2s ease-in forwards;}
@keyframes toast-in{from{opacity:0;transform:translateX(30px);}to{opacity:1;transform:translateX(0);}}
@keyframes toast-out{from{opacity:1;transform:translateX(0);}to{opacity:0;transform:translateX(30px);}}
.modal-overlay{position:fixed;inset:0;background:rgba(30,42,59,.45);z-index:10000;display:flex;align-items:center;justify-content:center;padding:20px;}
.modal-overlay.hidden{display:none;}
.modal-box{background:#fff;border-radius:10px;max-width:420px;width:100%;padding:24px;box-shadow:0 12px 40px rgba(0,0,0,.2);}
.modal-box p{font-size:15px;color:var(--text);line-height:1.5;margin-bottom:20px;white-space:pre-line;}
.modal-actions{display:flex;justify-content:flex-end;gap:10px;}
.edit-input{width:70px;text-align:center;padding:6px 8px;border:2px solid #e2e8f0;border-radius:8px;font-family:inherit;font-size:13px;}
.edit-select{padding:6px 8px;border:2px solid #e2e8f0;border-radius:8px;font-family:inherit;font-size:13px;}
.aviso-field-label{display:block;font-size:13px;font-weight:700;color:var(--text-soft);margin-bottom:6px;}
.aviso-field-input{width:100%;padding:10px 12px;border:2px solid #e2e8f0;border-radius:8px;font-family:inherit;font-size:14px;}
.aviso-field-input:focus{border-color:var(--purple);outline:none;}
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

<!-- MODAL EDITAR AVISO -->
<div class="modal-overlay hidden" id="editAvisoOverlay">
  <div class="modal-box" style="max-width:500px;">
    <h3 style="margin-bottom:16px;font-size:16px;font-weight:800;">Editar Aviso</h3>
    <div style="margin-bottom:14px;">
      <label class="aviso-field-label">Titulo</label>
      <input type="text" id="editAvisoTitulo" class="aviso-field-input">
    </div>
    <div style="margin-bottom:14px;">
      <label class="aviso-field-label">Contenido</label>
      <textarea id="editAvisoCuerpo" rows="4" class="aviso-field-input" style="resize:vertical;"></textarea>
    </div>
    <div style="margin-bottom:20px;">
      <label class="aviso-field-label">Estado</label>
      <select id="editAvisoEstado" class="aviso-field-input" style="width:auto;">
        <option value="activo">Activo</option>
        <option value="archivado">Archivado</option>
      </select>
    </div>
    <div class="modal-actions">
      <button class="btn btn-secondary" onclick="cerrarEditarAviso()">Cancelar</button>
      <button class="btn btn-primary" onclick="guardarAviso()">Guardar cambios</button>
    </div>
  </div>
</div>

<!-- LOGIN -->
<div id="page-login" class="<%= adm_hayBD ? "hidden" : "" %>">
  <div class="login-box">
    <div class="login-logo">
      <div class="delta-mark">&#916;</div>
      <h1>Sistema Delta</h1>
      <p>Universidad Tecnologica de Panama</p>
    </div>
    <div class="login-role-banner">&#128737; Portal Administrativo</div>
    <div class="form-group">
      <label for="loginUser">Usuario</label>
      <input id="loginUser" type="text" placeholder="Ej: admin" autocomplete="username">
    </div>
    <div class="form-group">
      <label for="loginPass">Contrasena</label>
      <input id="loginPass" type="password" placeholder="********" autocomplete="current-password">
    </div>
    <div class="login-error" id="loginError">Usuario o contrasena incorrecto.</div>
    <% if (adm_loginError) { %><script>document.getElementById('loginError').style.display='block';</script><% } %>
    <button class="btn btn-primary btn-full" onclick="doLogin()">Ingresar al Portal</button>
    <div class="login-hint">Demo: usuario <strong>admin</strong> &middot; clave <strong>1234</strong></div>
    <div class="login-switch"><a href="index.jsp">&#8592; Volver a seleccion de portal</a></div>
  </div>
</div>

<!-- PORTAL -->
<div id="page-portal" class="portal <%= adm_hayBD ? "" : "hidden" %>">
  <aside class="sidebar">
    <div class="sidebar-header">
      <div class="sidebar-logo">
        <div class="logo-mark">&#916;</div>
        <div>
          <div class="logo-name">Delta</div>
          <div class="logo-sub">Portal Administrativo</div>
        </div>
      </div>
    </div>
    <div class="sidebar-user">
      <div class="user-avatar">A</div>
      <div>
        <div class="user-name"><%= adm_nombre %></div>
        <div class="user-role-tag">Administrador</div>
      </div>
    </div>
    <nav class="nav-section">
      <div class="nav-label">Administrativo</div>
      <button class="nav-item active" onclick="irTab('dashboard',this)"><span class="nav-icon">&#128202;</span> Dashboard</button>
      <button class="nav-item" onclick="irTab('estudiantes',this)"><span class="nav-icon">&#127891;</span> Gestion de Estudiantes</button>
      <button class="nav-item" onclick="irTab('profesores',this)"><span class="nav-icon">&#128104;&#8205;&#127979;</span> Gestion de Profesores</button>
      <button class="nav-item" onclick="irTab('materias',this)"><span class="nav-icon">&#128218;</span> Gestion de Materias</button>
      <button class="nav-item" onclick="irTab('matricula',this)"><span class="nav-icon">&#128203;</span> Gestion de Matriculas</button>
      <button class="nav-item" onclick="irTab('limites',this)"><span class="nav-icon">&#128273;</span> Limites de Solicitudes</button>
      <div class="nav-label">Supervision</div>
      <button class="nav-item" onclick="irTab('sup-calificaciones',this)"><span class="nav-icon">&#128221;</span> Calificaciones</button>
      <div class="nav-label">Comunicacion</div>
      <button class="nav-item" onclick="irTab('avisos',this)"><span class="nav-icon">&#128227;</span> Gestion de Avisos</button>
      <button class="nav-item" onclick="irTab('reportes',this)"><span class="nav-icon">&#128200;</span> Reportes</button>
      <button class="nav-item" onclick="cerrarSesion()"><span class="nav-icon">&#128682;</span> Cerrar Sesion</button>
    </nav>
  </aside>

  <main class="main-content">

    <!-- DASHBOARD -->
    <div id="tab-dashboard" class="tab-panel active">
      <div class="topbar">
        <h2 class="page-title">Dashboard</h2>
        <div class="page-subtitle">Resumen general del sistema</div>
      </div>
      <div class="stats-row stats-4" id="dashStats"></div>
    </div>

    <!-- ESTUDIANTES -->
    <div id="tab-estudiantes" class="tab-panel">
      <div class="topbar"><h2 class="page-title">Gestion de Estudiantes</h2></div>
      <div class="filter-row">
        <input id="fEstNombre" placeholder="Nombre" onkeyup="if(event.key==='Enter')cargarEstudiantes()">
        <input id="fEstCedula" placeholder="Cedula / Matricula" onkeyup="if(event.key==='Enter')cargarEstudiantes()">
        <input id="fEstCarrera" placeholder="Carrera" onkeyup="if(event.key==='Enter')cargarEstudiantes()">
        <input id="fEstMateria" placeholder="Materia inscrita (ej: Calculo)" onkeyup="if(event.key==='Enter')cargarEstudiantes()">
        <button class="btn btn-primary btn-sm" onclick="cargarEstudiantes()">Filtrar</button>
      </div>
      <div class="card"><div style="overflow-x:auto;"><table class="delta-table" id="tblEstudiantes"></table></div></div>
    </div>

    <!-- PROFESORES -->
    <div id="tab-profesores" class="tab-panel">
      <div class="topbar"><h2 class="page-title">Gestion de Profesores</h2></div>
      <div class="filter-row">
        <input id="fProfNombre" placeholder="Nombre" onkeyup="if(event.key==='Enter')cargarProfesores()">
        <input id="fProfDepto" placeholder="Departamento" onkeyup="if(event.key==='Enter')cargarProfesores()">
        <input id="fProfMateria" placeholder="Materia" onkeyup="if(event.key==='Enter')cargarProfesores()">
        <button class="btn btn-primary btn-sm" onclick="cargarProfesores()">Filtrar</button>
      </div>
      <div class="card"><div style="overflow-x:auto;"><table class="delta-table" id="tblProfesores"></table></div></div>
    </div>

    <!-- MATERIAS -->
    <div id="tab-materias" class="tab-panel">
      <div class="topbar"><h2 class="page-title">Gestion de Materias</h2></div>
      <div class="card"><div style="overflow-x:auto;"><table class="delta-table" id="tblMaterias"></table></div></div>
    </div>

    <!-- MATRICULA -->
    <div id="tab-matricula" class="tab-panel">
      <div class="topbar"><h2 class="page-title">Gestion de Matriculas</h2></div>
      <div class="sub-nav">
        <button class="active" id="btnSolInsc" onclick="cargarSolicitudes('inscripcion',this)">Solicitudes de Inscripcion</button>
        <button id="btnSolRet" onclick="cargarSolicitudes('retiro',this)">Solicitudes de Retiro</button>
      </div>
      <div class="card"><div style="overflow-x:auto;"><table class="delta-table" id="tblSolicitudes"></table></div></div>
    </div>

    <!-- LIMITES -->
    <div id="tab-limites" class="tab-panel">
      <div class="topbar">
        <h2 class="page-title">&#128273; Oportunidades de Solicitud</h2>
        <div class="page-subtitle">Oportunidades de cada estudiante.</div>
      </div>
      <div id="limites-container" style="display:flex;flex-direction:column;gap:20px;"></div>
    </div>

    <!-- SUPERVISION CALIFICACIONES -->
    <div id="tab-sup-calificaciones" class="tab-panel">
      <div class="topbar">
        <h2 class="page-title">Calificaciones — Calidad de Software</h2>
        <div class="page-subtitle">Notas por componente con historial de modificaciones y autorizaciones</div>
      </div>
      <div id="contenedorCalificaciones" style="display:flex;flex-direction:column;gap:0;"></div>
      <div class="card" id="historialCard" style="display:none;margin-top:20px;">
        <div class="card-title" style="display:flex;align-items:center;justify-content:space-between;">
          Historial de cambios
          <button class="btn btn-secondary btn-sm" onclick="document.getElementById('historialCard').style.display='none';">Cerrar</button>
        </div>
        <div style="overflow-x:auto;"><table class="delta-table" id="tblHistorialNota"></table></div>
      </div>
    </div>

    <!-- AVISOS -->
    <div id="tab-avisos" class="tab-panel">
      <div class="topbar"><h2 class="page-title">Gestion de Avisos</h2></div>
      <div class="sub-nav" id="filtrosAvisos">
        <button class="active" data-estado="todos" onclick="cargarAvisos('todos',this)">Todos</button>
        <button data-estado="activo" onclick="cargarAvisos('activo',this)">Activos</button>
        <button data-estado="archivado" onclick="cargarAvisos('archivado',this)">Archivados</button>
      </div>
      <div class="card"><div style="overflow-x:auto;"><table class="delta-table" id="tblAvisos"></table></div></div>
    </div>

    <!-- REPORTES -->
    <div id="tab-reportes" class="tab-panel">
      <div class="topbar"><h2 class="page-title">Reportes</h2></div>
      <div class="card-title" style="margin-bottom:8px;">Reportes Academicos</div>
      <div class="sub-nav">
        <button class="active" onclick="cargarReporte('reportePromedioMateria',this)">Promedio por Materia</button>
        <button onclick="cargarReporte('reportePromedioCarrera',this)">Promedio por Carrera</button>
        <button onclick="cargarReporte('reporteAprobadosReprobados',this,{orden:'aprobados'})">Mas Aprobados</button>
        <button onclick="cargarReporte('reporteAprobadosReprobados',this,{orden:'reprobados'})">Mas Reprobados</button>
        <button onclick="cargarReporte('reporteRiesgo',this)">Estudiantes en Riesgo</button>
      </div>
      <div class="card-title" style="margin-bottom:8px;margin-top:18px;">Reportes de Matricula</div>
      <div class="sub-nav">
        <button onclick="cargarReporte('reporteInscritos',this,{orden:'desc'})">Mas Inscritos</button>
        <button onclick="cargarReporte('reporteInscritos',this,{orden:'asc'})">Menos Inscritos</button>
        <button onclick="cargarReporte('reporteCupos',this)">Cupos Disponibles</button>
      </div>
      <div class="card-title" style="margin-bottom:8px;margin-top:18px;">Reportes de Profesores</div>
      <div class="sub-nav">
        <button onclick="cargarReporte('reporteCargaProfesores',this)">Carga Academica y Horas Semanales</button>
      </div>
      <div class="card-title" style="margin-bottom:8px;margin-top:18px;">Reportes de Asistencia</div>
      <div class="sub-nav">
        <button onclick="cargarReporte('reporteAsistenciaPorcentaje',this,{agrupar:'estudiante'})">% Asistencia por Estudiante</button>
        <button onclick="cargarReporte('reporteAsistenciaPorcentaje',this,{agrupar:'grupo'})">% Asistencia por Grupo</button>
        <button onclick="cargarReporte('reporteAsistenciaPorcentaje',this,{agrupar:'materia'})">% Asistencia por Materia</button>
      </div>
      <div class="card" style="margin-top:18px;"><div style="overflow-x:auto;"><table class="delta-table" id="tblReportes"></table></div></div>
    </div>

  </main>
</div>

<script>
var CTX = document.querySelector('meta[name="ctx"]').content;
var HAY_BD = <%= adm_hayBD %>;

function showToast(mensaje, tipo) {
  tipo = tipo || 'info';
  var iconos = { success:'✅', error:'❌', info:'ℹ️' };
  var container = document.getElementById('toastContainer');
  if (!container) { window.alert(mensaje); return; }
  var toast = document.createElement('div');
  toast.className = 'toast toast-' + tipo;
  toast.innerHTML = '<span class="toast-icon">'+(iconos[tipo]||iconos.info)+'</span><span class="toast-msg"></span><button class="toast-close">&times;</button>';
  toast.querySelector('.toast-msg').textContent = mensaje;
  var quitar = function(){ toast.classList.add('toast-out'); setTimeout(function(){ if(toast.parentNode) toast.parentNode.removeChild(toast); },200); };
  toast.querySelector('.toast-close').addEventListener('click', quitar);
  container.appendChild(toast);
  setTimeout(quitar, 4000);
}

function showConfirm(mensaje, onConfirm) {
  var overlay = document.getElementById('confirmOverlay');
  var msgEl = document.getElementById('confirmMsg');
  var okBtn = document.getElementById('confirmOkBtn');
  var cancelBtn = document.getElementById('confirmCancelBtn');
  if (!overlay) { if(window.confirm(mensaje)) onConfirm(); return; }
  msgEl.textContent = mensaje;
  overlay.classList.remove('hidden');
  function cerrar(){ overlay.classList.add('hidden'); okBtn.onclick=null; cancelBtn.onclick=null; }
  okBtn.onclick = function(){ cerrar(); onConfirm(); };
  cancelBtn.onclick = cerrar;
}

function doLogin() {
  var user = document.getElementById('loginUser').value.trim();
  var pass = document.getElementById('loginPass').value.trim();
  var err  = document.getElementById('loginError');
  if (!user || !pass) { err.style.display='block'; return; }
  var form = document.createElement('form');
  form.method = 'POST'; form.action = CTX + '/login';
  var fields = {username:user, password:pass, destino:'admin'};
  Object.keys(fields).forEach(function(k){ var inp=document.createElement('input'); inp.type='hidden'; inp.name=k; inp.value=fields[k]; form.appendChild(inp); });
  document.body.appendChild(form); form.submit();
}
document.getElementById('loginPass').addEventListener('keydown', function(e){ if(e.key==='Enter') doLogin(); });

function irTab(id, btn) {
  document.querySelectorAll('.tab-panel').forEach(function(p){ p.classList.remove('active'); });
  document.querySelectorAll('.nav-item').forEach(function(n){ n.classList.remove('active'); });
  document.getElementById('tab-'+id).classList.add('active');
  if (btn) btn.classList.add('active');
  if (id==='dashboard') cargarDashboard();
  if (id==='estudiantes') cargarEstudiantes();
  if (id==='profesores') cargarProfesores();
  if (id==='materias') cargarMaterias();
  if (id==='matricula') cargarSolicitudes('inscripcion', document.getElementById('btnSolInsc'));
  if (id==='limites') cargarLimitesSolicitudes();
  if (id==='sup-calificaciones') cargarSupervisionCalificaciones();
  if (id==='avisos') cargarAvisos('todos', document.querySelector('#filtrosAvisos button'));
  if (id==='reportes') cargarReporte('reportePromedioMateria', document.querySelector('#tab-reportes .sub-nav button'));
}

function cerrarSesion() { window.location.href = CTX + '/logout'; }

function cargarDashboard() {
  if (!HAY_BD) return;
  fetch(CTX+'/admin?accion=dashboard').then(function(r){ return r.json(); }).then(function(d) {
    document.getElementById('dashStats').innerHTML =
      statCard('&#127891;','Estudiantes',d.totalEstudiantes) +
      statCard('&#128104;&#8205;&#127979;','Profesores',d.totalProfesores) +
      statCard('&#128218;','Materias',d.totalMaterias) +
      statCard('&#128227;','Avisos Activos',d.avisosActivos) +
      statCard('&#128203;','Inscripciones Pendientes',d.pendInscripcion) +
      statCard('&#128465;','Retiros Pendientes',d.pendRetiro);
  });
}

function statCard(icon, label, val) {
  return '<div class="stat-card"><div class="stat-icon">'+icon+'</div><div><div class="stat-label">'+label+'</div><div class="stat-value">'+(val||0)+'</div></div></div>';
}

function cargarEstudiantes() {
  var q = 'accion=estudiantes'
    +'&nombre='+encodeURIComponent(document.getElementById('fEstNombre').value)
    +'&cedula='+encodeURIComponent(document.getElementById('fEstCedula').value)
    +'&carrera='+encodeURIComponent(document.getElementById('fEstCarrera').value)
    +'&materia='+encodeURIComponent(document.getElementById('fEstMateria').value);
  fetch(CTX+'/admin?'+q).then(function(r){ return r.json(); }).then(function(rows) {
    renderTable('tblEstudiantes',['Cedula','Nombre','Carrera','Semestre','Materias Activas'],
      rows,function(r){ return [r.cedula,r.nombre,r.carrera,r.semestre,r.materiasActivas]; });
  });
}

function cargarProfesores() {
  var q = 'accion=profesores'
    +'&nombre='+encodeURIComponent(document.getElementById('fProfNombre').value)
    +'&departamento='+encodeURIComponent(document.getElementById('fProfDepto').value)
    +'&materia='+encodeURIComponent(document.getElementById('fProfMateria').value);
  fetch(CTX+'/admin?'+q).then(function(r){ return r.json(); }).then(function(rows) {
    renderTable('tblProfesores',['Codigo','Nombre','Departamento','Materias que Imparte','Grupos Asignados','Creditos','Horas Semanales'],
      rows,function(r){ return [r.codigo,r.nombre,r.departamento,r.materiasLista||'-',r.grupos,r.creditos,(Math.round((r.horasSemanales||0)*10)/10)+' h']; });
  });
}

var profesoresParaSelect = [];

function cargarMaterias() {
  fetch(CTX+'/admin?accion=profesoresSimple').then(function(r){ return r.json(); }).then(function(profs) {
    profesoresParaSelect = profs;
    return fetch(CTX+'/admin?accion=materias');
  }).then(function(r){ return r.json(); }).then(function(rows) {
    var tbl = document.getElementById('tblMaterias');
    var html = '<thead><tr><th>Codigo</th><th>Materia</th><th>Creditos</th><th>Cupos</th><th>Inscritos</th><th>Profesor</th><th>Grupo</th><th>Acciones</th></tr></thead><tbody>';
    rows.forEach(function(r, idx) {
      // Creditos: solo lectura (FIX - antes era <input> editable)
      var creditosCell = '<span style="font-weight:700;">'+r.creditos+'</span>';
      var capacidadCell, profesorCell, accionesCell;
      if (r.grupoId != null) {
        capacidadCell = '<input class="edit-input" type="number" min="0" id="mCap_'+idx+'" value="'+r.capacidad+'">';
        var profOptions = '<option value="">— Sin asignar —</option>';
        profesoresParaSelect.forEach(function(p) {
          var sel = (r.profesorId != null && p.id === r.profesorId) ? ' selected' : '';
          profOptions += '<option value="'+p.id+'"'+sel+'>'+esc(p.nombre)+'</option>';
        });
        profesorCell = '<select class="edit-select" id="mProf_'+idx+'">'+profOptions+'</select>';
        // FIX: botón Guardar solo cuando hay grupo (cupos + profesor)
        accionesCell = '<button class="btn btn-primary btn-sm" onclick="guardarMateria('+idx+','+r.grupoId+')">Guardar</button>';
      } else {
        capacidadCell = '<span style="color:var(--text-soft);">-</span>';
        profesorCell  = '<span style="color:var(--text-soft);">Sin grupo</span>';
        // FIX: sin grupo no hay nada editable, no mostrar botón
        accionesCell  = '<span style="color:var(--text-soft);font-size:13px;">Sin grupo</span>';
      }
      html += '<tr>'
        +'<td>'+esc(r.codigo)+'</td>'
        +'<td><strong>'+esc(r.nombre)+'</strong></td>'
        +'<td>'+creditosCell+'</td>'
        +'<td>'+capacidadCell+'</td>'
        +'<td>'+r.inscritos+'</td>'
        +'<td>'+profesorCell+'</td>'
        +'<td>'+esc(r.grupo||'-')+'</td>'
        +'<td>'+accionesCell+'</td>'
        +'</tr>';
    });
    tbl.innerHTML = html + '</tbody>';
  }).catch(function(){ showToast('Error al cargar materias.', 'error'); });
}

// FIX: guardarMateria ya NO intenta leer créditos (eran un span, no un input).
// Solo guarda capacidad y profesor del grupo.
function guardarMateria(idx, grupoId) {
  var capacidad = parseInt(document.getElementById('mCap_'+idx).value, 10);
  if (isNaN(capacidad) || capacidad < 0) {
    showToast('Los cupos deben ser un numero mayor o igual a 0.', 'error');
    return;
  }

  // Advertencia si cupos < inscritos actuales
  var filaInscritos = document.getElementById('tblMaterias').rows[idx + 1];
  var inscritosActuales = filaInscritos ? (parseInt(filaInscritos.cells[4].textContent, 10) || 0) : 0;
  if (capacidad < inscritosActuales) {
    showToast('Aviso: el cupo ('+capacidad+') es menor a los inscritos actuales ('+inscritosActuales+'). No se retirara a nadie automaticamente.', 'info');
  }

  var peticiones = [
    fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
      body:'accion=actualizarCapacidad&grupoId='+grupoId+'&capacidad='+capacidad})
  ];

  var profesorId = document.getElementById('mProf_'+idx).value;
  if (profesorId) {
    peticiones.push(fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
      body:'accion=reasignarProfesor&grupoId='+grupoId+'&profesorId='+profesorId}));
  }

  Promise.all(peticiones)
    .then(function(responses){ return Promise.all(responses.map(function(r){ return r.json(); })); })
    .then(function(results) {
      var error = results.find(function(d){ return !d.ok; });
      if (error) { showToast('Error: '+(error.error||'No se pudo guardar.'), 'error'); return; }
      showToast('Cambios guardados correctamente.', 'success');
      cargarMaterias();
    })
    .catch(function(){ showToast('Error de conexion al guardar los cambios.', 'error'); });
}

function cargarLimitesSolicitudes() {
  fetch(CTX+'/admin?accion=limitesSolicitudes').then(function(r){ return r.json(); }).then(function(rows) {
    var container = document.getElementById('limites-container');
    if (!rows.length) {
      container.innerHTML = '<div class="card" style="text-align:center;color:var(--text-soft);padding:32px;">No hay estudiantes con inscripciones activas en este modulo.</div>';
      return;
    }

    // Agrupar filas por estudiante
    var porEstudiante = {};
    rows.forEach(function(r) {
      if (!porEstudiante[r.estudianteId]) {
        porEstudiante[r.estudianteId] = { nombre: r.estudiante, materias: [] };
      }
      porEstudiante[r.estudianteId].materias.push(r);
    });

    var html = '';
    Object.keys(porEstudiante).forEach(function(estId) {
      var est = porEstudiante[estId];
      html += '<div class="card" style="padding:0;overflow:hidden;">';
      // Cabecera del estudiante
      html += '<div style="background:var(--purple-bg);padding:16px 20px;border-bottom:2px solid var(--purple);display:flex;align-items:center;gap:12px;">'
            + '<div style="width:40px;height:40px;border-radius:50%;background:var(--purple);color:#fff;display:flex;align-items:center;justify-content:center;font-weight:800;font-size:18px;">'
            + esc(est.nombre.charAt(0)) + '</div>'
            + '<div><div style="font-weight:800;font-size:16px;color:var(--purple);">'+esc(est.nombre)+'</div>'
            + '<div style="font-size:12px;color:var(--text-soft);">'+est.materias.length+' materia(s) inscrita(s)</div></div>'
            + '</div>';
      // Tabla de materias
      html += '<div style="padding:16px 20px;">';
      html += '<table class="delta-table" style="margin-bottom:0;">'
            + '<thead><tr><th>Materia</th><th style="text-align:center;">Oportunidades Usadas</th><th style="text-align:center;">Disponibles</th><th>Acciones</th></tr></thead><tbody>';
      est.materias.forEach(function(r) {
        var usadas = r.usadas || 0;
        var limite = r.limite || 3;
        var disponibles = Math.max(0, limite - usadas);
        var bloqueada = usadas >= limite;
        var barColor = bloqueada ? 'var(--red)' : (usadas >= limite - 1 ? 'var(--amber)' : 'var(--green)');
        var tagUsadas = bloqueada
          ? '<span class="tag tag-red">'+usadas+' / '+limite+' &#128274; Bloqueada</span>'
          : (usadas > 0
            ? '<span class="tag tag-amber">'+usadas+' / '+limite+'</span>'
            : '<span class="tag tag-green">'+usadas+' / '+limite+'</span>');
        var tagDisp = bloqueada
          ? '<span class="tag tag-red">0</span>'
          : '<span class="tag tag-green">'+disponibles+'</span>';
        html += '<tr>'
          + '<td><strong>'+esc(r.materia)+'</strong><br><span style="font-size:12px;color:var(--text-soft);">'+esc(r.materiaCodigo)+'</span></td>'
          + '<td style="text-align:center;">'+tagUsadas+'</td>'
          + '<td style="text-align:center;">'+tagDisp+'</td>'
          + '<td style="display:flex;gap:6px;flex-wrap:wrap;">'
          + '<button class="btn btn-secondary btn-sm" title="Reiniciar a 3/3" onclick="reiniciarOportunidades('+r.estudianteId+','+r.grupoId+',\''+esc(est.nombre)+'\',\''+esc(r.materia)+'\')">&#128260; Reiniciar</button>'
          + '<button class="btn btn-success btn-sm" title="Autorizar +1 oportunidad adicional" onclick="autorizarOportunidad('+r.estudianteId+','+r.grupoId+',\''+esc(est.nombre)+'\',\''+esc(r.materia)+'\')">+1 Autorizar</button>'
          + '</td>'
          + '</tr>';
      });
      html += '</tbody></table></div></div>';
    });
    container.innerHTML = html;
  }).catch(function(){ showToast('Error al cargar las oportunidades.', 'error'); });
}

function reiniciarOportunidades(estudianteId, grupoId, nombreEst, nombreMat) {
  showConfirm('¿Reiniciar oportunidades de '+nombreEst+' en '+nombreMat+'?\n\nEl contador volvera a 0/3 y se podran hacer nuevas solicitudes.', function() {
    fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
      body:'accion=reiniciarOportunidades&estudianteId='+estudianteId+'&grupoId='+grupoId})
      .then(function(r){ return r.json(); })
      .then(function(d) {
        if (d.ok) { showToast('Oportunidades reiniciadas correctamente.', 'success'); cargarLimitesSolicitudes(); }
        else showToast('Error: '+(d.error||'No se pudo reiniciar.'), 'error');
      }).catch(function(){ showToast('Error de conexion.', 'error'); });
  });
}

function autorizarOportunidad(estudianteId, grupoId, nombreEst, nombreMat) {
  showConfirm('¿Autorizar +1 oportunidad adicional para '+nombreEst+' en '+nombreMat+'?', function() {
    fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
      body:'accion=autorizarOportunidad&estudianteId='+estudianteId+'&grupoId='+grupoId})
      .then(function(r){ return r.json(); })
      .then(function(d) {
        if (d.ok) { showToast('+1 oportunidad autorizada correctamente.', 'success'); cargarLimitesSolicitudes(); }
        else showToast('Error: '+(d.error||'No se pudo autorizar.'), 'error');
      }).catch(function(){ showToast('Error de conexion.', 'error'); });
  });
}

var tipoSolicitudActual = 'inscripcion';
function cargarSolicitudes(tipo, btn) {
  tipoSolicitudActual = tipo;
  document.querySelectorAll('#tab-matricula .sub-nav button').forEach(function(b){ b.classList.remove('active'); });
  if (btn) btn.classList.add('active');
  fetch(CTX+'/matricula?accion=pendientes&tipo='+tipo).then(function(r){ return r.json(); }).then(function(rows) {
    var tbl = document.getElementById('tblSolicitudes');
    if (!rows.length) {
      tbl.innerHTML = '<tbody><tr><td colspan="6" style="text-align:center;color:#6b7e96;padding:20px;">No hay solicitudes pendientes.</td></tr></tbody>';
      return;
    }
    var html = '<thead><tr><th>Estudiante</th><th>Materia</th><th>Codigo</th><th>Grupo</th><th>Fecha</th><th>Acciones</th></tr></thead><tbody>';
    rows.forEach(function(s) {
      html += '<tr><td>'+esc(s.estudiante)+'</td><td>'+esc(s.materiaNombre)+'</td><td>'+esc(s.materiaCodigo)+'</td>'
        +'<td>'+esc(s.grupo||'-')+'</td><td>'+esc(s.fecha)+'</td><td>'
        +'<button class="btn btn-success btn-sm" onclick="resolverSolicitud('+s.id+',\'aprobar\')">Aprobar</button> '
        +'<button class="btn btn-danger btn-sm" onclick="resolverSolicitud('+s.id+',\'rechazar\')">Rechazar</button>'
        +'</td></tr>';
    });
    tbl.innerHTML = html + '</tbody>';
  });
}

function resolverSolicitud(id, accion) {
  var msg = accion === 'aprobar' ? '¿Aprobar esta solicitud?' : '¿Rechazar esta solicitud?';
  showConfirm(msg, function() {
    var body = 'accion='+accion+'&id='+id;
    if (accion === 'rechazar') body += '&motivo='+encodeURIComponent('Rechazada por administracion');
    fetch(CTX+'/matricula', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:body})
      .then(function(r){ return r.json(); })
      .then(function(d){
        if (d.ok) { cargarSolicitudes(tipoSolicitudActual, null); cargarDashboard(); showToast(accion==='aprobar'?'Solicitud aprobada.':'Solicitud rechazada.','success'); }
        else showToast('Error: '+(d.error||'No se pudo procesar'),'error');
      })
      .catch(function(){ showToast('Error de conexion al procesar la solicitud.', 'error'); });
  });
}

var avisosData = {};

function cargarAvisos(estado, btn) {
  if (btn) {
    document.querySelectorAll('#filtrosAvisos button').forEach(function(b){ b.classList.remove('active'); });
    btn.classList.add('active');
  }
  var url = CTX+'/admin?accion=avisos';
  if (estado && estado !== 'todos') url += '&estado='+estado;
  fetch(url).then(function(r){ return r.json(); }).then(function(rows) {
    avisosData = {};
    rows.forEach(function(a){ avisosData[a.id] = a; });
    var tbl = document.getElementById('tblAvisos');
    if (!rows.length) {
      tbl.innerHTML = '<tbody><tr><td colspan="6" style="text-align:center;color:var(--text-soft);padding:20px;">No hay avisos.</td></tr></tbody>';
      return;
    }
    var html = '<thead><tr><th>Titulo</th><th>Profesor</th><th>Grupo</th><th>Fecha</th><th>Estado</th><th>Acciones</th></tr></thead><tbody>';
    rows.forEach(function(a) {
      var esActivo = (a.estado === 'activo');
      var estadoTag = esActivo ? '<span class="tag tag-green">Activo</span>' : '<span class="tag tag-gray">Archivado</span>';
      var acciones = '<button class="btn btn-secondary btn-sm" onclick="abrirEditarAviso('+a.id+')">Editar</button> ';
      if (esActivo) acciones += '<button class="btn btn-secondary btn-sm" onclick="archivarAviso('+a.id+')">Archivar</button>';
      else acciones += '<button class="btn btn-success btn-sm" onclick="restaurarAviso('+a.id+')">Restaurar</button>';
      html += '<tr>'
        +'<td><strong>'+esc(a.titulo)+'</strong></td>'
        +'<td>'+esc(a.profesor||'Institucional')+'</td>'
        +'<td>'+esc(a.grupo||'Todos')+'</td>'
        +'<td>'+esc(a.fecha)+'</td>'
        +'<td>'+estadoTag+'</td>'
        +'<td>'+acciones+'</td></tr>';
    });
    tbl.innerHTML = html + '</tbody>';
  }).catch(function(){ showToast('Error al cargar los avisos.', 'error'); });
}

function filtroAvisosActual() {
  var btn = document.querySelector('#filtrosAvisos button.active');
  return btn ? (btn.dataset.estado || 'todos') : 'todos';
}

function archivarAviso(id) {
  showConfirm('¿Archivar este aviso? Podras restaurarlo despues.', function() {
    fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'accion=archivarAviso&id='+id})
      .then(function(r){ return r.json(); })
      .then(function(d){
        if (d.ok) { cargarAvisos(filtroAvisosActual(), document.querySelector('#filtrosAvisos button.active')); showToast('Aviso archivado.','success'); }
        else showToast('Error: '+(d.error||'No se pudo archivar.'),'error');
      }).catch(function(){ showToast('Error de conexion.','error'); });
  });
}

function restaurarAviso(id) {
  fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'accion=restaurarAviso&id='+id})
    .then(function(r){ return r.json(); })
    .then(function(d){
      if (d.ok) { cargarAvisos(filtroAvisosActual(), document.querySelector('#filtrosAvisos button.active')); showToast('Aviso restaurado.','success'); }
      else showToast('Error: '+(d.error||'No se pudo restaurar.'),'error');
    }).catch(function(){ showToast('Error de conexion.','error'); });
}

function abrirEditarAviso(id) {
  var a = avisosData[id];
  if (!a) return;
  document.getElementById('editAvisoTitulo').value = a.titulo || '';
  document.getElementById('editAvisoCuerpo').value = a.cuerpo || '';
  document.getElementById('editAvisoEstado').value = a.estado || 'activo';
  document.getElementById('editAvisoOverlay').dataset.avisoId = id;
  document.getElementById('editAvisoOverlay').classList.remove('hidden');
}

function cerrarEditarAviso() { document.getElementById('editAvisoOverlay').classList.add('hidden'); }

function guardarAviso() {
  var overlay = document.getElementById('editAvisoOverlay');
  var id = overlay.dataset.avisoId;
  var titulo = document.getElementById('editAvisoTitulo').value.trim();
  var cuerpo = document.getElementById('editAvisoCuerpo').value.trim();
  var estado = document.getElementById('editAvisoEstado').value;
  if (!titulo) { showToast('El titulo no puede estar vacio.', 'error'); return; }
  fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:'accion=actualizarAviso&id='+id+'&titulo='+encodeURIComponent(titulo)+'&cuerpo='+encodeURIComponent(cuerpo)+'&estado='+estado})
    .then(function(r){ return r.json(); })
    .then(function(d){
      if (d.ok) { cerrarEditarAviso(); cargarAvisos(filtroAvisosActual(), document.querySelector('#filtrosAvisos button.active')); showToast('Aviso actualizado.','success'); }
      else showToast('Error: '+(d.error||'No se pudo guardar.'),'error');
    }).catch(function(){ showToast('Error de conexion.','error'); });
}

var COMPONENTE_LABEL = {parcial1:'Parcial 1', parcial2:'Parcial 2', proyecto:'Proyecto', examen_final:'Examen Final'};

function cargarSupervisionCalificaciones() {
  fetch(CTX+'/admin?accion=supervisionCalificaciones').then(function(r){ return r.json(); }).then(function(rows) {
    var container = document.getElementById('contenedorCalificaciones');
    if (!rows.length) {
      container.innerHTML = '<div class="card" style="text-align:center;color:var(--text-soft);padding:32px;">No hay notas registradas para Calidad de Software.</div>';
      return;
    }

    // Agrupar por inscripcionId (un estudiante = un grupo de componentes)
    var porInscripcion = {};
    rows.forEach(function(r) {
      if (!porInscripcion[r.inscripcionId]) {
        porInscripcion[r.inscripcionId] = {
          inscripcionId: r.inscripcionId,
          estudiante: r.estudiante,
          materia: r.materia,
          materiaCodigo: r.materiaCodigo,
          grupo: r.grupo,
          componentes: []
        };
      }
      porInscripcion[r.inscripcionId].componentes.push(r);
    });

    var html = '';
    Object.keys(porInscripcion).forEach(function(inscId) {
      var est = porInscripcion[inscId];
      var inicial = esc(est.estudiante.charAt(0).toUpperCase());

      // Calcular promedio visual con los componentes disponibles
      var notas = {};
      est.componentes.forEach(function(c) { notas[c.componente] = c.notaActual; });
      var tieneAlguna = notas.parcial1!=null || notas.parcial2!=null || notas.proyecto!=null || notas.examen_final!=null;
      var promedio = '-';
      if (tieneAlguna) {
        var p = ((notas.parcial1||0)*0.25 + (notas.parcial2||0)*0.25 + (notas.proyecto||0)*0.20 + (notas.examen_final||0)*0.30);
        promedio = Math.round(p * 10) / 10;
      }

      html += '<div class="card" style="padding:0;overflow:hidden;margin-bottom:20px;">';
      // Cabecera del estudiante
      html += '<div style="background:var(--purple-light);padding:16px 20px;border-bottom:2px solid #e8edf5;display:flex;align-items:center;gap:12px;">'
            + '<div style="width:42px;height:42px;border-radius:50%;background:var(--purple);color:#fff;display:flex;align-items:center;justify-content:center;font-weight:800;font-size:18px;">'
            + inicial + '</div>'
            + '<div style="flex:1;">'
            + '<div style="font-weight:800;font-size:16px;color:var(--purple);">'+esc(est.estudiante)+'</div>'
            + '<div style="font-size:12px;color:var(--text-soft);">'+esc(est.materia)+' ('+esc(est.materiaCodigo)+') &bull; Grupo: '+esc(est.grupo||'-')+'</div>'
            + '</div>'
            + '<div style="text-align:right;">'
            + '<div style="font-size:11px;color:var(--text-soft);font-weight:700;text-transform:uppercase;letter-spacing:.04em;">Promedio</div>'
            + '<div style="font-size:22px;font-weight:800;color:var(--purple);">'+promedio+'</div>'
            + '</div>'
            + '</div>';

      // Tabla de componentes
      html += '<div style="padding:16px 20px;">';
      html += '<table class="delta-table" style="margin-bottom:0;">'
            + '<thead><tr>'
            + '<th>Componente</th>'
            + '<th style="text-align:center;">Nota</th>'
            + '<th>Modificaciones</th>'
            + '<th>Acciones</th>'
            + '</tr></thead><tbody>';

      est.componentes.forEach(function(r) {
        var notaTxt = (r.notaActual != null) ? r.notaActual : '<span style="color:var(--text-soft);">Sin registrar</span>';
        var compLabel = COMPONENTE_LABEL[r.componente] || r.componente;
        var modTag;
        if (r.modificaciones === 0) modTag = '<span class="tag tag-green">0 / '+r.limite+' sin cambios</span>';
        else if (r.enLimite) modTag = '<span class="tag tag-red">'+r.modificaciones+' / '+r.limite+' limite alcanzado</span>';
        else modTag = '<span class="tag tag-amber">'+r.modificaciones+' / '+r.limite+'</span>';

        html += '<tr>'
          + '<td><strong>'+esc(compLabel)+'</strong></td>'
          + '<td style="text-align:center;font-weight:800;">'+notaTxt+'</td>'
          + '<td>'+modTag+'</td>'
          + '<td style="display:flex;gap:6px;flex-wrap:wrap;">'
          + '<button class="btn btn-secondary btn-sm" onclick="verHistorialNota('+r.inscripcionId+',\''+r.componente+'\')">Ver historial</button>';
        if (r.enLimite) html += '<button class="btn btn-success btn-sm" onclick="autorizarModificacion('+r.inscripcionId+',\''+r.componente+'\')">Autorizar +1</button>';
        if (r.modificaciones > 0) html += '<button class="btn btn-danger btn-sm" onclick="reiniciarModificaciones('+r.inscripcionId+',\''+r.componente+'\')">Reiniciar</button>';
        html += '</td></tr>';
      });

      html += '</tbody></table></div></div>';
    });

    container.innerHTML = html;
  }).catch(function(){ showToast('Error al cargar supervision de calificaciones.', 'error'); });
}

function verHistorialNota(inscripcionId, componente) {
  fetch(CTX+'/admin?accion=historialNota&inscripcionId='+inscripcionId+'&componente='+encodeURIComponent(componente))
    .then(function(r){ return r.json(); })
    .then(function(rows) {
      var card = document.getElementById('historialCard');
      var tbl = document.getElementById('tblHistorialNota');
      var html = '<thead><tr><th>Fecha</th><th>Nota Anterior</th><th>Nota Nueva</th></tr></thead><tbody>';
      if (!rows.length) html += '<tr><td colspan="3" style="text-align:center;color:var(--text-soft);">Sin historial de modificaciones.</td></tr>';
      else rows.forEach(function(h){ html += '<tr><td>'+esc(h.fecha)+'</td><td>'+(h.notaAnterior!=null?h.notaAnterior:'-')+'</td><td>'+h.notaNueva+'</td></tr>'; });
      tbl.innerHTML = html + '</tbody>';
      card.style.display = '';
      card.scrollIntoView({behavior:'smooth', block:'nearest'});
    }).catch(function(){ showToast('Error al cargar el historial.', 'error'); });
}

function autorizarModificacion(inscripcionId, componente) {
  showConfirm('¿Autorizar una modificacion adicional para esta nota?', function() {
    fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
      body:'accion=autorizarModificacion&inscripcionId='+inscripcionId+'&componente='+encodeURIComponent(componente)+'&cantidad=1'})
      .then(function(r){ return r.json(); })
      .then(function(d){
        if (d.ok) { showToast('Modificacion adicional autorizada.','success'); cargarSupervisionCalificaciones(); }
        else showToast('Error: '+(d.error||'No se pudo autorizar.'),'error');
      }).catch(function(){ showToast('Error de conexion.','error'); });
  });
}

function reiniciarModificaciones(inscripcionId, componente) {
  var compLabel = COMPONENTE_LABEL[componente] || componente;
  showConfirm('¿Reiniciar el historial de modificaciones para '+compLabel+'?\n\nEl profesor volvera a tener el limite completo disponible.', function() {
    fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
      body:'accion=reiniciarModificaciones&inscripcionId='+inscripcionId+'&componente='+encodeURIComponent(componente)})
      .then(function(r){ return r.json(); })
      .then(function(d){
        if (d.ok) { showToast('Modificaciones reiniciadas.','success'); cargarSupervisionCalificaciones(); }
        else showToast('Error: '+(d.error||'No se pudo reiniciar.'),'error');
      }).catch(function(){ showToast('Error de conexion.','error'); });
  });
}

var REPORTE_COL_LABEL = {
  nombre:'Nombre', codigo:'Codigo', carrera:'Carrera', promedio:'Promedio',
  materias_evaluadas:'Materias Evaluadas', estudiante:'Estudiante', materia:'Materia',
  promedio_final:'Promedio Final', estado_academico:'Estado', total_evaluados:'Total Evaluados',
  aprobados:'Aprobados', reprobados:'Reprobados', inscritos:'Inscritos', capacidad:'Cupos Totales',
  codigo_grupo:'Grupo', cupos_disponibles:'Cupos Disponibles', profesor:'Profesor',
  departamento:'Departamento', grupos_asignados:'Grupos Asignados', creditos_totales:'Creditos Totales',
  horas_semanales:'Horas Semanales', id:'ID', total:'Total Clases', presentes:'Presentes',
  porcentaje:'% Asistencia', grupo:'Grupo'
};

function cargarReporte(accion, btn, extraParams) {
  document.querySelectorAll('#tab-reportes .sub-nav button').forEach(function(b){ b.classList.remove('active'); });
  if (btn) btn.classList.add('active');
  var q = 'accion='+accion;
  if (extraParams) Object.keys(extraParams).forEach(function(k){ q += '&'+k+'='+encodeURIComponent(extraParams[k]); });
  fetch(CTX+'/admin?'+q).then(function(r){ return r.json(); }).then(function(rows) {
    if (!rows.length) { document.getElementById('tblReportes').innerHTML = '<tbody><tr><td style="text-align:center;color:var(--text-soft);padding:20px;">Sin datos para este reporte.</td></tr></tbody>'; return; }
    var keys = Object.keys(rows[0]);
    var html = '<thead><tr>'+keys.map(function(k){ return '<th>'+(REPORTE_COL_LABEL[k]||k)+'</th>'; }).join('')+'</tr></thead><tbody>';
    rows.forEach(function(r) {
      html += '<tr>'+keys.map(function(k){
        var v = r[k];
        if (k==='porcentaje' && v!=null) v = v+'%';
        if (k==='estado_academico' && v!=null) {
          var cls = v==='RIESGO'?'tag-red':(v==='ALERTA'?'tag-amber':'tag-green');
          return '<td><span class="tag '+cls+'">'+esc(String(v))+'</span></td>';
        }
        return '<td>'+esc(String(v!=null?v:'-'))+'</td>';
      }).join('')+'</tr>';
    });
    document.getElementById('tblReportes').innerHTML = html + '</tbody>';
  }).catch(function(){ showToast('Error al cargar el reporte.', 'error'); });
}

function renderTable(id, headers, rows, mapFn) {
  var html = '<thead><tr>'+headers.map(function(h){ return '<th>'+h+'</th>'; }).join('')+'</tr></thead><tbody>';
  if (!rows.length) html += '<tr><td colspan="'+headers.length+'" style="text-align:center;color:#6b7e96;">Sin resultados</td></tr>';
  rows.forEach(function(r){ html += '<tr>'+mapFn(r).map(function(c){ return '<td>'+esc(String(c!=null?c:''))+'</td>'; }).join('')+'</tr>'; });
  document.getElementById(id).innerHTML = html + '</tbody>';
}

function esc(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

if (HAY_BD) cargarDashboard();
</script>
</body>
</html>

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
.filter-row { display:flex; gap:10px; flex-wrap:wrap; margin-bottom:16px; }
.filter-row input, .filter-row select { padding:9px 12px; border:2px solid #e2e8f0;
  border-radius:8px; font-family:inherit; font-size:14px; }
.sub-nav { display:flex; gap:8px; margin-bottom:16px; }
.sub-nav button { padding:8px 16px; border:2px solid #e2e8f0; background:#fff;
  border-radius:8px; font-family:inherit; font-weight:700; cursor:pointer; font-size:13px; }
.sub-nav button.active { border-color:var(--purple); background:var(--purple-light); color:var(--purple); }
@media(max-width:900px) { .stats-4 { grid-template-columns:1fr 1fr; } .main-content { padding:20px; } }
</style>
</head>
<body>

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
        <input id="fEstMateria" placeholder="Materia inscrita" onkeyup="if(event.key==='Enter')cargarEstudiantes()">
        <button class="btn btn-primary btn-sm" onclick="cargarEstudiantes()">Filtrar</button>
      </div>
      <div class="card"><div style="overflow-x:auto;"><table class="delta-table" id="tblEstudiantes"></table></div></div>
    </div>

    <!-- PROFESORES -->
    <div id="tab-profesores" class="tab-panel">
      <div class="topbar"><h2 class="page-title">Gestion de Profesores</h2></div>
      <div class="filter-row">
        <input id="fProfNombre" placeholder="Nombre">
        <input id="fProfDepto" placeholder="Departamento">
        <input id="fProfMateria" placeholder="Materia">
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

    <!-- AVISOS -->
    <div id="tab-avisos" class="tab-panel">
      <div class="topbar"><h2 class="page-title">Gestion de Avisos</h2></div>
      <div class="card"><div style="overflow-x:auto;"><table class="delta-table" id="tblAvisos"></table></div></div>
    </div>

    <!-- REPORTES -->
    <div id="tab-reportes" class="tab-panel">
      <div class="topbar"><h2 class="page-title">Reportes</h2></div>
      <div class="sub-nav">
        <button class="active" onclick="cargarReporte('reportePromedioMateria',this)">Promedio por Materia</button>
        <button onclick="cargarReporte('reporteRiesgo',this)">Estudiantes en Riesgo</button>
        <button onclick="cargarReporte('reporteInscritos',this)">Inscritos por Materia</button>
      </div>
      <div class="card"><div style="overflow-x:auto;"><table class="delta-table" id="tblReportes"></table></div></div>
    </div>

  </main>
</div>

<script>
var CTX = document.querySelector('meta[name="ctx"]').content;
var HAY_BD = <%= adm_hayBD %>;

function doLogin() {
  var user = document.getElementById('loginUser').value.trim();
  var pass = document.getElementById('loginPass').value.trim();
  var err  = document.getElementById('loginError');
  if (!user || !pass) { err.style.display='block'; return; }
  var params = 'username='+encodeURIComponent(user)+'&password='+encodeURIComponent(pass)+'&destino=admin';
  fetch(CTX+'/login', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:params, redirect:'follow'})
    .then(function(r) {
      if (r.url && r.url.indexOf('portal_administrador') !== -1 && r.url.indexOf('error') === -1) {
        window.location.href = r.url;
      } else {
        err.style.display='block';
      }
    }).catch(function(){ err.style.display='block'; });
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
  if (id==='avisos') cargarAvisos();
  if (id==='reportes') cargarReporte('reportePromedioMateria', document.querySelector('#tab-reportes .sub-nav button'));
}

function cerrarSesion() {
  window.location.href = CTX + '/logout';
}

function cargarDashboard() {
  if (!HAY_BD) return;
  fetch(CTX+'/admin?accion=dashboard')
    .then(function(r){ return r.json(); })
    .then(function(d) {
      document.getElementById('dashStats').innerHTML =
        statCard('&#127891;', 'Estudiantes', d.totalEstudiantes) +
        statCard('&#128104;&#8205;&#127979;', 'Profesores', d.totalProfesores) +
        statCard('&#128218;', 'Materias', d.totalMaterias) +
        statCard('&#128227;', 'Avisos Activos', d.avisosActivos) +
        statCard('&#128203;', 'Inscripciones Pendientes', d.pendInscripcion) +
        statCard('&#128465;', 'Retiros Pendientes', d.pendRetiro);
    });
}

function statCard(icon, label, val) {
  return '<div class="stat-card"><div class="stat-icon">'+icon+'</div><div><div class="stat-label">'+label+'</div><div class="stat-value">'+(val||0)+'</div></div></div>';
}

function cargarEstudiantes() {
  var q = 'accion=estudiantes'
    + '&nombre=' + encodeURIComponent(document.getElementById('fEstNombre').value)
    + '&cedula=' + encodeURIComponent(document.getElementById('fEstCedula').value)
    + '&carrera=' + encodeURIComponent(document.getElementById('fEstCarrera').value)
    + '&materia=' + encodeURIComponent(document.getElementById('fEstMateria').value);
  fetch(CTX+'/admin?'+q).then(function(r){ return r.json(); }).then(function(rows) {
    renderTable('tblEstudiantes', ['Cedula','Nombre','Carrera','Semestre','Materias Activas'],
      rows, function(r){ return [r.cedula,r.nombre,r.carrera,r.semestre,r.materiasActivas]; });
  });
}

function cargarProfesores() {
  var q = 'accion=profesores'
    + '&nombre=' + encodeURIComponent(document.getElementById('fProfNombre').value)
    + '&departamento=' + encodeURIComponent(document.getElementById('fProfDepto').value)
    + '&materia=' + encodeURIComponent(document.getElementById('fProfMateria').value);
  fetch(CTX+'/admin?'+q).then(function(r){ return r.json(); }).then(function(rows) {
    renderTable('tblProfesores', ['Cedula','Nombre','Departamento','Grupos','Creditos'],
      rows, function(r){ return [r.cedula,r.nombre,r.departamento,r.grupos,r.creditos]; });
  });
}

function cargarMaterias() {
  fetch(CTX+'/admin?accion=materias').then(function(r){ return r.json(); }).then(function(rows) {
    var tbl = document.getElementById('tblMaterias');
    var html = '<thead><tr><th>Codigo</th><th>Materia</th><th>Creditos</th><th>Capacidad</th><th>Inscritos</th><th>Profesor</th><th>Grupo</th></tr></thead><tbody>';
    rows.forEach(function(r) {
      html += '<tr><td>'+esc(r.codigo)+'</td><td><strong>'+esc(r.nombre)+'</strong></td>'
        + '<td>'+r.creditos+'</td><td>'+r.capacidad+'</td><td>'+r.inscritos+'</td>'
        + '<td>'+esc(r.profesor||'-')+'</td><td>'+esc(r.grupo||'-')+'</td></tr>';
    });
    tbl.innerHTML = html + '</tbody>';
  });
}

var tipoSolicitudActual = 'inscripcion';
function cargarSolicitudes(tipo, btn) {
  tipoSolicitudActual = tipo;
  document.querySelectorAll('#tab-matricula .sub-nav button').forEach(function(b){ b.classList.remove('active'); });
  if (btn) btn.classList.add('active');
  fetch(CTX+'/matricula?accion=pendientes&tipo='+tipo)
    .then(function(r){ return r.json(); })
    .then(function(rows) {
      var tbl = document.getElementById('tblSolicitudes');
      if (!rows.length) {
        tbl.innerHTML = '<tbody><tr><td colspan="6" style="text-align:center;color:#6b7e96;padding:20px;">No hay solicitudes pendientes.</td></tr></tbody>';
        return;
      }
      var html = '<thead><tr><th>Estudiante</th><th>Materia</th><th>Codigo</th><th>Grupo</th><th>Fecha</th><th>Acciones</th></tr></thead><tbody>';
      rows.forEach(function(s) {
        html += '<tr><td>'+esc(s.estudiante)+'</td><td>'+esc(s.materiaNombre)+'</td><td>'+esc(s.materiaCodigo)+'</td>'
          + '<td>'+esc(s.grupo||'-')+'</td><td>'+esc(s.fecha)+'</td><td>'
          + '<button class="btn btn-success btn-sm" onclick="resolverSolicitud('+s.id+',\'aprobar\')">Aprobar</button> '
          + '<button class="btn btn-danger btn-sm" onclick="resolverSolicitud('+s.id+',\'rechazar\')">Rechazar</button>'
          + '</td></tr>';
      });
      tbl.innerHTML = html + '</tbody>';
    });
}

function resolverSolicitud(id, accion) {
  var msg = accion === 'aprobar' ? 'Aprobar esta solicitud?' : 'Rechazar esta solicitud?';
  if (!confirm(msg)) return;
  var body = 'accion='+accion+'&id='+id;
  if (accion === 'rechazar') body += '&motivo=' + encodeURIComponent('Rechazada por administracion');
  fetch(CTX+'/matricula', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:body})
    .then(function(r){ return r.json(); })
    .then(function(d) {
      if (d.ok) { cargarSolicitudes(tipoSolicitudActual, null); cargarDashboard(); }
      else alert('Error: ' + (d.error || 'No se pudo procesar'));
    });
}

function cargarAvisos() {
  fetch(CTX+'/admin?accion=avisos').then(function(r){ return r.json(); }).then(function(rows) {
    var tbl = document.getElementById('tblAvisos');
    var html = '<thead><tr><th>Titulo</th><th>Profesor</th><th>Grupo</th><th>Fecha</th><th>Estado</th><th>Acciones</th></tr></thead><tbody>';
    rows.forEach(function(a) {
      var estado = a.activo ? '<span class="tag tag-green">Activo</span>' : '<span class="tag tag-red">Inactivo</span>';
      html += '<tr><td><strong>'+esc(a.titulo)+'</strong></td><td>'+esc(a.profesor||'Institucional')+'</td>'
        + '<td>'+esc(a.grupo||'Todos')+'</td><td>'+esc(a.fecha)+'</td><td>'+estado+'</td><td>';
      if (a.activo) html += '<button class="btn btn-secondary btn-sm" onclick="desactivarAviso('+a.id+')">Desactivar</button> ';
      html += '<button class="btn btn-danger btn-sm" onclick="eliminarAviso('+a.id+')">Eliminar</button></td></tr>';
    });
    tbl.innerHTML = html + '</tbody>';
  });
}

function desactivarAviso(id) {
  if (!confirm('Desactivar este aviso?')) return;
  fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'accion=desactivarAviso&id='+id})
    .then(function(){ cargarAvisos(); });
}

function eliminarAviso(id) {
  if (!confirm('Eliminar permanentemente este aviso?')) return;
  fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'accion=eliminarAviso&id='+id})
    .then(function(){ cargarAvisos(); });
}

function cargarReporte(accion, btn) {
  document.querySelectorAll('#tab-reportes .sub-nav button').forEach(function(b){ b.classList.remove('active'); });
  if (btn) btn.classList.add('active');
  fetch(CTX+'/admin?accion='+accion).then(function(r){ return r.json(); }).then(function(rows) {
    if (!rows.length) { document.getElementById('tblReportes').innerHTML = '<tbody><tr><td>Sin datos</td></tr></tbody>'; return; }
    var keys = Object.keys(rows[0]);
    var html = '<thead><tr>' + keys.map(function(k){ return '<th>'+k+'</th>'; }).join('') + '</tr></thead><tbody>';
    rows.forEach(function(r) {
      html += '<tr>' + keys.map(function(k){ return '<td>'+esc(String(r[k]!=null?r[k]:''))+'</td>'; }).join('') + '</tr>';
    });
    document.getElementById('tblReportes').innerHTML = html + '</tbody>';
  });
}

function renderTable(id, headers, rows, mapFn) {
  var html = '<thead><tr>' + headers.map(function(h){ return '<th>'+h+'</th>'; }).join('') + '</tr></thead><tbody>';
  if (!rows.length) html += '<tr><td colspan="'+headers.length+'" style="text-align:center;color:#6b7e96;">Sin resultados</td></tr>';
  rows.forEach(function(r) {
    html += '<tr>' + mapFn(r).map(function(c){ return '<td>'+esc(String(c!=null?c:''))+'</td>'; }).join('') + '</tr>';
  });
  document.getElementById(id).innerHTML = html + '</tbody>';
}

function esc(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

if (HAY_BD) cargarDashboard();
</script>
</body>
</html>

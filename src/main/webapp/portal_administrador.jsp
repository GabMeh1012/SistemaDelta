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
  --blue:#1a56a0; --green:#15803d; --amber:#b45309; --red:#dc2626; --red-bg:#fee2e2;
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
.btn-warning { background:var(--amber); color:#fff; }
.btn-sm { padding:6px 12px; font-size:12px; }
.btn-full { width:100%; padding:13px; font-size:15px; }
.login-hint { text-align:center; font-size:12px; color:var(--text-soft); margin-top:14px; }
.login-switch { text-align:center; font-size:13px; margin-top:16px; color:var(--text-soft); }
.login-switch a { color:var(--purple); font-weight:700; text-decoration:none; }

/* PORTAL */
.portal { display:flex; min-height:100vh; }
.sidebar { width:var(--sidebar-w); background:#fff; border-right:2px solid #e8edf5;
  position:fixed; top:0; left:0; height:100vh; overflow-y:auto; z-index:100;
  display:flex; flex-direction:column; }
.sidebar-footer { margin-top:auto; padding:16px 14px; border-top:2px solid #e8edf5; }
.logout-btn { display:flex; align-items:center; gap:10px; padding:12px 14px;
  border-radius:var(--radius-sm); font-size:14px; font-weight:700; color:var(--red);
  cursor:pointer; background:var(--red-bg); border:1.5px solid #fca5a5;
  width:100%; font-family:'Nunito',sans-serif; transition:all .18s; }
.logout-btn:hover { background:#fecaca; }
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
.stat-card.clickable { cursor:pointer; transition:border-color .15s, transform .1s; }
.stat-card.clickable:hover { border-color:var(--purple); transform:translateY(-2px); }
.attn-strip { display:flex; flex-direction:column; gap:8px; margin-bottom:20px; }
.attn-item { display:flex; align-items:center; gap:12px; width:100%; padding:12px 16px;
  border:none; border-radius:var(--radius-sm); font-family:inherit; font-size:13px; text-align:left; cursor:pointer; }
.attn-item.bad { background:var(--red-bg); color:#7f1d1d; }
.attn-item.warn { background:#fef3c7; color:#78350f; }
.attn-item.ok { background:#dcfce7; color:#14532d; cursor:default; }
.attn-item .attn-n { font-weight:800; font-size:16px; width:28px; text-align:center; flex-shrink:0; }
.attn-item .attn-txt { flex:1; }
.attn-item .attn-go { font-size:11px; font-weight:700; color:var(--purple); white-space:nowrap; }
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
.salon-group{background:#fff;border:2px solid #e8edf5;border-radius:var(--radius-sm);margin-bottom:14px;overflow:hidden;}
.salon-group summary{list-style:none;cursor:pointer;display:flex;align-items:center;justify-content:space-between;gap:12px;padding:12px 16px;background:var(--purple-light);}
.salon-group summary::-webkit-details-marker{display:none;}
.salon-group summary .chev{display:inline-block;color:var(--purple-dark);transition:transform .15s;}
.salon-group[open] summary .chev{transform:rotate(90deg);}
.salon-aula{font-family:Consolas,"SF Mono",monospace;font-weight:800;color:var(--purple-dark);background:#fff;border:1px solid #ddd0f7;padding:3px 10px;border-radius:8px;font-size:13px;}
.salon-carrera{font-size:12.5px;font-weight:700;color:var(--purple-dark);}
.salon-meta{font-size:12px;color:var(--text-soft);}
.mat-row-grid{display:grid;grid-template-columns:90px 1.6fr 62px 150px 105px 55px 1.3fr 110px 90px;gap:10px;align-items:center;padding:10px 16px;border-top:1px solid #f0f4fa;font-size:13px;}
.mat-row-grid:first-of-type{border-top:none;}
.mat-row-head{font-size:11px;font-weight:800;color:var(--text-soft);text-transform:uppercase;background:#f8f9fc;}
.mat-row-grid .mono-cell{font-family:Consolas,"SF Mono",monospace;font-size:12px;color:var(--text-soft);}
@media (max-width:1100px){ .mat-row-grid{grid-template-columns:1fr;gap:4px;padding:12px 16px;} .mat-row-head{display:none;} }
.aviso-field-label{display:block;font-size:13px;font-weight:700;color:var(--text-soft);margin-bottom:6px;}
.aviso-field-input{width:100%;padding:10px 12px;border:2px solid #e2e8f0;border-radius:8px;font-family:inherit;font-size:14px;}
.aviso-field-input:focus{border-color:var(--purple);outline:none;}
.aviso-field-input.input-error{border-color:var(--red)!important;}
.field-error{display:block;font-size:12px;color:var(--red);font-weight:700;margin-top:4px;min-height:16px;}
.cu-card-home{cursor:pointer;transition:box-shadow .2s,transform .15s;}
.cu-card-home:hover{box-shadow:0 6px 24px rgba(91,33,182,.15);transform:translateY(-2px);}
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

<!-- MODAL CREAR AVISO (institucional, visible para todos los estudiantes y profesores) -->
<div class="modal-overlay hidden" id="crearAvisoOverlay">
  <div class="modal-box" style="max-width:500px;">
    <h3 style="margin-bottom:16px;font-size:16px;font-weight:800;">Crear Aviso</h3>
    <p style="font-size:12.5px;color:var(--text-soft);margin:-10px 0 16px;">Se publica como "Administración Delta" y llega a todos los estudiantes y profesores.</p>
    <div style="margin-bottom:14px;">
      <label class="aviso-field-label">Titulo</label>
      <input type="text" id="crearAvisoTitulo" class="aviso-field-input">
      <span class="field-error" id="errCrearAvisoTitulo"></span>
    </div>
    <div style="margin-bottom:14px;">
      <label class="aviso-field-label">Contenido</label>
      <textarea id="crearAvisoCuerpo" rows="4" class="aviso-field-input" style="resize:vertical;"></textarea>
      <span class="field-error" id="errCrearAvisoCuerpo"></span>
    </div>
    <div style="margin-bottom:20px;">
      <label class="aviso-field-label">Tipo</label>
      <select id="crearAvisoTipo" class="aviso-field-input" style="width:auto;">
        <option value="info">&#128216; Informativo</option>
        <option value="urgente">&#9888;&#65039; Urgente</option>
      </select>
    </div>
    <div class="modal-actions">
      <button class="btn btn-secondary" onclick="cerrarCrearAviso()">Cancelar</button>
      <button class="btn btn-primary" id="btnCrearAviso" onclick="enviarCrearAviso()">Publicar</button>
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
      <button class="nav-item active" data-tab="dashboard" onclick="irTab('dashboard',this)"><span class="nav-icon">&#128202;</span> Dashboard</button>
      <button class="nav-item" data-tab="estudiantes" onclick="irTab('estudiantes',this)"><span class="nav-icon">&#127891;</span> Gestion de Estudiantes</button>
      <button class="nav-item" data-tab="profesores" onclick="irTab('profesores',this)"><span class="nav-icon">&#128104;&#8205;&#127979;</span> Gestion de Profesores</button>
      <button class="nav-item" data-tab="materias" onclick="irTab('materias',this)"><span class="nav-icon">&#128218;</span> Gestion de Materias</button>
      <button class="nav-item" data-tab="historial-prof" onclick="irTab('historial-prof',this)"><span class="nav-icon">&#128203;</span> Historial de Profesores</button>
      <button class="nav-item" data-tab="matricula" onclick="irTab('matricula',this)"><span class="nav-icon">&#128203;</span> Gestion de Matriculas</button>
      <button class="nav-item" data-tab="limites" onclick="irTab('limites',this)"><span class="nav-icon">&#128273;</span> Materias Retiradas</button>
      <button class="nav-item" data-tab="crear-usuarios" onclick="irTab('crear-usuarios',this)"><span class="nav-icon">&#128101;</span> Gestion de Usuarios</button>
      <div class="nav-label">Supervision</div>
      <button class="nav-item" data-tab="sup-calificaciones" onclick="irTab('sup-calificaciones',this)"><span class="nav-icon">&#128221;</span> Calificaciones</button>
      <div class="nav-label">Comunicacion</div>
      <button class="nav-item" data-tab="avisos" onclick="irTab('avisos',this)"><span class="nav-icon">&#128227;</span> Gestion de Avisos</button>
      <button class="nav-item" data-tab="reportes" onclick="irTab('reportes',this)"><span class="nav-icon">&#128200;</span> Reportes</button>
    </nav>
    <div class="sidebar-footer">
      <button class="logout-btn" onclick="cerrarSesion()">&#128682; Cerrar Sesion</button>
    </div>
  </aside>

  <main class="main-content">

    <!-- DASHBOARD -->
    <div id="tab-dashboard" class="tab-panel active">
      <div class="topbar">
        <h2 class="page-title">Dashboard</h2>
        <div class="page-subtitle">Resumen general del sistema</div>
      </div>
      <div class="attn-strip" id="dashAttn"></div>
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

      <div class="card" style="margin-bottom:16px;">
        <div style="display:flex;align-items:center;justify-content:space-between;cursor:pointer;" onclick="toggleCrearCarrera()">
          <h3 style="margin:0;font-size:16px;color:var(--purple);">&#127891; Crear Carrera</h3>
          <span id="crearCarreraToggleIcon">&#9656;</span>
        </div>
        <div id="crearCarreraBody" class="hidden" style="margin-top:14px;">
          <div class="page-subtitle" style="margin-bottom:10px;">Toda carrera se crea con exactamente 6 materias: puedes vincular materias existentes que aún no tengan carrera, y/o crear materias nuevas, hasta sumar 6.</div>
          <div style="display:grid;grid-template-columns:2fr 1fr 1fr;gap:10px;margin-bottom:12px;">
            <div class="form-group"><label class="aviso-field-label">Nombre de la carrera</label>
              <input type="text" id="ccNombre" class="aviso-field-input" placeholder="Ingeniería de Software" oninput="autoCodigoCarrera()"></div>
            <div class="form-group"><label class="aviso-field-label">Código <span style="font-weight:400;color:var(--text-soft);">(auto, editable)</span></label>
              <input type="text" id="ccCodigo" class="aviso-field-input" placeholder="IDS" oninput="ccCodigoManual=true"></div>
            <div class="form-group"><label class="aviso-field-label">Facultad</label>
              <select id="ccFacultad" class="aviso-field-input"></select></div>
          </div>
          <label class="aviso-field-label">Materias existentes sin carrera (marca las que quieras vincular)</label>
          <div id="ccMateriasExistentes" style="display:grid;grid-template-columns:1fr 1fr;gap:6px;padding:10px;background:#f8f9fc;border:2px solid #e2e8f0;border-radius:8px;max-height:160px;overflow-y:auto;margin-bottom:12px;">
            <span style="color:#6b7e96;font-size:13px;">Cargando...</span>
          </div>
          <div style="display:flex;gap:10px;align-items:center;margin-bottom:10px;">
            <label class="aviso-field-label" style="margin:0;" title="Aplica a todas las materias NUEVAS que definas abajo. Las materias existentes que vincules no se tocan.">Número de salones por materia nueva</label>
            <select id="ccNumSalonesGlobal" class="aviso-field-input" style="width:70px;" onchange="renderAulasGlobales()">
              <option value="1">1</option><option value="2">2</option><option value="3">3</option>
            </select>
          </div>
          <div style="margin-bottom:12px;">
            <label class="aviso-field-label" title="Cada salón (1, 2, 3...) es UN aula, la misma para todas las materias nuevas — no un aula distinta por materia. Ej: el 'salón 1' de todas las materias usa esta misma aula.">Aula de cada salón (compartida por todas las materias nuevas)</label>
            <div id="ccAulasGlobales" style="display:flex;gap:10px;flex-wrap:wrap;"></div>
          </div>
          <label class="aviso-field-label">Materias nuevas (opcional, para completar 6)</label>
          <div id="ccMateriasNuevas"></div>
          <button type="button" class="btn btn-secondary btn-sm" style="margin:8px 0;" onclick="agregarFilaMateriaNueva()">+ Agregar materia nueva</button>
          <div style="margin-top:10px;display:flex;gap:10px;align-items:center;">
            <button type="button" class="btn btn-primary" onclick="enviarCrearCarrera()">Crear Carrera</button>
            <span id="ccContador" style="font-size:13px;color:var(--text-soft);"></span>
          </div>
        </div>
      </div>

      <div style="display:flex;align-items:center;gap:10px;margin-bottom:10px;flex-wrap:wrap;">
        <label class="aviso-field-label" style="margin:0;">Filtrar por carrera</label>
        <select id="filtroCarreraMaterias" class="aviso-field-input" style="max-width:280px;" onchange="renderMateriasAgrupadas()">
          <option value="">— Todas —</option>
        </select>
        <input type="text" id="buscarMateria" class="aviso-field-input" style="max-width:240px;" placeholder="Buscar por código, materia o profesor…" oninput="renderMateriasAgrupadas()">
      </div>
      <div id="materiasAgrupadas"></div>
    </div>

    <!-- HISTORIAL DE ASIGNACIÓN DE PROFESORES -->
    <div id="tab-historial-prof" class="tab-panel">
      <div class="topbar">
        <h2 class="page-title">&#128203; Historial de Asignacion de Profesores</h2>
        <div class="page-subtitle">Registro de todos los cambios de profesor realizados. Solo lectura — no se puede editar ni eliminar.</div>
      </div>
      <div class="card"><div style="overflow-x:auto;"><table class="delta-table" id="tblHistorialProf"></table></div></div>
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
        <h2 class="page-title">&#128273; Materias Retiradas</h2>
        <div class="page-subtitle">Materias que un estudiante retiro y no puede volver a inscribir, salvo que se desbloqueen.</div>
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
      <div class="topbar" style="display:flex;align-items:center;justify-content:space-between;gap:10px;">
        <h2 class="page-title">Gestion de Avisos</h2>
        <button class="btn btn-primary btn-sm" onclick="abrirCrearAviso()">+ Crear Aviso</button>
      </div>
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
      <div class="card" style="margin-top:18px;">
        <div style="display:flex;justify-content:flex-end;margin-bottom:12px;">
          <button class="btn btn-secondary btn-sm" onclick="descargarReporteCSV()">&#11015; Descargar CSV</button>
        </div>
        <div style="overflow-x:auto;"><table class="delta-table" id="tblReportes"></table></div>
      </div>
    </div>

    <!-- GESTIÓN DE USUARIOS -->
    <div id="tab-crear-usuarios" class="tab-panel">
      <div class="topbar">
        <h2 class="page-title">&#128101; Gestion de Usuarios</h2>
        <div class="page-subtitle">Registrar nuevos estudiantes y profesores en el sistema</div>
      </div>

      <!-- Modal credenciales generadas -->
      <div class="modal-overlay hidden" id="credencialesOverlay">
        <div class="modal-box" style="max-width:460px;">
          <h3 style="margin-bottom:4px;font-size:17px;font-weight:800;">&#10003; Usuario creado exitosamente</h3>
          <p style="font-size:13px;color:var(--text-soft);margin-bottom:16px;">Guarde estas credenciales antes de cerrar.</p>
          <div id="credencialesContenido" style="background:#f8f9fc;border-radius:10px;padding:16px;font-size:14px;line-height:2.1;margin-bottom:20px;border:2px solid #e8edf5;"></div>
          <div class="modal-actions">
            <button class="btn btn-primary" onclick="cerrarCredenciales()">Entendido</button>
          </div>
        </div>
      </div>

      <!-- Pantalla inicio: dos tarjetas -->
      <div id="cuHomeUsuarios">
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;max-width:680px;margin-bottom:32px;">
          <div class="card" style="cursor:pointer;transition:box-shadow .2s;text-align:center;padding:32px 20px;"
               onmouseenter="this.style.boxShadow='0 6px 24px rgba(91,33,182,.13)'"
               onmouseleave="this.style.boxShadow=''"
               onclick="abrirFormCrear('estudiante')">
            <div style="font-size:48px;margin-bottom:12px;">&#127891;</div>
            <div style="font-weight:800;font-size:16px;margin-bottom:6px;">Registrar Estudiante</div>
            <div style="font-size:13px;color:var(--text-soft);">Crear cuenta para nuevo alumno de la facultad</div>
          </div>
          <div class="card" style="cursor:pointer;transition:box-shadow .2s;text-align:center;padding:32px 20px;"
               onmouseenter="this.style.boxShadow='0 6px 24px rgba(91,33,182,.13)'"
               onmouseleave="this.style.boxShadow=''"
               onclick="abrirFormCrear('profesor')">
            <div style="font-size:48px;margin-bottom:12px;">&#128104;&#8205;&#127979;</div>
            <div style="font-weight:800;font-size:16px;margin-bottom:6px;">Registrar Profesor</div>
            <div style="font-size:13px;color:var(--text-soft);">Crear cuenta docente con asignacion de materias</div>
          </div>
        </div>

        <!-- Listado de usuarios creados -->
        <div class="card">
          <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:16px;">
            <div class="card-title" style="margin-bottom:0;">Usuarios registrados recientemente</div>
            <button class="btn btn-secondary btn-sm" onclick="cargarListaUsuarios()">&#8635; Actualizar</button>
          </div>
          <div style="overflow-x:auto;">
            <table class="delta-table" id="tblUsuariosCreados">
              <thead><tr>
                <th>Nombre</th><th>Tipo</th><th>Usuario generado</th>
                <th>Correo</th><th>Documento</th><th>Estado</th>
              </tr></thead>
              <tbody id="tbodyUsuariosCreados">
                <tr><td colspan="6" style="text-align:center;color:var(--text-soft);padding:24px;">Cargando...</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Panel formularios (oculto por defecto) -->
      <div id="cuForms" class="hidden">
        <div style="display:flex;align-items:center;gap:12px;margin-bottom:20px;">
          <button class="btn btn-secondary btn-sm" onclick="volverHomeUsuarios()">&#8592; Volver</button>
          <!-- Sub-tabs -->
          <div class="sub-nav" style="margin-bottom:0;">
            <button class="active" id="btnTabEstudiante" onclick="switchCrearTab('estudiante',this)">&#127891; Estudiante</button>
            <button id="btnTabProfesor" onclick="switchCrearTab('profesor',this)">&#128104;&#8205;&#127979; Profesor</button>
          </div>
        </div>

        <!-- ===== FORMULARIO ESTUDIANTE ===== -->
        <div id="subCrearEstudiante" class="card" style="max-width:680px;">
          <div class="card-title">Nuevo Estudiante</div>
          <form id="frmEstudiante" onsubmit="enviarCrearEstudiante(event)" novalidate>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
              <div class="form-group">
                <label class="aviso-field-label">Nombre completo *</label>
                <input type="text" name="nombre" id="estNombre" class="aviso-field-input" placeholder="Juan Carlos" oninput="limpiarError('errEstNombre',this);autoEmailEstudiante()">
                <span class="field-error" id="errEstNombre"></span>
              </div>
              <div class="form-group">
                <label class="aviso-field-label">Apellido completo *</label>
                <input type="text" name="apellido" id="estApellido" class="aviso-field-input" placeholder="De Leon" oninput="limpiarError('errEstApellido',this);autoEmailEstudiante()">
                <span class="field-error" id="errEstApellido"></span>
              </div>
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
              <div class="form-group">
                <label class="aviso-field-label">Correo institucional</label>
                <input type="text" name="email" id="estEmail" class="aviso-field-input" readonly
                  style="background:#f8f9fc;color:var(--text-soft);cursor:default;" placeholder="Se genera automaticamente">
                <span class="field-error" id="errEstEmail"></span>
                <span style="font-size:11px;color:var(--text-soft);margin-top:3px;display:block;">&#128274; Generado automaticamente: nombre.apellido@delta.edu (si ya existe un estudiante con ese mismo nombre, el sistema agrega un número al final, ej: nombre.apellido2@delta.edu)</span>
              </div>
              <div class="form-group">
                <label class="aviso-field-label">Telefono *</label>
                <input type="text" name="telefono" id="estTelefono" class="aviso-field-input" placeholder="6123-4567" oninput="limpiarError('errEstTel',this)">
                <span class="field-error" id="errEstTel"></span>
              </div>
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
              <div class="form-group">
                <label class="aviso-field-label">Semestre <span style="font-weight:400;color:var(--text-soft);">(fijo)</span></label>
                <input type="text" class="aviso-field-input" value="5 Semestre — 3er año, 1er semestre" disabled style="background:#eef0f5;">
              </div>
              <div class="form-group">
                <label class="aviso-field-label">Nacionalidad</label>
                <select name="nacionalidad" id="estNacionalidad" class="aviso-field-input" onchange="toggleCedulaEstudiante()">
                  <option value="panameno">Panameno</option>
                  <option value="cubano">Cubano</option>
                  <option value="colombiano">Colombiano</option>
                  <option value="venezolano">Venezolano</option>
                  <option value="costarricense">Costarricense</option>
                  <option value="dominicano">Dominicano</option>
                  <option value="mexicano">Mexicano</option>
                  <option value="estadounidense">Estadounidense</option>
                </select>
              </div>
            </div>
            <div id="estCedulaGrupo" class="form-group">
              <label class="aviso-field-label">Cedula *</label>
              <input type="text" name="cedula" id="estCedula" class="aviso-field-input" placeholder="8-1042-245" oninput="limpiarError('errEstCedula',this)">
              <span class="field-error" id="errEstCedula"></span>
            </div>
            <div id="estExtranjeroInfo" class="hidden" style="background:#ede9fe;border-radius:10px;padding:12px 16px;margin-bottom:14px;font-size:13px;color:#4c1d95;">
              &#128161; Se generara un ID institucional automatico: <strong>E-8-XXXX</strong>
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
              <div class="form-group">
                <label class="aviso-field-label">Carrera</label>
                <select id="estCarrera" class="aviso-field-input" onchange="cargarSalonesParaEstudiante()"></select>
              </div>
              <div class="form-group">
                <label class="aviso-field-label">Salón (opcional)</label>
                <select id="estGrupoInicial" class="aviso-field-input">
                  <option value="">— No matricular en ningún salón por ahora —</option>
                </select>
                <span style="font-size:11px;color:var(--text-soft);margin-top:3px;display:block;">Cada opción es un salón (aula) de la carrera; al elegirlo se matricula al estudiante en las materias que comparten esa aula.</span>
              </div>
            </div>
            <div style="display:flex;gap:10px;align-items:center;margin-top:8px;">
              <button type="submit" id="btnCrearEst" class="btn btn-primary" style="min-width:180px;">Crear Estudiante</button>
              <button type="button" class="btn btn-secondary" onclick="resetFormEstudiante()">Limpiar</button>
            </div>
          </form>
        </div>

        <!-- ===== FORMULARIO PROFESOR ===== -->
        <div id="subCrearProfesor" class="card hidden" style="max-width:680px;">
          <div class="card-title">Nuevo Profesor</div>
          <form id="frmProfesor" onsubmit="enviarCrearProfesor(event)" novalidate>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
              <div class="form-group">
                <label class="aviso-field-label">Nombre *</label>
                <input type="text" name="nombre" id="profNombre" class="aviso-field-input" placeholder="Maria" oninput="limpiarError('errProfNombre',this);autoEmailProfesor()">
                <span class="field-error" id="errProfNombre"></span>
              </div>
              <div class="form-group">
                <label class="aviso-field-label">Apellido *</label>
                <input type="text" name="apellido" id="profApellido" class="aviso-field-input" placeholder="Gonzalez" oninput="limpiarError('errProfApellido',this);autoEmailProfesor()">
                <span class="field-error" id="errProfApellido"></span>
              </div>
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
              <div class="form-group">
                <label class="aviso-field-label">Correo institucional</label>
                <input type="text" name="email" id="profEmail" class="aviso-field-input" readonly
                  style="background:#f8f9fc;color:var(--text-soft);cursor:default;" placeholder="Se genera automaticamente">
                <span class="field-error" id="errProfEmail"></span>
                <span style="font-size:11px;color:var(--text-soft);margin-top:3px;display:block;">&#128274; Generado automaticamente: nombre.apellido@delta.edu (si ya existe un profesor con ese mismo nombre, el sistema agrega un número al final, ej: nombre.apellido2@delta.edu)</span>
              </div>
              <div class="form-group">
                <label class="aviso-field-label">Telefono</label>
                <input type="text" name="telefono" id="profTelefono" class="aviso-field-input" placeholder="6123-4567" oninput="limpiarError('errProfTel',this)">
                <span class="field-error" id="errProfTel"></span>
              </div>
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
              <div class="form-group">
                <label class="aviso-field-label">Departamento</label>
                <select name="departamento" class="aviso-field-input">
                  <option value="Sistemas">Sistemas</option>
                  <option value="Redes">Redes</option>
                  <option value="Tecnologia">Tecnologia</option>
                  <option value="Negocios">Negocios</option>
                  <option value="Etica">Etica</option>
                </select>
              </div>
              <div class="form-group">
                <label class="aviso-field-label">Nacionalidad</label>
                <select name="nacionalidad" id="profNacionalidad" class="aviso-field-input" onchange="toggleCedulaProfesor()">
                  <option value="panameno">Panameno</option>
                  <option value="cubano">Cubano</option>
                  <option value="colombiano">Colombiano</option>
                  <option value="venezolano">Venezolano</option>
                  <option value="costarricense">Costarricense</option>
                  <option value="dominicano">Dominicano</option>
                  <option value="mexicano">Mexicano</option>
                  <option value="estadounidense">Estadounidense</option>
                </select>
              </div>
            </div>
            <div id="profCedulaGrupo" class="form-group">
              <label class="aviso-field-label">Cedula</label>
              <input type="text" name="cedula" id="profCedula" class="aviso-field-input" placeholder="8-1042-245" oninput="limpiarError('errProfCedula',this)">
              <span class="field-error" id="errProfCedula"></span>
            </div>
            <div id="profExtranjeroInfo" class="hidden" style="background:#ede9fe;border-radius:10px;padding:12px 16px;margin-bottom:14px;font-size:13px;color:#4c1d95;">
              &#128161; Se generara un ID institucional automatico: <strong>E-8-XXXX</strong>
            </div>
            <div style="display:flex;gap:10px;align-items:center;margin-top:8px;">
              <button type="submit" id="btnCrearProf" class="btn btn-primary" style="min-width:180px;">Crear Profesor</button>
              <button type="button" class="btn btn-secondary" onclick="resetFormProfesor()">Limpiar</button>
            </div>
          </form>
        </div>
      </div>
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
  // Si no llega el boton (navegacion programatica, ej. desde una tarjeta del
  // dashboard), se busca el nav-item correspondiente por su data-tab para
  // que el resaltado morado del sidebar siga la pantalla real.
  if (!btn) btn = document.querySelector('.nav-item[data-tab="'+id+'"]');
  document.querySelectorAll('.tab-panel').forEach(function(p){ p.classList.remove('active'); });
  document.querySelectorAll('.nav-item').forEach(function(n){ n.classList.remove('active'); });
  document.getElementById('tab-'+id).classList.add('active');
  if (btn) btn.classList.add('active');
  if (id==='dashboard') cargarDashboard();
  if (id==='estudiantes') cargarEstudiantes();
  if (id==='profesores') cargarProfesores();
  if (id==='materias') cargarMaterias();
  if (id==='historial-prof') cargarHistorialAsignaciones();
  if (id==='matricula') cargarSolicitudes('inscripcion', document.getElementById('btnSolInsc'));
  if (id==='limites') cargarLimitesSolicitudes();
  if (id==='sup-calificaciones') cargarSupervisionCalificaciones();
  if (id==='avisos') cargarAvisos('todos', document.querySelector('#filtrosAvisos button'));
  if (id==='reportes') cargarReporte('reportePromedioMateria', document.querySelector('#tab-reportes .sub-nav button'));
  if (id==='crear-usuarios') inicializarCrearUsuarios();
}

// ── GESTIÓN DE USUARIOS ───────────────────────────────────────────────────

function inicializarCrearUsuarios() {
  document.getElementById('cuHomeUsuarios').classList.remove('hidden');
  document.getElementById('cuForms').classList.add('hidden');
  cargarListaUsuarios();
}

function abrirFormCrear(tipo) {
  document.getElementById('cuHomeUsuarios').classList.add('hidden');
  document.getElementById('cuForms').classList.remove('hidden');
  if (tipo === 'profesor') {
    switchCrearTab('profesor', document.getElementById('btnTabProfesor'));
  } else {
    switchCrearTab('estudiante', document.getElementById('btnTabEstudiante'));
  }
}

function volverHomeUsuarios() {
  document.getElementById('cuForms').classList.add('hidden');
  document.getElementById('cuHomeUsuarios').classList.remove('hidden');
  cargarListaUsuarios();
}

function switchCrearTab(tipo, btn) {
  document.querySelectorAll('#cuForms .sub-nav button').forEach(function(b){ b.classList.remove('active'); });
  btn.classList.add('active');
  if (tipo === 'estudiante') {
    document.getElementById('subCrearEstudiante').classList.remove('hidden');
    document.getElementById('subCrearProfesor').classList.add('hidden');
    cargarCarrerasParaEstudiante();
  } else {
    document.getElementById('subCrearEstudiante').classList.add('hidden');
    document.getElementById('subCrearProfesor').classList.remove('hidden');
  }
}

function toggleCedulaEstudiante() {
  var nac = document.getElementById('estNacionalidad').value;
  var esPanameno = (nac === 'panameno');
  document.getElementById('estCedulaGrupo').style.display = esPanameno ? '' : 'none';
  document.getElementById('estExtranjeroInfo').classList.toggle('hidden', esPanameno);
}

function toggleCedulaProfesor() {
  var nac = document.getElementById('profNacionalidad').value;
  var esPanameno = (nac === 'panameno');
  document.getElementById('profCedulaGrupo').style.display = esPanameno ? '' : 'none';
  document.getElementById('profExtranjeroInfo').classList.toggle('hidden', esPanameno);
}


function escHtml(s) {
  if (!s) return '';
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function validarCedulaPanamena(c) {
  return /^[1-9][0-9]*-[0-9]+-[0-9]+$/.test(String(c).trim());
}

function validarNombreApellido(v) {
  return v && /^[\p{L} ]+$/u.test(v.trim());
}

function validarTelefono(t) {
  if (!t || t.trim() === '') return false;
  return /^6[0-9]{3}-[0-9]{4}$|^6[0-9]{6,7}$/.test(t.trim());
}

function normalizarParaEmail(s) {
  if (!s) return '';
  return s.trim().toLowerCase()
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9 ]/g, '')
    .trim().replace(/\s+/g, '.');
}

function autoEmailEstudiante() {
  var nombre   = document.getElementById('estNombre').value;
  var apellido = document.getElementById('estApellido').value;
  var n = normalizarParaEmail(nombre);
  var a = normalizarParaEmail(apellido);
  var email = (n && a) ? n + '.' + a + '@delta.edu' : '';
  document.getElementById('estEmail').value = email;
  limpiarError('errEstEmail', null);
}

function autoEmailProfesor() {
  var nombre   = document.getElementById('profNombre').value;
  var apellido = document.getElementById('profApellido').value;
  var n = normalizarParaEmail(nombre);
  var a = normalizarParaEmail(apellido);
  var email = (n && a) ? n + '.' + a + '@delta.edu' : '';
  document.getElementById('profEmail').value = email;
  limpiarError('errProfEmail', null);
}

function marcarError(inputId, errorId, msg) {
  var inp = document.getElementById(inputId);
  var err = document.getElementById(errorId);
  if (inp) inp.classList.add('input-error');
  if (err) err.textContent = msg;
  return false;
}

function limpiarError(errorId, input) {
  var err = document.getElementById(errorId);
  if (err) err.textContent = '';
  if (input) input.classList.remove('input-error');
}

function limpiarTodosErrores(prefix, ids) {
  ids.forEach(function(id){ limpiarError(id, document.getElementById(id.replace('err','').toLowerCase())); });
}

function mostrarCredenciales(data) {
  var html = '';
  html += '<div><strong>Usuario:</strong> ' + escHtml(data.username) + '</div>';
  html += '<div><strong>Contrasena inicial:</strong> <code style="background:#e8edf5;padding:2px 8px;border-radius:5px;">' + escHtml(data.passwordInicial) + '</code></div>';
  if (data.codigo) html += '<div><strong>Codigo docente:</strong> ' + escHtml(data.codigo) + '</div>';
  html += '<div><strong>ID documento:</strong> ' + escHtml(data.idDocumento)
        + (data.tipoId === 'extranjero' ? ' <span class="tag tag-amber">ID Institucional</span>' : '') + '</div>';
  html += '<div style="margin-top:10px;font-size:12px;color:#6b7e96;">Entregue estas credenciales al usuario. Podra cambiar su contrasena en el primer inicio de sesion.</div>';
  document.getElementById('credencialesContenido').innerHTML = html;
  document.getElementById('credencialesOverlay').classList.remove('hidden');
}

function cerrarCredenciales() {
  document.getElementById('credencialesOverlay').classList.add('hidden');
}

function resetFormEstudiante() {
  document.getElementById('frmEstudiante').reset();
  document.getElementById('estEmail').value = '';
  toggleCedulaEstudiante();
  ['errEstNombre','errEstApellido','errEstEmail','errEstTel','errEstCedula'].forEach(function(id){
    var el = document.getElementById(id); if(el) el.textContent = '';
  });
  document.querySelectorAll('#frmEstudiante .input-error').forEach(function(el){ el.classList.remove('input-error'); });
  document.getElementById('estGrupoInicial').innerHTML = '<option value="">— No matricular en ningún salón por ahora —</option>';
}

// ── Carrera / salón inicial al crear estudiante ───────────────────────────
function cargarCarrerasParaEstudiante() {
  fetch(CTX+'/admin?accion=listarCarreras').then(function(r){return r.json();}).then(function(cs){
    var sel = document.getElementById('estCarrera');
    if (!Array.isArray(cs)) { sel.innerHTML = '<option value="">— Error al cargar carreras —</option>'; showToast('Error al cargar carreras: '+(cs.error||'respuesta inesperada'), 'error'); return; }
    if (!cs.length) { sel.innerHTML = '<option value="">— No hay carreras registradas —</option>'; return; }
    sel.innerHTML = cs.map(function(c, i){
      var esIDS = /ingenier[ií]a de software/i.test(c.nombre);
      return '<option value="'+c.id+'"'+(esIDS?' selected':'')+'>'+esc(c.nombre)+'</option>';
    }).join('');
    cargarSalonesParaEstudiante();
  }).catch(function(){ showToast('Error de conexión al cargar carreras.', 'error'); });
}
// Trae los "salones" de la carrera elegida agrupados por aula: el aula de
// cada numero de salon es compartida por TODAS las materias de la carrera,
// asi que elegir un salon matricula al estudiante de una vez en las 6
// materias que comparten esa aula (no hay paso intermedio de elegir materia).
function cargarSalonesParaEstudiante() {
  var carreraId = document.getElementById('estCarrera').value;
  var sel = document.getElementById('estGrupoInicial');
  sel.innerHTML = '<option value="">— No matricular en ningún salón por ahora —</option>';
  if (!carreraId) return;
  fetch(CTX+'/admin?accion=salonesPorCarrera&carreraId='+carreraId).then(function(r){return r.json();}).then(function(gs){
    if (!Array.isArray(gs)) { showToast('Error al cargar salones: '+(gs.error||'respuesta inesperada'), 'error'); return; }
    if (!gs.length) { sel.innerHTML += '<option value="" disabled>(esta carrera no tiene salones creados)</option>'; return; }
    gs.forEach(function(g, i){
      var ids = (g.grupoIds || []).join(',');
      sel.innerHTML += '<option value="'+esc(ids)+'" title="'+esc((g.materias||[]).join(', '))+'">Salón '+(i+1)+' — '+esc(g.aula)+' — '
        + g.totalMaterias+' materias — cupo disponible mínimo: '+g.cupoMinimo+'</option>';
    });
  }).catch(function(){ showToast('Error de conexión al cargar salones.', 'error'); });
}

function resetFormProfesor() {
  document.getElementById('frmProfesor').reset();
  toggleCedulaProfesor();
  ['errProfNombre','errProfApellido','errProfEmail','errProfTel','errProfCedula'].forEach(function(id){
    var el = document.getElementById(id); if(el) el.textContent = '';
  });
  document.querySelectorAll('#frmProfesor .input-error').forEach(function(el){ el.classList.remove('input-error'); });
}

function enviarCrearEstudiante(e) {
  e.preventDefault();
  var frm   = document.getElementById('frmEstudiante');
  var nac   = document.getElementById('estNacionalidad').value;
  var esExt = (nac !== 'panameno');
  var ok    = true;

  var nombre   = document.getElementById('estNombre').value.trim();
  var apellido = document.getElementById('estApellido').value.trim();
  var email    = document.getElementById('estEmail').value.trim();
  var telefono = document.getElementById('estTelefono').value.trim();
  var cedula   = document.getElementById('estCedula').value.trim();

  if (!nombre)                              { marcarError('estNombre','errEstNombre','El nombre es obligatorio.'); ok=false; }
  else if (!validarNombreApellido(nombre))  { marcarError('estNombre','errEstNombre','El nombre solo puede contener letras y espacios.'); ok=false; }
  if (!apellido)                            { marcarError('estApellido','errEstApellido','El apellido es obligatorio.'); ok=false; }
  else if (!validarNombreApellido(apellido)){ marcarError('estApellido','errEstApellido','El apellido solo puede contener letras y espacios.'); ok=false; }
  if (!email) {
    marcarError('estEmail','errEstEmail','Ingrese nombre y apellido para generar el correo automaticamente.'); ok=false;
  }
  if (!telefono)                            { marcarError('estTelefono','errEstTel','El telefono es obligatorio.'); ok=false; }
  else if (!validarTelefono(telefono))      { marcarError('estTelefono','errEstTel','Debe empezar con 6 y solo contener números (y un guión opcional). Ej: 6123-4567.'); ok=false; }
  if (!esExt) {
    if (!cedula)                     { marcarError('estCedula','errEstCedula','La cedula es obligatoria.'); ok=false; }
    else if (!validarCedulaPanamena(cedula)) { marcarError('estCedula','errEstCedula','Formato invalido. Use: 8-1042-245'); ok=false; }
  }
  if (!ok) return;

  var params = new URLSearchParams();
  params.set('accion', 'crearEstudiante');
  ['nombre','apellido','cedula','email','telefono','semestre','nacionalidad'].forEach(function(k){
    var el = frm.querySelector('[name=' + k + ']');
    if (el) params.set(k, el.value);
  });
  var carreraSel = document.getElementById('estCarrera').value;
  if (carreraSel) params.set('carreraId', carreraSel);
  var grupoSel = document.getElementById('estGrupoInicial').value;
  if (grupoSel) params.set('grupoIdsIniciales', grupoSel);

  var btn = document.getElementById('btnCrearEst');
  btn.disabled = true; btn.textContent = 'Creando...';

  fetch(CTX + '/admin', { method:'POST', body: params,
    headers:{'Content-Type':'application/x-www-form-urlencoded'} })
    .then(function(r){ return r.json(); })
    .then(function(d) {
      btn.disabled = false; btn.textContent = 'Crear Estudiante';
      if (d.ok) {
        resetFormEstudiante();
        mostrarCredenciales(d);
        showToast('Estudiante registrado correctamente', 'success');
      } else {
        var msg = d.error || 'Error al crear estudiante';
        showToast(msg, 'error');
        var ml = msg.toLowerCase();
        if (ml.indexOf('nombre') !== -1)   marcarError('estNombre','errEstNombre', msg);
        else if (ml.indexOf('apellido') !== -1) marcarError('estApellido','errEstApellido', msg);
        else if (ml.indexOf('correo') !== -1 || ml.indexOf('email') !== -1) marcarError('estEmail','errEstEmail', msg);
        else if (ml.indexOf('tel') !== -1)  marcarError('estTelefono','errEstTel', msg);
        else if (ml.indexOf('cedula') !== -1) marcarError('estCedula','errEstCedula', msg);
      }
    })
    .catch(function(err) {
      btn.disabled = false; btn.textContent = 'Crear Estudiante';
      showToast('Error de conexion: ' + err.message, 'error');
    });
}

function enviarCrearProfesor(e) {
  e.preventDefault();
  var frm   = document.getElementById('frmProfesor');
  var nac   = document.getElementById('profNacionalidad').value;
  var esExt = (nac !== 'panameno');
  var ok    = true;

  var nombre   = document.getElementById('profNombre').value.trim();
  var apellido = document.getElementById('profApellido').value.trim();
  var email    = document.getElementById('profEmail').value.trim();
  var telefono = document.getElementById('profTelefono').value.trim();
  var cedula   = document.getElementById('profCedula').value.trim();

  if (!nombre)   { marcarError('profNombre','errProfNombre','El nombre es obligatorio.'); ok=false; }
  if (!apellido) { marcarError('profApellido','errProfApellido','El apellido es obligatorio.'); ok=false; }
  if (!email)    { marcarError('profEmail','errProfEmail','Ingrese nombre y apellido para generar el correo automaticamente.'); ok=false; }
  if (!validarTelefono(telefono)) { marcarError('profTelefono','errProfTel','El teléfono debe empezar con 6 y solo contener números (y un guión opcional). Ej: 6123-4567.'); ok=false; }
  if (!esExt && cedula && !validarCedulaPanamena(cedula)) {
    marcarError('profCedula','errProfCedula','Formato invalido. Use: 8-1042-245'); ok=false;
  }
  if (!ok) return;

  var params = new URLSearchParams();
  params.set('accion', 'crearProfesor');
  ['nombre','apellido','cedula','email','telefono','departamento','nacionalidad'].forEach(function(k){
    var el = frm.querySelector('[name=' + k + ']');
    if (el) params.set(k, el.value);
  });

  var btn = document.getElementById('btnCrearProf');
  btn.disabled = true; btn.textContent = 'Creando...';

  fetch(CTX + '/admin', { method:'POST', body: params,
    headers:{'Content-Type':'application/x-www-form-urlencoded'} })
    .then(function(r){ return r.json(); })
    .then(function(d) {
      btn.disabled = false; btn.textContent = 'Crear Profesor';
      if (d.ok) {
        resetFormProfesor();
        mostrarCredenciales(d);
        showToast('Profesor registrado correctamente', 'success');
      } else {
        var msg = d.error || 'Error al crear profesor';
        showToast(msg, 'error');
        if (msg.toLowerCase().indexOf('email') !== -1) marcarError('profEmail','errProfEmail', msg);
        if (msg.toLowerCase().indexOf('cedula') !== -1) marcarError('profCedula','errProfCedula', msg);
      }
    })
    .catch(function(err) {
      btn.disabled = false; btn.textContent = 'Crear Profesor';
      showToast('Error de conexion: ' + err.message, 'error');
    });
}

function cargarListaUsuarios() {
  var tbody = document.getElementById('tbodyUsuariosCreados');
  if (!tbody) return;
  tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text-soft);padding:20px;">Cargando...</td></tr>';
  fetch(CTX + '/admin?accion=listarUsuariosCreados')
    .then(function(r){ return r.json(); })
    .then(function(rows) {
      if (!rows || rows.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text-soft);padding:24px;">No hay usuarios registrados aun.</td></tr>';
        return;
      }
      tbody.innerHTML = rows.map(function(u) {
        var rolTag = u.rol === 'estudiante'
          ? '<span class="tag tag-green">Estudiante</span>'
          : '<span class="tag" style="background:#dbeafe;color:#1e40af;">Profesor</span>';
        var estadoTag = u.activo
          ? '<span class="tag tag-green">Activo</span>'
          : '<span class="tag tag-gray">Inactivo</span>';
        return '<tr>'
          + '<td><strong>' + escHtml(u.nombre) + '</strong></td>'
          + '<td>' + rolTag + '</td>'
          + '<td><code style="background:#f1f5f9;padding:2px 8px;border-radius:5px;font-size:13px;">' + escHtml(u.username) + '</code></td>'
          + '<td>' + escHtml(u.email) + '</td>'
          + '<td>' + escHtml(u.documento) + '</td>'
          + '<td>' + estadoTag + '</td>'
          + '</tr>';
      }).join('');
    })
    .catch(function() {
      tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--red);padding:20px;">Error al cargar usuarios.</td></tr>';
    });
}

function cerrarSesion() {
  showConfirm('¿Desea cerrar sesion?', function() {
    window.location.href = CTX + '/logout';
  });
}

function cargarDashboard() {
  if (!HAY_BD) return;
  fetch(CTX+'/admin?accion=dashboard').then(function(r){ return r.json(); }).then(function(d) {
    document.getElementById('dashAttn').innerHTML =
      attnItem(d.estudiantesRiesgo, 'bad',
        (d.estudiantesRiesgo===1?'inscripción':'inscripciones')+' con promedio en riesgo (menos de 70) en materias del currículo activo',
        'irReporteDashboard(\'reporteRiesgo\')') +
      attnItem(d.materiasSinCarrera, 'warn',
        (d.materiasSinCarrera===1?'materia sin':'materias sin')+' carrera asignada (candidatas para vincular o archivar)',
        'irTab(\'materias\')') +
      attnItem(d.gruposSinProfesor, 'warn',
        (d.gruposSinProfesor===1?'salón sin':'salones sin')+' profesor asignado',
        'irTab(\'materias\')');
    document.getElementById('dashStats').innerHTML =
      statCard('&#127891;','Estudiantes',d.totalEstudiantes,'irTab(\'estudiantes\')') +
      statCard('&#128104;&#8205;&#127979;','Profesores',d.totalProfesores,'irTab(\'profesores\')') +
      statCard('&#128218;','Materias activas',d.materiasActivas,'irTab(\'materias\')') +
      statCard('&#128227;','Avisos Activos',d.avisosActivos,'irTab(\'avisos\')') +
      statCard('&#128203;','Inscripciones Pendientes',d.pendInscripcion,'irMatriculaDashboard(\'inscripcion\')') +
      statCard('&#128465;','Retiros Pendientes',d.pendRetiro,'irMatriculaDashboard(\'retiro\')');
  });
}

// Item de la franja "atencion requerida": en rojo/ambar si hay algo que
// atender, en verde (no clickeable) si el conteo esta en cero.
function attnItem(n, sev, texto, onclick) {
  n = n || 0;
  if (n === 0) {
    return '<button type="button" class="attn-item ok" disabled>&#10003; 0 '+texto+'</button>';
  }
  return '<button type="button" class="attn-item '+sev+'" onclick="'+onclick+'">'
       + '<span class="attn-n">'+n+'</span><span class="attn-txt">'+texto+'</span>'
       + '<span class="attn-go">Ver &#8594;</span></button>';
}

function statCard(icon, label, val, onclick) {
  var cls = onclick ? ' clickable' : '';
  var attr = onclick ? ' onclick="'+onclick+'" role="button" tabindex="0"' : '';
  return '<div class="stat-card'+cls+'"'+attr+'><div class="stat-icon">'+icon+'</div><div><div class="stat-label">'+label+'</div><div class="stat-value">'+(val||0)+'</div></div></div>';
}

// Navega a Reportes y carga el reporte indicado directamente (sin pasar por
// el reporte por defecto de irTab, para evitar dos fetch pisandose entre si).
function irReporteDashboard(accion) {
  document.querySelectorAll('.tab-panel').forEach(function(p){ p.classList.remove('active'); });
  document.querySelectorAll('.nav-item').forEach(function(n){ n.classList.remove('active'); });
  document.getElementById('tab-reportes').classList.add('active');
  var navBtn = document.querySelector('.nav-item[data-tab="reportes"]');
  if (navBtn) navBtn.classList.add('active');
  var subBtn = Array.prototype.find.call(document.querySelectorAll('#tab-reportes .sub-nav button'), function(b) {
    return b.getAttribute('onclick') && b.getAttribute('onclick').indexOf("'"+accion+"'") !== -1;
  });
  cargarReporte(accion, subBtn || null);
}

// Navega a Matriculas y selecciona el sub-filtro (inscripcion/retiro) pedido,
// sin pasar por el filtro por defecto de irTab (mismo motivo que arriba).
function irMatriculaDashboard(tipo) {
  document.querySelectorAll('.tab-panel').forEach(function(p){ p.classList.remove('active'); });
  document.querySelectorAll('.nav-item').forEach(function(n){ n.classList.remove('active'); });
  document.getElementById('tab-matricula').classList.add('active');
  var navBtn = document.querySelector('.nav-item[data-tab="matricula"]');
  if (navBtn) navBtn.classList.add('active');
  var btn = document.getElementById(tipo === 'retiro' ? 'btnSolRet' : 'btnSolInsc');
  cargarSolicitudes(tipo, btn);
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
var materiasCacheados = [];

function cargarMaterias() {
  fetch(CTX+'/admin?accion=profesoresSimple').then(function(r){ return r.json(); }).then(function(profs) {
    profesoresParaSelect = profs;
    return fetch(CTX+'/admin?accion=materias');
  }).then(function(r){ return r.json(); }).then(function(todasLasFilas) {
    materiasCacheados = todasLasFilas;
    sincronizarFiltroCarrera(todasLasFilas);
    renderMateriasAgrupadas();
  }).catch(function(){ showToast('Error al cargar materias.', 'error'); });
}

// Agrega al filtro cualquier carrera nueva que aparezca en los datos, sin
// borrar las opciones ni la seleccion actual — antes solo se poblaba una vez
// por carga de pagina, asi que una carrera creada en la misma sesion nunca
// aparecia hasta cerrar sesion y volver a entrar.
function sincronizarFiltroCarrera(todasLasFilas) {
  var selFiltro = document.getElementById('filtroCarreraMaterias');
  var yaPresentes = {};
  Array.prototype.forEach.call(selFiltro.options, function(o){ yaPresentes[o.value] = true; });
  var vistos = {};
  todasLasFilas.forEach(function(r){
    if (r.carreraId != null && !vistos[r.carreraId]) {
      vistos[r.carreraId] = true;
      if (!yaPresentes[String(r.carreraId)]) {
        selFiltro.innerHTML += '<option value="'+r.carreraId+'">'+esc(r.carrera)+'</option>';
      }
    }
  });
}

// Filtra (por carrera y por texto) y agrupa por salon (aula) los datos ya
// cacheados — no vuelve a pedir nada al servidor, asi que responde al
// instante mientras se escribe en el buscador o se cambia de carrera.
function renderMateriasAgrupadas() {
  var carreraFiltro = document.getElementById('filtroCarreraMaterias').value;
  var q = (document.getElementById('buscarMateria').value || '').trim().toLowerCase();

  var rows = materiasCacheados.filter(function(r){
    if (carreraFiltro && String(r.carreraId) !== carreraFiltro) return false;
    if (q) {
      var haystack = (r.codigo+' '+r.nombre+' '+(r.profesor||'')).toLowerCase();
      if (haystack.indexOf(q) === -1) return false;
    }
    return true;
  });

  var cont = document.getElementById('materiasAgrupadas');
  if (!rows.length) {
    cont.innerHTML = '<div class="card" style="text-align:center;color:var(--text-soft);padding:30px;">No se encontraron materias.</div>';
    return;
  }

  // El aula ya es compartida por todas las materias de un mismo numero de
  // salon (ver Crear Carrera), asi que agrupar por aula agrupa exactamente
  // por salon. Las materias sin grupo (sin aula) van aparte, en una lista
  // simple, porque no hay salon con el que agruparlas.
  var grupos = {}, ordenAulas = [], sinSalon = [];
  rows.forEach(function(r){
    if (!r.aula) { sinSalon.push(r); return; }
    if (!grupos[r.aula]) { grupos[r.aula] = []; ordenAulas.push(r.aula); }
    grupos[r.aula].push(r);
  });
  ordenAulas.sort();

  var idxGlobal = 0;
  var html = '';
  ordenAulas.forEach(function(aula){
    var filas = grupos[aula];
    var sinProfesor = filas.filter(function(r){ return r.profesorId == null; }).length;
    var carrerasGrupo = [];
    filas.forEach(function(r){ if (r.carrera && carrerasGrupo.indexOf(r.carrera) === -1) carrerasGrupo.push(r.carrera); });
    var carreraTexto = carrerasGrupo.length ? carrerasGrupo.join(' / ') : 'Sin carrera';
    html += '<details class="salon-group" open><summary>'
      + '<div style="display:flex;align-items:center;gap:10px;"><span class="chev">&#9656;</span>'
      + '<span class="salon-aula">'+esc(aula)+'</span>'
      + '<span class="salon-carrera">'+esc(carreraTexto)+'</span></div>'
      + '<span class="salon-meta">'+filas.length+' materia'+(filas.length===1?'':'s')
      + (sinProfesor ? ' &middot; '+sinProfesor+' sin profesor' : '')+'</span>'
      + '</summary>'
      + '<div class="mat-row-grid mat-row-head"><span>Código</span><span>Materia</span><span>Créd.</span><span>Horario</span><span>Cupos</span><span>Inscr.</span><span>Profesor</span><span>Grupo</span><span>Acciones</span></div>';
    filas.forEach(function(r){ html += renderFilaMateria(r, idxGlobal++); });
    html += '</details>';
  });

  if (sinSalon.length) {
    html += '<div class="card"><div class="card-title" style="font-size:14px;">Materias sin salón asignado</div>'
      + '<div style="overflow-x:auto;"><table class="delta-table"><thead><tr><th>Código</th><th>Materia</th><th>Créditos</th><th>Acciones</th></tr></thead><tbody>';
    sinSalon.forEach(function(r){
      var i = idxGlobal++;
      html += '<tr><td>'+esc(r.codigo)+'</td><td><strong>'+esc(r.nombre)+'</strong></td>'
        + '<td><input class="edit-input" type="number" min="1" max="20" style="width:60px;" id="mCred_'+i+'" value="'+r.creditos+'"></td>'
        + '<td><button class="btn btn-secondary btn-sm" onclick="guardarSoloCreditos('+i+','+r.id+')">Guardar Créditos</button></td></tr>';
    });
    html += '</tbody></table></div></div>';
  }

  cont.innerHTML = html;
}

// Una fila de materia dentro de una tarjeta de salon (aula ya conocida por
// el grupo, no se repite por fila).
function renderFilaMateria(r, idx) {
  var creditosCell = '<input class="edit-input" type="number" min="1" max="20" style="width:56px;" id="mCred_'+idx+'" value="'+r.creditos+'">';
  var capacidadCell = '<input class="edit-input" type="number" min="0" style="width:56px;" id="mCap_'+idx+'" value="'+r.capacidad+'"> <span style="font-size:10px;color:var(--text-soft);">min:'+r.inscritos+'</span>';
  var profesorCell;
  if (r.profesorId != null) {
    // Mientras el salon tenga profesor, no se edita el select directamente:
    // hay que liberarlo primero con "Cambiar profesor" (evita reemplazos accidentales).
    profesorCell = '<div style="display:flex;align-items:center;gap:6px;flex-wrap:wrap;">'
      + '<span class="tag tag-green">&#128100; '+esc(r.profesor)+'</span>'
      + '<button type="button" class="btn btn-secondary btn-sm" title="Libera el salón para poder elegir otro profesor" onclick="quitarProfesorSalon('+r.grupoId+')">&#128260;</button>'
      + '</div>';
  } else {
    var profOptions = '<option value="">— Sin asignar —</option>';
    profesoresParaSelect.forEach(function(p) {
      profOptions += '<option value="'+p.id+'">'+esc(p.nombre)+'</option>';
    });
    profesorCell = '<select class="edit-select" id="mProf_'+idx+'" style="width:100%;">'+profOptions+'</select>';
  }
  var horarioCell;
  if (r.horario) {
    var bloquesHtml = r.horario.split(' / ').map(function(b){ return '<div>'+esc(b)+'</div>'; }).join('');
    horarioCell = '<details><summary style="cursor:pointer;color:var(--purple);font-size:12px;font-weight:700;">Ver horario</summary>'
                + '<div style="margin-top:6px;font-size:12px;color:var(--text-soft);white-space:nowrap;">'+bloquesHtml+'</div></details>';
  } else {
    horarioCell = '<span style="color:var(--text-soft);font-size:12px;">-</span>';
  }
  return '<div class="mat-row-grid">'
    + '<span class="mono-cell">'+esc(r.codigo)+'</span>'
    + '<span><strong>'+esc(r.nombre)+'</strong></span>'
    + '<span>'+creditosCell+'</span>'
    + '<span>'+horarioCell+'</span>'
    + '<span>'+capacidadCell+'</span>'
    + '<span>'+r.inscritos+'</span>'
    + '<span>'+profesorCell+'</span>'
    + '<span class="mono-cell">'+esc(r.grupo||'-')+'</span>'
    + '<span><button class="btn btn-primary btn-sm" onclick="guardarMateria('+idx+','+r.grupoId+','+r.id+','+r.inscritos+')">Guardar</button></span>'
    + '</div>';
}

// ── Codigo de carrera auto-generado a partir de las iniciales del nombre ──
var ccCodigoManual = false;
function autoCodigoCarrera() {
  if (ccCodigoManual) return;
  var nombre = document.getElementById('ccNombre').value;
  var iniciales = nombre.split(/\s+/).filter(function(w){ return w.length > 0; })
    .map(function(w){ return w.charAt(0).toUpperCase(); }).join('');
  document.getElementById('ccCodigo').value = iniciales;
}

// ── Quitar profesor de un salón ──────────────────────────────────────────
function quitarProfesorSalon(grupoId) {
  showConfirm('¿Quitar el profesor asignado a este salón? Quedará vacante hasta que asignes uno nuevo.', function() {
    fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
      body:'accion=quitarProfesor&grupoId='+grupoId})
      .then(function(r){ return r.json(); })
      .then(function(d) {
        if (d.ok) { showToast('Profesor removido. El salón quedó vacante.', 'success'); cargarMaterias(); }
        else showToast('Error: '+(d.error||'No se pudo quitar el profesor.'), 'error');
      }).catch(function(){ showToast('Error de conexión.', 'error'); });
  });
}

// ── Crear Carrera ─────────────────────────────────────────────────────────
var ccCargado = false;
function toggleCrearCarrera() {
  var body = document.getElementById('crearCarreraBody');
  var icon = document.getElementById('crearCarreraToggleIcon');
  var abrir = body.classList.contains('hidden');
  body.classList.toggle('hidden');
  icon.innerHTML = abrir ? '&#9662;' : '&#9656;';
  if (abrir && !ccCargado) {
    ccCargado = true;
    fetch(CTX+'/admin?accion=listarFacultades').then(function(r){return r.json();}).then(function(fs){
      document.getElementById('ccFacultad').innerHTML = fs.map(function(f){ return '<option value="'+f.id+'">'+esc(f.nombre)+'</option>'; }).join('');
    });
    fetch(CTX+'/admin?accion=materiasSinCarrera').then(function(r){return r.json();}).then(function(ms){
      var cont = document.getElementById('ccMateriasExistentes');
      if (!ms.length) { cont.innerHTML = '<span style="color:#6b7e96;font-size:13px;">No hay materias sin carrera disponibles.</span>'; return; }
      cont.innerHTML = ms.map(function(m){
        return '<label style="display:flex;align-items:center;gap:8px;font-size:13px;cursor:pointer;padding:4px 0;">'
             + '<input type="checkbox" class="ccMatExistente" value="'+m.id+'" onchange="actualizarContadorCC()" style="accent-color:var(--purple);width:16px;height:16px;">'
             + '<span><strong>'+esc(m.codigo)+'</strong> — '+esc(m.nombre)+'</span></label>';
      }).join('');
    });
    renderAulasGlobales();
  }
}
// Un aula por CADA numero de salon (1, 2, 3...), compartida por TODAS las
// materias nuevas — no una aula distinta por materia. Auto-generadas, editables.
function renderAulasGlobales() {
  var n = parseInt(document.getElementById('ccNumSalonesGlobal').value, 10);
  var box = document.getElementById('ccAulasGlobales');
  var html = '';
  for (var i = 0; i < n; i++) {
    html += '<div><label style="font-size:11px;color:var(--text-soft);display:block;">Salón '+(i+1)+'</label>'
      + '<input type="text" class="ccAulaGlobal'+i+' aviso-field-input" value="Aula N'+(i+1)+'" style="max-width:140px;"></div>';
  }
  box.innerHTML = html;
}
// Asignacion de horario automatico para cada materia nueva, segun su orden.
// Como el aula de cada numero de salon es COMPARTIDA por todas las materias
// de la carrera, dos materias nunca pueden usar la misma combinacion de
// dia+bloque-horario (chocarian en la misma aula). Por eso, en vez de dos
// rotaciones independientes (que podian repetir una celda dia+hora), cada
// materia recibe una celda dia+hora exclusiva: se avanza de bloque horario
// cada 2 materias, alternando entre el par de dias lunes/martes y el par
// miercoles/jueves.
var CC_SLOTS_HORA = [['07:00','09:00'], ['09:00','11:00'], ['11:00','13:00'], ['13:00','15:00']];
var CC_PARES_DIAS = [['lunes','martes'], ['miercoles','jueves']];
var ccOrdenContador = 0;

function diaCapitalizado(d) { return d.charAt(0).toUpperCase() + d.slice(1); }
function horaAmPm(hhmm) {
  var p = hhmm.split(':'); var h = parseInt(p[0], 10);
  var ampm = h >= 12 ? 'pm' : 'am'; var h12 = h % 12; if (h12 === 0) h12 = 12;
  return h12 + ':' + p[1] + ampm;
}

function agregarFilaMateriaNueva() {
  var cont = document.getElementById('ccMateriasNuevas');
  var orden = ccOrdenContador++;
  var slot = CC_SLOTS_HORA[Math.floor(orden / 2) % CC_SLOTS_HORA.length];
  var dias = CC_PARES_DIAS[orden % CC_PARES_DIAS.length];

  var fila = document.createElement('div');
  fila.className = 'cc-fila-materia';
  fila.dataset.orden = orden;
  fila.dataset.horario = dias[0]+'@'+slot[0]+'@'+slot[1]+';'+dias[1]+'@'+slot[0]+'@'+slot[1];
  fila.style.cssText = 'border:1px solid #e2e8f0;border-radius:10px;padding:12px;margin-bottom:10px;background:#fbfbfd;';

  var horarioTexto = diaCapitalizado(dias[0]) + ' y ' + diaCapitalizado(dias[1]) + ', ' + horaAmPm(slot[0]) + '–' + horaAmPm(slot[1]);

  fila.innerHTML =
      '<div style="display:grid;grid-template-columns:2fr 1fr 70px 70px 32px;gap:8px;align-items:end;margin-bottom:8px;">'
    +   '<div><label style="font-size:11px;color:var(--text-soft);display:block;">Nombre</label>'
    +     '<input type="text" class="ccnNombre aviso-field-input" placeholder="Ej: Arquitectura de Software" oninput="autoCodigoMateriaNueva(this)"></div>'
    +   '<div><label style="font-size:11px;color:var(--text-soft);display:block;">Código <span style="font-weight:400;">(auto)</span></label>'
    +     '<input type="text" class="ccnCodigo aviso-field-input" placeholder="AS-501" oninput="this.closest(\'.cc-fila-materia\').dataset.codigoManual=\'1\'"></div>'
    +   '<div><label style="font-size:11px;color:var(--text-soft);display:block;" title="Créditos académicos de la materia">Créditos</label>'
    +     '<input type="number" class="ccnCreditos aviso-field-input" value="3" min="1"></div>'
    +   '<div><label style="font-size:11px;color:var(--text-soft);display:block;" title="Fijo: 3er año, 1er semestre">Nivel</label>'
    +     '<input type="number" class="ccnNivel aviso-field-input" value="5" disabled style="background:#eef0f5;"></div>'
    +   '<button type="button" class="btn btn-danger btn-sm" onclick="this.closest(\'.cc-fila-materia\').remove();actualizarContadorCC();" style="padding:6px;">&#10005;</button>'
    + '</div>'
    + '<div style="font-size:12px;color:var(--text-soft);">&#128197; Horario automático (según el orden): <strong>'+horarioTexto+'</strong></div>';
  cont.appendChild(fila);
  actualizarContadorCC();
}
// Auto-genera el código de la materia a partir de las iniciales del nombre,
// mientras el admin no lo haya editado a mano.
function autoCodigoMateriaNueva(nombreInput) {
  var fila = nombreInput.closest('.cc-fila-materia');
  if (fila.dataset.codigoManual === '1') return;
  var iniciales = nombreInput.value.split(/\s+/).filter(function(w){ return w.length > 0; })
    .map(function(w){ return w.charAt(0).toUpperCase(); }).join('');
  var num = String(parseInt(fila.dataset.orden, 10) + 1).padStart(2, '0');
  fila.querySelector('.ccnCodigo').value = iniciales + '-5' + num;
}
function actualizarContadorCC() {
  var marcadas = document.querySelectorAll('.ccMatExistente:checked').length;
  var nuevas = document.querySelectorAll('.cc-fila-materia').length;
  var total = marcadas + nuevas;
  var el = document.getElementById('ccContador');
  el.textContent = total + ' / 6 materias';
  el.style.color = total === 6 ? 'var(--green)' : 'var(--red)';
}
function enviarCrearCarrera() {
  actualizarContadorCC();
  var nombre = document.getElementById('ccNombre').value.trim();
  var codigo = document.getElementById('ccCodigo').value.trim();
  var facultadId = document.getElementById('ccFacultad').value;
  if (!nombre || !codigo) { showToast('Nombre y código de la carrera son obligatorios.', 'error'); return; }

  var idsExistentes = Array.prototype.map.call(document.querySelectorAll('.ccMatExistente:checked'), function(cb){ return cb.value; });

  // Las aulas son UNA por numero de salon, compartidas por TODAS las materias
  // nuevas (salon 1 de cualquier materia usa la misma aula, salon 2 usa otra, etc.).
  var n = parseInt(document.getElementById('ccNumSalonesGlobal').value, 10);
  var aulasGlobales = [];
  var errorSalones = null;
  for (var i = 0; i < n; i++) {
    var aulaInput = document.querySelector('.ccAulaGlobal'+i);
    var aula = aulaInput ? aulaInput.value.trim() : '';
    if (!aula) errorSalones = 'Falta el aula del salón ' + (i+1) + '.';
    aulasGlobales.push(aula);
  }
  if (errorSalones) { showToast(errorSalones, 'error'); return; }
  var aulasGlobalesStr = aulasGlobales.join('|');

  var nuevasCodigos = [], nuevasNombres = [], nuevasCreditos = [], nuevasNiveles = [];
  var nuevasNumSalones = [], nuevasAulas = [], nuevasHorarios = [];
  document.querySelectorAll('.cc-fila-materia').forEach(function(fila){
    nuevasCodigos.push(fila.querySelector('.ccnCodigo').value.trim());
    nuevasNombres.push(fila.querySelector('.ccnNombre').value.trim());
    nuevasCreditos.push(fila.querySelector('.ccnCreditos').value.trim());
    nuevasNiveles.push(fila.querySelector('.ccnNivel').value.trim());
    nuevasNumSalones.push(n);
    nuevasAulas.push(aulasGlobalesStr);
    nuevasHorarios.push(fila.dataset.horario);
  });

  var total = idsExistentes.length + nuevasCodigos.length;
  if (total !== 6) { showToast('Debes completar exactamente 6 materias (llevas ' + total + ').', 'error'); return; }

  var params = new URLSearchParams();
  params.set('accion', 'crearCarrera');
  params.set('nombre', nombre);
  params.set('codigo', codigo);
  params.set('facultadId', facultadId);
  params.set('materiaIdsExistentes', idsExistentes.join(','));
  params.set('nuevasNumSalones', nuevasNumSalones.join(','));
  params.set('nuevasAulas', nuevasAulas.join(','));
  params.set('nuevasHorarios', nuevasHorarios.join(','));
  params.set('nuevasCodigos', nuevasCodigos.join(','));
  params.set('nuevasNombres', nuevasNombres.join(','));
  params.set('nuevasCreditos', nuevasCreditos.join(','));
  params.set('nuevasNiveles', nuevasNiveles.join(','));

  fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body: params})
    .then(function(r){ return r.json(); })
    .then(function(d) {
      if (d.ok) {
        showToast('Carrera creada correctamente.', 'success');
        document.getElementById('crearCarreraBody').classList.add('hidden');
        document.getElementById('crearCarreraToggleIcon').innerHTML = '&#9656;';
        ccCargado = false;
        ccCodigoManual = false;
        ccOrdenContador = 0;
        document.getElementById('ccNumSalonesGlobal').value = '1';
        renderAulasGlobales();
        document.getElementById('ccMateriasNuevas').innerHTML = '';
        cargarMaterias();
      } else showToast('Error: '+(d.error||'No se pudo crear la carrera.'), 'error');
    }).catch(function(){ showToast('Error de conexión.', 'error'); });
}


// Guarda créditos únicamente (para materias sin grupo asignado)
function guardarSoloCreditos(idx, materiaId) {
  var creditos = parseInt(document.getElementById('mCred_'+idx).value, 10);
  if (isNaN(creditos) || creditos < 1) {
    showToast('Los creditos deben ser un número mayor o igual a 1.', 'error'); return;
  }
  fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:'accion=actualizarCreditos&materiaId='+materiaId+'&creditos='+creditos})
    .then(function(r){ return r.json(); })
    .then(function(d) {
      if (d.ok) { showToast('Créditos actualizados correctamente.', 'success'); cargarMaterias(); }
      else showToast('Error: '+(d.error||'No se pudo actualizar los créditos.'), 'error');
    }).catch(function(){ showToast('Error de conexión.', 'error'); });
}

function guardarMateria(idx, grupoId, materiaId, inscritosActuales) {
  var creditos  = parseInt(document.getElementById('mCred_'+idx).value, 10);
  var capacidad = parseInt(document.getElementById('mCap_'+idx).value, 10);

  if (isNaN(creditos) || creditos < 1) {
    showToast('Los créditos deben ser un número mayor o igual a 1.', 'error'); return;
  }
  if (isNaN(capacidad) || capacidad < 0) {
    showToast('Los cupos deben ser un número mayor o igual a 0.', 'error'); return;
  }
  // Validación de cupos en el frontend (reforzada en servidor)
  if (capacidad < inscritosActuales) {
    showToast('No se puede reducir los cupos a ' + capacidad +
      ' porque hay ' + inscritosActuales + ' estudiante(s) actualmente inscritos. ' +
      'El mínimo permitido es ' + inscritosActuales + '.', 'error');
    return;
  }

  var peticiones = [
    fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
      body:'accion=actualizarCreditos&materiaId='+materiaId+'&creditos='+creditos}),
    fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
      body:'accion=actualizarCapacidad&grupoId='+grupoId+'&capacidad='+capacidad})
  ];

  // El select de profesor solo existe si el salon esta vacante (si ya tiene
  // profesor, se muestra como texto y se cambia con el boton "Cambiar profesor").
  var profSelect = document.getElementById('mProf_'+idx);
  var profesorId = profSelect ? profSelect.value : '';
  if (profesorId) {
    peticiones.push(fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
      body:'accion=reasignarProfesor&grupoId='+grupoId+'&profesorId='+profesorId}));
  }

  Promise.all(peticiones)
    .then(function(responses){ return Promise.all(responses.map(function(r){ return r.json(); })); })
    .then(function(results) {
      var error = results.find(function(d){ return !d.ok; });
      if (error) { showToast('Error: '+(error.error||'No se pudo guardar.'), 'error'); return; }
      // Verificar si hubo cambio de profesor (la tercera petición devuelve cambiado:bool)
      var resultadoProf = peticiones.length === 3 ? results[2] : null;
      if (resultadoProf && resultadoProf.cambiado === false) {
        showToast('Créditos y cupos guardados. ' + (resultadoProf.msg || 'El profesor no cambió.'), 'info');
      } else if (resultadoProf && resultadoProf.cambiado === true) {
        showToast('Cambios guardados. Profesor reasignado y registrado en el historial.', 'success');
      } else {
        showToast('Cambios guardados correctamente.', 'success');
      }
      cargarMaterias();
    })
    .catch(function(){ showToast('Error de conexión al guardar los cambios.', 'error'); });
}

// Carga el historial de asignaciones de profesores
function cargarHistorialAsignaciones() {
  fetch(CTX+'/admin?accion=historialAsignaciones').then(function(r){ return r.json(); }).then(function(rows) {
    var tbl = document.getElementById('tblHistorialProf');
    if (!rows.length) {
      tbl.innerHTML = '<tbody><tr><td colspan="5" style="text-align:center;color:var(--text-soft);padding:24px;">No hay cambios registrados todavía.</td></tr></tbody>';
      return;
    }
    var html = '<thead><tr><th>Fecha</th><th>Materia</th><th>Profesor Anterior</th><th>Profesor Nuevo</th><th>Administrador</th></tr></thead><tbody>';
    rows.forEach(function(r, i) {
      var bg = i % 2 === 0 ? '' : 'style="background:var(--bg);"';
      html += '<tr '+bg+'>'
        +'<td style="color:var(--text-soft);white-space:nowrap;">'+esc(r.fecha)+'</td>'
        +'<td><strong>'+esc(r.materia)+'</strong></td>'
        +'<td><span class="tag tag-red">'+esc(r.profesorAnterior)+'</span></td>'
        +'<td><span class="tag tag-green">'+esc(r.profesorNuevo)+'</span></td>'
        +'<td style="color:var(--text-soft);">'+esc(r.admin)+'</td>'
        +'</tr>';
    });
    tbl.innerHTML = html + '</tbody>';
  }).catch(function(){ showToast('Error al cargar el historial.', 'error'); });
}

function cargarLimitesSolicitudes() {
  fetch(CTX+'/admin?accion=materiasRetiradas').then(function(r){ return r.json(); }).then(function(rows) {
    var container = document.getElementById('limites-container');
    if (!rows.length) {
      container.innerHTML = '<div class="card" style="text-align:center;color:var(--text-soft);padding:32px;">No hay materias retiradas actualmente.</div>';
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
            + '<div style="font-size:12px;color:var(--text-soft);">'+est.materias.length+' materia(s) retirada(s)</div></div>'
            + '</div>';
      // Tabla de materias
      html += '<div style="padding:16px 20px;">';
      html += '<table class="delta-table" style="margin-bottom:0;">'
            + '<thead><tr><th>Materia</th><th style="text-align:center;">Re-inscripcion</th><th>Acciones</th></tr></thead><tbody>';
      est.materias.forEach(function(r) {
        html += '<tr>'
          + '<td><strong>'+esc(r.materia)+'</strong><br><span style="font-size:12px;color:var(--text-soft);">'+esc(r.materiaCodigo)+'</span></td>'
          + '<td style="text-align:center;"><span class="tag tag-red">&#128274; Retirada</span></td>'
          + '<td><button class="btn btn-warning btn-sm" title="Permitir volver a inscribir esta materia" onclick="desbloquearMateria('+r.estudianteId+','+r.grupoId+',\''+esc(est.nombre)+'\',\''+esc(r.materia)+'\')">&#128275; Desbloquear</button></td>'
          + '</tr>';
      });
      html += '</tbody></table></div></div>';
    });
    container.innerHTML = html;
  }).catch(function(){ showToast('Error al cargar las materias retiradas.', 'error'); });
}

function desbloquearMateria(estudianteId, grupoId, nombreEst, nombreMat) {
  showConfirm('¿Permitir que '+nombreEst+' vuelva a inscribir '+nombreMat+'?\n\nEsta materia fue retirada previamente. Al desbloquearla podra volver a solicitar la inscripcion.', function() {
    fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
      body:'accion=desbloquearMateria&estudianteId='+estudianteId+'&grupoId='+grupoId})
      .then(function(r){ return r.json(); })
      .then(function(d) {
        if (d.ok) { showToast('Materia desbloqueada correctamente.', 'success'); cargarLimitesSolicitudes(); }
        else showToast('Error: '+(d.error||'No se pudo desbloquear.'), 'error');
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

// ── Crear aviso institucional (visible para todos los estudiantes y profesores) ──
function abrirCrearAviso() {
  document.getElementById('crearAvisoTitulo').value = '';
  document.getElementById('crearAvisoCuerpo').value = '';
  document.getElementById('crearAvisoTipo').value = 'info';
  document.getElementById('errCrearAvisoTitulo').textContent = '';
  document.getElementById('errCrearAvisoCuerpo').textContent = '';
  document.getElementById('crearAvisoOverlay').classList.remove('hidden');
}

function cerrarCrearAviso() { document.getElementById('crearAvisoOverlay').classList.add('hidden'); }

function enviarCrearAviso() {
  var titulo = document.getElementById('crearAvisoTitulo').value.trim();
  var cuerpo = document.getElementById('crearAvisoCuerpo').value.trim();
  var tipo   = document.getElementById('crearAvisoTipo').value;
  var ok = true;
  document.getElementById('errCrearAvisoTitulo').textContent = '';
  document.getElementById('errCrearAvisoCuerpo').textContent = '';
  if (!titulo) { document.getElementById('errCrearAvisoTitulo').textContent = 'El titulo es obligatorio.'; ok = false; }
  if (!cuerpo) { document.getElementById('errCrearAvisoCuerpo').textContent = 'El contenido es obligatorio.'; ok = false; }
  if (!ok) return;

  var btn = document.getElementById('btnCrearAviso');
  btn.disabled = true; btn.textContent = 'Publicando...';
  fetch(CTX+'/admin', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:'accion=crearAviso&titulo='+encodeURIComponent(titulo)+'&cuerpo='+encodeURIComponent(cuerpo)+'&tipo='+encodeURIComponent(tipo)})
    .then(function(r){ return r.json(); })
    .then(function(d){
      btn.disabled = false; btn.textContent = 'Publicar';
      if (d.ok) {
        cerrarCrearAviso();
        cargarAvisos(filtroAvisosActual(), document.querySelector('#filtrosAvisos button.active'));
        showToast('Aviso publicado. Ya es visible para todos los estudiantes y profesores.','success');
      } else showToast('Error: '+(d.error||'No se pudo publicar el aviso.'),'error');
    }).catch(function(){ btn.disabled = false; btn.textContent = 'Publicar'; showToast('Error de conexion.','error'); });
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

var reporteActualData = [];
var reporteActualKeys = [];
var reporteActualNombre = 'Reporte';

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
    reporteActualData = rows;
    reporteActualNombre = btn ? btn.textContent.trim() : accion;
    if (!rows.length) {
      reporteActualKeys = [];
      document.getElementById('tblReportes').innerHTML = '<tbody><tr><td style="text-align:center;color:var(--text-soft);padding:20px;">Sin datos para este reporte.</td></tr></tbody>';
      return;
    }
    reporteActualKeys = Object.keys(rows[0]);
    var keys = reporteActualKeys;
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

function descargarReporteCSV() {
  if (!reporteActualData.length) { showToast('No hay datos para descargar.', 'info'); return; }
  var headers = reporteActualKeys.map(function(k) { return REPORTE_COL_LABEL[k] || k; });
  var filas = [headers];
  reporteActualData.forEach(function(r) {
    filas.push(reporteActualKeys.map(function(k) {
      var v = r[k];
      if (k === 'porcentaje' && v != null) v = v + '%';
      return v != null ? String(v) : '';
    }));
  });
  var csv = filas.map(function(fila) {
    return fila.map(function(celda) {
      var val = String(celda).replace(/"/g, '""');
      if (val.indexOf(',') !== -1 || val.indexOf('"') !== -1 || val.indexOf('\n') !== -1) val = '"' + val + '"';
      return val;
    }).join(',');
  }).join('\r\n');
  var blob = new Blob(['﻿' + csv], {type:'text/csv;charset=utf-8;'});
  var url = URL.createObjectURL(blob);
  var link = document.createElement('a');
  link.href = url;
  link.download = reporteActualNombre.replace(/\s+/g, '_') + '.csv';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
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

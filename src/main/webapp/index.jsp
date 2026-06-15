<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
  // Siempre invalidar sesión al llegar al index — permite cambiar de portal
  HttpSession s = request.getSession(false);
  if (s != null) s.invalidate();
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sistema Delta UTP — Selección de Portal</title>
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&family=Merriweather:wght@700&display=swap" rel="stylesheet">
<style>
  :root {
    --blue:#1a56a0; --amber:#92400e;
    --bg:linear-gradient(145deg,#dbeafe 0%,#f4f6fb 55%,#fef3c7 100%);
  }
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family:'Nunito',sans-serif; min-height:100vh;
         background:var(--bg); display:flex; align-items:center; justify-content:center; }
  .wrap { text-align:center; padding:32px; }
  .logo { display:inline-flex; align-items:center; justify-content:center;
          width:80px; height:80px; border-radius:20px; background:var(--blue);
          color:#fff; font-family:'Merriweather',serif; font-size:38px;
          margin-bottom:16px; box-shadow:0 6px 24px rgba(26,86,160,.35); }
  h1 { font-family:'Merriweather',serif; font-size:28px; color:#1e2a3b; }
  p  { font-size:16px; color:#6b7e96; margin-top:8px; margin-bottom:36px; }
  .cards { display:flex; gap:24px; justify-content:center; flex-wrap:wrap; }
  .card  { background:#fff; border:2px solid #c8d8ec; border-radius:18px;
           padding:36px 40px; width:220px; cursor:pointer; transition:all .2s;
           text-decoration:none; display:flex; flex-direction:column; align-items:center; gap:12px; }
  .card:hover { transform:translateY(-4px); box-shadow:0 8px 32px rgba(26,86,160,.18); }
  .card-icon { font-size:40px; }
  .card-title { font-family:'Merriweather',serif; font-size:18px; }
  .card-sub   { font-size:14px; color:#6b7e96; }
  .card-est { border-color:#93c5fd; }  .card-est:hover { border-color:var(--blue); }
  .card-prof { border-color:#fcd34d; } .card-prof:hover { border-color:var(--amber); }
</style>
</head>
<body>
<div class="wrap">
  <div class="logo">∆</div>
  <h1>Sistema Delta</h1>
  <p>Universidad Tecnológica de Panamá · Seleccione su portal</p>
  <div class="cards">
    <a class="card card-est" href="portal_estudiante.jsp">
      <div class="card-icon">🎓</div>
      <div class="card-title">Estudiante</div>
      <div class="card-sub">Portal Estudiantil</div>
    </a>
    <a class="card card-prof" href="portal_profesor.jsp">
      <div class="card-icon">👩‍🏫</div>
      <div class="card-title">Docente</div>
      <div class="card-sub">Portal Docente</div>
    </a>
  </div>
  <div style="margin-top:28px;font-size:13px;">
    <a href="portal_administrador.jsp" style="color:#9ca3af;text-decoration:none;">Acceso administrativo</a>
  </div>
</div>
</body>
</html>

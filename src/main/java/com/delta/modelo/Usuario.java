package com.delta.modelo;

import java.time.LocalDateTime;

public class Usuario {
    private int id;
    private String username;
    private String password;
    private String rol;          // 'estudiante' | 'profesor' | 'admin'
    private boolean activo;
    private LocalDateTime createdAt;

    public Usuario() {}

    public Usuario(int id, String username, String rol) {
        this.id = id;
        this.username = username;
        this.rol = rol;
    }

    // ── Getters / Setters ──
    public int getId()                          { return id; }
    public void setId(int id)                   { this.id = id; }

    public String getUsername()                 { return username; }
    public void setUsername(String username)    { this.username = username; }

    public String getPassword()                 { return password; }
    public void setPassword(String password)    { this.password = password; }

    public String getRol()                      { return rol; }
    public void setRol(String rol)              { this.rol = rol; }

    public boolean isActivo()                   { return activo; }
    public void setActivo(boolean activo)       { this.activo = activo; }

    public LocalDateTime getCreatedAt()         { return createdAt; }
    public void setCreatedAt(LocalDateTime dt)  { this.createdAt = dt; }

    public boolean esProfesor()    { return "profesor".equals(rol); }
    public boolean esEstudiante()  { return "estudiante".equals(rol); }
    public boolean esAdmin()       { return "admin".equals(rol); }
}

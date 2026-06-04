package com.delta.modelo;

import java.time.LocalDateTime;

public class Notificacion {
    private int id;
    private int usuarioId;
    private String tipo;      // 'mensaje' | 'riesgo' | 'sistema' | 'nota'
    private String titulo;
    private String cuerpo;
    private boolean leida;
    private String enlace;
    private LocalDateTime createdAt;

    public Notificacion() {}

    // ── Getters / Setters ──
    public int getId()                              { return id; }
    public void setId(int id)                       { this.id = id; }

    public int getUsuarioId()                       { return usuarioId; }
    public void setUsuarioId(int v)                 { this.usuarioId = v; }

    public String getTipo()                         { return tipo; }
    public void setTipo(String tipo)                { this.tipo = tipo; }

    public String getTitulo()                       { return titulo; }
    public void setTitulo(String titulo)            { this.titulo = titulo; }

    public String getCuerpo()                       { return cuerpo; }
    public void setCuerpo(String cuerpo)            { this.cuerpo = cuerpo; }

    public boolean isLeida()                        { return leida; }
    public void setLeida(boolean leida)             { this.leida = leida; }

    public String getEnlace()                       { return enlace; }
    public void setEnlace(String enlace)            { this.enlace = enlace; }

    public LocalDateTime getCreatedAt()             { return createdAt; }
    public void setCreatedAt(LocalDateTime dt)      { this.createdAt = dt; }
}

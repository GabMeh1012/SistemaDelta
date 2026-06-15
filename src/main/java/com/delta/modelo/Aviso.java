package com.delta.modelo;

import java.time.LocalDateTime;

public class Aviso {
    private int id;
    private Integer profesorId;   // null = aviso institucional / sistema
    private Integer grupoId;      // null = dirigido a todos los estudiantes
    private String titulo;
    private String cuerpo;
    private String tipo;          // 'info' | 'urgente' | 'exito' | 'recordatorio'
    private LocalDateTime createdAt;

    // Datos auxiliares para mostrar en el front (no son columnas propias)
    private String profesorNombre;
    private String codigoGrupo;

    public Aviso() {}

    // ── Getters / Setters ──
    public int getId()                          { return id; }
    public void setId(int id)                   { this.id = id; }

    public Integer getProfesorId()              { return profesorId; }
    public void setProfesorId(Integer v)        { this.profesorId = v; }

    public Integer getGrupoId()                 { return grupoId; }
    public void setGrupoId(Integer v)           { this.grupoId = v; }

    public String getTitulo()                   { return titulo; }
    public void setTitulo(String titulo)        { this.titulo = titulo; }

    public String getCuerpo()                   { return cuerpo; }
    public void setCuerpo(String cuerpo)        { this.cuerpo = cuerpo; }

    public String getTipo()                     { return tipo; }
    public void setTipo(String tipo)            { this.tipo = tipo; }

    public LocalDateTime getCreatedAt()         { return createdAt; }
    public void setCreatedAt(LocalDateTime dt)  { this.createdAt = dt; }

    public String getProfesorNombre()           { return profesorNombre; }
    public void setProfesorNombre(String v)     { this.profesorNombre = v; }

    public String getCodigoGrupo()              { return codigoGrupo; }
    public void setCodigoGrupo(String v)        { this.codigoGrupo = v; }
}

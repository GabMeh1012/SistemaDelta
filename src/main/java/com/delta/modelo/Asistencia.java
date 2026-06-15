package com.delta.modelo;

import java.time.LocalDate;

public class Asistencia {
    private int id;
    private int inscripcionId;
    private LocalDate fecha;
    private String estado;       // 'presente' | 'ausente' | 'tardanza'
    private String observacion;

    public Asistencia() {}

    public int getId()                       { return id; }
    public void setId(int id)                { this.id = id; }

    public int getInscripcionId()            { return inscripcionId; }
    public void setInscripcionId(int v)      { this.inscripcionId = v; }

    public LocalDate getFecha()              { return fecha; }
    public void setFecha(LocalDate fecha)    { this.fecha = fecha; }

    public String getEstado()                { return estado; }
    public void setEstado(String estado)     { this.estado = estado; }

    public String getObservacion()           { return observacion; }
    public void setObservacion(String v)     { this.observacion = v; }
}

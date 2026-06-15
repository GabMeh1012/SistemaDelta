package com.delta.modelo;

import java.time.LocalDateTime;

public class SolicitudMatricula {
    private int id;
    private int estudianteId;
    private int grupoId;
    private String tipo;       // inscripcion | retiro
    private String estado;     // pendiente | aprobada | rechazada
    private Integer inscripcionId;
    private String motivo;
    private Integer adminUsuarioId;
    private LocalDateTime fechaSolicitud;
    private LocalDateTime fechaResolucion;

    private String estudianteNombre;
    private String materiaCodigo;
    private String materiaNombre;
    private String grupoCodigo;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getEstudianteId() { return estudianteId; }
    public void setEstudianteId(int estudianteId) { this.estudianteId = estudianteId; }

    public int getGrupoId() { return grupoId; }
    public void setGrupoId(int grupoId) { this.grupoId = grupoId; }

    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

    public Integer getInscripcionId() { return inscripcionId; }
    public void setInscripcionId(Integer inscripcionId) { this.inscripcionId = inscripcionId; }

    public String getMotivo() { return motivo; }
    public void setMotivo(String motivo) { this.motivo = motivo; }

    public Integer getAdminUsuarioId() { return adminUsuarioId; }
    public void setAdminUsuarioId(Integer adminUsuarioId) { this.adminUsuarioId = adminUsuarioId; }

    public LocalDateTime getFechaSolicitud() { return fechaSolicitud; }
    public void setFechaSolicitud(LocalDateTime fechaSolicitud) { this.fechaSolicitud = fechaSolicitud; }

    public LocalDateTime getFechaResolucion() { return fechaResolucion; }
    public void setFechaResolucion(LocalDateTime fechaResolucion) { this.fechaResolucion = fechaResolucion; }

    public String getEstudianteNombre() { return estudianteNombre; }
    public void setEstudianteNombre(String estudianteNombre) { this.estudianteNombre = estudianteNombre; }

    public String getMateriaCodigo() { return materiaCodigo; }
    public void setMateriaCodigo(String materiaCodigo) { this.materiaCodigo = materiaCodigo; }

    public String getMateriaNombre() { return materiaNombre; }
    public void setMateriaNombre(String materiaNombre) { this.materiaNombre = materiaNombre; }

    public String getGrupoCodigo() { return grupoCodigo; }
    public void setGrupoCodigo(String grupoCodigo) { this.grupoCodigo = grupoCodigo; }
}

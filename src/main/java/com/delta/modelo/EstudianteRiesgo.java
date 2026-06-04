package com.delta.modelo;

public class EstudianteRiesgo {
    private int    estudianteId;
    private String nombre;
    private String codigoGrupo;
    private String materia;
    private double promedioFinal;
    private String estadoAcademico;  // 'RIESGO' | 'ALERTA' | 'NORMAL'

    public EstudianteRiesgo() {}

    // ── Getters / Setters ──
    public int    getEstudianteId()                   { return estudianteId; }
    public void   setEstudianteId(int v)              { this.estudianteId = v; }

    public String getNombre()                         { return nombre; }
    public void   setNombre(String v)                 { this.nombre = v; }

    public String getCodigoGrupo()                    { return codigoGrupo; }
    public void   setCodigoGrupo(String v)            { this.codigoGrupo = v; }

    public String getMateria()                        { return materia; }
    public void   setMateria(String v)                { this.materia = v; }

    public double getPromedioFinal()                  { return promedioFinal; }
    public void   setPromedioFinal(double v)          { this.promedioFinal = v; }

    public String getEstadoAcademico()                { return estadoAcademico; }
    public void   setEstadoAcademico(String v)        { this.estadoAcademico = v; }

    public boolean isEnRiesgo() {
        return "RIESGO".equals(estadoAcademico) || "ALERTA".equals(estadoAcademico);
    }
}

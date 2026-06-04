package com.delta.modelo;

import java.time.LocalDateTime;

public class Mensaje {
    private int id;
    private int remitenteId;
    private int destinatarioId;
    private String remitenteNombre;
    private String asunto;
    private String cuerpo;
    private boolean leido;
    private LocalDateTime fechaEnvio;

    public Mensaje() {}

    // ── Getters / Setters ──
    public int getId()                              { return id; }
    public void setId(int id)                       { this.id = id; }

    public int getRemitenteId()                     { return remitenteId; }
    public void setRemitenteId(int v)               { this.remitenteId = v; }

    public int getDestinatarioId()                  { return destinatarioId; }
    public void setDestinatarioId(int v)            { this.destinatarioId = v; }

    public String getRemitenteNombre()              { return remitenteNombre; }
    public void setRemitenteNombre(String v)        { this.remitenteNombre = v; }

    public String getAsunto()                       { return asunto; }
    public void setAsunto(String asunto)            { this.asunto = asunto; }

    public String getCuerpo()                       { return cuerpo; }
    public void setCuerpo(String cuerpo)            { this.cuerpo = cuerpo; }

    public boolean isLeido()                        { return leido; }
    public void setLeido(boolean leido)             { this.leido = leido; }

    public LocalDateTime getFechaEnvio()            { return fechaEnvio; }
    public void setFechaEnvio(LocalDateTime fecha)  { this.fechaEnvio = fecha; }
}

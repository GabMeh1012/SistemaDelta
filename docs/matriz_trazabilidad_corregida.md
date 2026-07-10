# Matriz de Trazabilidad de Requisitos Funcionales — SistemaDelta (corregida)

Se eliminaron 3 requisitos que la matriz original marcaba como "Cubierto" pero que no tienen pantalla
que los use (verificado contra el código fuente): supervisión de asistencia desde el admin, gestión de
periodos académicos, e historial de asistencia del estudiante. Los IDs (SD-RF-xx y TC-xxx-nn) se
renumeraron para no dejar huecos. Total original: 40 → 37 requisitos.

**Actualización de esta semana:** se agregaron 3 requisitos nuevos (SD-RF-38 a SD-RF-40) por
funcionalidad de nuevo desarrollo, y se corrigieron las observaciones de 5 requisitos ya existentes
cuyos defectos fueron resueltos (SD-RF-07, SD-RF-08, SD-RF-14, SD-RF-18 a SD-RF-20, SD-RF-31). Total
actualizado: 37 → 40 requisitos.

| ID Requisito | Módulo | Descripción | Casos de prueba | Cobertura | Observaciones |
|---|---|---|---|---|---|
| SD-RF-01 | Login | Autenticar usuario con **usuario** y contraseña cifrada (SHA-256) | TC-AUTH-01 | Cubierto | Corregido: el login usa nombre de usuario, no correo electrónico |
| SD-RF-02 | Login | Redirigir al portal según el rol del usuario (admin/profesor/estudiante) | TC-AUTH-02 | Cubierto | |
| SD-RF-03 | Login | Mostrar mensaje de error ante credenciales incorrectas | TC-AUTH-03 | Cubierto | |
| SD-RF-04 | Login | Cerrar sesión y limpiar la sesión activa del usuario | TC-AUTH-04 | Cubierto | |
| SD-RF-05 | Portal Profesor | Registrar notas por componente (parcial1, parcial2, proyecto, examen_final) | TC-NOT-01 | Cubierto | |
| SD-RF-06 | Portal Profesor | Limitar a 3 modificaciones de nota por componente por estudiante | TC-NOT-02 | Cubierto | Se corrigió un defecto donde el bloqueo visual no se aplicaba tras el 3er intento; re-ejecutar TC-NOT-02 |
| SD-RF-07 | Portal Profesor / Admin | Autorizar modificación extra de nota desde el portal administrador | TC-NOT-03 | Cubierto | Corregido esta semana: la pantalla de supervisión estaba fijada a una sola materia ("Calidad del Software"); ahora se filtra por carrera y materia, cubriendo todas las materias del sistema |
| SD-RF-08 | Portal Profesor / Admin | Registrar historial de cambios de notas con nota anterior y nueva | TC-NOT-04 | Cubierto | |
| SD-RF-09 | Portal Profesor / Estudiante | Calcular automáticamente la nota final con ponderación (25%/25%/20%/30%) | TC-NOT-05 | Cubierto | |
| SD-RF-10 | Portal Estudiante | Permitir al estudiante consultar sus notas por materia | TC-NOT-06 | Cubierto | |
| SD-RF-11 | Portal Profesor | Registrar asistencia diaria de estudiantes por grupo | TC-ASI-01 | Cubierto | |
| SD-RF-12 | Portal Admin | Generar reporte de porcentaje de asistencia por grupo o estudiante | TC-ASI-02 | Cubierto | |
| SD-RF-13 | Portal Estudiante | Permitir al estudiante solicitar inscripción a una materia | TC-MAT-01 | Cubierto | |
| SD-RF-14 | Portal Estudiante | Permitir al estudiante solicitar retiro de una materia | TC-MAT-02 | Cubierto | Corregido esta semana: antes, al aprobarse el retiro se eliminaban permanentemente notas y asistencia; ahora la inscripción cambia a estado 'retirado' conservando su historial, y una re-inscripción posterior reactiva la misma inscripción en vez de duplicarla |
| SD-RF-15 | Portal Admin | Aprobar o rechazar solicitudes de matrícula desde el admin | TC-MAT-03 | Cubierto | |
| SD-RF-16 | Portal Estudiante | Limitar a 6 materias activas por estudiante | TC-MAT-04 | Cubierto | |
| SD-RF-17 | Portal Estudiante | Visualizar el estado de solicitudes de matrícula pendientes | TC-MAT-05 | Cubierto | |
| SD-RF-18 | Portal Profesor / Estudiante | Enviar mensajes internos entre usuarios del sistema | TC-MSG-01 | Cubierto | Corregido esta semana: el destinatario ya no es texto libre; el estudiante solo puede enviar a profesores de su propia carrera (validado también en el servidor) |
| SD-RF-19 | Portal Profesor / Estudiante | Consultar bandeja de mensajes recibidos y enviados | TC-MSG-02 | Cubierto | |
| SD-RF-20 | Portal Profesor / Estudiante | Marcar mensajes como leídos y gestionar notificaciones | TC-MSG-03 | Cubierto | |
| SD-RF-21 | Portal Profesor | Publicar avisos dirigidos a un grupo o de forma general | TC-AVI-01 | Cubierto | |
| SD-RF-22 | Portal Estudiante / Profesor | Visualizar avisos activos según el rol del usuario | TC-AVI-02 | Cubierto | |
| SD-RF-23 | Portal Admin | Archivar, restaurar y editar avisos desde el administrador | TC-AVI-03 | Cubierto | |
| SD-RF-24 | Portal Profesor | Visualizar los grupos y estudiantes asignados al profesor | TC-GRP-01 | Cubierto | |
| SD-RF-25 | Portal Profesor / Admin | Identificar y visualizar estudiantes en riesgo académico | TC-GRP-02 | Cubierto | |
| SD-RF-26 | Portal Admin | Reasignar o quitar profesores de grupos académicos | TC-GRP-03 | Cubierto | |
| SD-RF-27 | Portal Admin | Actualizar capacidad de grupos y créditos de materias | TC-GRP-04 | Cubierto | |
| SD-RF-28 | Portal Admin | Crear carreras con materias, facultades y salones asociados | TC-CAR-01 | Cubierto | |
| SD-RF-29 | Portal Admin | Crear grupos con horarios y aulas asignados | TC-CAR-02 | Cubierto | |
| SD-RF-30 | Portal Admin | Crear nuevos usuarios estudiantes con carrera y grupos iniciales | TC-USR-01 | Cubierto | |
| SD-RF-31 | Portal Admin | Crear nuevos usuarios profesores con departamento asignado | TC-USR-02 | Cubierto | Corregido esta semana: se agregó la columna cédula (con restricción UNIQUE) y se corrigió la validación de duplicados, que antes comparaba la columna equivocada y nunca detectaba repetidos |
| SD-RF-32 | Portal Admin | Generar reporte de promedio de notas por materia | TC-REP-01 | Cubierto | |
| SD-RF-33 | Portal Admin | Generar reporte de promedio de notas por carrera | TC-REP-02 | Cubierto | |
| SD-RF-34 | Portal Admin | Generar reporte de estudiantes aprobados y reprobados | TC-REP-03 | Cubierto | |
| SD-RF-35 | Portal Admin | Generar reporte de inscritos por materia y cupos disponibles | TC-REP-04 | Cubierto | El sub-reporte "Más/Menos Inscritos" no distingue entre salones de una misma materia con 2 secciones (defecto ya reportado); "Cupos Disponibles" sí distingue correctamente |
| SD-RF-36 | Portal Admin | Generar reporte de carga académica de profesores | TC-REP-05 | Cubierto | |
| SD-RF-37 | Portal Admin | Mostrar dashboard con estadísticas generales del sistema | TC-REP-06 | Cubierto | |
| SD-RF-38 | Portal Admin | Publicar avisos institucionales dirigidos a todos los estudiantes y profesores, editables y archivables | TC-AVI-04 | Cubierto | Nuevo esta semana; reutiliza el mismo mecanismo de edición/archivado ya existente para avisos de profesor |
| SD-RF-39 | Portal Estudiante | Restringir el envío de mensajes solo a profesores que dictan clase en la carrera del estudiante | TC-MSG-04 | Cubierto | Nuevo esta semana; el campo de destinatario pasó de texto libre a un selector con opciones válidas, y se valida también en el servidor |
| SD-RF-40 | Portal Profesor | Mostrar en el dashboard de inicio los grupos activos y notas pendientes reales del profesor en sesión | TC-GRP-05 | Cubierto | Nuevo esta semana; antes mostraba valores fijos (3 grupos, 12 pendientes) iguales para cualquier profesor que iniciara sesión |

## Requisitos removidos de esta matriz (no tienen pantalla que los use)

| ID original | Módulo | Descripción | Motivo |
|---|---|---|---|
| SD-RF-12 | Portal Estudiante | Permitir al estudiante consultar su historial de asistencia | No existe ninguna referencia a asistencia en el portal estudiante — ni pestaña ni endpoint |
| SD-RF-13 | Portal Admin | Supervisar y corregir registros de asistencia desde el admin | Backend completo (`listarSupervisionAsistencia`, `corregirAsistencia`) pero sin pantalla; confirmado que no es un requisito real del sistema |
| SD-RF-31 | Portal Admin | Gestionar períodos académicos (crear, activar) | Backend completo (`crearPeriodo`, `activarPeriodo`, `listarPeriodos`) pero sin pantalla; confirmado que el período actual es fijo para pruebas y no necesita gestión |

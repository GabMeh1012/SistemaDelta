# Plan: Carreras, Salones y Horarios en el Portal Administrador

**Estado:** ✅ Implementado y verificado (esquema, backend y UI aplicados contra la base real; ver commit/resumen en el chat).
**Objetivo de la simulación (corregido):** crear la carrera **"Ingeniería de Software"** (nueva, distinta de "Ingeniería en Sistemas Computacionales") bajo la Facultad de Sistemas, reutilizando 6 materias que **ya existen** en el catálogo, de **3er año / 1er semestre** (nivel 5). Todos los estudiantes ya creados pasan a pertenecer a esta carrera. Una de esas 6 materias (`SO-301`) se usa para probar la funcionalidad de **múltiples salones con distintos profesores**.

## 0. Supuestos fijados

- "3er año, 1er semestre" = **nivel 5** en la numeración 1–10 que ya usa `estudiantes.semestre`. Etiqueta nueva en las materias, no un periodo calendario. No se valida contra el semestre real del estudiante — solo metadata organizativa.
- `materias.carrera_id` es una FK simple (1 materia → 1 carrera), no N:N.
- **`IS-301` (Ingeniería de Software I) y `PS-301` (Pruebas de Software) quedan completamente fuera de este plan.** Ambas las dicta María Mosquera y **ambas ya tienen estudiantes reales inscritos** (`IS-301`: ana.cedeno, roberto.flores, maria.rios, carlos.mendoza — `PS-301`: daniela.vega, fernando.castro, silvia.nunez). No se les cambia `carrera_id`, grupo, horario ni profesor. Siguen excluidas del autoservicio de inscripción exactamente como hoy.

---

## 1. Reglas fijas del sistema (aplican a cualquier carrera futura, no solo a esta)

| Regla | Detalle |
|---|---|
| Toda carrera se crea con **exactamente 6 materias** | Pueden ser materias **existentes que se vinculan** (este caso) o materias **nuevas que se crean** en el mismo paso — mezcla permitida, siempre que sumen exactamente 6. |
| Máximo **3 salones por materia** | `crearGrupo()` cuenta los grupos existentes de esa materia; si ya hay 3, rechaza la creación de un 4º. |
| **Horario compartido por materia** | El horario (día + hora inicio/fin) se define **una sola vez, al crear el primer salón adicional** de una materia. Los salones siguientes de esa misma materia **heredan automáticamente** ese horario — no se vuelve a pedir. Cada salón adicional solo pide **aula** y (opcionalmente) **profesor**. |

Validaciones centrales: **choque de aula** (dos salones, cualquiera sea la materia, no pueden compartir aula a la misma hora) y **choque de profesor** (un profesor no puede estar en dos salones a la misma hora, sin importar la materia).

---

## 2. Base de datos — AGREGAR

| Objeto | Detalle | Por qué |
|---|---|---|
| Columna `materias.carrera_id` | `INT NULL`, FK → `carreras.id` | Hoy las materias no pertenecen a ninguna carrera. |
| Columna `materias.nivel` | `INT NULL` (1–10, mismo criterio que `estudiantes.semestre`) | Marca nivel de plan de estudios (5 = 3er año/1er sem). |
| Tabla `periodos` | `codigo VARCHAR(20) PK`, `nombre`, `fecha_inicio`, `fecha_fin`, `activo` | Formaliza `grupos.semestre`, hoy texto libre. Seed: `('2026-I', activo=1)`. |
| Fila nueva en `carreras` | `('Ingeniería de Software', 'IDS', facultad_id=FSC)` | La carrera de esta simulación. |

## 3. Base de datos — MODIFICAR

| Objeto | Cambio | Por qué |
|---|---|---|
| `grupos.profesor_id` | `NOT NULL` → `NULL` | Indispensable para crear salón vacante. |
| `grupos.semestre` | + FK → `periodos.codigo` | Sin riesgo, único valor actual coincide con el seed. |
| `materias` — 6 filas: `BD-301`, `IS-401`, `RC-402`, `WD-201`, `IA-401`, `SO-301` | `UPDATE ... SET carrera_id = IDS, nivel = 5` | Estas son las 6 materias reutilizadas de la nueva carrera. **No se tocan** `IS-301` ni `PS-301` (ver sección 0). Las 2 materias restantes del catálogo (`EM-201`, `EC-301`) quedan sin carrera por ahora. |
| `estudiantes` — los 26 registros actuales | `UPDATE estudiantes SET carrera_id = IDS, carrera = 'Ingeniería de Software'` | Todos los estudiantes ya creados (los 5 con `.est`, los 10 antiguos `EST-`, y los 11 restantes) pasan a pertenecer a esta carrera. |

## 4. Base de datos — ELIMINAR

Nada.

---

## 5. Backend — DAOs/métodos nuevos

| Archivo | Método nuevo | Función |
|---|---|---|
| `AdminDAO.java` (o nuevo `CarreraDAO.java`) | `listarCarreras()` | Lista carreras (id, nombre, código, facultad). |
| | `crearCarrera(nombre, codigo, facultadId, List<Integer> materiaIdsExistentes, List<MateriaNueva> materiasNuevas)` | Transacción única: inserta la carrera; vincula las materias existentes (`UPDATE carrera_id`) y crea las nuevas si las hay. Rechaza si el total combinado no es exactamente 6. |
| | `listarPeriodos()` / `crearPeriodo(codigo, nombre, fechaInicio, fechaFin)` / `activarPeriodo(codigo)` | CRUD simple de periodos; activar uno desactiva los demás. |
| `GrupoDAO.java` (o `AdminDAO.java`) | `crearGrupo(materiaId, codigoGrupo, aula, capacidad, periodoCodigo, horario opcional)` | Si la materia **no tiene** salones aún, exige `horario` (valida 7:00–15:00). Si **ya tiene** al menos 1 salón, clona automáticamente su horario para el nuevo. Rechaza si la materia ya tiene 3 salones. Valida `codigo_grupo` único y **choque de aula**. |
| | `listarHorarios(grupoId)` | Lectura del horario efectivo de un salón (propio o heredado). |
| | `listarSalonesSinProfesor(periodoCodigo)` | `grupos WHERE profesor_id IS NULL AND semestre = ?`. |
| | `listarProfesoresPorMateria(materiaId)` | Filtra profesores vía `profesor_materias` (primera vez que esa tabla se lee). |
| `AdminDAO.reasignarProfesor(...)` | Modificar | Bloquear si el salón ya tiene profesor; agregar chequeo de choque de horario del profesor contra **todos sus salones, cualquier materia, mismo periodo**; además, sembrar `profesor_materias` (`INSERT IGNORE`) para esa combinación profesor↔materia como efecto secundario (ver nota abajo). |
| `AdminDAO.java` | `quitarProfesor(grupoId, adminUsuarioId)` | Pone `profesor_id = NULL` (requerido antes de reasignar un salón ocupado). |
| `CrearUsuarioDAO.crearEstudiante(...)` | Modificar | Agregar parámetro `carreraId` (reemplaza el `obtenerCarreraId()` hardcodeado; default sugerido = "Ingeniería de Software") y `grupoIdInicial` opcional. Si viene `grupoIdInicial`, dentro de la misma transacción valida cupo e inserta directo en `inscripciones`. |

**Cambio ya aplicado (adelantado del plan):** se quitó la sección "Materias que imparte" (checkboxes) del formulario "Crear Profesor" — ese mecanismo llenaba `profesor_materias` pero nunca se leía en ningún flujo real. `CrearUsuarioDAO.crearProfesor(...)` ya no recibe `materiaIds`; el método `listarMaterias()` de esa misma clase y la acción `listarMaterias` de `AdminServlet` se eliminaron por quedar sin uso. La asignación profesor↔materia ahora ocurre exclusivamente al asignar un profesor a un **salón específico** (`reasignarProfesor`), que puebla `profesor_materias` automáticamente como efecto secundario — de ahí que ese método necesite el `INSERT IGNORE` adicional descrito arriba.

## 6. Backend — acciones nuevas en `AdminServlet.java`

`listarCarreras`, `crearCarrera`, `listarPeriodos`, `crearPeriodo`, `activarPeriodo`, `crearGrupo`, `listarHorarios`, `listarSalonesSinProfesor`, `listarProfesoresPorMateria`, `quitarProfesor`. `reasignarProfesor` ya existe, solo se refuerza.

## 7. Frontend

**A. Pantalla "Crear Carrera" (nueva):** nombre, código, facultad (fija). Para las 6 materias: checkboxes de materias existentes sin carrera asignada (para vincular) + opción de agregar materias nuevas si hacen falta, hasta sumar exactamente 6.

**B. Pantalla de gestión (reutiliza la pestaña "Materias" existente):** confirmado que `AdminDAO.listarMaterias()` ya hace `LEFT JOIN grupos` sin agrupar — una materia con varios salones ya devuelve varias filas de forma natural. Extensiones:
- Agrupar/encabezar visualmente por carrera.
- Mostrar aula y horario por fila.
- Botón **"Agregar salón"** por materia (máx. 3).
- Botón **"Quitar profesor"** junto al selector.
- Selector de profesor filtrado por `profesor_materias`.

**C. Vista "Salones sin profesor"** — filtro/badge dentro de la misma pantalla.

**D. Extender "Crear Estudiante":** selector de carrera (default "Ingeniería de Software") + selector opcional de salón específico si la materia elegida tiene más de uno. Inserción directa en `inscripciones` en la misma transacción, sin pasar por `solicitudes_matricula`.

---

## 8. Validaciones (resumen final)

1. Toda carrera con exactamente 6 materias (existentes vinculadas y/o nuevas).
2. Máximo 3 salones por materia.
3. Horario dentro de 7:00am–3:00pm, definido solo en el primer salón adicional.
4. Salones siguientes heredan el horario sin re-validar rango.
5. Sin choque de aula entre salones (cualquier materia), mismo horario/periodo.
6. No se asigna profesor a salón ya ocupado (hay que quitarlo primero).
7. No se asigna profesor con choque de horario en cualquiera de sus otros salones.
8. `codigo_grupo` único.

## 9. Explícitamente fuera de alcance

- Crear una facultad nueva (se usa solo "Facultad de Sistemas").
- Tocar `IS-301` o `PS-301` de cualquier forma (grupo, horario, profesor, carrera).
- Validar `materias.nivel` contra `estudiantes.semestre`.
- Multi-periodo con fechas calendario reales.
- Materias compartidas entre carreras (N:N).

## 10. Datos de la simulación concreta

- **Carrera nueva:** "Ingeniería de Software" (código `IDS`), Facultad de Sistemas.
- **Sus 6 materias** (reutilizadas del catálogo existente, `nivel=5`): `BD-301` (Base de Datos II), `IS-401` (Calidad del Software), `RC-402` (Redes y Comunicaciones), `WD-201` (Desarrollo Web), `IA-401` (Inteligencia Artificial), `SO-301` (Sistemas Operativos).
- **Todos los estudiantes ya creados (26)** pasan a `carrera_id = IDS`.
- **Materia de prueba para 3 salones:** `SO-301` — sin inscripciones activas de ningún estudiante hoy. Su salón actual (`GRP-SO-301`, profesora Sofía Quirós, Aula 2A) tiene horario en **4 bloques**: lunes, martes, miércoles y jueves, 7:00–9:00am (no 2 como se asumió en una versión anterior). Los salones 2 y 3 heredan esos 4 bloques completos.
  - Profesores libres los 4 días a esa hora (verificado contra la BD): Ana Rodríguez, Carlos Núñez, Luis Torres, Petra Méndez, Roberto King. Propuesta: **Ana Rodríguez** (salón 2) y **Luis Torres** (salón 3).
  - Aulas nuevas propuestas (ninguna de las 10 aulas actuales se repite): **"Aula 7A"** (salón 2) y **"Aula 7B"** (salón 3).
- `IS-301` y `PS-301` no se tocan bajo ninguna circunstancia (ver sección 0).

## 11. Restricciones y validaciones adicionales (encontradas en revisión de calidad)

**Restricciones técnicas a implementar:**
1. **Autoservicio dinámico por conteo de salones.** Cambiar la exclusión fija (`NOT IN ('IS-301','PS-301')`) en `portal_estudiante.jsp` por una regla que excluya automáticamente cualquier materia con más de 1 salón (ej. `HAVING COUNT(g.id) = 1`), combinada con la exclusión manual de esas dos. Sin esto, `SO-301` (hoy abierta a autoservicio) hereda el bug de `LIMIT 1`: los estudiantes que se autoinscriban siempre caerían en el salón de menor id, y los salones 2 y 3 nunca recibirían inscripciones por esa vía.
2. **`crearCarrera` debe rechazar vincular una materia que ya tenga `carrera_id` distinto asignado** — evita "robarle" silenciosamente una materia a otra carrera.
3. **El choque de horario/aula se valida bloque por bloque** (día + hora), no como un horario único — una materia puede tener varios bloques a la semana (`SO-301` tiene 4).
4. **El filtro de profesor por `profesor_materias` debe ser validación real de backend**, no solo de la lista desplegable del formulario — y como esa tabla está vacía hoy (0 filas), hay que sembrarla para los profesores actuales de las 6 materias **antes** de activar esa validación, o nadie pasaría el filtro.
5. **Concurrencia (menor prioridad):** revalidar el choque de aula/horario justo antes del `INSERT`, dentro de la misma transacción, por si dos operaciones administrativas ocurren casi simultáneamente.
6. **Mantener sincronizados `estudiantes.carrera` (texto) y `estudiantes.carrera_id` (FK)** en cada escritura — `AdminDAO.reportePromedioCarrera()` agrupa por el campo de texto.

**Checklist operativo para quien implemente/pruebe:**
1. Respaldo de la base de datos (`mysqldump`) antes de correr el `ALTER TABLE`/`UPDATE` masivo.
2. Confirmar que MySQL esté corriendo antes de usar las pantallas nuevas.
3. Verificar el horario real de cada materia antes de elegir profesores para salones adicionales (ya se corrigió el caso de `SO-301`, que tiene 4 bloques, no 2).
4. Confirmar que el profesor elegido tenga la materia marcada en `profesor_materias` antes de intentar asignarlo.
5. Revisar la convención del código de grupo antes de guardarlo (no hay UI para editarlo después).
6. Confirmar que la capacidad de cada salón nuevo sea realista para la cantidad de estudiantes que se planea matricular ahí.

# Matriz de Trazabilidad de Requisitos No Funcionales — SistemaDelta

Verificada directamente contra el código fuente y la configuración real del entorno (XAMPP/MySQL local,
sin build system). Cada fila indica si el requisito está efectivamente cubierto por el sistema tal como
existe hoy, no como se documentó originalmente.

| ID Requisito | Categoría | Descripción | Casos de prueba | Cobertura | Observaciones |
|---|---|---|---|---|---|
| RNF-01 | Seguridad | Las contraseñas deben almacenarse cifradas, nunca en texto plano | TC-NF-01 | Cubierto | Hash SHA-256 unidireccional en `UsuarioDAO`, verificado en código |
| RNF-02 | Seguridad | El sistema debe validar la sesión del usuario antes de exponer datos de cualquier portal | TC-NF-02 | Cubierto | Todos los servlets verifican `session.getAttribute` antes de procesar la petición |
| RNF-03 | Seguridad | El acceso a cada portal debe estar restringido según el rol del usuario autenticado | TC-NF-03 | Cubierto | Verificado control de rol en `LoginServlet` y en cada portal (admin/profesor/estudiante) |
| RNF-04 | Seguridad | Un estudiante no debe poder comunicarse con profesores fuera de su propia carrera | TC-NF-04 | Cubierto | Nuevo esta semana: `MensajeDAO.validarDestinatario` valida la relación real profesor↔carrera↔estudiante en el servidor, no solo en la interfaz |
| RNF-05 | Seguridad | El sistema debe limitar o bloquear intentos repetidos de acceso con credenciales incorrectas | — | No cubierto | No existe mecanismo de bloqueo de cuenta tras intentos fallidos; brecha conocida, fuera del alcance de este ciclo |
| RNF-06 | Seguridad | Las comunicaciones entre cliente y servidor deben viajar cifradas (HTTPS) | — | No cubierto | El sistema corre sobre HTTP plano en `localhost` (XAMPP); aceptable para el entorno académico actual, no para un despliegue en producción |
| RNF-07 | Seguridad | El acceso a la base de datos debe estar protegido con credenciales | — | No cubierto | La conexión usa el usuario `root` de MySQL sin contraseña (configuración por defecto de XAMPP, confirmado en `ConexionDB`) |
| RNF-08 | Integridad de datos | Las tablas relacionadas deben mantener integridad referencial mediante llaves foráneas | TC-NF-05 | Cubierto | Nuevo esta semana: se agregaron las 15 FK que faltaban en 9 tablas, siguiendo el mismo patrón CASCADE/SET NULL/RESTRICT ya usado en las 20 FK originales |
| RNF-09 | Integridad de datos | Las operaciones de retiro e inscripción no deben destruir el historial académico del estudiante | TC-NF-06 | Cubierto | Nuevo esta semana: el retiro cambia el estado de la inscripción en vez de eliminarla |
| RNF-10 | Trazabilidad | Los cambios de nota deben quedar registrados con fecha, valor anterior y nuevo valor | TC-NOT-04 | Cubierto | Verificado contra `notas_historial` y `historialNota()` |
| RNF-11 | Usabilidad | Los mensajes de error y confirmación deben ser claros y estar en español | TC-NF-07 | Cubierto | `showToast`/`showConfirm` usados de forma consistente en los 3 portales |
| RNF-12 | Usabilidad | La interfaz debe ser comprensible para usuarios sin experiencia técnica, incluyendo adultos mayores | TC-NF-08 | Cubierto | Validado al redactar los manuales de usuario de los 3 portales |
| RNF-13 | Usabilidad | Las funciones no implementadas deben notificarse explícitamente en vez de simular una acción que no ocurre | TC-NF-09 | Cubierto | Corregido esta semana en los botones "Descargar PDF" y "Adjuntar" de ambos portales |
| RNF-14 | Rendimiento | El sistema debe responder en un tiempo aceptable bajo la carga normal de uso académico de la universidad | — | No evaluado | Sin pruebas de carga/rendimiento; explícitamente fuera del alcance de este ciclo por restricción de tiempo del equipo de QA |
| RNF-15 | Disponibilidad | El sistema debe operar de forma continua durante el horario académico | — | No evaluado | Entorno de desarrollo local sobre XAMPP; no aplica infraestructura de alta disponibilidad en esta etapa del proyecto |
| RNF-16 | Mantenibilidad | El código no debe contener endpoints o funciones muertas que compliquen su mantenimiento | TC-NF-10 | Parcialmente cubierto | Se eliminaron 9 endpoints muertos de `AdminServlet` esta semana; persisten 2 (`corregirAsistencia`, `supervisionAsistencia`) sin pantalla que los use, documentados como conocidos |
| RNF-17 | Compatibilidad | El sistema debe operar sobre el stack declarado (Java Servlets/JSP, MySQL/MariaDB) sin depender de integraciones externas | TC-NF-11 | Cubierto | Confirmado: no existen integraciones con sistemas externos a la universidad en ningún módulo |
| RNF-18 | Escalabilidad de datos | El modelo de datos de carreras y salones debe soportar el esquema real de la universidad (6 materias por carrera, salón compartido) | TC-NF-12 | Cubierto | Implementado esta semana en `CarreraDAO` |

## Fuera de alcance para esta matriz

Pruebas de carga/rendimiento (RNF-14), disponibilidad de infraestructura (RNF-15), y pruebas de
seguridad especializadas (pentesting) más allá de la verificación de código realizada, quedan
explícitamente fuera del alcance de este ciclo de pruebas, consistente con lo definido en el Plan de
Pruebas del proyecto.

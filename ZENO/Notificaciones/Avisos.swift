import Foundation
import UserNotifications

/// Reglas de la sección 7 de la especificación:
/// - Cero avisos por defecto: solo si la persona los activa.
/// - Como mucho uno al día, a su hora de más energía, y nunca un día en que ya abrió ZENO.
/// - Si ignora el aviso diario dos veces seguidas, ZENO deja de enviarlo solo (queda en pausa).
/// - Tras más de tres días sin abrir: un único "Lumi sigue aquí". Nada más.
/// - Nunca culpa, rachas, números, sonidos ni el texto de las tareas (se ve en la pantalla bloqueada).
/// - Según la energía esperada a esa hora: baja → solo una frase de Chispa y nunca dos avisos en la
///   misma hora; media o alta → propone el siguiente paso pequeño (Diaz, 20 nov 2026).
///
/// iOS no ejecuta nuestro código cuando llega un aviso, así que todo se decide al abrir
/// la app o al salir de ella: se programa por adelantado y se revisa lo que pasó la vez siguiente.
enum Avisos {
    static let idDiario = "zeno.aviso.diario"
    static let idSigueAqui = "zeno.aviso.sigueAqui"
    static let idPrueba = "zeno.aviso.prueba"

    /// Pasado este tiempo sin tocar el aviso ni abrir la app, el aviso cuenta como ignorado.
    static let margenParaAbrir: TimeInterval = 3 * 3600
    private static let claveTocado = "zeno.avisoTocadoEn"

    // MARK: Plan (función pura: se puede comprobar sin esperar días)

    struct Plan: Equatable {
        var diario: Date?
        var sigueAqui: Date?
    }

    static func plan(activos: Bool, enPausa: Bool, mejorHora: Int, ultimoUso: Date,
                     calendario: Calendar = .current) -> Plan {
        guard activos else { return Plan() }

        // Diario: mañana a su mejor hora (hoy ya usó ZENO, así que hoy no hace falta).
        var diario: Date?
        if !enPausa, let manana = calendario.date(byAdding: .day, value: 1, to: ultimoUso) {
            diario = calendario.date(bySettingHour: mejorHora, minute: 0, second: 0, of: manana)
        }

        // "Lumi sigue aquí": la primera vez a su mejor hora después de tres días completos sin abrir.
        let limite = ultimoUso.addingTimeInterval(3 * 86_400)
        var sigueAqui = calendario.date(bySettingHour: mejorHora, minute: 0, second: 0, of: limite)
        if let s = sigueAqui, s < limite {
            sigueAqui = calendario.date(byAdding: .day, value: 1, to: s)
        }
        return Plan(diario: diario, sigueAqui: sigueAqui)
    }

    /// ¿Se ignoró el aviso diario? Solo si ya pasó, no se tocó y la app no se abrió poco después.
    static func fueIgnorado(programado: Date, tocadoEn: Date?, ahora: Date) -> Bool? {
        guard programado <= ahora else { return nil }                // todavía no llegaba
        if let tocadoEn, tocadoEn >= programado { return false }
        return ahora.timeIntervalSince(programado) > margenParaAbrir
    }

    // MARK: Según la energía (funciones puras)

    /// Qué dice un aviso. iOS no deja correr código cuando llega, así que se decide al programarlo
    /// con la energía que ZENO espera a esa hora (la misma curva de la mejor hora).
    enum TipoDeAviso: Equatable {
        /// Energía baja: solo una frase cálida de Chispa, sin proponer nada.
        case frase
        /// Energía media o alta: propone el siguiente paso pequeño (sin decir cuál: el texto de las
        /// tareas nunca sale en la pantalla bloqueada).
        case paso
    }

    static func tipo(para nivel: NivelDeEnergia) -> TipoDeAviso { nivel == .baja ? .frase : .paso }

    /// La energía esperada a una hora del día (0–23), con lo aprendido.
    static func nivelEsperado(hora: Int, horasDelDia: [Double]) -> NivelDeEnergia {
        guard horasDelDia.indices.contains(hora) else { return .media }
        return MotorDeEnergia.nivel(horasDelDia[hora])
    }

    /// Con energía baja, nunca dos avisos en la misma hora: si otro aviso (el de una tarea) cae a menos
    /// de 60 minutos, el de ZENO no se manda. Con energía media o alta no hace falta.
    static func caben(_ fecha: Date, nivel: NivelDeEnergia, otros: [Date]) -> Bool {
        nivel != .baja || !otros.contains { abs($0.timeIntervalSince(fecha)) < 3600 }
    }

    // MARK: Al abrir y al salir

    /// Al abrir ZENO: revisa si el último aviso se ignoró y vuelve a programar.
    @MainActor
    static func alAbrir(_ persona: Persona, eventos: [Senal]) async {
        let centro = UNUserNotificationCenter.current()
        let ajustes = await centro.notificationSettings()

        // La persona puede quitar el permiso desde los Ajustes del iPhone.
        if persona.notificacionesActivas && ajustes.authorizationStatus != .authorized {
            persona.notificacionesActivas = false
        }

        if let programado = persona.avisoDiarioProgramado {
            let tocado = UserDefaults.standard.object(forKey: claveTocado) as? Date
            if let ignorado = fueIgnorado(programado: programado, tocadoEn: tocado, ahora: .now) {
                persona.avisosIgnorados = ignorado ? persona.avisosIgnorados + 1 : 0
                persona.avisoDiarioProgramado = nil
                if persona.avisosIgnorados >= 2 { persona.avisosEnPausa = true }
            }
        }
        // Ya abrió: el aviso de bienvenida de vuelta ya no hace falta en la bandeja.
        centro.removeAllDeliveredNotifications()
        await programar(persona, eventos: eventos)
    }

    /// Al salir de ZENO: los tres días de "Lumi sigue aquí" se cuentan desde este momento.
    @MainActor
    static func alSalir(_ persona: Persona, eventos: [Senal]) async {
        await programar(persona, eventos: eventos)
    }

    @MainActor
    static func programar(_ persona: Persona, eventos: [Senal], ahora: Date = .now) async {
        let centro = UNUserNotificationCenter.current()
        centro.removePendingNotificationRequests(withIdentifiers: [idDiario, idSigueAqui])

        let hora = MotorDeEnergia.mejorHora(persona: persona, eventos: eventos, ahora: ahora)
        let plan = plan(activos: persona.notificacionesActivas, enPausa: persona.avisosEnPausa,
                        mejorHora: hora, ultimoUso: ahora)
        // Antes de cada aviso: la energía esperada a esa hora decide qué dice y si cabe.
        let horas = MotorDeEnergia.horasDelDia(persona: persona, eventos: eventos, ahora: ahora)
        let deTareas = await pendientes().filter { $0.id.hasPrefix(AvisosDeTareas.prefijo) }.compactMap(\.fecha)
        func nivel(_ fecha: Date) -> NivelDeEnergia {
            nivelEsperado(hora: Calendar.current.component(.hour, from: fecha), horasDelDia: horas)
        }

        var diario = plan.diario
        if let fecha = diario, caben(fecha, nivel: nivel(fecha), otros: deTareas) {
            let tipo = tipo(para: nivel(fecha))
            try? await centro.add(peticion(idDiario, fecha: fecha, texto: frase(para: fecha, tipo: tipo),
                                           titulo: tipo == .frase ? Cohete.nombre : "Lumi"))
        } else {
            diario = nil
        }
        persona.avisoDiarioProgramado = diario
        if let fecha = plan.sigueAqui, caben(fecha, nivel: nivel(fecha), otros: deTareas) {
            try? await centro.add(peticion(idSigueAqui, fecha: fecha,
                                           texto: Idioma.texto("Lumi sigue aquí.")))
        }
    }

    // MARK: Activar y desactivar

    enum Resultado { case activados, denegados }

    /// Solo se pide permiso cuando la persona enciende el interruptor (nunca "provisional").
    @MainActor
    static func activar(_ persona: Persona, eventos: [Senal]) async -> Resultado {
        let centro = UNUserNotificationCenter.current()
        let permitido = (try? await centro.requestAuthorization(options: [.alert])) ?? false
        guard permitido else {
            persona.notificacionesActivas = false
            return .denegados
        }
        persona.notificacionesActivas = true
        persona.avisosEnPausa = false
        persona.avisosIgnorados = 0
        await programar(persona, eventos: eventos)
        return .activados
    }

    @MainActor
    static func desactivar(_ persona: Persona) {
        persona.notificacionesActivas = false
        persona.avisoDiarioProgramado = nil
        // Solo los avisos diarios: los de las tareas los pidió la persona y siguen.
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [idDiario, idSigueAqui])
        UserDefaults.standard.removeObject(forKey: claveTocado)
    }

    /// Volver a encender el aviso diario después de una pausa.
    @MainActor
    static func reanudar(_ persona: Persona, eventos: [Senal]) async {
        persona.avisosEnPausa = false
        persona.avisosIgnorados = 0
        await programar(persona, eventos: eventos)
    }

    /// Al apagar los avisos o borrar los datos: no queda nada pendiente ni en la bandeja.
    static func cancelarTodo() {
        let centro = UNUserNotificationCenter.current()
        centro.removeAllPendingNotificationRequests()
        centro.removeAllDeliveredNotifications()
        UserDefaults.standard.removeObject(forKey: claveTocado)
    }

    static func registrarToque() {
        UserDefaults.standard.set(Date.now, forKey: claveTocado)
    }

    // MARK: Pruebas (Modo de prueba)

    static func enviarPrueba(en segundos: TimeInterval = 10) async {
        let contenido = contenido(Idioma.texto("Es tu mejor momento del día. Una sola cosa, si quieres."))
        let disparo = UNTimeIntervalNotificationTrigger(timeInterval: segundos, repeats: false)
        try? await UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: idPrueba, content: contenido, trigger: disparo))
    }

    static func pendientes() async -> [(id: String, fecha: Date?)] {
        await UNUserNotificationCenter.current().pendingNotificationRequests().map { p in
            (p.identifier, (p.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
                ?? (p.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate())
        }
    }

    // MARK: Contenido

    /// Frases amables que cambian según el día. Nunca el texto de una tarea, nunca números.
    /// Energía baja: solo compañía de Chispa. Media o alta: el siguiente paso pequeño, sin decir cuál.
    static func frase(para fecha: Date, tipo: TipoDeAviso = .paso) -> String {
        let frases = tipo == .frase ? [
            Idioma.texto("Aquí sigo, sin prisa."),
            Idioma.texto("Hoy puede ser suave. Te acompaño."),
            Idioma.texto("Nada que hacer ahora. Solo pasaba a saludarte."),
            Idioma.texto("Descansar también cuenta. Aquí estoy.")
        ] : [
            Idioma.texto("Tienes un paso pequeño listo. Uno solo, si quieres."),
            Idioma.texto("Es tu mejor momento del día. Una sola cosa, si quieres."),
            Idioma.texto("Un buen rato para una sola cosa."),
            Idioma.texto("Si te apetece, Lumi tiene algo pequeño para ti.")
        ]
        let dia = Calendar.current.ordinality(of: .day, in: .era, for: fecha) ?? 0
        return frases[dia % frases.count]
    }

    private static func contenido(_ texto: String, titulo: String = "Lumi") -> UNMutableNotificationContent {
        let c = UNMutableNotificationContent()
        c.title = titulo
        c.body = texto
        c.sound = nil                       // sin sonidos
        c.interruptionLevel = .active
        c.threadIdentifier = "zeno"
        return c
    }

    private static func peticion(_ id: String, fecha: Date, texto: String, titulo: String = "Lumi") -> UNNotificationRequest {
        let partes = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fecha)
        // Nunca se repite solo: así un aviso ignorado no sigue llegando.
        let disparo = UNCalendarNotificationTrigger(dateMatching: partes, repeats: false)
        return UNNotificationRequest(identifier: id, content: contenido(texto, titulo: titulo), trigger: disparo)
    }
}

/// Recibe los toques en los avisos. Se instala al arrancar la app para no perder
/// el toque que abre ZENO desde cero (si no, parecería que el aviso se ignoró).
final class CentroDeAvisos: NSObject, UNUserNotificationCenterDelegate {
    static let compartido = CentroDeAvisos()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        Avisos.registrarToque()
    }

    /// Con ZENO abierta no hace falta el aviso diario (sí el de prueba y los de tareas).
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Los avisos de tareas sí se muestran: la persona los pidió para esa hora.
        let id = notification.request.identifier
        return id == Avisos.idPrueba || id.hasPrefix(AvisosDeTareas.prefijo) ? [.banner, .list] : []
    }
}

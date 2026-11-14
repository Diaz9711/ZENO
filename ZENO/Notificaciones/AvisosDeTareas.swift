import Foundation
import SwiftData
import UserNotifications

/// Cuándo avisar de una tarea con día y hora.
enum OpcionDeAviso: Int, CaseIterable, Identifiable {
    case ninguno, aLaHora, diezAntes, unaHoraAntes, personalizado
    var id: Int { rawValue }

    /// Minutos antes de la hora planeada (para las opciones fijas).
    var minutosAntes: Int? {
        switch self {
        case .aLaHora: 0
        case .diezAntes: 10
        case .unaHoraAntes: 60
        case .ninguno, .personalizado: nil
        }
    }

    init(minutosAntes: Int?, personalizado: Date?) {
        if personalizado != nil { self = .personalizado; return }
        switch minutosAntes {
        case 0: self = .aLaHora
        case 10: self = .diezAntes
        case 60: self = .unaHoraAntes
        default: self = .ninguno
        }
    }
}

extension Tarea {
    var opcionDeAviso: OpcionDeAviso {
        OpcionDeAviso(minutosAntes: avisoMinutosAntes, personalizado: avisoPersonalizado)
    }

    /// El instante exacto del aviso, si la persona pidió uno.
    var momentoDelAviso: Date? {
        if let avisoPersonalizado { return avisoPersonalizado }
        guard let fechaPlaneada, let minutos = avisoMinutosAntes else { return nil }
        return fechaPlaneada.addingTimeInterval(-Double(minutos) * 60)
    }

    /// Guarda el plan elegido en la tarea.
    func aplicarPlan(fecha: Date?, aviso: OpcionDeAviso, personalizado: Date) {
        fechaPlaneada = fecha
        guard fecha != nil else {
            avisoMinutosAntes = nil
            avisoPersonalizado = nil
            return
        }
        avisoMinutosAntes = aviso.minutosAntes
        avisoPersonalizado = aviso == .personalizado ? personalizado : nil
    }
}

/// Los avisos que la persona programa para sus tareas (aparte del aviso diario de `Avisos`).
/// Regla simple: cada vez que algo cambia se borran todos los avisos de tareas pendientes en iOS
/// y se vuelven a crear desde lo guardado. Así editar, terminar o borrar nunca deja uno suelto.
enum AvisosDeTareas {
    static let prefijo = "zeno.tarea."

    @MainActor
    static func sincronizar(_ contexto: ModelContext) async {
        try? contexto.save()
        let tareas = (try? contexto.fetch(FetchDescriptor<Tarea>())) ?? []
        let centro = UNUserNotificationCenter.current()

        let viejos = await centro.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(prefijo) }
        centro.removePendingNotificationRequests(withIdentifiers: viejos)

        guard await centro.notificationSettings().authorizationStatus == .authorized else { return }
        for tarea in tareas where tarea.terminadaEn == nil {
            guard let cuando = tarea.momentoDelAviso, cuando > .now else { continue }
            let id: String
            if let existente = tarea.idAviso {
                id = existente
            } else {
                id = UUID().uuidString
                tarea.idAviso = id
            }
            let c = UNMutableNotificationContent()
            c.title = "Lumi"
            // Sin el texto de la tarea: se vería en la pantalla bloqueada (regla de ZENO).
            c.body = tarea.opcionDeAviso == .aLaHora
                ? Idioma.texto("Es el momento que elegiste. Lumi te acompaña.")
                : Idioma.texto("Se acerca algo que planeaste. Sin prisa.")
            c.sound = nil
            c.threadIdentifier = "zeno"
            let partes = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: cuando)
            let disparo = UNCalendarNotificationTrigger(dateMatching: partes, repeats: false)
            try? await centro.add(UNNotificationRequest(identifier: prefijo + id, content: c, trigger: disparo))
        }
        try? contexto.save()
    }

    enum Permiso { case concedido, denegado }

    /// Se pide solo cuando la persona elige un aviso para una tarea: entiende para qué es.
    static func pedirPermiso() async -> Permiso {
        let centro = UNUserNotificationCenter.current()
        switch await centro.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .concedido
        case .notDetermined:
            let si = (try? await centro.requestAuthorization(options: [.alert])) ?? false
            return si ? .concedido : .denegado
        default:
            return .denegado
        }
    }
}

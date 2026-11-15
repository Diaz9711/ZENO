import Foundation
import CryptoKit
import Security
import LocalAuthentication

/// La clave de ZENO (decisión de Diaz, 14 nov 2026): protege ZENO en ESTE iPhone.
/// No hay servidor: la clave nunca sale del teléfono y no se guarda tal cual, sino su huella
/// (sal aleatoria + SHA-256 repetido) en el Llavero de iOS, solo en este dispositivo.
/// Si se olvida, se recupera con Face ID o el código del iPhone y se elige una nueva.
enum Clave {
    private static let servicio = "app.zeno.ZENO.clave"
    private static let cuenta = "zeno"
    private static let vueltas = 20_000
    static let minimo = 6

    // MARK: Validación

    enum Problema: Equatable {
        case vacia, corta, noCoinciden, incorrecta, bloqueada(segundos: Int)

        var mensaje: String {
            switch self {
            case .vacia: Idioma.texto("Escribe tu clave.")
            case .corta: Idioma.texto("La clave necesita al menos \(Clave.minimo) caracteres.")
            case .noCoinciden: Idioma.texto("Las dos claves no son iguales.")
            case .incorrecta: Idioma.texto("Esa no es tu clave. Inténtalo otra vez.")
            case .bloqueada(let s): Idioma.texto("Demasiados intentos. Espera \(s) segundos o usa Face ID.")
            }
        }
    }

    /// Para crear o cambiar la clave.
    static func validar(nueva: String, repetida: String) -> Problema? {
        if nueva.isEmpty { return .vacia }
        if nueva.count < minimo { return .corta }
        if nueva != repetida { return .noCoinciden }
        return nil
    }

    // MARK: Guardar y comprobar

    /// Se recuerda: leer el Llavero en cada dibujo de Ajustes frenaba la entrada a la página.
    private static var existeGuardado: Bool?
    static var existe: Bool {
        if let ya = existeGuardado { return ya }
        let hay = leer() != nil
        existeGuardado = hay
        return hay
    }

    static func guardar(_ texto: String) {
        var sal = Data(count: 16)
        _ = sal.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!) }
        escribir(sal + huella(texto, sal: sal))
        UserDefaults.standard.removeObject(forKey: claveIntentos)
        UserDefaults.standard.removeObject(forKey: claveBloqueo)
    }

    /// Comprueba la clave; tras 5 fallos seguidos espera 30 s (Face ID sigue disponible).
    static func comprobar(_ texto: String) -> Problema? {
        if texto.isEmpty { return .vacia }
        let ajustes = UserDefaults.standard
        if let hasta = ajustes.object(forKey: claveBloqueo) as? Date, hasta > .now {
            return .bloqueada(segundos: Int(hasta.timeIntervalSinceNow.rounded(.up)))
        }
        guard let datos = leer(), datos.count == 48 else { return .incorrecta }
        let sal = datos.prefix(16)
        if huella(texto, sal: Data(sal)) == datos.suffix(32) {
            ajustes.removeObject(forKey: claveIntentos)
            return nil
        }
        let intentos = ajustes.integer(forKey: claveIntentos) + 1
        ajustes.set(intentos, forKey: claveIntentos)
        if intentos >= 5 {
            ajustes.set(Date.now.addingTimeInterval(30), forKey: claveBloqueo)
            ajustes.set(0, forKey: claveIntentos)
            return .bloqueada(segundos: 30)
        }
        return .incorrecta
    }

    static func borrar() {
        SecItemDelete(consulta as CFDictionary)
        existeGuardado = false
        UserDefaults.standard.removeObject(forKey: claveIntentos)
        UserDefaults.standard.removeObject(forKey: claveBloqueo)
    }

    // MARK: Face ID o código del iPhone

    /// ¿Este iPhone puede confirmar que es su dueño (Face ID, Touch ID o código)?
    static var puedeUsarFaceID: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    static var nombreBiometria: String {
        let c = LAContext()
        _ = c.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch c.biometryType {
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Face ID"
        }
    }

    /// Confirma que quien tiene el iPhone es su dueño. Si no hay Face ID, iOS pide el código.
    static func confirmarDueno(motivo: String) async -> Bool {
        let contexto = LAContext()
        contexto.localizedCancelTitle = Idioma.texto("Cancelar")
        return (try? await contexto.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: motivo)) ?? false
    }

    // MARK: Por dentro

    private static let claveIntentos = "zeno.clave.intentos"
    private static let claveBloqueo = "zeno.clave.bloqueo"

    private static func huella(_ texto: String, sal: Data) -> Data {
        var actual = Data(SHA256.hash(data: sal + Data(texto.utf8)))
        for _ in 1..<vueltas { actual = Data(SHA256.hash(data: actual + sal)) }
        return actual
    }

    private static var consulta: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: servicio,
         kSecAttrAccount as String: cuenta]
    }

    private static func leer() -> Data? {
        var q = consulta
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var resultado: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &resultado) == errSecSuccess else { return nil }
        return resultado as? Data
    }

    private static func escribir(_ datos: Data) {
        existeGuardado = true
        SecItemDelete(consulta as CFDictionary)
        var q = consulta
        q[kSecValueData as String] = datos
        q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(q as CFDictionary, nil)
    }
}
